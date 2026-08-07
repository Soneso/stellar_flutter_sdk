#!/usr/bin/env ruby
# frozen_string_literal: true

# Derives the SEP-0051 XDR-JSON name of every enum member, struct field and union
# arm directly from the .x sources, and checks the derivation against the pinned
# XDR-JSON reference CLI.
#
# The derivation rules come from the generator's own json_names.rb, the single
# definition of the SEP-0051 naming algorithm for this repository, so this check
# gates the module that emits the names rather than a second copy of it.
#
# Names are computed from the parsed .x AST rather than from generated Dart, so
# the tool keeps working when an XDR pin bump introduces types before any Dart
# exists for them.
#
# Usage:
#   ruby name_map.rb              Write name-map.json and type_map.json.
#   ruby name_map.rb --diff       Also probe the reference CLI for every enum
#                                 member and struct type it can resolve, and
#                                 report mismatches. Exits 1 if any name
#                                 disagrees with the reference.
#   ruby name_map.rb --check      Diff without writing anything, and report
#                                 whether the committed artefacts are current.
#                                 Exits 1 on a mismatch or a stale artefact,
#                                 so it can gate a build.
#   ruby name_map.rb --advisory   Diff against whatever build STELLAR_XDR names
#                                 instead of the pinned one, writing nothing. For
#                                 checking a new reference release before adopting
#                                 it; the pinned gates are unaffected.
#   ruby name_map.rb --offline    Check the committed name table against a fresh
#                                 derivation from the .x sources without the
#                                 reference CLI, writing nothing. For a per-commit
#                                 gate on a machine that has no reference build.
#   ruby name_map.rb --diff --quiet   Diff, printing only the summary.
#
# An offline run checks the half of the table that derives from the .x sources:
# the names themselves. It cannot check them against the reference, so it leaves
# the verification block and type_map.json — both of which the reference produces
# — to the runs that have a reference build. What it catches is the table going
# stale against an XDR pin bump, which is the failure a per-commit gate is for.
#
# Exit codes:
#   0  the derived names agree with the reference, and the artefacts are current
#   1  a name disagrees, or a committed artefact is stale
#   2  the reference CLI is missing or does not match the pin
#
# A caller that treats any non-zero exit as disagreement would report a missing
# CLI as a name mismatch, so the prerequisite failure is a distinct code.
#
# Types and enum members newer than the commit the reference CLI vendors are
# reported as unresolvable, never as mismatches; oracle-pin.json records both
# commits.

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../xdr-generator/Gemfile', __dir__)

require 'bundler/setup'
require 'xdrgen'
require 'base64'
require 'json'
require 'open3'
require 'set'
require 'tmpdir'
require_relative '../xdr-generator/generator/json_names'
require_relative '../xdr-generator/generator/name_overrides'

Sep51Names = Sep51JsonNames

# The reference CLI is absent or does not match the pin. Distinct from a name
# disagreement, because the two call for different responses: install the pinned
# build, versus fix the derivation.
PrerequisiteError = Class.new(StandardError)

SCRIPT_DIR = __dir__
XDR_DIR = File.expand_path('../../xdr', __dir__)
PIN_FILE = File.join(SCRIPT_DIR, 'oracle-pin.json')

# Source files whose types this SDK does not generate. The SDK generates Dart for
# every .x file it downloads, so the list is empty and the diff universe is the
# whole type set.
EXCLUDED_SOURCES = [].freeze

# Type names the reference CLI spells differently because the direct spelling
# would collide with a Rust built-in. The reference escapes such a name by
# prefixing "S": the .x `struct Error` is addressed as `SError`, and its schema
# reports itself as "SError is an XDR Struct defined as: struct Error {...}".
#
# The escape is confined to how a type is addressed on the command line. It never
# reaches the wire: a struct renders as an object keyed by its field names, and a
# union arm is keyed by its discriminant member, so no JSON key derives from a
# type name.
#
# Each entry is checked on every run — a key that resolves without the escape is
# stale, and an escaped name the reference does not know is wrong — so the table
# cannot silently outlive the behaviour it describes.
ORACLE_TYPE_ESCAPES = {
  'Error' => 'SError'
}.freeze

# Structs that SEP-0051 renders as a single JSON string rather than an object:
# the integer-parts types become one base-10 decimal, and the account and
# signed-payload types become strkeys. They carry no JSON field names, so the
# field-name diff does not apply to them and reports them separately. Names are
# the qualified .x identifiers, so a nested type is unambiguous. A struct
# appearing here unexpectedly means a new type needs a string rendering; one
# disappearing means a type that used to be a string is now an object.
STRING_RENDERED_STRUCTS = %w[
  Int128Parts
  Int256Parts
  UInt128Parts
  UInt256Parts
  MuxedEd25519Account
  MuxedAccountMed25519
  SignerKeyEd25519SignedPayload
].freeze

# Unions that SEP-0051 renders as a single JSON string carrying the arm's own
# value rather than as an object keyed by the arm: the account, address, signer
# and balance types become strkeys, and an asset code becomes the code itself.
# No arm name reaches the wire, so the arm-key diff does not apply to them.
#
# This is a narrower set than "every union the reference renders as a string".
# A union whose arms are all void also renders as a string, but as one of a
# fixed set of arm names, which the reference's schema states as an enum and
# which a reader must still compare. The distinction the schema draws -- a
# free-form string against an enumerated one -- is what separates the two.
STRING_RENDERED_UNIONS = %w[
  PublicKey
  MuxedAccount
  SCAddress
  SignerKey
  ClaimableBalanceID
  AssetCode
].freeze

# Walks the parsed .x AST and produces the full name table.
class NameMapBuilder
  include Xdrgen::AST

  def initialize(top)
    @top = top
    @enums = []
    @structs = []
    @unions = []
  end

  attr_reader :enums, :structs, :unions

  def build
    walk_definitions(@top)
    self
  end

  private

  def walk_definitions(node)
    node.definitions.each { |definition| visit(definition) }
    node.namespaces.each { |namespace| walk_definitions(namespace) }
  end

  def visit(definition)
    if definition.respond_to?(:nested_definitions)
      definition.nested_definitions.each { |nested| visit(nested) }
    end

    case definition
    when Definitions::Enum then @enums << describe_enum(definition)
    when Definitions::Struct then @structs << describe_struct(definition)
    when Definitions::Union then @unions << describe_union(definition)
    end
  end

  def describe_enum(enum)
    identifiers = enum.members.map(&:name)
    {
      'xdr_name' => qualified_name(enum),
      'dart_name' => dart_name(enum),
      'members' => enum.members.map do |member|
        {
          'identifier' => member.name,
          'value' => member.value,
          'json' => Sep51Names.enum_member_json_name(member.name, identifiers)
        }
      end
    }
  end

  def describe_struct(struct)
    {
      'xdr_name' => qualified_name(struct),
      'dart_name' => dart_name(struct),
      'fields' => struct.members.map do |member|
        {
          'identifier' => member.name,
          'json' => Sep51Names.struct_field_json_name(member.name)
        }
      end
    }
  end

  # A union arm's key is the discriminant member's own JSON name, so an
  # enum-discriminated arm can never disagree with the enum's own rendering. An
  # integer-discriminated union keys its arms "v" followed by the case value.
  def describe_union(union)
    discriminant_enum = union.discriminant_type
    identifiers = discriminant_enum.is_a?(Definitions::Enum) ? discriminant_enum.members.map(&:name) : nil

    arms = union.arms.flat_map do |arm|
      if arm.is_a?(Definitions::UnionDefaultArm)
        [{ 'case' => 'default', 'json' => nil, 'void' => arm.void? }]
      else
        arm.cases.map do |kase|
          { 'case' => kase.value_s, 'json' => Sep51Names.union_arm_json_key(kase, union), 'void' => arm.void? }
        end
      end
    end

    {
      'xdr_name' => qualified_name(union),
      'dart_name' => dart_name(union),
      'discriminant' => union.discriminant.name,
      'discriminant_kind' => identifiers ? 'enum' : 'int',
      'arms' => arms
    }
  end

  # The .x identifier, camelized and qualified by its parents for a nested type.
  # This is the key every artefact is written under: unlike the Dart name it is
  # injective, so two .x types can never collapse onto one entry.
  def qualified_name(definition)
    camel = definition.name.camelize
    return camel unless definition.is_a?(Concerns::NestedDefinition)

    "#{qualified_name(definition.parent_defn)}#{camel}"
  end

  # The generated Dart class name, resolved exactly as the Dart generator resolves
  # it: NAME_OVERRIDES keyed on the qualified .x name first, then on the bare one,
  # then the Xdr prefix. Recorded as a value only; it is many-to-one, so nothing
  # is ever looked up by it.
  def dart_name(definition)
    qualified = qualified_name(definition)
    return NAME_OVERRIDES[qualified] if NAME_OVERRIDES.key?(qualified)

    camel = definition.name.camelize
    return NAME_OVERRIDES[camel] if NAME_OVERRIDES.key?(camel)

    return "Xdr#{camel}" unless definition.is_a?(Concerns::NestedDefinition)

    "#{dart_name(definition.parent_defn)}#{camel}"
  end
end

# Drives the pinned reference CLI.
class Oracle
  UnknownType = Class.new(StandardError)

  attr_reader :version, :xdr_commit

  def initialize(pin, advisory: false)
    @cli = ENV.fetch('STELLAR_XDR', 'stellar-xdr')
    @pin = pin
    @advisory = advisory
    verify_pin
  end

  def types
    @types ||= run!('types', 'list').lines.map(&:strip).reject(&:empty?).to_set
  end

  def knows?(type) = types.include?(type)

  # Renders one enum member. XDR encodes an enum as a four-byte big-endian
  # signed integer, so a member is probed by decoding its own value.
  def decode_enum_member(type, value)
    encoded = Base64.strict_encode64([value].pack('l>'))
    output, status = run('decode', '--type', type, '--input', 'single-base64', '--output', 'json',
                         stdin: encoded)
    raise UnknownType, output.strip unless status.success?

    JSON.parse(output.strip, quirks_mode: true)
  end

  # The reference CLI orders schema properties alphabetically, so a schema is
  # evidence about field names only and says nothing about emission order.
  def type_schema(type)
    output, status = run('types', 'schema', '--type', type)
    raise UnknownType, output.strip unless status.success?

    JSON.parse(output)
  end

  def self.field_names(schema)
    (schema['properties'] || {}).keys.reject { |key| key == '$schema' }.to_set
  end

  # True for a type the reference renders as a string carrying a value of its
  # own, rather than as an object or as one of a fixed set of names. An
  # enumerated string still puts derived names on the wire, so it is excluded.
  def self.free_form_string?(schema)
    schema['type'] == 'string' && !schema.key?('enum')
  end

  private

  def verify_pin
    output, status = run('version')
    unless status.success?
      raise PrerequisiteError, <<~MESSAGE
        '#{@cli} version' failed; is it the XDR reference CLI?
          #{output.strip}
        Install the pinned build with:
          #{@pin['install']}
      MESSAGE
    end

    @version = output.lines.first.to_s.split[1]
    @xdr_commit = output.lines.find { |line| line.start_with?('xdr:') }.to_s.split[1]
    version = @version
    xdr_commit = @xdr_commit

    return if version == @pin['version'] && xdr_commit == @pin['xdr_commit']

    # An advisory run exists precisely to probe a build other than the pinned one, so the
    # mismatch is the point rather than a failure. The build actually used is reported.
    return if @advisory

    raise PrerequisiteError, <<~MESSAGE
      reference CLI does not match oracle-pin.json.
          want: version #{@pin['version']}, xdr #{@pin['xdr_commit']}
          got:  version #{version}, xdr #{xdr_commit}
        Install the pinned build with:
          #{@pin['install']}
    MESSAGE
  end

  def run(*args, stdin: nil)
    output, error, status = Open3.capture3(@cli, *args, stdin_data: stdin.to_s)
    [status.success? ? output : "#{output}#{error}", status]
  rescue SystemCallError => e
    # The binary is absent or not executable, which Open3 reports by raising
    # rather than through an exit status.
    raise PrerequisiteError, <<~MESSAGE
      reference CLI #{@cli.inspect} could not be run: #{e.message}
      Install the pinned build with:
        #{@pin['install']}
      then ensure it is on PATH, or set STELLAR_XDR.
    MESSAGE
  end

  def run!(*args)
    output, status = run(*args)
    raise "#{@cli} #{args.join(' ')} failed: #{output}" unless status.success?

    output
  end
end

def load_ast
  sources = Dir.glob(File.join(XDR_DIR, '*.x')).sort.reject do |path|
    EXCLUDED_SOURCES.include?(File.basename(path))
  end

  if sources.empty?
    abort "No .x files in #{XDR_DIR}. Run 'make xdr-generate' first."
  end

  Xdrgen::Compilation.new(sources, output_dir: Dir.tmpdir, namespace: 'name_map').ast
end

# The reference CLI spells type names in UpperCamelCase of the .x identifier
# (SCVal becomes ScVal). Nested types carry their parent's name, matching how the
# qualified .x name is built.
def resolve_oracle_type(oracle, xdr_name)
  candidate = Sep51Names.upper_camel(xdr_name)
  return candidate if oracle.knows?(candidate)

  escaped = ORACLE_TYPE_ESCAPES[candidate]
  return escaped if escaped && oracle.knows?(escaped)

  oracle.types.find { |type| type.casecmp?(candidate) || type.casecmp?(xdr_name) }
end

# Fails the run when an escape entry no longer describes the reference's
# behaviour, so the table cannot mask a type the reference has since renamed or
# dropped.
def verify_type_escapes(oracle)
  ORACLE_TYPE_ESCAPES.each do |plain, escaped|
    if oracle.knows?(plain)
      abort "ORACLE_TYPE_ESCAPES maps #{plain.inspect} to #{escaped.inspect}, but reference CLI " \
            "#{oracle.version} resolves #{plain.inspect} directly; drop the entry"
    end

    next if oracle.knows?(escaped)

    abort "ORACLE_TYPE_ESCAPES maps #{plain.inspect} to #{escaped.inspect}, which reference CLI " \
          "#{oracle.version} does not know; the escape is wrong or the type is gone"
  end
end

# Keyed on the qualified .x name, which is injective. The Dart name is carried as
# a value: NAME_OVERRIDES is many-to-one, so keying on it would silently collapse
# the three Dart names that have two .x sources each.
def build_type_map(oracle, entries)
  mapping = {}
  unknown = []

  entries.each do |entry|
    xdr_name = entry['xdr_name']
    resolved = resolve_oracle_type(oracle, xdr_name)
    if resolved
      mapping[xdr_name] = { 'oracle' => resolved, 'dart' => entry['dart_name'] }
    else
      unknown << xdr_name
    end
  end

  accounted = mapping.length + unknown.length
  if accounted != entries.length
    abort "type_map lost #{entries.length - accounted} of #{entries.length} types to duplicate " \
          'qualified .x names; the map is no longer keyed injectively'
  end

  [mapping, unknown]
end

def diff(oracle, builder, quiet:)
  enum_total = 0
  enum_checked = 0
  enum_unresolvable = []
  struct_checked = 0
  struct_unresolvable = []
  union_checked = 0
  union_unresolvable = []
  union_string_rendered = []
  mismatches = []

  builder.enums.each do |entry|
    type = resolve_oracle_type(oracle, entry['xdr_name'])
    entry['members'].each do |member|
      enum_total += 1
      label = "#{entry['xdr_name']}.#{member['identifier']}"

      if type.nil?
        enum_unresolvable << label
        next
      end

      begin
        actual = oracle.decode_enum_member(type, member['value'])
      rescue Oracle::UnknownType
        enum_unresolvable << label
        next
      end

      enum_checked += 1
      next if actual == member['json']

      mismatches << "enum  #{label}: derived #{member['json'].inspect}, reference #{actual.inspect}"
    end
  end

  string_rendered = []

  builder.structs.each do |entry|
    type = resolve_oracle_type(oracle, entry['xdr_name'])
    if type.nil?
      struct_unresolvable << entry['xdr_name']
      next
    end

    begin
      schema = oracle.type_schema(type)
    rescue Oracle::UnknownType
      struct_unresolvable << entry['xdr_name']
      next
    end

    # A struct the reference renders as a string has no field names to compare.
    if schema['type'] != 'object'
      string_rendered << entry['xdr_name']
      unless STRING_RENDERED_STRUCTS.include?(entry['xdr_name'])
        mismatches << "struct #{entry['xdr_name']}: reference renders it as " \
                      "#{schema['type'].inspect}, not an object, and it is not a known " \
                      'string-rendered type'
      end
      next
    end

    struct_checked += 1
    derived = entry['fields'].map { |field| field['json'] }.to_set
    actual = Oracle.field_names(schema)
    next if derived == actual

    mismatches << "struct #{entry['xdr_name']}: derived #{derived.to_a.sort.inspect}, " \
                  "reference #{actual.to_a.sort.inspect}"
  end

  # A type the reference cannot resolve says nothing about its rendering, and it is already
  # reported as unresolvable, so it is not also counted as a lost string rendering.
  (STRING_RENDERED_STRUCTS - string_rendered - struct_unresolvable).each do |name|
    mismatches << "struct #{name}: expected the reference to render it as a string, but it " \
                  'did not; its string rendering may have been dropped'
  end

  builder.unions.each do |entry|
    type = resolve_oracle_type(oracle, entry['xdr_name'])
    if type.nil?
      union_unresolvable << entry['xdr_name']
      next
    end

    begin
      schema = oracle.type_schema(type)
    rescue Oracle::UnknownType
      union_unresolvable << entry['xdr_name']
      next
    end

    # A union rendered as a value of its own puts no arm name on the wire, so a
    # reader comparing arm keys has nothing to compare it against.
    unless Oracle.free_form_string?(schema)
      union_checked += 1
      next
    end

    union_string_rendered << entry['xdr_name']
    next if STRING_RENDERED_UNIONS.include?(entry['xdr_name'])

    mismatches << "union #{entry['xdr_name']}: reference renders it as a value of its own, " \
                  'not as a keyed arm, and it is not a known string-rendered type'
  end

  (STRING_RENDERED_UNIONS - union_string_rendered - union_unresolvable).each do |name|
    mismatches << "union #{name}: expected the reference to render it as a value of its own, " \
                  'but it did not; its string rendering may have been dropped'
  end

  enum_mismatches = mismatches.count { |line| line.start_with?('enum ') }
  struct_mismatches = mismatches.count { |line| line.start_with?('struct ') }
  union_mismatches = mismatches.count { |line| line.start_with?('union ') }

  unless quiet
    puts
    puts "Unresolvable by reference CLI #{oracle.version} (newer than the XDR commit it vendors):"
    puts "  enum members (#{enum_unresolvable.length}):"
    enum_unresolvable.each { |label| puts "    #{label}" }
    puts "  struct types (#{struct_unresolvable.length}):"
    struct_unresolvable.each { |label| puts "    #{label}" }
    puts "  union types (#{union_unresolvable.length}):"
    union_unresolvable.each { |label| puts "    #{label}" }
    puts
    puts "Rendered as a string by the reference, so no field names to diff (#{string_rendered.length}):"
    string_rendered.sort.each { |label| puts "    #{label}" }
    puts
    puts 'Rendered as a value of their own by the reference, so no arm names to diff ' \
         "(#{union_string_rendered.length}):"
    union_string_rendered.sort.each { |label| puts "    #{label}" }
  end

  puts
  puts "SEP-0051 name derivation vs reference CLI #{oracle.version}"
  puts format('  enum members:  %d total, %d resolvable, %d matched, %d mismatched',
              enum_total, enum_checked, enum_checked - enum_mismatches, enum_mismatches)
  puts format('  struct types:  %d total, %d field-comparable, %d matched, %d mismatched ' \
              '(%d string-rendered, %d unresolvable)',
              builder.structs.length, struct_checked, struct_checked - struct_mismatches,
              struct_mismatches, string_rendered.length, struct_unresolvable.length)
  puts format('  union types:   %d total, %d arm-comparable, %d string-rendered, ' \
              '%d unresolvable, %d mismatched',
              builder.unions.length, union_checked, union_string_rendered.length,
              union_unresolvable.length, union_mismatches)

  unless mismatches.empty?
    puts
    puts 'Mismatches:'
    mismatches.each { |line| puts "  #{line}" }
  end

  { enum_total: enum_total, enum_checked: enum_checked, enum_unresolvable: enum_unresolvable,
    struct_checked: struct_checked, struct_unresolvable: struct_unresolvable,
    string_rendered: string_rendered, union_string_rendered: union_string_rendered,
    mismatches: mismatches }
end

# Writes the artefact, or in check mode compares it with what is already committed and reports
# whether it is current. Returns true when the file on disk matches the freshly derived content.
def emit(name, content, check_only:)
  path = File.join(SCRIPT_DIR, name)

  unless check_only
    File.write(path, content)
    puts "Wrote #{path}"
    return true
  end

  committed = File.exist?(path) ? File.read(path) : nil
  if committed == content
    puts "Up to date: #{path}"
    true
  else
    puts "STALE: #{path} differs from the freshly derived table; re-run without --check"
    false
  end
end

# Compares the committed name table's derived sections against a fresh derivation.
#
# The provenance is compared too: a table derived under one XDR pin and committed
# under another describes .x files that are no longer the ones on disk, and the
# names are only meaningful against the sources they came from.
def offline_check(builder, pin)
  path = File.join(SCRIPT_DIR, 'name-map.json')
  unless File.exist?(path)
    warn "name_map.rb: #{path} does not exist."
    warn '  Build it with: ruby tools/sep-51-oracle/name_map.rb --diff'
    return false
  end

  committed = JSON.parse(File.read(path))
  derived = JSON.parse(JSON.generate(
                         'oracle' => pin.slice('tool', 'version', 'xdr_commit'),
                         'sdk_xdr_commit' => pin['sdk_xdr_commit'],
                         'enums' => builder.enums,
                         'structs' => builder.structs,
                         'unions' => builder.unions
                       ))

  stale = derived.keys.reject { |key| committed[key] == derived[key] }

  puts "Checked #{builder.enums.length} enums, #{builder.structs.length} structs " \
       "and #{builder.unions.length} unions against #{path}."
  puts 'The verification block and type_map.json come from the reference build and ' \
       'are not checked here.'

  if stale.empty?
    puts 'Up to date: every derived name matches the .x sources.'
    return true
  end

  warn "STALE: #{path} disagrees with the .x sources in: #{stale.join(', ')}"
  warn '  Rebuild it with: ruby tools/sep-51-oracle/name_map.rb --diff'
  false
end

def main
  advisory = ARGV.include?('--advisory')
  check_only = ARGV.include?('--check')
  offline = ARGV.include?('--offline')
  # Checking without diffing would compare the artefacts against themselves and prove nothing.
  run_diff = ARGV.include?('--diff') || check_only || advisory
  quiet = ARGV.include?('--quiet')

  builder = NameMapBuilder.new(load_ast).build

  if offline
    # No Oracle is constructed: an offline run must work where no reference build
    # exists, and constructing one is what probes for it.
    exit(offline_check(builder, JSON.parse(File.read(PIN_FILE))) ? 0 : 1)
  end

  pin = JSON.parse(File.read(PIN_FILE))
  oracle = Oracle.new(pin, advisory: advisory)

  if advisory
    puts "ADVISORY: comparing against #{oracle.version} (xdr #{oracle.xdr_commit}), " \
         "not the pinned #{pin['version']}."
    puts 'Nothing is written; the pinned gates are unaffected.'
    puts
  end

  verify_type_escapes(oracle)

  entries = builder.enums + builder.structs + builder.unions
  type_map, unknown = build_type_map(oracle, entries)

  type_map_content =
    "#{JSON.pretty_generate(
      'oracle' => pin.slice('tool', 'version', 'xdr_commit'),
      'sdk_xdr_commit' => pin['sdk_xdr_commit'],
      'description' => 'Maps the qualified .x type name to the reference CLI\'s spelling and ' \
                       'to this SDK\'s generated Dart class name. Keyed on the .x name because ' \
                       'the Dart name is many-to-one. unknown_to_oracle lists every type the ' \
                       'reference build does not resolve, whatever the cause; the expected ' \
                       'cause is a type added after the XDR commit that build vendors, and the ' \
                       'list is empty while the two pins agree closely enough.',
      'type_map' => type_map.sort.to_h,
      'unknown_to_oracle' => unknown.sort
    )}\n"

  result = run_diff ? diff(oracle, builder, quiet: quiet) : nil

  name_map_content =
    "#{JSON.pretty_generate(
      'oracle' => pin.slice('tool', 'version', 'xdr_commit'),
      'sdk_xdr_commit' => pin['sdk_xdr_commit'],
      'description' => 'SEP-0051 XDR-JSON names derived from the .x sources. Regenerate with ' \
                       'ruby tools/sep-51-oracle/name_map.rb --diff after any XDR pin bump.',
      'verification' => result ? {
        'enum_members_total' => result[:enum_total],
        'enum_members_checked' => result[:enum_checked],
        'enum_members_unresolvable' => result[:enum_unresolvable].sort,
        'struct_types_total' => builder.structs.length,
        'struct_types_field_comparable' => result[:struct_checked],
        'struct_types_string_rendered' => result[:string_rendered].sort,
        'struct_types_unresolvable' => result[:struct_unresolvable].sort,
        'union_types_string_rendered' => result[:union_string_rendered].sort,
        'mismatches' => result[:mismatches]
      } : 'not verified in this run; re-run with --diff',
      'enums' => builder.enums,
      'structs' => builder.structs,
      'unions' => builder.unions
    )}\n"

  puts
  if advisory
    # An advisory run reports and stops: the artefacts belong to the pinned build, so
    # neither writing them nor judging them stale against another build would be right.
    if result[:mismatches].empty?
      puts 'ADVISORY: every derived name matches this build. A pin bump would be routine.'
      exit 0
    end
    puts "ADVISORY: #{result[:mismatches].length} name(s) differ under this build."
    exit 1
  end

  current = emit('type_map.json', type_map_content, check_only: check_only)
  current &= emit('name-map.json', name_map_content, check_only: check_only)

  exit 1 if result && !result[:mismatches].empty?
  exit 1 unless current
end

if $PROGRAM_NAME == __FILE__
  begin
    main
  rescue PrerequisiteError => e
    warn "name_map.rb: #{e.message}"
    exit 2
  end
end
