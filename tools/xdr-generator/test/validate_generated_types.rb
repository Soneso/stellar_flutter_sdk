#!/usr/bin/env ruby
# frozen_string_literal: true

# Validates the generated Dart XDR files against the XDR .x file definitions.
#
# This script parses the .x files using xdrgen's AST and compares the structure
# of each generated Dart file to ensure accuracy. It reuses the same override
# files and type mapping logic that the generator uses.
#
# Usage:
#   cd tools/xdr-generator && bundle exec ruby test/validate_generated_types.rb

require 'xdrgen'
require 'set'
require_relative '../generator/generator'

AST = Xdrgen::AST unless defined?(AST)

# =============================================================================
# Validation Engine
# =============================================================================

class GeneratedTypeValidator
  attr_reader :pass_count, :fail_count, :missing_count, :skip_count, :failures

  def initialize(generated_dir, xdr_dir)
    @generated_dir = generated_dir
    @xdr_dir = xdr_dir
    @pass_count = 0
    @fail_count = 0
    @missing_count = 0
    @skip_count = 0
    @failures = []
    @missing_types = []
    @generated_files_cache = Set.new
    @seen_dart_names = Set.new

    @gen = GeneratorHelper.new
  end

  # ---------------------------------------------------------------------------
  # Main entry point
  # ---------------------------------------------------------------------------

  def validate
    Dir.glob(File.join(@generated_dir, "*.dart")).each do |path|
      @generated_files_cache.add(File.basename(path, ".dart"))
    end

    Dir.chdir(File.expand_path("../../..", __dir__))
    compilation = Xdrgen::Compilation.new(
      Dir.glob("xdr/*.x"),
      output_dir: "/dev/null/",
      generator: Generator,
      namespace: "stellar",
    )
    top = compilation.send(:ast)

    walk_definitions(top)

    print_report
  end

  private

  # ---------------------------------------------------------------------------
  # AST Traversal
  # ---------------------------------------------------------------------------

  def walk_definitions(node)
    node.definitions.each { |defn| validate_definition(defn) }
    node.namespaces.each { |ns| walk_definitions(ns) }
  end

  def walk_nested_definitions(defn)
    return unless defn.respond_to?(:nested_definitions)
    defn.nested_definitions.each { |nested| validate_definition(nested) }
  end

  def validate_definition(defn)
    return if defn.is_a?(AST::Definitions::Namespace)

    walk_nested_definitions(defn)

    dart_name = @gen.name(defn)

    return if defn.is_a?(AST::Definitions::Const)

    # TYPE_OVERRIDES types don't get their own file
    if TYPE_OVERRIDES.key?(dart_name)
      @skip_count += 1
      return
    end

    return if @seen_dart_names.include?(dart_name)
    @seen_dart_names.add(dart_name)

    # For BASE_WRAPPER_TYPES, check the _base.dart file
    is_base = BASE_WRAPPER_TYPES.include?(dart_name)
    if is_base
      file_base = @gen.file_name(dart_name).sub(".dart", "_base")
      class_name = "#{dart_name}Base"
    else
      file_base = @gen.file_name(dart_name).sub(".dart", "")
      class_name = dart_name
    end

    dart_file = File.join(@generated_dir, "#{file_base}.dart")
    unless File.exist?(dart_file)
      @missing_count += 1
      @missing_types << "#{dart_name} (#{file_base}.dart)"
      return
    end

    content = File.read(dart_file)

    case defn
    when AST::Definitions::Struct
      validate_struct(defn, dart_name, class_name, content)
    when AST::Definitions::Enum
      validate_enum(defn, dart_name, class_name, content)
    when AST::Definitions::Union
      validate_union(defn, dart_name, class_name, content, is_base)
    when AST::Definitions::Typedef
      validate_typedef(defn, dart_name, class_name, content)
    end
  end

  # ---------------------------------------------------------------------------
  # Enum Validation
  #
  # Dart enums are classes with static const members:
  #   class XdrFoo {
  #     final _value;
  #     const XdrFoo._internal(this._value);
  #     static const MEMBER_NAME = const XdrFoo._internal(42);
  #   }
  #
  # After dart format, long lines wrap:
  #   static const MEMBER_NAME = const XdrFoo._internal(
  #     42,
  #   );
  # ---------------------------------------------------------------------------

  def validate_enum(enum_defn, dart_name, class_name, content)
    errors = []

    unless content =~ /class #{Regexp.escape(class_name)}\s*\{/
      errors << "Not declared as 'class #{class_name}'"
    end

    # Build expected members
    expected_members = enum_defn.members.map do |m|
      { name: m.name.to_s, value: m.value.to_s }
    end

    # Extract actual static const members - handle both single-line and multi-line
    # Single: static const NAME = const Class._internal(VALUE);
    # Multi:  static const NAME = const Class._internal(\n    VALUE,\n  );
    actual_members = []
    escaped_class = Regexp.escape(class_name)
    content.scan(/static\s+const\s+(\w+)\s*=\s*const\s+#{escaped_class}\._internal\(\s*(-?\d+)\s*[,]?\s*\)/m) do |match|
      actual_members << { name: match[0], value: match[1] }
    end

    if expected_members.length != actual_members.length
      errors << "Member count mismatch: expected #{expected_members.length}, got #{actual_members.length}"
      errors << "  Expected: #{expected_members.map { |m| m[:name] }.join(', ')}"
      errors << "  Actual:   #{actual_members.map { |m| m[:name] }.join(', ')}"
    end

    expected_members.each_with_index do |expected, idx|
      actual = actual_members[idx]
      next unless actual

      if expected[:name] != actual[:name]
        errors << "Member #{idx} name mismatch: expected '#{expected[:name]}', got '#{actual[:name]}'"
      end

      if expected[:value] != actual[:value]
        errors << "Member '#{expected[:name]}' value mismatch: expected #{expected[:value]}, got #{actual[:value]}"
      end
    end

    # Verify decode switch has all cases
    decode_cases = content.scan(/case\s+(-?\d+):/).map { |m| m[0] }
    expected_values = expected_members.map { |m| m[:value] }
    missing_decode = expected_values - decode_cases
    unless missing_decode.empty?
      errors << "Decode switch missing cases for values: #{missing_decode.join(', ')}"
    end

    record_result(dart_name, "enum", errors)
  end

  # ---------------------------------------------------------------------------
  # Struct Validation
  # ---------------------------------------------------------------------------

  def validate_struct(struct_defn, dart_name, class_name, content)
    errors = []

    unless content =~ /class #{Regexp.escape(class_name)}\s/
      errors << "Not declared as 'class #{class_name}'"
    end

    # Build expected fields
    expected_fields = struct_defn.members.map do |m|
      field_name = @gen.resolve_field_name(dart_name, m.name)
      type_str = @gen.dart_type_string(m.declaration, m)

      xdr_field_name = m.name.to_s
      if FIELD_TYPE_OVERRIDES.key?(dart_name) && FIELD_TYPE_OVERRIDES[dart_name].key?(xdr_field_name)
        override = FIELD_TYPE_OVERRIDES[dart_name][xdr_field_name]
        type_str = type_str.end_with?('?') ? "#{override}?" : override
      end

      { name: field_name, type: type_str }
    end

    # Extract actual fields from Dart file
    # Match private fields: Type _fieldName; (handles generic types like List<Foo>)
    actual_fields = extract_private_fields(content, class_name)

    if expected_fields.length != actual_fields.length
      errors << "Field count mismatch: expected #{expected_fields.length}, got #{actual_fields.length}"
      errors << "  Expected: #{expected_fields.map { |f| "#{f[:type]} #{f[:name]}" }.join(', ')}"
      errors << "  Actual:   #{actual_fields.map { |f| "#{f[:type]} #{f[:name]}" }.join(', ')}"
    end

    expected_fields.each_with_index do |expected, idx|
      actual = actual_fields[idx]
      next unless actual

      if expected[:name] != actual[:name]
        errors << "Field #{idx} name mismatch: expected '#{expected[:name]}', got '#{actual[:name]}'"
      end

      exp_type = normalize_type(expected[:type])
      act_type = normalize_type(actual[:type])
      if exp_type != act_type
        errors << "Field '#{expected[:name]}' type mismatch: expected '#{exp_type}', got '#{act_type}'"
      end
    end

    record_result(dart_name, "struct", errors)
  end

  # ---------------------------------------------------------------------------
  # Union Validation
  # ---------------------------------------------------------------------------

  def validate_union(union_defn, dart_name, class_name, content, is_base)
    errors = []

    unless content =~ /class #{Regexp.escape(class_name)}\s/
      errors << "Not declared as 'class #{class_name}'"
    end

    # For BASE_WRAPPER_TYPES that extend other classes (e.g., XdrChangeTrustAsset extends XdrAsset),
    # the base only adds new arms; parent handles shared arms. Skip detailed arm validation.
    extends_parent = is_base && content =~ /extends\s+\w+/
    if extends_parent
      record_result(dart_name, "union (base extends parent)", errors)
      return
    end

    disc_info = @gen.resolve_discriminant_info(union_defn)
    arms = @gen.build_union_arms(union_defn, dart_name, disc_info)

    # Validate discriminant field exists
    if disc_info[:kind] == :enum
      disc_type = disc_info[:dart_name]
      disc_field = disc_info[:field_name]
      unless content =~ /#{Regexp.escape(disc_type)}\s+_#{Regexp.escape(disc_field)}\s*;/
        errors << "Discriminant field '#{disc_type} _#{disc_field}' not found"
      end
      # Check for discriminant getter (may use field name or 'discriminant')
      unless content =~ /get\s+(?:discriminant|#{Regexp.escape(disc_field)})\s/
        errors << "Discriminant getter not found"
      end
    else
      disc_field = disc_info[:field_name]
      # Int discriminant can be `int _v` or `XdrUint32 _v` (for uint32 discriminants)
      unless content =~ /(?:int|XdrUint32)\s+_#{Regexp.escape(disc_field)}\s*;/
        errors << "Discriminant field '_#{disc_field}' not found (expected int or XdrUint32)"
      end
    end

    # Validate arm fields (non-void arms should have nullable fields)
    non_void_arms = arms.reject { |a| a[:void] }
    expected_arm_fields = non_void_arms.map do |arm|
      { name: arm[:field_name], type: "#{arm[:dart_type]}?" }
    end

    # Extract nullable fields (arm fields are always nullable with ?)
    actual_arm_fields = extract_nullable_fields(content, class_name)

    if expected_arm_fields.length != actual_arm_fields.length
      errors << "Arm field count mismatch: expected #{expected_arm_fields.length}, got #{actual_arm_fields.length}"
      errors << "  Expected: #{expected_arm_fields.map { |f| "#{f[:type]} #{f[:name]}" }.join(', ')}"
      errors << "  Actual:   #{actual_arm_fields.map { |f| "#{f[:type]} #{f[:name]}" }.join(', ')}"
    end

    expected_arm_fields.each_with_index do |expected, idx|
      actual = actual_arm_fields[idx]
      next unless actual

      if expected[:name] != actual[:name]
        errors << "Arm #{idx} name mismatch: expected '#{expected[:name]}', got '#{actual[:name]}'"
      end

      exp_type = normalize_type(expected[:type])
      act_type = normalize_type(actual[:type])
      if exp_type != act_type
        errors << "Arm '#{expected[:name]}' type mismatch: expected '#{exp_type}', got '#{act_type}'"
      end
    end

    # Validate encode/decode switch case labels
    # Separate non-void labels (must be explicit) from void labels (can be covered by default:)
    non_void_labels = non_void_arms.flat_map { |a| a[:case_labels] }.uniq
    void_arms = arms.select { |a| a[:void] }
    void_labels = void_arms.flat_map { |a| a[:case_labels] }.uniq
    has_default_arm = arms.any? { |a| a[:is_default] }

    validate_switch_cases(content, non_void_labels, void_labels, has_default_arm, "encode", errors)
    validate_switch_cases(content, non_void_labels, void_labels, has_default_arm, "decode", errors)

    record_result(dart_name, "union", errors)
  end

  # ---------------------------------------------------------------------------
  # Typedef Validation
  # ---------------------------------------------------------------------------

  def validate_typedef(typedef_defn, dart_name, class_name, content)
    errors = []
    decl = typedef_defn.declaration

    unless content =~ /class #{Regexp.escape(class_name)}\s/
      errors << "Not declared as 'class #{class_name}'"
    end

    field_name = @gen.underscore_field(class_name)

    # Apply FIELD_TYPE_OVERRIDES for typedefs
    if FIELD_TYPE_OVERRIDES.key?(dart_name) && FIELD_TYPE_OVERRIDES[dart_name].key?(field_name)
      expected_type = FIELD_TYPE_OVERRIDES[dart_name][field_name]
    else
      # Determine expected type from declaration
      case decl
      when AST::Declarations::Opaque
        expected_type = "Uint8List"
      when AST::Declarations::String
        expected_type = "String"
      when AST::Declarations::Array
        element_type = @gen.dart_type_for_typespec(decl.type)
        expected_type = "List<#{element_type}>"
      else
        resolved_type = @gen.resolve_typedef_type(decl.respond_to?(:type) ? decl.type : nil)
        if resolved_type
          expected_type = resolved_type[:dart_type]
        else
          errors << "Unknown typedef declaration type: #{decl.class.name}"
          record_result(dart_name, "typedef", errors)
          return
        end
      end
    end

    # Extract the first private field
    actual_fields = extract_private_fields(content, class_name)
    if actual_fields.empty?
      errors << "Typedef field '#{expected_type} _#{field_name}' not found (no private fields)"
    else
      actual = actual_fields.first
      if actual[:name] != field_name
        errors << "Typedef field name mismatch: expected '_#{field_name}', got '_#{actual[:name]}'"
      end
      if normalize_type(actual[:type]) != normalize_type(expected_type)
        errors << "Typedef inner type mismatch: expected '#{expected_type}', got '#{actual[:type]}'"
      end
    end

    # Verify encode/decode methods exist
    unless content =~ /static\s+void\s+encode\s*\(/
      errors << "Missing static encode method"
    end
    unless content =~ /static\s+#{Regexp.escape(class_name)}\s+decode\s*\(/
      errors << "Missing static decode method"
    end

    record_result(dart_name, "typedef", errors)
  end

  # ---------------------------------------------------------------------------
  # Field Extraction Helpers
  # ---------------------------------------------------------------------------

  # Extract private fields from class body (non-nullable)
  # Handles: Type _name; and List<Type> _name; and Type? _name; (reported with ?)
  def extract_private_fields(content, class_name)
    fields = []
    # Find class body
    class_start = content.index(/class #{Regexp.escape(class_name)}\s/)
    return fields unless class_start

    # Extract all private field declarations: Type _fieldName;
    # This regex handles simple types, generic types, and nullable types
    body = content[class_start..]
    body.scan(/^\s+([\w<>,\s?]+)\s+(_\w+)\s*;/) do |match|
      ftype = match[0].strip
      fname = match[1].strip.sub(/\A_/, '')

      # Skip special fields
      next if fname == "value" && ftype == "final"

      # Skip nullable fields (arm fields) - they'll be extracted separately
      # But include them here for struct validation
      fields << { name: fname, type: ftype }
    end
    fields
  end

  # Extract only nullable private fields (for union arm validation)
  def extract_nullable_fields(content, class_name)
    fields = []
    class_start = content.index(/class #{Regexp.escape(class_name)}\s/)
    return fields unless class_start

    body = content[class_start..]
    body.scan(/^\s+([\w<>,\s]+\?)\s+(_\w+)\s*;/) do |match|
      ftype = match[0].strip
      fname = match[1].strip.sub(/\A_/, '')
      fields << { name: fname, type: ftype }
    end
    fields
  end

  # ---------------------------------------------------------------------------
  # Switch Case Validation
  # ---------------------------------------------------------------------------

  def validate_switch_cases(content, non_void_labels, void_labels, has_default_arm, method_name, errors)
    # Find the method body
    method_match = content.match(/static\s+\S+\s+#{Regexp.escape(method_name)}\s*\(/)
    return unless method_match

    method_start = method_match.end(0)
    switch_match = content[method_start..].match(/switch\s*\([^)]*\)\s*\{/)
    return unless switch_match

    switch_start = method_start + switch_match.end(0)
    brace_count = 1
    pos = switch_start
    while pos < content.length && brace_count > 0
      if content[pos] == '{'
        brace_count += 1
      elsif content[pos] == '}'
        brace_count -= 1
      end
      pos += 1
    end
    switch_body = content[switch_start...pos]

    actual_labels = switch_body.scan(/case\s+([^:]+):/).map { |m| m[0].strip }
    has_default = switch_body.include?("default:")

    # Non-void arm labels must always be present explicitly
    missing_non_void = non_void_labels.select do |label|
      next false if label == "default"
      !actual_labels.any? { |al| labels_match?(al, label) }
    end

    unless missing_non_void.empty?
      errors << "#{method_name} switch missing non-void case labels: #{missing_non_void.join(', ')}"
    end

    # Void arm labels: if switch has `default:`, they're covered.
    # Only report missing void labels if there's no default case.
    unless has_default
      missing_void = void_labels.select do |label|
        next false if label == "default"
        !actual_labels.any? { |al| labels_match?(al, label) }
      end
      unless missing_void.empty?
        errors << "#{method_name} switch missing void case labels (no default): #{missing_void.join(', ')}"
      end
    end

    # If the XDR has a default arm but the switch doesn't, that's an issue
    if has_default_arm && !has_default
      errors << "#{method_name} switch missing 'default:' case"
    end
  end

  def labels_match?(actual, expected)
    actual.gsub(/\s+/, '') == expected.gsub(/\s+/, '')
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def normalize_type(type_str)
    return nil if type_str.nil?
    type_str.strip.gsub(/\s+/, " ")
  end

  def record_result(dart_name, kind, errors)
    if errors.empty?
      @pass_count += 1
    else
      @fail_count += 1
      @failures << { name: dart_name, kind: kind, errors: errors }
    end
  end

  # ---------------------------------------------------------------------------
  # Report
  # ---------------------------------------------------------------------------

  def print_report
    total = @pass_count + @fail_count + @missing_count

    puts ""
    puts "=" * 72
    puts "XDR Generated Type Validation Report (Dart)"
    puts "=" * 72
    puts ""
    puts "Total types checked:  #{total}"
    puts "  Passed:             #{@pass_count}"
    puts "  Failed:             #{@fail_count}"
    puts "  Missing files:      #{@missing_count}"
    puts "  Skipped:            #{@skip_count}"
    puts ""

    if @missing_types.any?
      puts "-" * 72
      puts "MISSING FILES (#{@missing_types.length}):"
      puts "-" * 72
      @missing_types.sort.each { |name| puts "  #{name}" }
      puts ""
    end

    if @failures.any?
      puts "-" * 72
      puts "FAILURES (#{@failures.length}):"
      puts "-" * 72
      @failures.sort_by { |f| f[:name] }.each do |failure|
        puts ""
        puts "  #{failure[:name]} (#{failure[:kind]}):"
        failure[:errors].each { |e| puts "    - #{e}" }
      end
      puts ""
    end

    if @fail_count == 0 && @missing_count == 0
      puts "All generated types passed validation."
    end

    puts "=" * 72
  end
end

# =============================================================================
# GeneratorHelper -- exposes Generator's private methods for validation
# =============================================================================

class GeneratorHelper
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

  def file_name(dart_class_name)
    snake = dart_class_name
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .downcase
    "#{snake}.dart"
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
    when AST::Typespecs::Bool
      "bool"
    when AST::Typespecs::Int
      "int"
    when AST::Typespecs::UnsignedInt
      "int"
    when AST::Typespecs::Hyper
      "BigInt"
    when AST::Typespecs::UnsignedHyper
      "BigInt"
    when AST::Typespecs::Float
      "double"
    when AST::Typespecs::Double
      "double"
    when AST::Typespecs::Quadruple
      raise "quadruple not supported in Dart"
    when AST::Typespecs::String
      "String"
    when AST::Typespecs::Opaque
      "Uint8List"
    when AST::Typespecs::Simple
      resolved = type.resolved_type
      resolved_name = name(resolved)
      if TYPE_OVERRIDES.key?(resolved_name)
        return TYPE_OVERRIDES[resolved_name]
      end
      if resolved.is_a?(AST::Definitions::Typedef)
        underlying = resolved.declaration.type
        if underlying.sub_type == :optional
          return dart_type_for_typespec(underlying)
        end
      end
      resolved_name
    when AST::Definitions::Base
      name(type)
    when AST::Concerns::NestedDefinition
      name(type)
    else
      raise "Unknown type reference: #{type.class.name}"
    end
  end

  def dart_type_string(decl, member = nil)
    is_optional = member && (member.type.sub_type == :optional || typedef_is_optional?(decl.type))

    case decl
    when AST::Declarations::Array
      element_type = dart_type_for_typespec(decl.type)
      "List<#{element_type}>"
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
        dart_name = name(resolved)
        return { kind: :enum, dart_name: dart_name, enum_defn: resolved, field_name: disc_field_name }
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
        arms << {
          case_labels: labels,
          void: true,
          is_default: false,
        }
      else
        field_name = resolve_field_name(union_name, arm.name)
        next if seen_fields.include?(field_name)
        seen_fields.add(field_name)

        labels = arm.cases.map { |c| format_case_label(c.value, disc_info) }
        arm_info = resolve_dart_arm_info(arm, union_name)

        arms << {
          case_labels: labels,
          void: false,
          field_name: field_name,
          dart_type: arm_info[:dart_type],
          encode_style: arm_info[:encode_style],
          decode_style: arm_info[:decode_style],
          element_type: arm_info[:element_type],
          inner_type: arm_info[:inner_type],
          fixed_size: arm_info[:fixed_size],
          is_default: false,
        }
      end
    end

    if union.default_arm.present?
      da = union.default_arm
      if da.void?
        arms << {
          case_labels: ["default"],
          void: true,
          is_default: true,
        }
      else
        field_name = resolve_field_name(union_name, da.name)
        arm_info = resolve_dart_arm_info(da, union_name)
        arms << {
          case_labels: ["default"],
          void: false,
          field_name: field_name,
          dart_type: arm_info[:dart_type],
          encode_style: arm_info[:encode_style],
          decode_style: arm_info[:decode_style],
          element_type: arm_info[:element_type],
          inner_type: arm_info[:inner_type],
          fixed_size: arm_info[:fixed_size],
          is_default: true,
        }
      end
    end

    arms
  end

  def format_case_label(value, disc_info)
    if value.is_a?(AST::Identifier)
      if disc_info[:kind] == :enum
        "#{disc_info[:dart_name]}.#{value.name}"
      else
        value.name.to_s
      end
    else
      value.value.to_s
    end
  end

  def resolve_dart_arm_info(arm, union_name)
    decl = arm.declaration

    case decl
    when AST::Declarations::Array
      element_type = dart_type_for_typespec(decl.type)
      {
        dart_type: "List<#{element_type}>",
        encode_style: :array,
        decode_style: :array,
        element_type: element_type,
        inner_type: nil,
      }
    when AST::Declarations::Optional
      inner_type = dart_type_for_typespec(decl.type)
      {
        dart_type: inner_type,
        encode_style: :optional,
        decode_style: :optional,
        element_type: nil,
        inner_type: inner_type,
      }
    when AST::Declarations::String
      {
        dart_type: "String",
        encode_style: :string,
        decode_style: :string,
        element_type: nil,
        inner_type: nil,
      }
    when AST::Declarations::Opaque
      if decl.fixed?
        {
          dart_type: "Uint8List",
          encode_style: :opaque_fixed,
          decode_style: :opaque_fixed,
          element_type: nil,
          inner_type: nil,
          fixed_size: decl.size,
        }
      else
        {
          dart_type: "XdrDataValue",
          encode_style: :simple,
          decode_style: :simple,
          element_type: nil,
          inner_type: nil,
        }
      end
    else
      type_str = dart_type_for_typespec(decl.type)
      if type_str == "Uint8List"
        fos = fixed_opaque_typedef_size(decl.type)
        if fos
          {
            dart_type: "Uint8List",
            encode_style: :opaque_fixed,
            decode_style: :opaque_fixed,
            element_type: nil,
            inner_type: nil,
            fixed_size: fos,
          }
        else
          {
            dart_type: "Uint8List",
            encode_style: :simple,
            decode_style: :simple,
            element_type: nil,
            inner_type: nil,
          }
        end
      else
        {
          dart_type: type_str,
          encode_style: :simple,
          decode_style: :simple,
          element_type: nil,
          inner_type: nil,
        }
      end
    end
  end

  def resolve_typedef_type(underlying)
    return nil if underlying.nil?

    case underlying
    when AST::Typespecs::Int
      { dart_type: "int" }
    when AST::Typespecs::UnsignedInt
      { dart_type: "int" }
    when AST::Typespecs::Hyper
      { dart_type: "BigInt" }
    when AST::Typespecs::UnsignedHyper
      { dart_type: "BigInt" }
    when AST::Typespecs::Bool
      { dart_type: "bool" }
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

  def underscore_field(class_name)
    short = class_name.sub(/\AXdr/, '').sub(/Base\z/, '')
    short[0].downcase + short[1..]
  end

  def fixed_opaque_typedef_size(typespec)
    return nil unless typespec.is_a?(AST::Typespecs::Simple)
    return nil unless typespec.respond_to?(:resolved_type)
    resolved = typespec.resolved_type
    return nil unless resolved.is_a?(AST::Definitions::Typedef)
    decl = resolved.declaration
    return nil unless decl.is_a?(AST::Declarations::Opaque) && decl.fixed?
    decl.size
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
  generated_dir = File.join(project_root, "lib", "src", "xdr")
  xdr_dir = File.join(project_root, "xdr")

  unless Dir.exist?(generated_dir)
    $stderr.puts "ERROR: Generated files directory not found: #{generated_dir}"
    exit 1
  end

  unless Dir.exist?(xdr_dir)
    $stderr.puts "ERROR: XDR directory not found: #{xdr_dir}"
    exit 1
  end

  validator = GeneratedTypeValidator.new(generated_dir, xdr_dir)
  validator.validate

  exit(validator.fail_count > 0 || validator.missing_count > 0 ? 1 : 0)
end
