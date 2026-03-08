#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates Dart unit tests for all XDR types from the .x file definitions.
#
# This script parses the .x files using xdrgen's AST and generates roundtrip
# encode/decode tests for every XDR type. It reuses the generator's override
# infrastructure to produce correct test values.
#
# Usage:
#   cd tools/xdr-generator && bundle exec ruby test/generate_tests.rb
#
# Output:
#   test/unit/xdr/generated/xdr_*_gen_test.dart  (test files)
#   test/unit/xdr/generated/xdr_test_helpers.dart (shared helpers)

require 'xdrgen'
require 'set'
require 'fileutils'
require_relative '../generator/generator'

AST = Xdrgen::AST unless defined?(AST)

# =============================================================================
# TestGenerator
# =============================================================================

class TestGenerator
  def initialize(output_dir, xdr_dir)
    @output_dir = output_dir
    @xdr_dir = xdr_dir
    @gen = TestGeneratorHelper.new
    @seen_names = Set.new
    @type_registry = {}  # dart_name => { kind:, defn:, source_file: }
    @test_groups = Hash.new { |h, k| h[k] = [] }  # source_file => [test_code]
    @project_root = File.expand_path("../../..", __dir__)
  end

  def generate
    FileUtils.mkdir_p(@output_dir)
    # Clean old generated files
    Dir.glob(File.join(@output_dir, "*.dart")).each { |f| File.delete(f) }

    Dir.chdir(@project_root)
    xdr_files = Dir.glob("xdr/*.x").sort
    compilation = Xdrgen::Compilation.new(
      xdr_files,
      output_dir: "/dev/null/",
      generator: Generator,
      namespace: "stellar",
    )
    top = compilation.send(:ast)

    # First pass: collect all type definitions
    # Namespaces map 1:1 to the sorted .x file list
    top.namespaces.each_with_index do |ns, i|
      source_file = File.basename(xdr_files[i], ".x") if i < xdr_files.length
      source_file ||= "unknown"
      collect_namespace_definitions(ns, source_file)
    end

    # Second pass: generate tests (skip types whose Dart file doesn't exist)
    @type_registry.each do |dart_name, info|
      next unless dart_file_exists?(dart_name)
      tests = generate_tests_for_type(dart_name, info)
      next if tests.empty?
      @test_groups[info[:source_file]] += tests
    end

    # Write helper file
    write_helpers_file

    # Write test files
    @test_groups.each do |source_file, tests|
      write_test_file(source_file, tests)
    end

    puts "Generated #{@test_groups.values.flatten.length} tests across #{@test_groups.size} files"
  end

  private

  # Check if the type's Dart file exists AND is exported from the SDK barrel file.
  # Types with files that aren't exported can't be used in tests.
  def dart_file_exists?(dart_name)
    @exported_files ||= load_exported_files
    path = dart_file_path(dart_name)
    File.exist?(path) && @exported_files.include?(File.basename(path))
  end

  def dart_file_path(dart_name)
    is_base = BASE_WRAPPER_TYPES.include?(dart_name)
    file_base = @gen.file_name(dart_name)
    suffix = is_base ? "_base.dart" : ".dart"
    File.join(@project_root, "lib", "src", "xdr", "#{file_base}#{suffix}")
  end

  # Detect the number of positional constructor parameters from the Dart file.
  # Returns nil if the constructor can't be parsed.
  def detect_constructor_arity(class_name)
    path = dart_file_path(class_name.sub(/Base\z/, ''))
    # For base types, check the base file
    if class_name.end_with?("Base")
      dart_name = class_name.sub(/Base\z/, '')
      file_base = @gen.file_name(dart_name)
      path = File.join(@project_root, "lib", "src", "xdr", "#{file_base}_base.dart")
    end
    return nil unless File.exist?(path)

    content = File.read(path)
    # Match the constructor: ClassName(this._a, this._b, ...);
    # or ClassName(Type a, Type b, ...);
    pattern = /#{Regexp.escape(class_name)}\s*\(([^)]*)\)\s*[;{:]/
    if content =~ pattern
      params = $1.strip
      return 0 if params.empty?
      params.split(',').length
    else
      nil
    end
  end

  def load_exported_files
    barrel = File.join(@project_root, "lib", "src", "xdr", "xdr.dart")
    return Set.new unless File.exist?(barrel)
    exports = Set.new
    File.readlines(barrel).each do |line|
      if line =~ /export\s+'([^']+)'/
        exports.add($1)
      end
    end
    exports
  end

  # Detect if an int discriminant uses XdrUint32 wrapper instead of raw int.
  def detect_disc_uses_wrapper(dart_name)
    path = dart_file_path(dart_name)
    return false unless File.exist?(path)
    content = File.read(path)
    # Check if the constructor takes XdrUint32 (wrapper) for the discriminant
    content.include?("XdrUint32 _") && content.include?("XdrUint32 get")
  end

  # Detect the actual discriminant getter name from the Dart file.
  # Generator-modified files use 'discriminant', hand-written files use the XDR field name.
  # For base types that extend parent classes, also check the parent file.
  def detect_disc_getter(dart_name, xdr_field_name)
    path = dart_file_path(dart_name)
    return "discriminant" unless File.exist?(path)

    content = File.read(path)
    # Check for "get discriminant" in this file or parent
    if content.include?("get discriminant")
      return "discriminant"
    end

    # For base types extending parent, check the parent file too
    if content =~ /extends\s+(\w+)/
      parent_class = $1
      parent_file = File.join(File.dirname(path), "#{@gen.file_name(parent_class)}.dart")
      if File.exist?(parent_file)
        parent_content = File.read(parent_file)
        return "discriminant" if parent_content.include?("get discriminant")
      end
    end

    xdr_field_name
  end

  # ---------------------------------------------------------------------------
  # AST Collection
  # ---------------------------------------------------------------------------

  def collect_namespace_definitions(ns, source_file)
    ns.definitions.each { |defn| collect_definition(defn, source_file) }
  end

  def collect_nested_definitions(defn, source_file)
    return unless defn.respond_to?(:nested_definitions)
    defn.nested_definitions.each { |nested| collect_definition(nested, source_file) }
  end

  def collect_definition(defn, source_file)
    return if defn.is_a?(AST::Definitions::Namespace)

    collect_nested_definitions(defn, source_file)

    dart_name = @gen.name(defn)
    return if defn.is_a?(AST::Definitions::Const)
    return if TYPE_OVERRIDES.key?(dart_name)
    return if @seen_names.include?(dart_name)
    @seen_names.add(dart_name)

    kind = case defn
           when AST::Definitions::Struct then :struct
           when AST::Definitions::Enum then :enum
           when AST::Definitions::Union then :union
           when AST::Definitions::Typedef then :typedef
           else nil
           end
    return unless kind

    @type_registry[dart_name] = { kind: kind, defn: defn, source_file: source_file }
  end

  # ---------------------------------------------------------------------------
  # Test Generation
  # ---------------------------------------------------------------------------

  def generate_tests_for_type(dart_name, info)
    defn = info[:defn]
    case info[:kind]
    when :enum
      generate_enum_tests(dart_name, defn)
    when :struct
      generate_struct_tests(dart_name, defn)
    when :union
      generate_union_tests(dart_name, defn)
    when :typedef
      generate_typedef_tests(dart_name, defn)
    else
      []
    end
  rescue => e
    $stderr.puts "WARNING: Failed to generate tests for #{dart_name}: #{e.message}"
    []
  end

  # ---------------------------------------------------------------------------
  # Enum Tests
  # ---------------------------------------------------------------------------

  def generate_enum_tests(dart_name, enum_defn)
    members = enum_defn.members.map { |m| "#{dart_name}.#{m.name}" }
    return [] if members.empty?

    test_code = <<~DART
      test('#{dart_name} enum roundtrip', () {
        final members = [
          #{members.join(",\n        ")},
        ];

        for (var member in members) {
          XdrDataOutputStream output = XdrDataOutputStream();
          #{dart_name}.encode(output, member);
          Uint8List encoded = Uint8List.fromList(output.bytes);

          XdrDataInputStream input = XdrDataInputStream(encoded);
          var decoded = #{dart_name}.decode(input);

          expect(decoded.value, equals(member.value),
              reason: 'Failed roundtrip for ${member}');

          var base64Decoded = #{dart_name}.fromBase64EncodedXdrString(
              member.toBase64EncodedXdrString());
          expect(base64Decoded.value, equals(member.value),
              reason: 'Failed base64 roundtrip for ${member}');
        }
      });
    DART

    [test_code]
  end

  # ---------------------------------------------------------------------------
  # Struct Tests
  # ---------------------------------------------------------------------------

  def generate_struct_tests(dart_name, struct_defn)
    is_base = BASE_WRAPPER_TYPES.include?(dart_name)
    class_name = is_base ? "#{dart_name}Base" : dart_name

    fields = struct_defn.members.map do |m|
      field_name = @gen.resolve_field_name(dart_name, m.name)
      type_str = @gen.dart_type_string(m.declaration, m)

      xdr_field_name = m.name.to_s
      if FIELD_TYPE_OVERRIDES.key?(dart_name) && FIELD_TYPE_OVERRIDES[dart_name].key?(xdr_field_name)
        override = FIELD_TYPE_OVERRIDES[dart_name][xdr_field_name]
        type_str = type_str.end_with?('?') ? "#{override}?" : override
      end

      { name: field_name, type: type_str, decl: m.declaration }
    end

    # Generate test value expressions for each field
    field_values = fields.map do |f|
      if f[:type].end_with?('?')
        { name: f[:name], type: f[:type], expr: "null", optional: true }
      elsif f[:type] == "Uint8List" && (fsize = @gen.fixed_opaque_size(f[:decl]))
        { name: f[:name], type: f[:type], expr: "Uint8List.fromList(List<int>.filled(#{fsize}, 0xAB))", optional: false }
      elsif f[:decl].is_a?(AST::Declarations::Array) && f[:decl].fixed? && f[:type] =~ /\AList<(.+)>\z/
        # Fixed-size array: generate exactly the right number of elements
        element_type = $1
        count = f[:decl].size.to_i
        inner = test_value_expr(element_type, 1)
        next nil unless inner
        { name: f[:name], type: f[:type], expr: "List.generate(#{count}, (_) => #{inner})", optional: false }
      else
        expr = test_value_expr(f[:type], 0)
        next nil unless expr
        { name: f[:name], type: f[:type], expr: expr, optional: false }
      end
    end

    return [] if field_values.any?(&:nil?)

    # Detect actual constructor arity from the Dart file
    arity = detect_constructor_arity(class_name)
    if arity && arity != field_values.length
      # Constructor takes a different number of args than the XDR struct has fields.
      # This happens with hand-written classes. Skip these - can't safely match args.
      return []
    end

    constructor_args = field_values.map { |f| f[:expr] }.join(", ")

    # Generate assertions (skip optional/null fields)
    assertions = field_values.reject { |f| f[:optional] }.map do |f|
      accessor = accessor_expr(f[:type], f[:name])
      if accessor
        "      expect(decoded.#{accessor}, equals(original.#{accessor}));"
      else
        nil
      end
    end.compact

    base64_assertions = assertions.map { |a| a.gsub("decoded.", "base64Decoded.") }

    has_assertions = !assertions.empty?
    decode_line = if has_assertions
                    "var decoded = #{class_name}.decode(input);"
                  else
                    "#{class_name}.decode(input);"
                  end
    base64_decode_line = if has_assertions
                           "var base64Decoded = #{class_name}.fromBase64EncodedXdrString(\n            original.toBase64EncodedXdrString());"
                         else
                           "#{class_name}.fromBase64EncodedXdrString(\n            original.toBase64EncodedXdrString());"
                         end

    test_code = <<~DART
      test('#{dart_name} struct roundtrip', () {
        var original = #{class_name}(#{constructor_args});

        XdrDataOutputStream output = XdrDataOutputStream();
        #{class_name}.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        #{decode_line}

    #{assertions.join("\n")}

        #{base64_decode_line}

    #{base64_assertions.join("\n")}
      });
    DART

    [test_code]
  end

  # ---------------------------------------------------------------------------
  # Union Tests
  # ---------------------------------------------------------------------------

  def generate_union_tests(dart_name, union_defn)
    is_base = BASE_WRAPPER_TYPES.include?(dart_name)
    class_name = is_base ? "#{dart_name}Base" : dart_name

    disc_info = @gen.resolve_discriminant_info(union_defn)
    arms = @gen.build_union_arms(union_defn, dart_name, disc_info)

    # Detect actual discriminant getter name and type from the Dart file
    disc_getter = detect_disc_getter(dart_name, disc_info[:field_name])
    disc_uses_wrapper = detect_disc_uses_wrapper(dart_name)

    disc_assert = if disc_info[:kind] == :enum
                    "expect(decoded.#{disc_getter}.value, equals(original.#{disc_getter}.value));"
                  elsif disc_uses_wrapper
                    "expect(decoded.#{disc_getter}.uint32, equals(original.#{disc_getter}.uint32));"
                  else
                    "expect(decoded.#{disc_getter}, equals(original.#{disc_getter}));"
                  end

    tests = []

    # Read the Dart file to check which arms actually exist
    dart_content = File.read(dart_file_path(dart_name)) rescue ""

    arms.each do |arm|
      next if arm[:is_default]  # Skip default arms for test generation

      # Get the discriminant case label
      label = arm[:case_labels].first
      next unless label
      next if label == "default"

      # Skip non-void arms whose setter doesn't exist in the Dart file
      if !arm[:void] && arm[:field_name]
        unless dart_content.include?("set #{arm[:field_name]}") || dart_content.include?("#{arm[:field_name]} =")
          next
        end
      end

      # For int discriminants that use XdrUint32 wrapper, wrap the value
      disc_value = if disc_info[:kind] == :int && disc_uses_wrapper
                     "XdrUint32(#{label})"
                   else
                     label
                   end

      base64_disc_assert = disc_assert.gsub("decoded.", "base64Decoded.")

      if arm[:void]
        test_code = <<~DART
          test('#{dart_name} #{label} void arm roundtrip', () {
            var original = #{class_name}(#{disc_value});

            XdrDataOutputStream output = XdrDataOutputStream();
            #{class_name}.encode(output, original);
            Uint8List encoded = Uint8List.fromList(output.bytes);

            XdrDataInputStream input = XdrDataInputStream(encoded);
            var decoded = #{class_name}.decode(input);

            #{disc_assert}

            var base64Decoded = #{class_name}.fromBase64EncodedXdrString(
                original.toBase64EncodedXdrString());
            #{base64_disc_assert}
          });
        DART
        tests << test_code
      else
        # Non-void arm: construct, set arm value, roundtrip
        field = arm[:field_name]
        dart_type = arm[:dart_type]
        # For fixed-opaque arms, use the correct byte size
        value_expr = if arm[:fixed_size] && dart_type == "Uint8List"
                       "Uint8List.fromList(List<int>.filled(#{arm[:fixed_size]}, 0xAB))"
                     else
                       test_value_expr(dart_type, 0)
                     end
        next unless value_expr
        # Wrap in parens if it contains cascades, to prevent cascade leaking
        # to the outer `original.field = expr..nested` context
        value_expr = "(#{value_expr})" if value_expr.include?("..") && !value_expr.start_with?("(")

        accessor = accessor_expr(dart_type, field, nullable: true)
        assertion = if accessor
                     "      expect(decoded.#{accessor}, equals(original.#{accessor}));"
                   else
                     "      // Verify arm field is not null\n      expect(decoded.#{field}, isNotNull);"
                   end
        base64_assertion = assertion.gsub("decoded.", "base64Decoded.")

        test_code = <<~DART
          test('#{dart_name} #{label} arm roundtrip', () {
            var original = #{class_name}(#{disc_value});
            original.#{field} = #{value_expr};

            XdrDataOutputStream output = XdrDataOutputStream();
            #{class_name}.encode(output, original);
            Uint8List encoded = Uint8List.fromList(output.bytes);

            XdrDataInputStream input = XdrDataInputStream(encoded);
            var decoded = #{class_name}.decode(input);

            #{disc_assert}
        #{assertion}

            var base64Decoded = #{class_name}.fromBase64EncodedXdrString(
                original.toBase64EncodedXdrString());
            #{base64_disc_assert}
        #{base64_assertion}
          });
        DART
        tests << test_code
      end
    end

    tests
  end

  # ---------------------------------------------------------------------------
  # Typedef Tests
  # ---------------------------------------------------------------------------

  def generate_typedef_tests(dart_name, typedef_defn)
    is_base = BASE_WRAPPER_TYPES.include?(dart_name)
    class_name = is_base ? "#{dart_name}Base" : dart_name
    decl = typedef_defn.declaration

    # Determine inner type and value
    inner_type = nil
    case decl
    when AST::Declarations::Opaque
      inner_type = "Uint8List"
    when AST::Declarations::String
      inner_type = "String"
    when AST::Declarations::Array
      element_type = @gen.dart_type_for_typespec(decl.type)
      inner_type = "List<#{element_type}>"
    else
      resolved = @gen.resolve_typedef_type(decl.respond_to?(:type) ? decl.type : nil)
      inner_type = resolved[:dart_type] if resolved
    end

    return [] unless inner_type

    # Check FIELD_TYPE_OVERRIDES
    field_name = @gen.underscore_field(class_name)
    if FIELD_TYPE_OVERRIDES.key?(dart_name) && FIELD_TYPE_OVERRIDES[dart_name].key?(field_name)
      inner_type = FIELD_TYPE_OVERRIDES[dart_name][field_name]
    end

    # For fixed-opaque typedefs, use the correct byte size
    value_expr = if decl.is_a?(AST::Declarations::Opaque) && decl.fixed?
                   "Uint8List.fromList(List<int>.filled(#{decl.size.to_i}, 0xAB))"
                 elsif inner_type =~ /\AList</ && test_value_expr(inner_type, 0).nil?
                   # For array typedefs whose element type can't be auto-constructed,
                   # use an empty list as the inner value
                   "[]"
                 else
                   test_value_expr(inner_type, 0)
                 end
    return [] unless value_expr

    accessor = accessor_expr(inner_type, field_name)
    assertion = if accessor
                 "      expect(decoded.#{accessor}, equals(original.#{accessor}));"
               else
                 "      expect(decoded.#{field_name}, isNotNull);"
               end

    base64_assertion = assertion.gsub("decoded.", "base64Decoded.")

    test_code = <<~DART
      test('#{dart_name} typedef roundtrip', () {
        var original = #{class_name}(#{value_expr});

        XdrDataOutputStream output = XdrDataOutputStream();
        #{class_name}.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = #{class_name}.decode(input);

    #{assertion}

        var base64Decoded = #{class_name}.fromBase64EncodedXdrString(
            original.toBase64EncodedXdrString());

    #{base64_assertion}
      });
    DART

    [test_code]
  end

  # ---------------------------------------------------------------------------
  # Test Value Expressions
  # ---------------------------------------------------------------------------

  MAX_DEPTH = 3

  def test_value_expr(type_str, depth)
    return nil if depth > MAX_DEPTH

    # Strip nullable
    base_type = type_str.gsub(/\?\z/, '')

    case base_type
    when "int"
      "42"
    when "BigInt"
      "BigInt.from(123456789)"
    when "bool"
      "true"
    when "String"
      "'test_string'"
    when "double"
      "3.14"
    when "Uint8List"
      "Uint8List.fromList([1, 2, 3, 4])"
    when /\AList<(.+)>\z/
      inner = test_value_expr($1, depth + 1)
      return nil unless inner
      "[#{inner}]"
    else
      # Try fallback first (handles TYPE_OVERRIDES types like XdrAccountID, XdrPublicKey etc.)
      fb = generate_fallback_value(base_type, depth)
      return fb if fb

      # Look up in type registry (only if Dart file exists)
      if @type_registry.key?(base_type) && dart_file_exists?(base_type)
        info = @type_registry[base_type]
        generate_value_expr(base_type, info, depth + 1)
      else
        nil
      end
    end
  end

  def generate_value_expr(dart_name, info, depth)
    return nil if depth > MAX_DEPTH

    case info[:kind]
    when :enum
      first_member = info[:defn].members.first
      return nil unless first_member
      "#{dart_name}.#{first_member.name}"
    when :typedef
      generate_typedef_value(dart_name, info[:defn], depth)
    when :struct
      generate_struct_value(dart_name, info[:defn], depth)
    when :union
      generate_union_value(dart_name, info[:defn], depth)
    else
      nil
    end
  end

  # Generate a value expression for a typedef (used as field value, not for test)
  # Always uses the wrapper class name (not Base) since callers expect the wrapper type.
  def generate_typedef_value(dart_name, typedef_defn, depth)
    decl = typedef_defn.declaration

    case decl
    when AST::Declarations::Opaque
      if decl.fixed?
        size = decl.size.to_i
        return "#{dart_name}(Uint8List.fromList(List<int>.filled(#{size}, 0xAB)))"
      else
        return "#{dart_name}(Uint8List.fromList([1, 2, 3]))"
      end
    when AST::Declarations::String
      return "#{dart_name}('test')"
    when AST::Declarations::Array
      element_type = @gen.dart_type_for_typespec(decl.type)
      inner = test_value_expr(element_type, depth)
      return nil unless inner
      return "#{dart_name}([#{inner}])"
    else
      resolved = @gen.resolve_typedef_type(decl.respond_to?(:type) ? decl.type : nil)
      return nil unless resolved
      inner_type = resolved[:dart_type]
    end

    return nil unless inner_type

    inner_value = test_value_expr(inner_type, depth)
    return nil unless inner_value
    "#{dart_name}(#{inner_value})"
  end

  # Generate a value expression for a struct (used as field value, not for test)
  # Always uses the wrapper class name (not Base) since callers expect the wrapper type.
  def generate_struct_value(dart_name, struct_defn, depth)
    all_args = struct_defn.members.map do |m|
      type_str = @gen.dart_type_string(m.declaration, m)
      xdr_field_name = m.name.to_s
      if FIELD_TYPE_OVERRIDES.key?(dart_name) && FIELD_TYPE_OVERRIDES[dart_name].key?(xdr_field_name)
        override = FIELD_TYPE_OVERRIDES[dart_name][xdr_field_name]
        type_str = type_str.end_with?('?') ? "#{override}?" : override
      end

      # For optional fields, use null
      if type_str.end_with?('?')
        { expr: "null", optional: true }
      elsif type_str == "Uint8List" && (fsize = @gen.fixed_opaque_size(m.declaration))
        { expr: "Uint8List.fromList(List<int>.filled(#{fsize}, 0xAB))", optional: false }
      elsif m.declaration.is_a?(AST::Declarations::Array) && m.declaration.fixed? && type_str =~ /\AList<(.+)>\z/
        element_type = $1
        count = m.declaration.size.to_i
        inner = test_value_expr(element_type, depth + 1)
        return nil unless inner
        { expr: "List.generate(#{count}, (_) => #{inner})", optional: false }
      else
        val = test_value_expr(type_str, depth)
        return nil unless val
        { expr: val, optional: false }
      end
    end

    # Check constructor arity - hand-written classes may omit optional fields
    arity = detect_constructor_arity(dart_name)
    if arity && arity != all_args.length
      # Only include required (non-optional) args
      required = all_args.reject { |a| a[:optional] }
      if required.length == arity
        return "#{dart_name}(#{required.map { |a| a[:expr] }.join(', ')})"
      else
        return nil  # Can't safely construct
      end
    end

    "#{dart_name}(#{all_args.map { |a| a[:expr] }.join(', ')})"
  end

  # Generate a value expression for a union (used as field value, not for test)
  # Always uses the wrapper class name (not Base) since callers expect the wrapper type.
  def generate_union_value(dart_name, union_defn, depth)
    disc_info = @gen.resolve_discriminant_info(union_defn)

    # Find the simplest arm (prefer void, then first non-void)
    void_arm = union_defn.normal_arms.find(&:void?)
    if void_arm
      label = @gen.format_case_label(void_arm.cases.first.value, disc_info)
      return "#{dart_name}(#{label})"
    end

    # Use first non-void arm - must also set the arm field
    first_arm = union_defn.normal_arms.first
    return nil unless first_arm

    label = @gen.format_case_label(first_arm.cases.first.value, disc_info)
    field_name = @gen.resolve_field_name(dart_name, first_arm.name)
    arm_info = @gen.resolve_dart_arm_info(first_arm, dart_name)
    arm_value = test_value_expr(arm_info[:dart_type], depth)
    if arm_value
      # Wrap arm_value in parens if it contains cascades, to prevent
      # ..field = expr..nested from cascading ..nested on the outer target
      arm_val = arm_value.include?("..") ? "(#{arm_value})" : arm_value
      "(#{dart_name}(#{label})..#{field_name} = #{arm_val})"
    else
      nil  # Can't construct value without arm
    end
  end

  def generate_fallback_value(type_str, depth)
    # Common XDR wrapper types not in the registry (TYPE_OVERRIDES resolved)
    case type_str
    when "XdrUint32"
      "XdrUint32(42)"
    when "XdrInt32"
      "XdrInt32(7)"
    when "XdrUint64"
      "XdrUint64(BigInt.from(123456))"
    when "XdrInt64"
      "XdrInt64(BigInt.from(654321))"
    when "XdrBigInt64"
      "XdrBigInt64(BigInt.from(999999))"
    when "XdrHash"
      "XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB)))"
    when "XdrUint256"
      "XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)))"
    when "XdrDataValue"
      "XdrDataValue(Uint8List.fromList([1, 2, 3]))"
    when "XdrSignature"
      "XdrSignature(Uint8List.fromList([4, 5, 6]))"
    when "XdrSignatureHint"
      "XdrSignatureHint(Uint8List.fromList(List<int>.filled(4, 0xAB)))"
    when "XdrThresholds"
      "XdrThresholds(Uint8List.fromList(List<int>.filled(4, 0xAB)))"
    when "XdrValue"
      "XdrValue(Uint8List.fromList([7, 8, 9]))"
    when "XdrUpgradeType"
      "XdrUpgradeType(Uint8List.fromList([10, 11]))"
    when "XdrString32"
      "XdrString32('test32')"
    when "XdrString64"
      "XdrString64('test64')"
    when "XdrAccountID"
      "XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))))"
    when "XdrMuxedAccount"
      "(XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519)..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))))"
    when "XdrPublicKey"
      "(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))))"
    when "XdrNodeID"
      "XdrNodeID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))))"
    when "XdrAsset"
      "XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE)"
    when "XdrChangeTrustAsset"
      "XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_NATIVE)"
    when "XdrTrustLineAsset"
      "XdrTrustLineAsset(XdrAssetType.ASSET_TYPE_NATIVE)"
    when "XdrPrice"
      "XdrPrice(XdrInt32(1), XdrInt32(2))"
    when "XdrExtensionPoint"
      "XdrExtensionPoint(0)"
    when "XdrSequenceNumber"
      "XdrSequenceNumber(XdrBigInt64(BigInt.from(100)))"
    when "XdrSCVal"
      "XdrSCVal(XdrSCValType.SCV_VOID)"
    when "XdrSCAddress"
      "(XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT)..accountId = XdrAccountID((XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))))))"
    when "XdrSCSpecTypeDef"
      "XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BOOL)"
    when "XdrClaimableBalanceID"
      "(XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0)..v0 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB))))"
    when "XdrLedgerKey"
      "(XdrLedgerKey(XdrLedgerEntryType.ACCOUNT)..account = XdrLedgerKeyAccount(XdrAccountID((XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)))))))"
    when "XdrTransactionEnvelope"
      # TransactionEnvelope is complex - skip for now
      nil
    when "XdrGeneralizedTransactionSet"
      "(XdrGeneralizedTransactionSet(1)..v1TxSet = XdrTransactionSetV1(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), []))"
    when "XdrLedgerEntryData"
      nil  # Complex union, skip
    when "XdrLedgerEntryChange"
      nil  # Complex union, skip
    when "XdrLedgerEntry"
      nil  # Complex struct, skip
    when "XdrContractIDPreimage"
      # The base class has address/salt fields, not fromAddress
      "(XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET)..fromAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE))"
    when "XdrContractExecutable"
      "XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET)"
    when "XdrHostFunction"
      "(XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT)..invokeContract = XdrInvokeContractArgs((XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT)..accountId = XdrAccountID((XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)))))), XdrSCVal(XdrSCValType.SCV_VOID), []))"
    when "XdrLedgerCloseMeta"
      # Use discriminant 0 (V0) with empty lists for complex nested types
      "(XdrLedgerCloseMeta(0)..v0 = XdrLedgerCloseMetaV0(XdrLedgerHeaderHistoryEntry(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrLedgerHeader(XdrUint32(0), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrStellarValue(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint64(BigInt.zero), [], XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC)), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint32(0), XdrInt64(BigInt.zero), XdrInt64(BigInt.zero), XdrUint32(0), XdrUint64(BigInt.zero), XdrUint32(0), XdrUint32(0), XdrUint32(0), [XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00)))], XdrLedgerHeaderExt(0)), XdrLedgerHeaderHistoryEntryExt(0)), XdrTransactionSet(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), []), [], [], []))"
    when "XdrTransactionMeta"
      nil  # Complex union, skip
    when "XdrTransactionResult"
      nil  # Complex, skip
    when "XdrOperationResult"
      nil  # Complex union, skip
    when "XdrOperation"
      nil  # Complex, skip
    when "XdrSorobanAuthorizedFunction"
      "(XdrSorobanAuthorizedFunction(XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN)..contractFn = XdrInvokeContractArgs((XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT)..accountId = XdrAccountID((XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)))))), XdrSCVal(XdrSCValType.SCV_VOID), []))"
    when "XdrSorobanAuthorizedInvocation"
      nil  # Self-referencing, skip
    when "XdrSorobanAuthorizationEntry"
      nil  # Complex, skip
    when "XdrContractEvent"
      "(XdrContractEvent(XdrExtensionPoint(0), null, XdrContractEventType.CONTRACT, (XdrContractEventBody(0)..v0 = XdrContractEventV0([], XdrSCVal(XdrSCValType.SCV_VOID)))))"
    when "XdrDiagnosticEvent"
      "XdrDiagnosticEvent(false, XdrContractEvent(XdrExtensionPoint(0), null, XdrContractEventType.CONTRACT, (XdrContractEventBody(0)..v0 = XdrContractEventV0([], XdrSCVal(XdrSCValType.SCV_VOID)))))"
    when "XdrTransactionEvent"
      "XdrTransactionEvent(XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_TX, XdrContractEvent(XdrExtensionPoint(0), null, XdrContractEventType.CONTRACT, (XdrContractEventBody(0)..v0 = XdrContractEventV0([], XdrSCVal(XdrSCValType.SCV_VOID)))))"
    when "XdrSignerKey"
      "(XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519)..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))))"
    when "XdrLedgerEntryChanges"
      "XdrLedgerEntryChanges([])"
    when "XdrLedgerFootprint"
      "XdrLedgerFootprint([], [])"
    when "XdrSorobanTransactionData"
      "XdrSorobanTransactionData(XdrSorobanTransactionDataExt(0), XdrSorobanResources(XdrLedgerFootprint([], []), XdrUint32(0), XdrUint32(0), XdrUint32(0)), XdrInt64(BigInt.from(0)))"
    when "XdrSorobanTransactionDataExt"
      "XdrSorobanTransactionDataExt(0)"
    when "XdrSorobanResources"
      "XdrSorobanResources(XdrLedgerFootprint([], []), XdrUint32(0), XdrUint32(0), XdrUint32(0))"
    when "XdrCurve25519Public"
      "XdrCurve25519Public(Uint8List.fromList(List<int>.filled(32, 0xAB)))"
    when "XdrCurve25519Secret"
      "XdrCurve25519Secret(Uint8List.fromList(List<int>.filled(32, 0xAB)))"
    when "XdrHmacSha256Key"
      "XdrHmacSha256Key(Uint8List.fromList(List<int>.filled(32, 0xAB)))"
    when "XdrHmacSha256Mac"
      "XdrHmacSha256Mac(Uint8List.fromList(List<int>.filled(32, 0xAB)))"
    when "XdrShortHashSeed"
      "XdrShortHashSeed(Uint8List.fromList(List<int>.filled(16, 0xAB)))"
    when "XdrDecoratedSignature"
      "XdrDecoratedSignature(XdrSignatureHint(Uint8List.fromList(List<int>.filled(4, 0xAB))), XdrSignature(Uint8List.fromList([1, 2, 3])))"
    when "XdrMemo"
      "XdrMemo(XdrMemoType.MEMO_NONE)"
    when "XdrPreconditions"
      "XdrPreconditions(XdrPreconditionType.PRECOND_NONE)"
    # --- Ledger close meta and related types ---
    when "XdrStellarValue"
      "XdrStellarValue(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint64(BigInt.zero), [], XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC))"
    when "XdrStellarValueExt"
      "XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC)"
    when "XdrLedgerHeader"
      "XdrLedgerHeader(XdrUint32(0), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrStellarValue(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint64(BigInt.zero), [], XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC)), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint32(0), XdrInt64(BigInt.zero), XdrInt64(BigInt.zero), XdrUint32(0), XdrUint64(BigInt.zero), XdrUint32(0), XdrUint32(0), XdrUint32(0), [XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00)))], XdrLedgerHeaderExt(0))"
    when "XdrLedgerHeaderHistoryEntry"
      "XdrLedgerHeaderHistoryEntry(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrLedgerHeader(XdrUint32(0), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrStellarValue(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint64(BigInt.zero), [], XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC)), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint32(0), XdrInt64(BigInt.zero), XdrInt64(BigInt.zero), XdrUint32(0), XdrUint64(BigInt.zero), XdrUint32(0), XdrUint32(0), XdrUint32(0), [XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00)))], XdrLedgerHeaderExt(0)), XdrLedgerHeaderHistoryEntryExt(0))"
    when "XdrLedgerCloseMetaExt"
      "XdrLedgerCloseMetaExt(0)"
    when "XdrTransactionSet"
      "XdrTransactionSet(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), [])"
    when "XdrTransactionSetV1"
      "XdrTransactionSetV1(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), [])"
    when "XdrLedgerCloseMetaV0"
      "XdrLedgerCloseMetaV0(XdrLedgerHeaderHistoryEntry(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrLedgerHeader(XdrUint32(0), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrStellarValue(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint64(BigInt.zero), [], XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC)), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint32(0), XdrInt64(BigInt.zero), XdrInt64(BigInt.zero), XdrUint32(0), XdrUint64(BigInt.zero), XdrUint32(0), XdrUint32(0), XdrUint32(0), [XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00)))], XdrLedgerHeaderExt(0)), XdrLedgerHeaderHistoryEntryExt(0)), XdrTransactionSet(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), []), [], [], [])"
    when "XdrLedgerCloseMetaV1"
      "XdrLedgerCloseMetaV1(XdrLedgerCloseMetaExt(0), XdrLedgerHeaderHistoryEntry(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrLedgerHeader(XdrUint32(0), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrStellarValue(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint64(BigInt.zero), [], XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC)), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint32(0), XdrInt64(BigInt.zero), XdrInt64(BigInt.zero), XdrUint32(0), XdrUint64(BigInt.zero), XdrUint32(0), XdrUint32(0), XdrUint32(0), [XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00)))], XdrLedgerHeaderExt(0)), XdrLedgerHeaderHistoryEntryExt(0)), (XdrGeneralizedTransactionSet(1)..v1TxSet = XdrTransactionSetV1(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), [])), [], [], [], XdrUint64(BigInt.zero), [], [])"
    when "XdrLedgerCloseMetaV2"
      "XdrLedgerCloseMetaV2(XdrLedgerCloseMetaExt(0), XdrLedgerHeaderHistoryEntry(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrLedgerHeader(XdrUint32(0), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrStellarValue(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint64(BigInt.zero), [], XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC)), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint32(0), XdrInt64(BigInt.zero), XdrInt64(BigInt.zero), XdrUint32(0), XdrUint64(BigInt.zero), XdrUint32(0), XdrUint32(0), XdrUint32(0), [XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00)))], XdrLedgerHeaderExt(0)), XdrLedgerHeaderHistoryEntryExt(0)), (XdrGeneralizedTransactionSet(1)..v1TxSet = XdrTransactionSetV1(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), [])), [], [], [], XdrUint64(BigInt.zero), [])"
    when "XdrLedgerCloseMetaBatch"
      "XdrLedgerCloseMetaBatch(XdrUint32(0), XdrUint32(0), [])"
    # --- Transaction set types ---
    when "XdrTxSetComponentTxsMaybeDiscountedFee"
      "XdrTxSetComponentTxsMaybeDiscountedFee(null, [])"
    when "XdrTxSetComponent"
      "(XdrTxSetComponent(XdrTxSetComponentType.TXSET_COMP_TXS_MAYBE_DISCOUNTED_FEE)..txsMaybeDiscountedFee = XdrTxSetComponentTxsMaybeDiscountedFee(null, []))"
    when "XdrTransactionPhase"
      "(XdrTransactionPhase(0)..v0Components = [])"
    when "XdrParallelTxsComponent"
      "XdrParallelTxsComponent(null, [])"
    when "XdrDependentTxCluster"
      "XdrDependentTxCluster([])"
    when "XdrParallelTxExecutionStage"
      "XdrParallelTxExecutionStage([])"
    when "XdrStoredTransactionSet"
      "(XdrStoredTransactionSet(0)..txSet = XdrTransactionSet(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), []))"
    when "XdrStoredDebugTransactionSet"
      "XdrStoredDebugTransactionSet((XdrStoredTransactionSet(0)..txSet = XdrTransactionSet(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), [])), XdrUint32(0), XdrStellarValue(XdrHash(Uint8List.fromList(List<int>.filled(32, 0x00))), XdrUint64(BigInt.zero), [], XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC)))"
    when "XdrSorobanAuthorizationEntries"
      "XdrSorobanAuthorizationEntries([])"
    # --- SCP persistence types ---
    when "XdrPersistedSCPStateV0"
      "XdrPersistedSCPStateV0([], [], [])"
    when "XdrPersistedSCPStateV1"
      "XdrPersistedSCPStateV1([], [])"
    when "XdrPersistedSCPState"
      "(XdrPersistedSCPState(0)..v0 = XdrPersistedSCPStateV0([], [], []))"
    # --- Survey types ---
    when "XdrSurveyResponseBody"
      "(XdrSurveyResponseBody(XdrSurveyMessageResponseType.SURVEY_TOPOLOGY_RESPONSE_V2)..topologyResponseBodyV2 = XdrTopologyResponseBodyV2(XdrTimeSlicedPeerDataList([]), XdrTimeSlicedPeerDataList([]), XdrTimeSlicedNodeData(XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), false, XdrUint32(0), XdrUint32(0))))"
    when "XdrTopologyResponseBodyV2"
      "XdrTopologyResponseBodyV2(XdrTimeSlicedPeerDataList([]), XdrTimeSlicedPeerDataList([]), XdrTimeSlicedNodeData(XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), false, XdrUint32(0), XdrUint32(0)))"
    when "XdrTimeSlicedPeerDataList"
      "XdrTimeSlicedPeerDataList([])"
    when "XdrTimeSlicedNodeData"
      "XdrTimeSlicedNodeData(XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0), false, XdrUint32(0), XdrUint32(0))"
    else
      nil
    end
  end

  # ---------------------------------------------------------------------------
  # Accessor Expressions (for equality assertions)
  # ---------------------------------------------------------------------------

  def accessor_expr(type_str, field_name, nullable: false)
    base_type = type_str.gsub(/\?\z/, '')
    bang = nullable ? "!" : ""

    case base_type
    when "int"
      field_name
    when "BigInt"
      field_name
    when "bool"
      field_name
    when "String"
      field_name
    when "double"
      field_name
    when "Uint8List"
      field_name
    when "XdrUint32"
      "#{field_name}#{bang}.uint32"
    when "XdrInt32"
      "#{field_name}#{bang}.int32"
    when "XdrUint64"
      "#{field_name}#{bang}.uint64"
    when "XdrInt64"
      "#{field_name}#{bang}.int64"
    when "XdrBigInt64"
      "#{field_name}#{bang}.bigInt"
    when "XdrHash"
      "#{field_name}#{bang}.hash"
    when /\AList</
      nil  # Lists need special comparison
    else
      # For complex types, just check not null
      nil
    end
  end

  # ---------------------------------------------------------------------------
  # File Writing
  # ---------------------------------------------------------------------------

  def write_helpers_file
    path = File.join(@output_dir, "xdr_test_helpers.dart")
    File.open(path, "w") do |f|
      f.puts <<~DART
        // AUTO-GENERATED - DO NOT EDIT
        // Generated by tools/xdr-generator/test/generate_tests.rb

        import 'dart:typed_data';
        import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

        /// Encode an XDR value and return the raw bytes.
        Uint8List xdrEncode<T>(T value, void Function(XdrDataOutputStream, T) encode) {
          XdrDataOutputStream output = XdrDataOutputStream();
          encode(output, value);
          return Uint8List.fromList(output.bytes);
        }
      DART
    end
    puts "  Wrote #{path}"
  end

  # Map source file basenames to clean group names
  SOURCE_FILE_NAMES = {
    "Stellar-types" => "types",
    "Stellar-ledger-entries" => "ledger_entries",
    "Stellar-ledger" => "ledger",
    "Stellar-transaction" => "transaction",
    "Stellar-SCP" => "scp",
    "Stellar-overlay" => "overlay",
    "Stellar-contract" => "contract",
    "Stellar-contract-config-setting" => "contract_config",
    "Stellar-contract-env-meta" => "contract_env_meta",
    "Stellar-contract-meta" => "contract_meta",
    "Stellar-contract-spec" => "contract_spec",
    "Stellar-exporter" => "exporter",
    "Stellar-internal" => "internal",
  }.freeze

  def write_test_file(source_file, tests)
    clean_name = SOURCE_FILE_NAMES[source_file] || source_file.to_s.gsub(/[^a-z0-9_]/, '_').downcase
    filename = "xdr_#{clean_name}_gen_test.dart"
    path = File.join(@output_dir, filename)

    File.open(path, "w") do |f|
      f.puts <<~DART
        // AUTO-GENERATED - DO NOT EDIT
        // Generated by tools/xdr-generator/test/generate_tests.rb

        import 'dart:typed_data';
        import 'package:flutter_test/flutter_test.dart';
        import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

        void main() {
          group('XDR #{clean_name} generated tests', () {
        #{tests.map { |t| indent(t, 4) }.join("\n")}
          });
        }
      DART
    end

    puts "  Wrote #{path} (#{tests.length} tests)"
  end

  def indent(text, spaces)
    prefix = " " * spaces
    text.lines.map { |line| line.strip.empty? ? "" : "#{prefix}#{line}" }.join
  end
end

# =============================================================================
# TestGeneratorHelper
# =============================================================================

class TestGeneratorHelper
  def name(named)
    raw_xdr_name = raw_xdr_qualified_name(named)

    if NAME_OVERRIDES.key?(raw_xdr_name)
      return NAME_OVERRIDES[raw_xdr_name]
    end

    xdr_name = named.name.camelize
    if NAME_OVERRIDES.key?(xdr_name)
      return NAME_OVERRIDES[xdr_name]
    end

    if named.is_a?(AST::Concerns::NestedDefinition)
      parent = name(named.parent_defn)
      "#{parent}#{xdr_name}"
    else
      "Xdr#{xdr_name}"
    end
  end

  def raw_xdr_qualified_name(named)
    xdr_name = named.name.camelize
    if named.is_a?(AST::Concerns::NestedDefinition)
      parent_raw = raw_xdr_qualified_name(named.parent_defn)
      "#{parent_raw}#{xdr_name}"
    else
      xdr_name
    end
  end

  def file_name(dart_name)
    # Convert CamelCase to snake_case: XdrAccountEntry → xdr_account_entry
    # Must match generator.rb's file_name method exactly.
    # Uses two-pass approach to handle uppercase runs (e.g., SCP → scp, not s_c_p)
    dart_name
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .downcase
  end

  def resolve_field_name(type_name, xdr_field_name)
    field = xdr_field_name.to_s
    if FIELD_OVERRIDES.key?(type_name) && FIELD_OVERRIDES[type_name].key?(field)
      FIELD_OVERRIDES[type_name][field]
    else
      field
    end
  end

  def dart_type_for_typespec(type)
    case type
    when AST::Typespecs::Bool then "bool"
    when AST::Typespecs::Int then "int"
    when AST::Typespecs::UnsignedInt then "int"
    when AST::Typespecs::Hyper then "BigInt"
    when AST::Typespecs::UnsignedHyper then "BigInt"
    when AST::Typespecs::Float then "double"
    when AST::Typespecs::Double then "double"
    when AST::Typespecs::Quadruple then raise "quadruple not supported"
    when AST::Typespecs::String then "String"
    when AST::Typespecs::Opaque then "Uint8List"
    when AST::Typespecs::Simple
      resolved = type.resolved_type
      resolved_name = name(resolved)
      return TYPE_OVERRIDES[resolved_name] if TYPE_OVERRIDES.key?(resolved_name)
      if resolved.is_a?(AST::Definitions::Typedef)
        underlying = resolved.declaration.type
        return dart_type_for_typespec(underlying) if underlying.sub_type == :optional
      end
      resolved_name
    when AST::Definitions::Base then name(type)
    when AST::Concerns::NestedDefinition then name(type)
    else raise "Unknown type: #{type.class.name}"
    end
  end

  def dart_type_string(decl, member = nil)
    is_optional = member && (member.type.sub_type == :optional || typedef_is_optional?(decl.type))
    case decl
    when AST::Declarations::Array
      "List<#{dart_type_for_typespec(decl.type)}>"
    when AST::Declarations::Opaque
      "Uint8List"
    when AST::Declarations::String
      is_optional ? "String?" : "String"
    else
      base = dart_type_for_typespec(decl.type)
      is_optional ? "#{base}?" : base
    end
  end

  def resolve_discriminant_info(union)
    dtype = union.discriminant.type
    disc_field_name = union.discriminant.name.to_s
    if dtype.respond_to?(:resolved_type)
      resolved = dtype.resolved_type
      if resolved.is_a?(AST::Definitions::Enum)
        return { kind: :enum, dart_name: name(resolved), enum_defn: resolved, field_name: disc_field_name }
      end
    end
    { kind: :int, dart_name: nil, enum_defn: nil, field_name: disc_field_name }
  end

  def build_union_arms(union, union_name, disc_info)
    arms = []
    seen_fields = Set.new

    union.normal_arms.each do |arm|
      if arm.void?
        labels = arm.cases.map { |c| format_case_label(c.value, disc_info) }
        arms << { case_labels: labels, void: true, is_default: false }
      else
        field_name = resolve_field_name(union_name, arm.name)
        next if seen_fields.include?(field_name)
        seen_fields.add(field_name)

        labels = arm.cases.map { |c| format_case_label(c.value, disc_info) }
        arm_info = resolve_dart_arm_info(arm, union_name)
        arms << {
          case_labels: labels, void: false, field_name: field_name,
          dart_type: arm_info[:dart_type], is_default: false,
          fixed_size: arm_info[:fixed_size],
        }
      end
    end

    if union.default_arm.present?
      da = union.default_arm
      if da.void?
        arms << { case_labels: ["default"], void: true, is_default: true }
      else
        field_name = resolve_field_name(union_name, da.name)
        arm_info = resolve_dart_arm_info(da, union_name)
        arms << {
          case_labels: ["default"], void: false, field_name: field_name,
          dart_type: arm_info[:dart_type], is_default: true,
        }
      end
    end

    arms
  end

  def format_case_label(value, disc_info)
    if value.is_a?(AST::Identifier)
      disc_info[:kind] == :enum ? "#{disc_info[:dart_name]}.#{value.name}" : value.name.to_s
    else
      value.value.to_s
    end
  end

  def resolve_dart_arm_info(arm, union_name)
    decl = arm.declaration
    case decl
    when AST::Declarations::Array
      { dart_type: "List<#{dart_type_for_typespec(decl.type)}>", decode_style: :array }
    when AST::Declarations::Optional
      { dart_type: dart_type_for_typespec(decl.type), decode_style: :optional }
    when AST::Declarations::String
      { dart_type: "String", decode_style: :string }
    when AST::Declarations::Opaque
      if decl.fixed?
        { dart_type: "Uint8List", decode_style: :opaque_fixed, fixed_size: decl.size.to_i }
      else
        { dart_type: "XdrDataValue", decode_style: :simple }
      end
    else
      type_str = dart_type_for_typespec(decl.type)
      info = { dart_type: type_str, decode_style: :simple }
      # Check if resolved type is a typedef wrapping fixed opaque (e.g., AssetCode12 → opaque<12>)
      if type_str == "Uint8List" && decl.type.is_a?(AST::Typespecs::Simple)
        resolved = decl.type.resolved_type
        if resolved.is_a?(AST::Definitions::Typedef) &&
           resolved.declaration.is_a?(AST::Declarations::Opaque) &&
           resolved.declaration.fixed?
          info[:fixed_size] = resolved.declaration.size.to_i
        end
      end
      info
    end
  end

  def resolve_typedef_type(underlying)
    return nil if underlying.nil?
    case underlying
    when AST::Typespecs::Int then { dart_type: "int" }
    when AST::Typespecs::UnsignedInt then { dart_type: "int" }
    when AST::Typespecs::Hyper then { dart_type: "BigInt" }
    when AST::Typespecs::UnsignedHyper then { dart_type: "BigInt" }
    when AST::Typespecs::Bool then { dart_type: "bool" }
    when AST::Typespecs::Simple
      resolved = underlying.resolved_type
      if resolved.is_a?(AST::Definitions::Typedef)
        inner_decl = resolved.declaration
        if inner_decl.respond_to?(:type) && !inner_decl.is_a?(AST::Declarations::Opaque) &&
           !inner_decl.is_a?(AST::Declarations::String) && !inner_decl.is_a?(AST::Declarations::Array)
          return resolve_typedef_type(inner_decl.type)
        end
      end
      dart_name = name(resolved)
      dart_name = TYPE_OVERRIDES[dart_name] if TYPE_OVERRIDES.key?(dart_name)
      { dart_type: dart_name }
    else
      nil
    end
  end

  # Returns the fixed-opaque byte size for a declaration, or nil if not fixed-opaque.
  # Handles both direct opaque<N> declarations and typedef references (e.g., AssetCode12 → opaque<12>).
  def fixed_opaque_size(decl)
    if decl.is_a?(AST::Declarations::Opaque) && decl.fixed?
      return decl.size.to_i
    end
    # Check if it's a typedef reference to a fixed opaque
    if decl.respond_to?(:type) && decl.type.is_a?(AST::Typespecs::Simple)
      resolved = decl.type.resolved_type
      if resolved.is_a?(AST::Definitions::Typedef) &&
         resolved.declaration.is_a?(AST::Declarations::Opaque) &&
         resolved.declaration.fixed?
        return resolved.declaration.size.to_i
      end
    end
    nil
  rescue
    nil
  end

  def underscore_field(class_name)
    short = class_name.sub(/\AXdr/, '').sub(/Base\z/, '')
    short[0].downcase + short[1..]
  end

  def typedef_is_optional?(type)
    return false unless type.is_a?(AST::Typespecs::Simple)
    resolved = type.resolved_type
    return false unless resolved.is_a?(AST::Definitions::Typedef)
    resolved_name = name(resolved)
    return false if TYPE_OVERRIDES.key?(resolved_name)
    resolved.declaration.type.sub_type == :optional
  rescue
    false
  end
end

# =============================================================================
# Main
# =============================================================================

if __FILE__ == $0
  project_root = File.expand_path("../../..", __dir__)
  output_dir = File.join(project_root, "test", "unit", "xdr", "generated")
  xdr_dir = File.join(project_root, "xdr")

  generator = TestGenerator.new(output_dir, xdr_dir)
  generator.generate
end
