#!/usr/bin/env ruby
# frozen_string_literal: true

# Diffs the SEP-0051 XDR-JSON names that actually reached the generated Dart against
# name-map.json, the table name_map.rb derives from the .x sources and checks against the
# pinned reference CLI.
#
# This closes a gap name_map.rb cannot close. That tool proves the derivation module agrees
# with the reference, but it calls the module the same way for every type, so it can only
# ever confirm that the rules are right. It says nothing about how the generator invokes
# them: a wrong sibling list handed to the enum prefix computation, a key emitted under the
# wrong field, a struct whose keys come out in the wrong order, or a type-level rendering
# that stopped being applied would all leave name_map.rb green and ship wrong JSON. Reading
# the emitted Dart back is the only check that sees those.
#
# Usage:
#   ruby emitted_names.rb           Report the diff.
#   ruby emitted_names.rb --quiet   Print only the summary and any problems.
#
# Never writes anything. Exits 1 on any mismatch, missing name, extra name, or missing file.

require 'json'
require 'set'

SCRIPT_DIR = __dir__
ROOT = File.expand_path('../..', __dir__)
DART_DIR = File.join(ROOT, 'lib/src/xdr')
NAME_MAP = File.join(SCRIPT_DIR, 'name-map.json')

require File.join(ROOT, 'tools/xdr-generator/generator/type_overrides')

# The verification-block lists naming the types the reference renders as a single string
# rather than as an object or a keyed arm. A type in one of these carries no derived names,
# so it is checked by its rendering instead of by its keys.
STRING_RENDERED_KEYS = %w[
  struct_types_string_rendered
  union_types_string_rendered
].freeze

# ---------------------------------------------------------------------------
# Reading the emitted Dart
#
# The scans below tolerate any line breaking, because `dart format` wraps a long
# signature, a long return and a long map literal differently from short ones, and a
# scan fitted to one shape would silently compare nothing for the others.
# ---------------------------------------------------------------------------

# Reproduces the generator's file naming so a type is read from the file it was written to.
# A path this derives wrongly surfaces as a missing file rather than as a silent pass.
def file_for(dart_name)
  base = BASE_WRAPPER_TYPES.include?(dart_name) ? "#{dart_name}Base" : dart_name
  snake = base
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
  File.join(DART_DIR, "#{snake}.dart")
end

# The source from [start], which must index an opening brace, through its match.
#
# Single-quoted Dart strings are stepped over, so a brace inside a message or an
# interpolation cannot unbalance the count.
def balanced_braces(source, start)
  depth = 0
  index = start

  while index < source.length
    case source[index]
    when "'"
      index += 1
      index += source[index] == '\\' ? 2 : 1 while index < source.length && source[index] != "'"
    when '{'
      depth += 1
    when '}'
      depth -= 1
      return source[start..index] if depth.zero?
    end
    index += 1
  end

  nil
end

# The body of the member matching [signature], or nil.
def member_body(source, signature)
  match = source.match(signature)
  return nil unless match

  brace = source.index('{', match.end(0))
  brace && balanced_braces(source, brace)
end

# The source of `toXdrJsonValue`, bounded by the next class member.
def to_json_value_member(source)
  index = source =~ /Object\?\s+toXdrJsonValue\s*\(\s*\)/
  return nil unless index

  tail = source[index..]
  stop = tail.index(%r{\n  ///|\n  static |\n  Object\? }, 40) || tail.length
  tail[0...stop]
end

# The object literal a type builds for its own rendering, or nil when it renders as
# something other than an object.
def json_object_body(source)
  member = to_json_value_member(source)
  return nil unless member

  open = member.index('<String, Object?>')
  return nil unless open

  brace = member.index('{', open)
  brace && balanced_braces(member, brace)
end

# The keys of a Dart map literal, in order.
#
# Scanning for quoted strings alone would over-match: a field rendered through a
# type-level helper carries its own type and key as arguments, so
# `'asset_code': XdrJsonHelper.assetCode4(_assetCode, type: 'XdrAssetAlphaNum4',
# key: 'asset_code')` holds three quoted strings and one key. Only a string at the
# literal's own nesting depth, followed by a colon, is a key.
def map_literal_keys(body)
  keys = []
  depth = 0
  index = 0

  while index < body.length
    case body[index]
    when '(', '[', '{'
      depth += 1
    when ')', ']', '}'
      depth -= 1
    when "'"
      close = index + 1
      close += body[close] == '\\' ? 2 : 1 while close < body.length && body[close] != "'"
      break if close >= body.length

      literal = body[(index + 1)...close]
      keys << literal if depth == 1 && body[(close + 1)..]&.match?(/\A\s*:/)
      index = close
    end
    index += 1
  end

  keys
end

# ---------------------------------------------------------------------------
# Comparison
# ---------------------------------------------------------------------------

# NAME_OVERRIDES is many-to-one: three Dart names have two .x sources each, and one Dart
# class is all that exists for both. A group like that can only carry one .x type's member
# identifiers, so the identifier-keyed comparison below does not apply to it. What must
# still hold is that the collapse is invisible on the wire -- the sources have to agree on
# every JSON name, or one of them is being rendered as the other. That agreement is checked
# first, and the emitted Dart is then compared against the shared wire surface.
class Group
  attr_reader :dart_name, :entries

  def initialize(dart_name, entries)
    @dart_name = dart_name
    @entries = entries
  end

  def collapsed? = entries.length > 1
  def sources = entries.map { |entry| entry['xdr_name'] }

  def wire_names(kind)
    entries.map { |entry| Group.wire_of(entry, kind) }
  end

  def self.wire_of(entry, kind)
    case kind
    when :enum then entry['members'].map { |member| member['json'] }
    when :struct then entry['fields'].map { |field| field['json'] }
    else entry['arms'].reject { |arm| arm['case'] == 'default' }.map { |arm| arm['json'] }
    end
  end

  def self.build(entries)
    entries.group_by { |entry| entry['dart_name'] }
           .map { |dart_name, group| new(dart_name, group) }
  end
end

class Diff
  attr_reader :problems, :notes, :counts

  def initialize(string_rendered)
    @string_rendered = string_rendered
    @problems = []
    @notes = []
    @counts = Hash.new(0)
  end

  def read(dart_name, kind)
    path = file_for(dart_name)
    return File.read(path) if File.exist?(path)

    @problems << "#{kind} #{dart_name}: no generated file at #{path.sub("#{ROOT}/", '')}"
    nil
  end

  # Reports a group whose sources disagree on the wire, and records the rest as notes.
  def check_collapse(group, kind)
    return true unless group.collapsed?

    @counts[:collapsed] += 1
    names = group.wire_names(kind)
    if names.uniq.length > 1
      @problems << "#{kind} #{group.dart_name}: collapses #{group.sources.join(' and ')}, " \
                   'which do not agree on their JSON names, so one of them cannot be rendered'
      return false
    end

    @notes << "#{kind} #{group.dart_name}: one Dart type for #{group.sources.join(' and ')}, " \
              'identical on the wire'
    true
  end

  # An enum's reader pairs each JSON name with the member it returns, so the two are read
  # from one place and cannot be matched up wrongly here. A collapsed group has no single
  # identifier set to pair against, so it is compared on its ordered wire names instead.
  def enums(groups)
    groups.each do |group|
      next unless check_collapse(group, :enum)

      dart_name = group.dart_name
      source = read(dart_name, 'enum') or next
      body = member_body(source, /static\s+#{dart_name}\s+fromXdrJsonValue\s*\(/)
      if body.nil?
        @problems << "enum #{dart_name}: emits no fromXdrJsonValue"
        next
      end

      pairs = body.scan(/case\s+'([^']*)':\s*\n\s*return\s+\w+\s*\.\s*(\w+)\s*;/m)
      expected = group.entries.first['members']
      @counts[:enum_members] += expected.length

      if group.collapsed?
        compare_list("enum #{dart_name}", pairs.map(&:first),
                     expected.map { |member| member['json'] })
        next
      end

      emitted = pairs.to_h { |json, identifier| [identifier, json] }
      table = expected.to_h { |member| [member['identifier'], member['json']] }

      (table.keys - emitted.keys).each do |id|
        @problems << "enum #{dart_name}.#{id}: no member emitted"
      end
      (emitted.keys - table.keys).each do |id|
        @problems << "enum #{dart_name}.#{id}: emitted but not in the table"
      end
      table.each do |identifier, json|
        actual = emitted[identifier]
        next if actual.nil? || actual == json

        @problems << "enum #{dart_name}.#{identifier}: emitted #{actual.inspect}, " \
                     "table #{json.inspect}"
      end
    end
  end

  # Struct keys are compared as an ordered list: SEP-0051 output is field declaration order,
  # so a reordering is a wire-format change even when the key set is unchanged.
  def structs(groups)
    groups.each do |group|
      next unless check_collapse(group, :struct)
      next if skip_string_rendered(group, 'struct')

      dart_name = group.dart_name
      source = read(dart_name, 'struct') or next
      expected = Group.wire_of(group.entries.first, :struct)
      @counts[:struct_types] += 1
      @counts[:struct_keys] += expected.length

      body = json_object_body(source)
      if body.nil?
        @problems << "struct #{dart_name}: emits no JSON object"
        next
      end

      compare_list("struct #{dart_name}", map_literal_keys(body), expected)
    end
  end

  # Arm keys are compared as a set: a union renders one arm at a time, so their order in the
  # generated dispatch carries no wire meaning.
  def unions(groups)
    groups.each do |group|
      next unless check_collapse(group, :union)
      next if skip_string_rendered(group, 'union')

      dart_name = group.dart_name
      source = read(dart_name, 'union') or next
      class_name = BASE_WRAPPER_TYPES.include?(dart_name) ? "#{dart_name}Base" : dart_name
      expected = Group.wire_of(group.entries.first, :union).to_set
      @counts[:union_types] += 1
      @counts[:union_arms] += expected.length

      body = member_body(source, /static\s+#{class_name}\s+fromXdrJsonValue\s*\(/)
      if body.nil?
        @problems << "union #{dart_name}: emits no fromXdrJsonValue"
        next
      end

      emitted = body.scan(/case\s+'([^']*)':/).flatten.to_set
      next if emitted == expected

      @problems << "union #{dart_name}: emitted #{emitted.to_a.sort.inspect}, " \
                   "table #{expected.to_a.sort.inspect}"
    end
  end

  # A type the reference renders as a single string carries no derived names to diff. It must
  # still exist, and it must genuinely have stopped emitting an object: a type that kept its
  # object rendering is one whose Stellar-specific rendering never got applied.
  def skip_string_rendered(group, kind)
    return false unless @string_rendered.include?(group.dart_name)

    @counts[:string_rendered] += 1
    source = read(group.dart_name, kind)
    if source && json_object_body(source)
      @problems << "#{kind} #{group.dart_name}: the reference renders this as a string, " \
                   'but it still emits a JSON object'
    end
    true
  end

  def compare_list(label, emitted, expected)
    return if emitted == expected

    @problems << "#{label}: emitted #{emitted.inspect}, table #{expected.inspect}"
  end
end

def main
  quiet = ARGV.include?('--quiet')

  unless File.exist?(NAME_MAP)
    abort "Missing #{NAME_MAP}. Run 'ruby tools/sep-51-oracle/name_map.rb' first."
  end

  table = JSON.parse(File.read(NAME_MAP))

  # Read from the oracle's own verdict rather than from the generator's registry, so a type
  # the generator forgot to override is reported instead of being excused by the same
  # omission. The name map records these under their .x names, one list per definition kind.
  #
  # A kind the verification block does not record yet reads as empty rather than failing, so
  # the list of kinds can grow in the name map without a matching edit here.
  string_rendered_x = STRING_RENDERED_KEYS
                      .flat_map { |name| table.dig('verification', name).to_a }
                      .to_set
  string_rendered = (table['structs'] + table['unions'])
                    .select { |entry| string_rendered_x.include?(entry['xdr_name']) }
                    .map { |entry| entry['dart_name'] }.to_set

  diff = Diff.new(string_rendered)
  diff.enums(Group.build(table['enums']))
  diff.structs(Group.build(table['structs']))
  diff.unions(Group.build(table['unions']))

  counts = diff.counts
  total = counts[:enum_members] + counts[:struct_keys] + counts[:union_arms]

  unless quiet
    puts
    puts 'Generated Dart vs name-map.json'
  end
  puts format('  enum members:    %d', counts[:enum_members])
  puts format('  struct types:    %d, %d field keys compared in emission order',
              counts[:struct_types], counts[:struct_keys])
  puts format('  union types:     %d, %d arm keys', counts[:union_types], counts[:union_arms])
  puts format('  string-rendered: %d types skipped', counts[:string_rendered])
  puts format('  collapsed names: %d Dart types serving two .x types each', counts[:collapsed])
  puts format('  names compared:  %d', total)
  puts format('  problems:        %d', diff.problems.length)

  if !quiet && !diff.notes.empty?
    puts
    puts 'Notes:'
    diff.notes.each { |note| puts "  #{note}" }
  end

  if total.zero?
    puts
    puts 'Compared no names at all, which means the patterns no longer match the emitted Dart.'
    exit 1
  end

  unless diff.problems.empty?
    puts
    puts 'Problems:'
    diff.problems.each { |problem| puts "  #{problem}" }
    exit 1
  end
end

main if $PROGRAM_NAME == __FILE__
