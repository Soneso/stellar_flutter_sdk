#!/usr/bin/env ruby
# frozen_string_literal: true

# Traces all XDR types reachable from TransactionEnvelope and related roots,
# printing the sorted list of Dart class names.
#
# Usage:
#   cd tools/xdr-generator && bundle exec ruby test/trace_txrep_types.rb

require 'xdrgen'
require 'set'
require_relative '../generator/name_overrides'

AST = Xdrgen::AST unless defined?(AST)

# ---------------------------------------------------------------------------
# Name conversion -- mirrors the generator's name() method exactly.
# ---------------------------------------------------------------------------

def raw_xdr_qualified_name(named)
  xdr_name = named.name.camelize
  if named.is_a?(AST::Concerns::NestedDefinition)
    parent_raw = raw_xdr_qualified_name(named.parent_defn)
    "#{parent_raw}#{xdr_name}"
  else
    xdr_name
  end
end

def dart_name_for(named)
  raw = raw_xdr_qualified_name(named)
  return NAME_OVERRIDES[raw] if NAME_OVERRIDES.key?(raw)

  xdr_name = named.name.camelize
  return NAME_OVERRIDES[xdr_name] if NAME_OVERRIDES.key?(xdr_name)

  if named.is_a?(AST::Concerns::NestedDefinition)
    parent = dart_name_for(named.parent_defn)
    "#{parent}#{xdr_name}"
  else
    "Xdr#{xdr_name}"
  end
end

# ---------------------------------------------------------------------------
# Collect all definitions from the AST into a flat name->defn map.
# ---------------------------------------------------------------------------

def collect_all_definitions(node, map)
  node.definitions.each do |defn|
    next if defn.is_a?(AST::Definitions::Const)
    map[defn.name.to_s] = defn

    # Also index nested definitions (inline unions/structs)
    if defn.respond_to?(:nested_definitions)
      defn.nested_definitions.each do |nested|
        # Nested definitions are keyed by their raw field name since find_definition
        # searches by simple name. We store them under the parent-qualified key too.
        map[nested.name.to_s] ||= nested
      end
    end
  end
  node.namespaces.each { |ns| collect_all_definitions(ns, map) }
end

# ---------------------------------------------------------------------------
# Recursive type tracer
# ---------------------------------------------------------------------------

class TypeTracer
  # Primitive Dart types we never need to recurse into.
  PRIMITIVES = %w[int bool double String BigInt Uint8List void].freeze

  def initialize(top)
    @top = top
    @visited_dart_names = Set.new   # dart names already fully visited
    @reachable_dart_names = Set.new # dart names collected so far
  end

  def trace_roots(xdr_root_names)
    xdr_root_names.each do |xdr_name|
      defn = @top.find_definition(xdr_name)
      if defn.nil?
        warn "WARNING: root type '#{xdr_name}' not found in AST"
        next
      end
      trace_defn(defn)
    end
  end

  def reachable_dart_names
    @reachable_dart_names.to_a.sort
  end

  private

  def trace_defn(defn)
    return if defn.nil?
    return if defn.is_a?(AST::Definitions::Const)

    dart = dart_name_for(defn)
    return if @visited_dart_names.include?(dart)
    @visited_dart_names.add(dart)

    # Skip raw primitive mappings (e.g. uint32 -> int) -- they have no class
    return if PRIMITIVES.include?(dart) || dart.start_with?("List<")

    @reachable_dart_names.add(dart)

    case defn
    when AST::Definitions::Struct
      trace_struct(defn)
    when AST::Definitions::Union
      trace_union(defn)
    when AST::Definitions::Typedef
      trace_typedef(defn)
    when AST::Definitions::Enum
      # Enums have no references to other complex types; just record them.
    end
  end

  def trace_struct(defn)
    # First recurse into nested definitions (inline unions within the struct)
    if defn.respond_to?(:nested_definitions)
      defn.nested_definitions.each { |nested| trace_defn(nested) }
    end

    defn.members.each do |member|
      trace_declaration(member.declaration)
    end
  end

  def trace_union(defn)
    # Nested definitions within the union
    if defn.respond_to?(:nested_definitions)
      defn.nested_definitions.each { |nested| trace_defn(nested) }
    end

    # The discriminant type (an enum or typedef)
    disc_type = defn.discriminant_type
    trace_defn(disc_type) if disc_type

    # All non-void arms
    defn.arms.each do |arm|
      next if arm.declaration.is_a?(AST::Declarations::Void)
      trace_declaration(arm.declaration)
    end

    # Default arm
    if defn.default_arm && !defn.default_arm.declaration.is_a?(AST::Declarations::Void)
      trace_declaration(defn.default_arm.declaration)
    end
  end

  def trace_typedef(defn)
    trace_declaration(defn.declaration)
  end

  def trace_declaration(decl)
    return if decl.nil?

    case decl
    when AST::Declarations::Void
      # nothing
    when AST::Declarations::Opaque
      # raw bytes -- no class to recurse into
    when AST::Declarations::String
      # raw String -- no class
    when AST::Declarations::Array
      # The element type of the array
      trace_typespec(decl.type)
    else
      # Simple, Optional, and other declarations all have a .type typespec
      trace_typespec(decl.type)
    end
  end

  def trace_typespec(type)
    return if type.nil?

    case type
    when AST::Typespecs::Bool,
         AST::Typespecs::Int,
         AST::Typespecs::UnsignedInt,
         AST::Typespecs::Hyper,
         AST::Typespecs::UnsignedHyper,
         AST::Typespecs::Float,
         AST::Typespecs::Double,
         AST::Typespecs::String,
         AST::Typespecs::Opaque
      # primitive -- nothing to recurse into
    when AST::Typespecs::Simple
      begin
        resolved = type.resolved_type
        trace_defn(resolved)
      rescue StandardError => e
        warn "WARNING: could not resolve type '#{type.text_value}': #{e.message}"
      end
    when AST::Definitions::Base
      trace_defn(type)
    when AST::Concerns::NestedDefinition
      trace_defn(type)
    else
      warn "WARNING: unknown typespec class #{type.class.name}"
    end
  end
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

ROOT_XDR_TYPES = %w[
  TransactionEnvelope
  TransactionV0Envelope
  TransactionV1Envelope
  FeeBumpTransactionEnvelope
  Transaction
  TransactionV0
  FeeBumpTransaction
  DecoratedSignature
].freeze

# Run from the tools/xdr-generator directory; xdr files are two levels up.
project_root = File.expand_path("../../..", __dir__)
xdr_files = Dir.glob(File.join(project_root, "xdr/*.x")).sort

if xdr_files.empty?
  abort "No .x files found under #{project_root}/xdr/. Run from tools/xdr-generator/."
end

compilation = Xdrgen::Compilation.new(
  xdr_files,
  output_dir: "/dev/null/",
  generator: Class.new(Xdrgen::Generators::Base) { def generate; end },
  namespace: "stellar",
)
top = compilation.send(:ast)

tracer = TypeTracer.new(top)
tracer.trace_roots(ROOT_XDR_TYPES)

dart_names = tracer.reachable_dart_names

puts "Dart types reachable from TransactionEnvelope roots (#{dart_names.size} total):"
puts
dart_names.each { |n| puts "  #{n}" }
