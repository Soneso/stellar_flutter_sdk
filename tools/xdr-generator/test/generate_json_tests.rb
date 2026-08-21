#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates the SEP-0051 (XDR-JSON) Dart unit tests for every XDR type the SDK
# generates, from the .x definitions.
#
# The battery is derived rather than authored, so it grows with the .x set: one
# round trip per type from a deterministic seeded instance, one test per union
# arm, one test per enum member pinning the wire name beside the numeric value,
# a negative per union shape, and an undeclared-key rejection per struct.
#
# Every round trip crosses into the binary codec as well as through JSON. A
# JSON-only round trip cannot see the two readers disagreeing about the value
# they built: `{"vec":null}` and `{"vec":[]}` are different XDR, and a reader
# that conflated them would still render back what it was given.
#
# Instance construction is TestGenerator's, reused unchanged. What is added here
# is the seeding an XDR-JSON rendering needs and the encode/decode tests do not:
# the two states of an optional union arm, the present and absent elements of an
# array of optionals, and the present state of an optional struct field.
#
# Usage:
#   cd tools/xdr-generator && bundle exec ruby test/generate_json_tests.rb
#
# Output:
#   test/unit/xdr/json_generated/xdr_*_json_test.dart

require 'fileutils'
require 'set'
require 'stringio'
require 'xdrgen'
require_relative 'generate_tests'

# =============================================================================
# JsonTestGenerator
# =============================================================================

class JsonTestGenerator < TestGenerator
  # Names no .x declares, so a rejection is asserted against input that is
  # well-formed JSON and wrong only in the way the test is about.
  UNDECLARED_KEY = 'xdr_json_undeclared_key'
  UNDECLARED_ARM = 'xdr_json_undeclared_arm'
  UNDECLARED_MEMBER = 'xdr_json_undeclared_member'

  def generate
    Dir.chdir(@project_root)
    xdr_files = Dir.glob('xdr/*.x').sort
    compilation = Xdrgen::Compilation.new(
      xdr_files,
      output_dir: '/dev/null/',
      generator: Generator,
      namespace: 'stellar',
    )
    top = compilation.send(:ast)

    # Namespaces map 1:1 to the sorted .x file list.
    top.namespaces.each_with_index do |ns, index|
      source_file = index < xdr_files.length ? File.basename(xdr_files[index], '.x') : 'unknown'
      collect_namespace_definitions(ns, source_file)
    end

    unseeded = []
    @unseeded_arms = []
    @unseeded_elements = Set.new
    @budget_restarted = false
    @type_registry.each do |dart_name, info|
      next unless dart_file_exists?(dart_name)

      tests = json_tests_for_type(dart_name, info)
      if tests.empty?
        unseeded << dart_name
        next
      end
      @test_groups[info[:source_file]] += tests
    end

    # A type with no constructible seed is a type the battery does not cover,
    # and the battery is the only thing standing behind the emitted renderings.
    # Both checks run before the output directory is touched, so a run that
    # reports a gap leaves the committed emission as it found it.
    unless unseeded.empty?
      warn "No constructible seed for #{unseeded.length} type(s): #{unseeded.sort.join(', ')}"
      warn 'Every generated type must be seeded. Extend the seeding in this file.'
      exit 1
    end

    # A union arm carries its own wire key and its own branch in both directions,
    # so an arm without a seed is a rendering nothing exercises. The same rule
    # applies as for a type, at the granularity the rendering actually has.
    unless @unseeded_arms.empty?
      warn "No constructible seed for #{@unseeded_arms.length} union arm(s):"
      @unseeded_arms.sort.each { |arm| warn "  #{arm}" }
      warn 'Every declared arm must be seeded. Extend arm_body_value in this file.'
      exit 1
    end

    # Every file is rendered before any of them is written, so the write phase
    # has nothing left that can fail partway and leave a half-emitted directory.
    files = @test_groups.to_h do |source_file, tests|
      [test_file_path(source_file), test_file_body(source_file, tests)]
    end

    FileUtils.mkdir_p(@output_dir)
    # A removed type must leave no file behind, so the directory is emptied
    # before anything is written to it. The temporary names of the write below
    # are swept with it, so an interrupted run leaves nothing for the next one.
    Dir.glob(File.join(@output_dir, '*.dart{,.tmp}')).each { |path| File.delete(path) }

    files.each do |path, body|
      write_atomically(path, body)
      puts "  Wrote #{path}"
    end

    puts "Generated #{@test_groups.values.flatten.length} tests across #{files.size} files"

    # Reported rather than fatal: the element type is one this generator's
    # seeding cannot build at any depth, so the run cannot close the gap and
    # failing would only block regeneration. The arrays concerned render as an
    # empty list, and their element rendering is covered by the conformance
    # corpus instead.
    return if @unseeded_elements.empty?

    puts "No constructible element for #{@unseeded_elements.length} array element " \
         "type(s): #{@unseeded_elements.sort.join(', ')}"
    puts 'Arrays of these seed empty; their element rendering is covered by the corpus.'
  end

  private

  def json_tests_for_type(dart_name, info)
    case info[:kind]
    when :enum then json_enum_tests(dart_name, info[:defn])
    when :struct then json_struct_tests(dart_name, info[:defn])
    when :union then json_union_tests(dart_name, info[:defn])
    when :typedef then json_typedef_tests(dart_name, info[:defn])
    else []
    end
  end

  # True for a type SEP-0051 renders as something other than its XDR shape. Such
  # a type has no object of declared keys and no arm-keyed envelope, so the
  # negatives that name either do not apply to it.
  def sep51_type_override?(dart_name)
    SEP51_TYPE_RENDERERS.key?(dart_name)
  end

  # ---------------------------------------------------------------------------
  # Enums
  # ---------------------------------------------------------------------------

  # A member is pinned by both of the things that identify it: the name
  # SEP-0051 gives it, and the number the binary codec writes. Pinning only the
  # name would let a member's value drift; pinning only the value would let the
  # name drift.
  def json_enum_tests(dart_name, enum_defn)
    identifiers = enum_defn.members.map { |member| member.name.to_s }
    return [] if identifiers.empty?

    tests = enum_defn.members.map do |member|
      json = Sep51JsonNames.enum_member_json_name(member.name.to_s, identifiers)
      name = dart_literal(json)
      document = dart_literal(%("#{json}"))

      test_block("#{dart_name} #{member.name} renders as #{json}", [
        "var member = #{dart_name}.#{member.name};",
        "expect(member.value, #{member.value});",
        "expect(member.toXdrJsonValue(), #{name});",
        "expect(member.toXdrJson(), #{document});",
        "var parsed = #{dart_name}.fromXdrJson(#{document});",
        "expect(parsed.value, #{member.value});",
        'expect(parsed.toBase64EncodedXdrString(),',
        '    member.toBase64EncodedXdrString());',
        "expect(#{dart_name}.fromXdrJsonValue(#{name}).value, #{member.value});",
      ])
    end

    tests << rejection_test(
      "#{dart_name} rejects an undeclared member name",
      "#{dart_name}.fromXdrJsonValue(#{dart_literal(UNDECLARED_MEMBER)})"
    )

    # Emitted whatever the type's rendering is, on the same reasoning as the
    # union negative: a rendering selects on the value and a value outside the
    # declared set selects nothing, so the refusal is a property of the type
    # rather than of the shape it renders to. Gating this on the override would
    # let a future type-level renderer drop its own negative without a word.
    declared = enum_member_values(enum_defn)
    if declared
      tests << rejection_test(
        "#{dart_name} rejects an undeclared value",
        "#{dart_name}(#{unused_value(declared)}).toXdrJsonValue()"
      )
    end

    tests
  end

  # ---------------------------------------------------------------------------
  # Structs
  # ---------------------------------------------------------------------------

  def json_struct_tests(dart_name, struct_defn)
    seed = generate_struct_value(dart_name, struct_defn, 0)
    return [] unless seed

    sponsored = optional_element_array_lines(dart_name, struct_defn)
    tests = [round_trip_test("#{dart_name} round trip", dart_name, seed, sponsored)]

    present = present_optional_lines(dart_name, struct_defn)
    if present && !present.empty?
      tests << round_trip_test(
        "#{dart_name} round trip with its optional fields present",
        dart_name, seed, sponsored + present
      )
    end

    tests << if sep51_type_override?(dart_name)
               rejection_test(
                 "#{dart_name} rejects a rendering that is not a string",
                 "#{dart_name}.fromXdrJsonValue(<String, Object?>{})"
               )
             else
               undeclared_key_test(dart_name, seed, sponsored)
             end
    tests
  end

  # A struct emitted without its declared-key set accepts anything, and the
  # omission is invisible to every other test. Starting from a valid rendering
  # and adding one key is what distinguishes the two: a fail-open reader parses
  # this input rather than rejecting it.
  def undeclared_key_test(dart_name, seed, extra_lines)
    lines = ["var original = #{seed};"]
    lines.concat(extra_lines)
    lines.concat([
      'var object = <String, Object?>{',
      '  ...(original.toXdrJsonValue() as Map<String, Object?>),',
      "  #{dart_literal(UNDECLARED_KEY)}: null,",
      '};',
      "expect(() => #{dart_name}.fromXdrJsonValue(object),",
      '    throwsA(isA<FormatException>()));',
    ])
    test_block("#{dart_name} rejects an undeclared key", lines)
  end

  # An array whose element type is an optional typedef carries a presence flag
  # per element, so both element states have to appear in one value for the
  # rendering and the binary form to be checked against each other.
  #
  # The element type is spelled from the declaration rather than from the
  # field's Dart type string, which does not carry the element's optionality.
  def optional_element_array_lines(dart_name, struct_defn)
    struct_defn.members.filter_map do |member|
      decl = member.declaration
      next unless array_of_optional?(decl)

      element = @gen.dart_type_for_typespec(decl.type)
      value = test_value_expr(element, 0)
      raise "#{dart_name}.#{member.name}: no seed for optional element #{element}" unless value

      field = @gen.resolve_field_name(dart_name, member.name)
      "original.#{field} = <#{element}?>[#{value}, null];"
    end
  end

  # An optional field renders as null when absent and as its value when
  # present, and the two are different code paths on both sides. The seeded
  # instance leaves every optional absent, so the present state is reached by
  # assigning after construction rather than by seeding a second instance.
  #
  # Returns nil when any optional field has no constructible value, since a
  # partially present variant would not test what it names.
  def present_optional_lines(dart_name, struct_defn)
    lines = []
    struct_defn.members.each do |member|
      next unless struct_field_optional?(member)

      type_str = struct_field_type(dart_name, member)
      value = test_value_expr(type_str, 0)
      return nil unless value

      value = "(#{value})" if value.include?('..') && !value.start_with?('(')
      lines << "original.#{@gen.resolve_field_name(dart_name, member.name)} = #{value};"
    end
    lines
  end

  # The emitted Dart type of a struct field, matching what the generator emits:
  # the declaration's type, then the field-level override where one applies.
  def struct_field_type(dart_name, member)
    type_str = @gen.dart_type_string(member.declaration, member)
    xdr_field_name = member.name.to_s
    return "Uint8List" if BYTES_BACKED_STRING_FIELDS.dig(dart_name, xdr_field_name)

    overrides = FIELD_TYPE_OVERRIDES[dart_name]
    return type_str unless overrides&.key?(xdr_field_name)

    override = overrides[xdr_field_name]
    type_str.end_with?('?') ? "#{override}?" : override
  end

  # True when a field may be absent, mirroring the rule the emitter renders by:
  # an array or an opaque declaration is never optional, whatever its element
  # type says.
  def struct_field_optional?(member)
    decl = member.declaration
    return false if decl.is_a?(AST::Declarations::Array) || decl.is_a?(AST::Declarations::Opaque)

    member.type.sub_type == :optional || @gen.typedef_is_optional?(decl.type)
  end

  def array_of_optional?(decl)
    decl.is_a?(AST::Declarations::Array) && @gen.typedef_is_optional?(decl.type)
  end

  # ---------------------------------------------------------------------------
  # Unions
  # ---------------------------------------------------------------------------

  def json_union_tests(dart_name, union_defn)
    disc_info = @gen.resolve_discriminant_info(union_defn)
    override = sep51_type_override?(dart_name)
    branches = union_branches(dart_name, union_defn, disc_info)
    return [] if branches.empty?

    tests = branches.flat_map { |branch| union_branch_tests(dart_name, branch, override) }
    return [] if tests.empty?

    tests + union_rejection_tests(dart_name, branches, disc_info, override)
  end

  # One branch per declared case, not per arm: each case carries its own key on
  # the wire and its own switch branch in the emitted rendering, so an arm
  # covering several members is several renderings.
  #
  # Arms sharing one Dart member are collapsed, because the generator collapses
  # them too and the second one reaches no emitted branch.
  def union_branches(dart_name, union_defn, disc_info)
    branches = []
    seen_fields = Set.new
    dart_source = File.read(dart_file_path(dart_name))

    union_defn.normal_arms.each do |arm|
      if arm.void?
        arm.cases.each do |kase|
          branches << {
            void: true,
            label: @gen.format_case_label(kase.value, disc_info),
            key: Sep51JsonNames.union_arm_json_key(kase, union_defn),
          }
        end
        next
      end

      field = @gen.resolve_field_name(dart_name, arm.name)
      next if seen_fields.include?(field)

      seen_fields.add(field)
      next unless dart_source.include?("set #{field}")

      info = @gen.resolve_dart_arm_info(arm, dart_name)
      arm.cases.each do |kase|
        branches << {
          void: false,
          field: field,
          dart_type: info[:dart_type],
          fixed_size: info[:fixed_size],
          optional: arm.declaration.is_a?(AST::Declarations::Optional),
          label: @gen.format_case_label(kase.value, disc_info),
          key: Sep51JsonNames.union_arm_json_key(kase, union_defn),
        }
      end
    end

    branches
  end

  def union_branch_tests(dart_name, branch, override)
    return void_branch_tests(dart_name, branch, override) if branch[:void]
    return optional_branch_tests(dart_name, branch, override) if branch[:optional]

    value = arm_value_expr(branch)
    unless value
      @unseeded_arms << "#{dart_name}.#{branch[:key]} (#{branch[:dart_type]})"
      return []
    end

    [round_trip_test(
      "#{dart_name} #{branch[:key]} arm round trip",
      dart_name,
      "#{dart_name}(#{branch[:label]})",
      ["original.#{branch[:field]} = #{value};"],
      arm_key_assertion(branch, override)
    )]
  end

  def void_branch_tests(dart_name, branch, override)
    pin = override ? [] : ["expect(original.toXdrJsonValue(), #{dart_literal(branch[:key])});"]
    [round_trip_test(
      "#{dart_name} #{branch[:key]} arm round trip",
      dart_name,
      "#{dart_name}(#{branch[:label]})",
      [],
      pin
    )]
  end

  # An optional arm has three states the rendering must keep apart: the key with
  # a null behind it, the key with an empty value behind it, and the key with a
  # populated value. The first two share a JSON shape only if the reader
  # conflates them, and they differ in the bytes, so the binary crossing in each
  # round trip is what separates them.
  def optional_branch_tests(dart_name, branch, override)
    pin = arm_key_assertion(branch, override)
    tests = [round_trip_test(
      "#{dart_name} #{branch[:key]} arm round trip with an absent body",
      dart_name,
      "#{dart_name}(#{branch[:label]})",
      ["original.#{branch[:field]} = null;"],
      pin
    )]

    element = branch[:dart_type].to_s[/\AList<(.+)>\z/, 1]
    if element
      tests << round_trip_test(
        "#{dart_name} #{branch[:key]} arm round trip with an empty body",
        dart_name,
        "#{dart_name}(#{branch[:label]})",
        ["original.#{branch[:field]} = <#{element}>[];"],
        pin
      )
    end

    value = arm_value_expr(branch)
    if value
      tests << round_trip_test(
        "#{dart_name} #{branch[:key]} arm round trip with a present body",
        dart_name,
        "#{dart_name}(#{branch[:label]})",
        ["original.#{branch[:field]} = #{value};"],
        pin
      )
    end

    tests
  end

  def arm_value_expr(branch)
    value =
      if branch[:fixed_size] && branch[:dart_type] == 'Uint8List'
        "Uint8List.fromList(List<int>.filled(#{branch[:fixed_size]}, 0xAB))"
      else
        test_value_expr(branch[:dart_type], 0) || arm_body_value(branch[:dart_type])
      end
    return nil unless value

    value.include?('..') && !value.start_with?('(') ? "(#{value})" : value
  end

  # Builds an arm body with the construction budget the payload type's own round
  # trip gets.
  #
  # An arm body is the value the rendering is about, not a field nested inside
  # one, so spending a level of the budget on reaching it leaves the deepest
  # types unconstructible and their arms silently untested. Seeding them the way
  # their own test seeds them is what makes every declared arm reachable.
  # A restart is not re-entrant. Restarting again inside one would reset the
  # budget at every level of a type that contains itself, and the construction
  # would never terminate; the inner value keeps the budget it has.
  def arm_body_value(dart_type)
    return nil if @budget_restarted
    return nil unless @type_registry.key?(dart_type) && dart_file_exists?(dart_type)

    @budget_restarted = true
    begin
      generate_value_expr(dart_type, @type_registry[dart_type], 0)
    ensure
      @budget_restarted = false
    end
  end

  # An array element gets the same budget restart an arm body gets, for the same
  # reason: it is the value the rendering is about.
  #
  # An empty list is never a choice here. It is what the inherited seeding falls
  # back to when the element cannot be built, and an empty container in the
  # emitted battery reads as a fixture for the specification's "empty renders as
  # `[]`" rule rather than as the absence of a seed. Where the restart does not
  # help either, the element type is recorded and reported, because the array's
  # element rendering is then exercised by nothing.
  def test_value_expr(type_str, depth)
    value = super
    return value unless value == '[]'

    element = type_str.to_s.sub(/\?\z/, '')[/\AList<(.+)>\z/, 1]
    # An array nested inside a value that is itself being built keeps the budget
    # it has, so nothing is restarted and nothing is reported: the array under
    # test is the outer one.
    return value if element.nil? || @budget_restarted

    inner = arm_body_value(element)
    if inner.nil?
      @unseeded_elements << element
      return value
    end

    "[#{inner}]"
  end

  # A valued arm renders as a single-key object, and the key is the arm's own
  # SEP-0051 name. Pinning it here is what keeps an arm key from drifting away
  # from the discriminant member's rendering of the same case.
  def arm_key_assertion(branch, override)
    return [] if override

    ['expect(',
     '    (original.toXdrJsonValue() as Map<String, Object?>).keys.single,',
     "    #{dart_literal(branch[:key])});"]
  end

  def union_rejection_tests(dart_name, branches, disc_info, override)
    # A type rendered as something other than an arm-keyed object still selects
    # its rendering by discriminant, so it still refuses one it has no arm for.
    # The read-side negatives are what its rendering changes, not the write-side
    # one.
    undeclared = undeclared_discriminant(branches, disc_info)
    write_side =
      if undeclared
        [rejection_test(
          "#{dart_name} rejects an undeclared discriminant",
          "#{dart_name}(#{undeclared}).toXdrJsonValue()"
        )]
      else
        []
      end

    if override
      return write_side + [rejection_test(
        "#{dart_name} rejects a rendering that is not a string",
        "#{dart_name}.fromXdrJsonValue(<String, Object?>{})"
      )]
    end

    void_arms = branches.any? { |branch| branch[:void] }
    valued_arms = branches.any? { |branch| !branch[:void] }
    tests = []

    if void_arms
      tests << rejection_test(
        "#{dart_name} rejects an undeclared arm name",
        "#{dart_name}.fromXdrJsonValue(#{dart_literal(UNDECLARED_ARM)})"
      )
    end

    if valued_arms
      tests << rejection_test(
        "#{dart_name} rejects an undeclared arm key",
        "#{dart_name}.fromXdrJsonValue(" \
        "<String, Object?>{#{dart_literal(UNDECLARED_ARM)}: null})"
      )
    end

    if void_arms && !valued_arms
      tests << rejection_test(
        "#{dart_name} rejects a value that is not an arm name",
        "#{dart_name}.fromXdrJsonValue(<String, Object?>{})"
      )
    end

    write_side + tests
  end

  # An expression for a discriminant no arm of this union answers to.
  #
  # Rendering is a total function on the declared cases and on nothing else, so
  # a value outside them has no name and must be refused rather than guessed at.
  # The discriminant is constructible from an arbitrary number in both forms,
  # which is what makes the refusal testable rather than merely intended.
  def undeclared_discriminant(branches, disc_info)
    if disc_info[:kind] == :enum
      declared = enum_member_values(disc_info[:enum_defn])
      return nil unless declared

      return "#{disc_info[:dart_name]}(#{unused_value(declared)})"
    end

    declared = branches.map { |branch| Integer(branch[:label], exception: false) }
    return nil if declared.any?(&:nil?)

    unused_value(declared)
  end

  def enum_member_values(enum_defn)
    return nil if enum_defn.nil? || enum_defn.members.empty?

    values = enum_defn.members.map { |member| Integer(member.value, exception: false) }
    values.any?(&:nil?) ? nil : values
  end

  # The smallest non-negative integer no member declares.
  def unused_value(values)
    candidate = 0
    candidate += 1 while values.include?(candidate)
    candidate
  end

  # ---------------------------------------------------------------------------
  # Typedefs
  # ---------------------------------------------------------------------------

  def json_typedef_tests(dart_name, typedef_defn)
    seed = generate_typedef_value(dart_name, typedef_defn, 0)
    if seed.nil? && typedef_defn.declaration.is_a?(AST::Declarations::Array)
      element = @gen.dart_type_for_typespec(typedef_defn.declaration.type)
      # The same budget restart an array element gets anywhere else. Only when
      # that fails too does the seed fall back to an empty list, and the element
      # type is recorded so the fallback is reported rather than mistaken for a
      # fixture of the empty rendering.
      inner = arm_body_value(element)
      @unseeded_elements << element if inner.nil?
      seed = inner ? "#{dart_name}(<#{element}>[#{inner}])" : "#{dart_name}(<#{element}>[])"
    end
    return [] unless seed

    [round_trip_test("#{dart_name} round trip", dart_name, seed)]
  end

  # ---------------------------------------------------------------------------
  # Test bodies
  # ---------------------------------------------------------------------------

  # The round trip runs both entry points and crosses into the binary codec from
  # each. The document form pins the canonical bytes of the rendering; the tree
  # form pins its structure; the base64 comparison pins the value both readers
  # actually built, which neither of the other two can observe.
  def round_trip_test(description, class_name, seed, setup = [], extra = [])
    lines = ["var original = #{seed};"]
    lines.concat(setup)
    lines.concat(extra)
    lines.concat([
      'var json = original.toXdrJson();',
      "var fromDocument = #{class_name}.fromXdrJson(json);",
      'expect(fromDocument.toXdrJson(), json);',
      'expect(fromDocument.toBase64EncodedXdrString(),',
      '    original.toBase64EncodedXdrString());',
      "var fromTree = #{class_name}.fromXdrJsonValue(original.toXdrJsonValue());",
      'expect(fromTree.toXdrJsonValue(), original.toXdrJsonValue());',
      'expect(fromTree.toBase64EncodedXdrString(),',
      '    original.toBase64EncodedXdrString());',
    ])
    test_block(description, lines)
  end

  def rejection_test(description, expression)
    test_block(description, [
      "expect(() => #{expression},",
      '    throwsA(isA<FormatException>()));',
    ])
  end

  def test_block(description, lines)
    body = lines.map { |line| "  #{line}" }.join("\n")
    "test('#{dart_escape(description)}', () {\n#{body}\n});\n"
  end

  # A Dart single-quoted string literal. Every JSON name the .x yields is an
  # identifier, but the escape is unconditional so that a future one that is not
  # cannot emit source that means something else.
  def dart_literal(value)
    "'#{dart_escape(value)}'"
  end

  def dart_escape(value)
    value.to_s.gsub('\\', '\\\\\\\\').gsub("'", "\\\\'").gsub('$', '\\\\$')
  end

  # ---------------------------------------------------------------------------
  # File writing
  # ---------------------------------------------------------------------------

  def clean_source_name(source_file)
    SOURCE_FILE_NAMES[source_file] ||
      source_file.to_s.gsub(/[^a-z0-9_]/, '_').downcase
  end

  def test_file_path(source_file)
    File.join(@output_dir, "xdr_#{clean_source_name(source_file)}_json_test.dart")
  end

  def test_file_body(source_file, tests)
    clean_name = clean_source_name(source_file)
    body = StringIO.new
    body.puts '// AUTO-GENERATED - DO NOT EDIT'
    body.puts '// Generated by tools/xdr-generator/test/generate_json_tests.rb'
    body.puts ''
    body.puts "import 'dart:typed_data';" if tests.any? { |test| test.include?('Uint8List') }
    body.puts "import 'package:flutter_test/flutter_test.dart';"
    body.puts "import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';"
    body.puts ''
    body.puts 'void main() {'
    body.puts "  group('SEP-0051 #{clean_name} renderings', () {"
    tests.each { |test| body.puts indent(test, 4) }
    body.puts '  });'
    body.puts '}'
    body.string
  end

  # A reader never sees a partially written file: the content lands under a
  # temporary name in the same directory and is renamed into place, which is
  # atomic on the filesystems this runs on.
  def write_atomically(path, body)
    temp = "#{path}.tmp"
    File.write(temp, body)
    File.rename(temp, path)
  end
end

# =============================================================================
# Main
# =============================================================================

if __FILE__ == $0
  project_root = File.expand_path('../../..', __dir__)
  output_dir = File.join(project_root, 'test', 'unit', 'xdr', 'json_generated')
  xdr_dir = File.join(project_root, 'xdr')

  JsonTestGenerator.new(output_dir, xdr_dir).generate
end
