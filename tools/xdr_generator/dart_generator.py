"""Dart code generator for XDR types.

Generates Dart code matching existing Flutter SDK XDR patterns exactly,
including proper encoding/decoding, field declarations, and method signatures.
"""

from typing import Dict, List, Optional, Set
from .xdr_ast import (
    XdrFile, XdrEnum, XdrStruct, XdrUnion, XdrTypedef,
    XdrField, XdrConstant, XdrEnumValue, XdrUnionCase
)
from .type_mapping import TypeMapper, get_type_mapper
from .file_mapping import FileMapper, get_file_mapper


class DartGenerator:
    """Generates Dart code from XDR AST nodes."""

    def __init__(self, type_mapper: Optional[TypeMapper] = None,
                 file_mapper: Optional[FileMapper] = None):
        """Initialize the Dart generator.

        Args:
            type_mapper: Type mapping system (uses default if None)
            file_mapper: File mapping system (uses default if None)
        """
        self.type_mapper = type_mapper or get_type_mapper()
        self.file_mapper = file_mapper or get_file_mapper()
        self.indent = '  '  # 2-space indentation
        self.constant_values: Dict[str, int] = {}  # Track constant values for enum resolution

    def _snake_to_camel(self, name: str) -> str:
        """Convert snake_case field name to camelCase, preserving uppercase sequences.

        Examples:
            wasm_hash -> wasmHash
            balance_id -> balanceID
            liquidity_pool_id -> liquidityPoolID
            ledger_seq -> ledgerSeq
            contract_id -> contractID
            account_id -> accountID
            claimable_balance_i_d -> claimableBalanceID

        Args:
            name: snake_case field name

        Returns:
            camelCase field name with uppercase sequences preserved
        """
        if '_' not in name:
            return name

        # Split by underscore
        parts = name.split('_')

        # Start with first part lowercase
        result = parts[0].lower()

        # Process remaining parts
        i = 1
        while i < len(parts):
            part = parts[i].lower()  # Normalize to lowercase first

            # Check if this is part of an uppercase sequence (ID, URL, etc.)
            # Look ahead to see if next parts are single letters that form an acronym
            if len(part) == 1:
                # Collect consecutive single-letter parts
                uppercase_seq = part.upper()
                j = i + 1
                while j < len(parts) and len(parts[j]) == 1:
                    uppercase_seq += parts[j].upper()
                    j += 1

                # Check common patterns (2+ letters)
                if len(uppercase_seq) >= 2 and uppercase_seq in ['ID', 'URL', 'URI', 'UUID', 'HTML', 'XML', 'JSON']:
                    result += uppercase_seq
                    i = j
                    continue
                # Single letter by itself - check if it's I followed by D (for ID)
                elif uppercase_seq == 'I' and i + 1 < len(parts) and parts[i + 1].lower() == 'd':
                    result += 'ID'
                    i += 2
                    continue

            # Check for common 2-letter patterns like 'id'
            if part == 'id':
                result += 'ID'
            elif part in ['url', 'uri', 'html', 'xml', 'json', 'uuid']:
                result += part.upper()
            else:
                # Regular part - capitalize first letter
                result += part.capitalize()

            i += 1

        return result

    def register_constants(self, constants: List[XdrConstant]):
        """Register constants for enum value resolution.

        Args:
            constants: List of XdrConstant definitions
        """
        for const in constants:
            self.constant_values[const.name] = const.value

    def register_enum_values(self, enum: XdrEnum):
        """Register enum values as constants for cross-reference resolution.

        Args:
            enum: XdrEnum definition
        """
        for i, enum_val in enumerate(enum.values):
            if enum_val.value is not None:
                self.constant_values[enum_val.name] = enum_val.value
            elif enum_val.value_ref:
                # Try to resolve reference
                ref_value = self.constant_values.get(enum_val.value_ref)
                if ref_value is not None:
                    self.constant_values[enum_val.name] = ref_value
            else:
                # Auto-increment from previous value
                if i > 0:
                    prev_name = enum.values[i - 1].name
                    prev_value = self.constant_values.get(prev_name, i - 1)
                    self.constant_values[enum_val.name] = prev_value + 1
                else:
                    self.constant_values[enum_val.name] = 0

    def resolve_enum_value(self, enum_val: XdrEnumValue) -> int:
        """Resolve enum value to integer, handling constant references.

        Args:
            enum_val: XdrEnumValue to resolve

        Returns:
            Integer value for the enum
        """
        # Direct value specified
        if enum_val.value is not None:
            return enum_val.value

        # Reference to another constant
        if enum_val.value_ref:
            resolved = self.constant_values.get(enum_val.value_ref)
            if resolved is not None:
                return resolved
            # If not found, try to find it in the current enum (for auto-increment)
            # Default to 0 if can't resolve
            print(f"Warning: Cannot resolve constant reference '{enum_val.value_ref}' for enum value '{enum_val.name}', defaulting to 0")
            return 0

        # No value specified - should have been caught during parsing
        return 0

    def generate_enum(self, enum: XdrEnum) -> str:
        """Generate Dart enum class matching existing pattern.

        Pattern from xdr_type.dart:
        ```dart
        class XdrPublicKeyType {
          final _value;
          const XdrPublicKeyType._internal(this._value);
          toString() => 'PublicKeyType.$_value';
          XdrPublicKeyType(this._value);
          get value => this._value;

          static const PUBLIC_KEY_TYPE_ED25519 = const XdrPublicKeyType._internal(0);

          static XdrPublicKeyType decode(XdrDataInputStream stream) { ... }
          static void encode(XdrDataOutputStream stream, XdrPublicKeyType value) { ... }
        }
        ```

        Args:
            enum: XdrEnum node

        Returns:
            Generated Dart code
        """
        class_name = self.type_mapper.get_dart_class_name(enum.name)
        simple_name = enum.name  # For toString without Xdr prefix

        lines = []
        lines.append(f'class {class_name} {{')
        lines.append(f'{self.indent}final _value;')
        lines.append(f'{self.indent}const {class_name}._internal(this._value);')
        lines.append(f'{self.indent}toString() => \'{simple_name}.$_value\';')
        lines.append(f'{self.indent}{class_name}(this._value);')
        lines.append(f'{self.indent}get value => this._value;')
        lines.append('')

        # Generate static constants for each enum value
        for enum_val in enum.values:
            # Resolve value (handles constant references)
            value_int = self.resolve_enum_value(enum_val)
            lines.append(f'{self.indent}static const {enum_val.name} = const {class_name}._internal({value_int});')

        lines.append('')

        # Generate decode method
        lines.append(f'{self.indent}static {class_name} decode(XdrDataInputStream stream) {{')
        lines.append(f'{self.indent * 2}int value = stream.readInt();')
        lines.append(f'{self.indent * 2}switch (value) {{')
        for enum_val in enum.values:
            # Resolve value (handles constant references)
            value_int = self.resolve_enum_value(enum_val)
            lines.append(f'{self.indent * 3}case {value_int}:')
            lines.append(f'{self.indent * 4}return {enum_val.name};')
        lines.append(f'{self.indent * 3}default:')
        lines.append(f'{self.indent * 4}throw Exception("Unknown enum value: $value");')
        lines.append(f'{self.indent * 2}}}')
        lines.append(f'{self.indent}}}')
        lines.append('')

        # Generate encode method
        lines.append(f'{self.indent}static void encode(XdrDataOutputStream stream, {class_name} value) {{')
        lines.append(f'{self.indent * 2}stream.writeInt(value.value);')
        lines.append(f'{self.indent}}}')
        lines.append('}')

        return '\n'.join(lines)

    def generate_struct(self, struct: XdrStruct) -> str:
        """Generate Dart struct class matching existing pattern.

        Pattern from xdr_asset.dart:
        ```dart
        class XdrAssetAlphaNum4 {
          Uint8List _assetCode;
          Uint8List get assetCode => this._assetCode;
          set assetCode(Uint8List value) => this._assetCode = value;

          XdrAccountID _issuer;
          XdrAccountID get issuer => this._issuer;
          set issuer(XdrAccountID value) => this._issuer = value;

          XdrAssetAlphaNum4(this._assetCode, this._issuer);

          static void encode(XdrDataOutputStream stream, XdrAssetAlphaNum4 encoded) { ... }
          static XdrAssetAlphaNum4 decode(XdrDataInputStream stream) { ... }
        }
        ```

        Args:
            struct: XdrStruct node

        Returns:
            Generated Dart code
        """
        # Apply inline struct aliasing to share identical anonymous structs
        # Example: PathPaymentStrictReceiveResultSuccess -> PathPaymentResultSuccess
        struct_name = self.type_mapper.apply_inline_struct_alias(struct.name)
        class_name = self.type_mapper.get_dart_class_name(struct_name)

        lines = []
        lines.append(f'class {class_name} {{')

        # Generate field declarations (private field + getter + setter)
        for field in struct.fields:
            field_decls = self._generate_field_declaration(field)
            for decl in field_decls:
                lines.append(f'{self.indent}{decl}')
            if field != struct.fields[-1]:  # Add blank line between fields
                lines.append('')

        lines.append('')

        # Generate constructor
        # Check if all fields are optional
        all_optional = all(field.is_optional or
                          (hasattr(field, 'optional_elements') and field.optional_elements)
                          for field in struct.fields)

        if all_optional and len(struct.fields) > 0:
            # All fields are optional - make constructor parameters optional too
            optional_params = ', '.join([f'this._{self._snake_to_camel(field.name)}' for field in struct.fields])
            lines.append(f'{self.indent}{class_name}([{optional_params}]);')
        else:
            # Normal constructor with required parameters
            constructor_params = ', '.join([f'this._{self._snake_to_camel(field.name)}' for field in struct.fields])
            lines.append(f'{self.indent}{class_name}({constructor_params});')
        lines.append('')

        # Generate encode method
        # Use camelCase version of class name for parameter (e.g., encodedAssetAlphaNum4)
        param_name = f'encoded{class_name[3:]}'  # Remove 'Xdr' prefix
        lines.append(f'{self.indent}static void encode(XdrDataOutputStream stream, {class_name} {param_name}) {{')
        for field in struct.fields:
            encode_stmt = self._generate_field_encode(field, param_name)
            lines.append(f'{self.indent * 2}{encode_stmt}')
        lines.append(f'{self.indent}}}')
        lines.append('')

        # Generate decode method
        lines.append(f'{self.indent}static {class_name} decode(XdrDataInputStream stream) {{')

        # Check if any fields have complex decoding (arrays or optionals)
        has_complex_fields = any(
            (field.is_array() and field.type_name != 'opaque') or field.is_optional
            for field in struct.fields
        )

        if has_complex_fields:
            # Complex struct - need intermediate variables for arrays/optionals
            decode_vars = []

            for field in struct.fields:
                dart_type = self._get_dart_type(field)
                field_name = self._snake_to_camel(field.name)
                var_name = f'x{field_name[0].upper()}{field_name[1:]}'  # xFieldName

                # Handle arrays and optionals inline
                if field.is_array() and field.type_name != 'opaque':
                    # Typed array - needs inline decoding
                    decode_stmts = self._generate_array_decode_inline(field, var_name, dart_type)
                    for stmt in decode_stmts:
                        lines.append(f'{self.indent * 2}{stmt}')
                elif field.is_optional:
                    # Optional field - needs inline decoding
                    decode_stmts = self._generate_optional_decode_inline(field, var_name, dart_type)
                    for stmt in decode_stmts:
                        lines.append(f'{self.indent * 2}{stmt}')
                else:
                    # Simple field
                    if field.type_name == 'opaque' and field.is_fixed_array:
                        size = field.array_size or 0
                        lines.append(f'{self.indent * 2}int {field_name}size = {size};')
                        decode_stmt = f'stream.readBytes({field_name}size)'
                    else:
                        decode_stmt = self._generate_field_decode(field)

                    lines.append(f'{self.indent * 2}{dart_type} {var_name} = {decode_stmt};')

                decode_vars.append(var_name)

            # Return directly with decoded variables
            return_params = ', '.join(decode_vars)
            lines.append(f'{self.indent * 2}return {class_name}({return_params});')
        else:
            # Simple struct - return directly with inline decode calls

            # Declare size variables for fixed opaque arrays
            for field in struct.fields:
                if field.type_name == 'opaque' and field.is_fixed_array:
                    size = field.array_size or 0
                    field_name = self._snake_to_camel(field.name)
                    lines.append(f'{self.indent * 2}int {field_name}size = {size};')

            # Build inline decode expressions
            inline_params = []
            for field in struct.fields:
                field_name = self._snake_to_camel(field.name)
                if field.type_name == 'opaque' and field.is_fixed_array:
                    inline_params.append(f'stream.readBytes({field_name}size)')
                else:
                    inline_params.append(self._generate_field_decode(field))

            # Return directly with proper formatting
            # Use threshold: 1-2 fields = single-line, 3+ fields = multi-line
            if len(inline_params) <= 2:
                # 1-2 parameters - keep on one line
                params_str = ', '.join(inline_params)
                lines.append(f'{self.indent * 2}return {class_name}({params_str});')
            else:
                # 3+ parameters - format nicely with trailing comma
                lines.append(f'{self.indent * 2}return {class_name}(')
                for param in inline_params:
                    lines.append(f'{self.indent * 3}{param},')
                lines.append(f'{self.indent * 2});')

        lines.append(f'{self.indent}}}')
        lines.append('}')

        return '\n'.join(lines)

    def generate_union(self, union: XdrUnion) -> str:
        """Generate Dart union class matching existing pattern.

        Pattern from xdr_memo.dart (enum discriminant):
        ```dart
        class XdrMemo {
          XdrMemo(this._type);

          XdrMemoType _type;
          XdrMemoType get discriminant => this._type;
          set discriminant(XdrMemoType value) => this._type = value;

          String? _text;
          String? get text => this._text;
          set text(String? value) => this._text = value;

          static void encode(XdrDataOutputStream stream, XdrMemo encoded) { ... }
          static XdrMemo decode(XdrDataInputStream stream) { ... }
        }
        ```

        Pattern from xdr_account.dart (int discriminant):
        ```dart
        class XdrExtensionPoint {
          XdrExtensionPoint(this._v);

          int _v;
          int get discriminant => this._v;
          set discriminant(int value) => this._v = value;

          static void encode(XdrDataOutputStream stream, XdrExtensionPoint encoded) {
            stream.writeInt(encoded.discriminant);
            switch (encoded.discriminant) { ... }
          }

          static XdrExtensionPoint decode(XdrDataInputStream stream) {
            int discriminant = stream.readInt();
            XdrExtensionPoint decoded = XdrExtensionPoint(discriminant);
            switch (decoded.discriminant) { ... }
          }
        }
        ```

        Args:
            union: XdrUnion node

        Returns:
            Generated Dart code
        """
        class_name = self.type_mapper.get_dart_class_name(union.name)

        # Check if this class has inheritance
        parent_class = self.file_mapper.extends_class(class_name)
        additional_fields = self.file_mapper.get_additional_fields(class_name)

        # Check if discriminant is int or enum type
        is_int_discriminant = union.discriminant_type.lower() in ['int', 'integer']

        # Check if discriminant is a primitive wrapper (like uint32 -> XdrUint32)
        discriminant_value_property = self.type_mapper.get_value_property(union.discriminant_type)
        is_primitive_wrapper = discriminant_value_property is not None

        if is_int_discriminant:
            discriminant_type = 'int'
        else:
            discriminant_type = self.type_mapper.get_dart_class_name(union.discriminant_type)

        lines = []
        # Generate class declaration with inheritance if applicable
        if parent_class:
            lines.append(f'class {class_name} extends {parent_class} {{')
        else:
            lines.append(f'class {class_name} {{')

        # Generate discriminant field FIRST (if not inherited)
        if not parent_class:
            lines.append(f'{self.indent}{discriminant_type} _{union.discriminant_name};')
            lines.append(f'{self.indent}{discriminant_type} get discriminant => this._{union.discriminant_name};')
            lines.append(f'{self.indent}set discriminant({discriminant_type} value) => this._{union.discriminant_name} = value;')
            lines.append('')

        # Collect all unique variant fields (all are nullable)
        variant_fields: Dict[str, XdrField] = {}

        # If this class extends a parent, get the parent's fields to skip them
        parent_fields: Set[str] = set()
        if parent_class:
            # Get the parent union definition to extract its field names
            # The parent fields should be skipped in the child class
            # For XdrTrustlineAsset extends XdrAsset, skip: alphaNum4, alphaNum12
            # We need to identify which fields belong to the parent union
            parent_fields = self._get_parent_union_fields(parent_class)

        # Add additional fields for inherited classes FIRST (like poolId for XdrTrustlineAsset)
        # This ensures the original SDK field names take precedence over spec names
        additional_field_names: Set[str] = set()
        if additional_fields:
            for discriminant_value, fields_list in additional_fields.items():
                for field_name, field_type, is_nullable in fields_list:
                    # Track this field name so we don't add spec-named version later
                    additional_field_names.add(field_name)
                    if field_name not in variant_fields:
                        # Create a synthetic XdrField for the additional field
                        field = XdrField(
                            name=field_name,
                            type_name=field_type.replace('Xdr', ''),  # Remove Xdr prefix for type name
                            is_optional=is_nullable,
                            is_fixed_array=False,
                            is_variable_array=False,
                            array_size=None
                        )
                        variant_fields[field_name] = field

        # Now add fields from XDR spec (but skip if we have an additional field that replaces it)
        for case in union.cases:
            if case.field and not case.field.name == 'void':
                field_name = self._snake_to_camel(case.field.name)
                # Skip fields that belong to parent class or conflict with additional fields
                if field_name not in parent_fields and field_name not in variant_fields:
                    # Check if this field is replaced by an additional field with different name
                    # For example, liquidity_pool_id (becomes liquidityPoolID) is replaced by poolId
                    # We need to skip spec fields when an additional field exists for the same discriminant
                    should_skip = False
                    if additional_fields:
                        # Find which discriminant case this field belongs to
                        for discriminant_value in case.case_values:
                            if discriminant_value in additional_fields:
                                # This case has additional fields, so skip the spec field
                                should_skip = True
                                break

                    if not should_skip:
                        variant_fields[field_name] = case.field

        # Generate variant field declarations (all nullable)
        for field_name, field in variant_fields.items():
            field_decls = self._generate_field_declaration(field, force_nullable=True)
            for decl in field_decls:
                lines.append(f'{self.indent}{decl}')
            if field_name != list(variant_fields.keys())[-1]:
                lines.append('')

        if variant_fields:
            lines.append('')

        # Generate constructor AFTER fields
        if parent_class:
            # Constructor with super call for inherited classes
            # Include discriminant + all nullable variant fields
            variant_params = ', '.join([f'this._{field_name}' for field_name in variant_fields.keys()])
            if variant_params:
                lines.append(f'{self.indent}{class_name}({discriminant_type} {union.discriminant_name}, {variant_params}) : super({union.discriminant_name});')
            else:
                lines.append(f'{self.indent}{class_name}({discriminant_type} {union.discriminant_name}) : super({union.discriminant_name});')
        else:
            # Normal constructor - include discriminant + all nullable variant fields
            variant_params = ', '.join([f'this._{field_name}' for field_name in variant_fields.keys()])
            if variant_params:
                lines.append(f'{self.indent}{class_name}(this._{union.discriminant_name}, {variant_params});')
            else:
                lines.append(f'{self.indent}{class_name}(this._{union.discriminant_name});')
        lines.append('')

        # Generate encode method
        # Use camelCase version for parameter (e.g., encodedMemo)
        param_name = f'encoded{class_name[3:]}'  # Remove 'Xdr' prefix
        lines.append(f'{self.indent}static void encode(XdrDataOutputStream stream, {class_name} {param_name}) {{')

        # Write discriminant - always write for both parent and inherited classes
        # Static encode methods need to write the discriminant even for child classes
        if is_int_discriminant:
            lines.append(f'{self.indent * 2}stream.writeInt({param_name}.discriminant);')
        elif is_primitive_wrapper:
            # Primitive wrapper like XdrUint32 - use property accessor
            lines.append(f'{self.indent * 2}stream.writeInt({param_name}.discriminant.{discriminant_value_property});')
        else:
            # Enum type - use .value
            lines.append(f'{self.indent * 2}stream.writeInt({param_name}.discriminant.value);')

        # Switch statement - use property accessor for primitive wrappers
        if is_int_discriminant:
            switch_expr = f'{param_name}.discriminant'
        elif is_primitive_wrapper:
            switch_expr = f'{param_name}.discriminant.{discriminant_value_property}'
        else:
            switch_expr = f'{param_name}.discriminant'

        lines.append(f'{self.indent * 2}switch ({switch_expr}) {{')

        for case in union.cases:
            # Generate case labels
            for case_value in case.case_values:
                if is_int_discriminant or is_primitive_wrapper:
                    # Use raw int values for int discriminants and primitive wrappers
                    lines.append(f'{self.indent * 3}case {case_value}:')
                else:
                    # Use enum constants
                    lines.append(f'{self.indent * 3}case {discriminant_type}.{case_value}:')

            # Check if this case has additional fields for inherited classes
            has_additional_field = False
            additional_field_to_encode = None
            if additional_fields and case.case_values:
                # Get the discriminant constant name for this case
                discriminant_const = case.case_values[0]
                if discriminant_const in additional_fields:
                    has_additional_field = True
                    # Get the field info: [(field_name, field_type, is_nullable), ...]
                    fields_list = additional_fields[discriminant_const]
                    if fields_list:
                        additional_field_to_encode = fields_list[0]  # Just encode the first additional field

            # Generate case body
            if has_additional_field and additional_field_to_encode:
                # Encode the additional field for inherited class
                field_name, field_type, is_nullable = additional_field_to_encode
                camel_field_name = self._snake_to_camel(field_name)
                non_null_op = '!' if is_nullable else ''
                lines.append(f'{self.indent * 4}{field_type}.encode(stream, {param_name}.{camel_field_name}{non_null_op});')
                lines.append(f'{self.indent * 4}break;')
            elif case.field and case.field.type_name != 'void':
                # Check if this is an array field that needs inline encoding
                if case.field.is_array() and case.field.type_name != 'opaque':
                    # Array field - needs inline encoding with loop
                    field_name = self._snake_to_camel(case.field.name)
                    field_access = f'{param_name}.{field_name}!'
                    element_type = self.type_mapper.map_type(case.field.type_name)

                    # Check if elements are optional
                    has_optional_elements = hasattr(case.field, 'optional_elements') and case.field.optional_elements

                    # Variable arrays need length prefix
                    if case.field.is_variable_array:
                        lines.append(f'{self.indent * 4}int {field_name}size = {field_access}.length;')
                        lines.append(f'{self.indent * 4}stream.writeInt({field_name}size);')
                        lines.append(f'{self.indent * 4}for (int i = 0; i < {field_name}size; i++) {{')
                    else:
                        # Fixed arrays don't write length
                        size = case.field.array_size or 0
                        lines.append(f'{self.indent * 4}for (int i = 0; i < {size}; i++) {{')

                    # Encode element - handle optional elements
                    if has_optional_elements:
                        lines.append(f'{self.indent * 5}if ({field_access}[i] != null) {{')
                        lines.append(f'{self.indent * 6}stream.writeInt(1);')
                        lines.append(f'{self.indent * 6}{element_type}.encode(stream, {field_access}[i]);')
                        lines.append(f'{self.indent * 5}}} else {{')
                        lines.append(f'{self.indent * 6}stream.writeInt(0);')
                        lines.append(f'{self.indent * 5}}}')
                    else:
                        lines.append(f'{self.indent * 5}{element_type}.encode(stream, {field_access}[i]);')

                    lines.append(f'{self.indent * 4}}}')
                else:
                    # Simple field - use regular encode
                    encode_stmt = self._generate_field_encode(case.field, param_name, force_non_null=True)
                    lines.append(f'{self.indent * 4}{encode_stmt}')

                lines.append(f'{self.indent * 4}break;')
            else:
                # Void case - no encoding
                lines.append(f'{self.indent * 4}break;')

        lines.append(f'{self.indent * 2}}}')
        lines.append(f'{self.indent}}}')
        lines.append('')

        # Generate decode method
        decoded_name = f'decoded{class_name[3:]}'  # Remove 'Xdr' prefix
        lines.append(f'{self.indent}static {class_name} decode(XdrDataInputStream stream) {{')

        # Inherited classes read discriminant and create instance
        if parent_class:
            # Decode discriminant and create inherited class instance
            lines.append(f'{self.indent * 2}{class_name} {decoded_name} = {class_name}({discriminant_type}.decode(stream));')
        else:
            # Decode discriminant - different for int vs enum vs primitive wrapper
            if is_int_discriminant:
                lines.append(f'{self.indent * 2}{class_name} {decoded_name} = {class_name}(stream.readInt());')
            else:
                # Both enum and primitive wrapper decode the same way
                lines.append(f'{self.indent * 2}{class_name} {decoded_name} = {class_name}({discriminant_type}.decode(stream));')

        # Switch statement - use property accessor for primitive wrappers
        if is_int_discriminant:
            switch_expr = f'{decoded_name}.discriminant'
        elif is_primitive_wrapper:
            switch_expr = f'{decoded_name}.discriminant.{discriminant_value_property}'
        else:
            switch_expr = f'{decoded_name}.discriminant'

        lines.append(f'{self.indent * 2}switch ({switch_expr}) {{')

        for case in union.cases:
            # Generate case labels
            for case_value in case.case_values:
                if is_int_discriminant or is_primitive_wrapper:
                    # Use raw int values for int discriminants and primitive wrappers
                    lines.append(f'{self.indent * 3}case {case_value}:')
                else:
                    # Use enum constants
                    lines.append(f'{self.indent * 3}case {discriminant_type}.{case_value}:')

            # Check if this case has additional fields for inherited classes
            has_additional_field = False
            additional_field_to_decode = None
            if additional_fields and case.case_values:
                # Get the discriminant constant name for this case
                discriminant_const = case.case_values[0]
                if discriminant_const in additional_fields:
                    has_additional_field = True
                    # Get the field info: [(field_name, field_type, is_nullable), ...]
                    fields_list = additional_fields[discriminant_const]
                    if fields_list:
                        additional_field_to_decode = fields_list[0]  # Just decode the first additional field

            # Generate case body
            if has_additional_field and additional_field_to_decode:
                # Decode the additional field for inherited class
                field_name, field_type, is_nullable = additional_field_to_decode
                camel_field_name = self._snake_to_camel(field_name)
                lines.append(f'{self.indent * 4}{decoded_name}.{camel_field_name} = {field_type}.decode(stream);')
                lines.append(f'{self.indent * 4}break;')
            elif case.field and case.field.type_name != 'void':
                field_name = self._snake_to_camel(case.field.name)

                # Check if this is an array field that needs inline decoding
                if case.field.is_array() and case.field.type_name != 'opaque':
                    # Array field - needs inline decoding with loop
                    dart_type = self._get_dart_type(case.field)
                    element_type = self.type_mapper.map_type(case.field.type_name)

                    # Check if elements are optional
                    has_optional_elements = hasattr(case.field, 'optional_elements') and case.field.optional_elements

                    # Read size (for variable arrays)
                    if case.field.is_variable_array:
                        lines.append(f'{self.indent * 4}int {field_name}size = stream.readInt();')
                        size_var = f'{field_name}size'
                    else:
                        size_var = str(case.field.array_size or 0)

                    # Create empty list
                    if has_optional_elements:
                        lines.append(f'{self.indent * 4}List<{element_type}?> {field_name} = List<{element_type}?>.empty(growable: true);')
                    else:
                        lines.append(f'{self.indent * 4}List<{element_type}> {field_name} = List<{element_type}>.empty(growable: true);')

                    # Loop to decode elements
                    lines.append(f'{self.indent * 4}for (int i = 0; i < {size_var}; i++) {{')

                    if has_optional_elements:
                        # Handle optional elements
                        presence_var = f'{field_name}Present'
                        lines.append(f'{self.indent * 5}int {presence_var} = stream.readInt();')
                        lines.append(f'{self.indent * 5}if ({presence_var} != 0) {{')
                        lines.append(f'{self.indent * 6}{field_name}.add({element_type}.decode(stream));')
                        lines.append(f'{self.indent * 5}}} else {{')
                        lines.append(f'{self.indent * 6}{field_name}.add(null);')
                        lines.append(f'{self.indent * 5}}}')
                    else:
                        # Normal non-optional elements
                        lines.append(f'{self.indent * 5}{field_name}.add({element_type}.decode(stream));')

                    lines.append(f'{self.indent * 4}}}')
                    lines.append(f'{self.indent * 4}{decoded_name}.{field_name} = {field_name};')
                else:
                    # Simple field - use regular decode
                    decode_stmt = self._generate_field_decode(case.field)
                    lines.append(f'{self.indent * 4}{decoded_name}.{field_name} = {decode_stmt};')

                lines.append(f'{self.indent * 4}break;')
            else:
                # Void case - no decoding
                lines.append(f'{self.indent * 4}break;')

        lines.append(f'{self.indent * 2}}}')
        lines.append(f'{self.indent * 2}return {decoded_name};')
        lines.append(f'{self.indent}}}')
        lines.append('}')

        return '\n'.join(lines)

    def generate_typedef(self, typedef: XdrTypedef) -> str:
        """Generate Dart wrapper class for typedef if needed.

        Some typedefs need wrapper classes, others are just type aliases
        that are handled by the type mapper.

        Args:
            typedef: XdrTypedef node

        Returns:
            Generated Dart code or empty string if no class needed
        """
        # Check if this is a special wrapper type (manually implemented)
        if typedef.name in self.type_mapper.SPECIAL_WRAPPERS:
            return ''

        # Check if this is a typedef alias (no wrapper needed)
        if typedef.name in self.type_mapper.TYPEDEF_ALIASES:
            return ''

        # Detect optional typedef (underlying_type ends with *)
        is_optional = typedef.underlying_type.endswith('*')
        base_type = typedef.underlying_type.rstrip('*') if is_optional else typedef.underlying_type

        # Pattern 1: Simple type alias (no wrapper needed)
        # Example: typedef PublicKey AccountID;
        if not typedef.is_opaque and not typedef.is_string and not typedef.is_variable and not typedef.is_fixed and not is_optional:
            # Simple alias - handled by type_mapping
            return ''

        # Pattern 2: Variable array typedef
        # Example: typedef SCVal SCVec<>; or typedef Hash TxAdvertVector<TX_ADVERT_VECTOR_MAX_SIZE>;
        if typedef.is_variable and not typedef.is_opaque and not typedef.is_string:
            return self._generate_variable_array_typedef(typedef, base_type)

        # Pattern 3: String typedef with limit
        # Example: typedef string SCSymbol<SCSYMBOL_LIMIT>;
        if typedef.is_string:
            return self._generate_string_typedef(typedef)

        # Pattern 4: Opaque typedef (variable length)
        # Example: typedef opaque EncryptedBody<64000>;
        if typedef.is_opaque and typedef.is_variable:
            return self._generate_opaque_typedef(typedef)

        # Pattern 5: Optional/Pointer typedef
        # Example: typedef AccountID* SponsorshipDescriptor;
        if is_optional:
            return self._generate_optional_typedef(typedef, base_type)

        # Default: no wrapper needed
        return ''

    def _generate_variable_array_typedef(self, typedef: XdrTypedef, element_type: str) -> str:
        """Generate wrapper for variable array typedef.

        Example: typedef SCVal SCVec<>;
        Generates a wrapper class with List<XdrSCVal> field.

        Args:
            typedef: XdrTypedef node
            element_type: The element type name

        Returns:
            Generated Dart code
        """
        class_name = self.type_mapper.get_dart_class_name(typedef.name)
        dart_element_type = self.type_mapper.get_dart_class_name(element_type)

        # Use simplified field name based on type (e.g., SCVec -> vec, SCMap -> map)
        # Convert type name to simple field name
        simple_name = typedef.name
        if simple_name.startswith('SC'):
            field_name = simple_name[2:].lower()  # SCVec -> vec, SCMap -> map
        else:
            # Generic fallback: lowercase first letter
            field_name = simple_name[0].lower() + simple_name[1:] if len(simple_name) > 1 else simple_name.lower()

        lines = []
        lines.append(f'class {class_name} {{')
        lines.append(f'{self.indent}List<{dart_element_type}> _{field_name};')
        lines.append(f'{self.indent}List<{dart_element_type}> get {field_name} => this._{field_name};')
        lines.append(f'{self.indent}set {field_name}(List<{dart_element_type}> value) => this._{field_name} = value;')
        lines.append('')
        lines.append(f'{self.indent}{class_name}(this._{field_name});')
        lines.append('')

        # Generate encode method
        param_name = f'encoded{class_name[3:]}'  # Remove 'Xdr' prefix
        lines.append(f'{self.indent}static void encode(XdrDataOutputStream stream, {class_name} {param_name}) {{')
        lines.append(f'{self.indent * 2}int size = {param_name}.{field_name}.length;')
        lines.append(f'{self.indent * 2}stream.writeInt(size);')
        lines.append(f'{self.indent * 2}for (int i = 0; i < size; i++) {{')
        lines.append(f'{self.indent * 3}{dart_element_type}.encode(stream, {param_name}.{field_name}[i]);')
        lines.append(f'{self.indent * 2}}}')
        lines.append(f'{self.indent}}}')
        lines.append('')

        # Generate decode method
        lines.append(f'{self.indent}static {class_name} decode(XdrDataInputStream stream) {{')
        lines.append(f'{self.indent * 2}int size = stream.readInt();')
        lines.append(f'{self.indent * 2}List<{dart_element_type}> {field_name} = List<{dart_element_type}>.empty(growable: true);')
        lines.append(f'{self.indent * 2}for (int i = 0; i < size; i++) {{')
        lines.append(f'{self.indent * 3}{field_name}.add({dart_element_type}.decode(stream));')
        lines.append(f'{self.indent * 2}}}')
        lines.append(f'{self.indent * 2}return {class_name}({field_name});')
        lines.append(f'{self.indent}}}')
        lines.append('}')

        return '\n'.join(lines)

    def _generate_string_typedef(self, typedef: XdrTypedef) -> str:
        """Generate wrapper for string typedef.

        Example: typedef string SCSymbol<SCSYMBOL_LIMIT>;
        Generates a wrapper class with String field.

        Args:
            typedef: XdrTypedef node

        Returns:
            Generated Dart code
        """
        class_name = self.type_mapper.get_dart_class_name(typedef.name)

        # Use simplified field name based on type
        simple_name = typedef.name
        if simple_name.startswith('SC'):
            field_name = simple_name[2:].lower()  # SCSymbol -> symbol
        else:
            field_name = simple_name[0].lower() + simple_name[1:] if len(simple_name) > 1 else simple_name.lower()

        lines = []
        lines.append(f'class {class_name} {{')
        lines.append(f'{self.indent}String _{field_name};')
        lines.append(f'{self.indent}String get {field_name} => this._{field_name};')
        lines.append(f'{self.indent}set {field_name}(String value) => this._{field_name} = value;')
        lines.append('')
        lines.append(f'{self.indent}{class_name}(this._{field_name});')
        lines.append('')

        # Generate encode method
        param_name = f'encoded{class_name[3:]}'  # Remove 'Xdr' prefix
        lines.append(f'{self.indent}static void encode(XdrDataOutputStream stream, {class_name} {param_name}) {{')
        lines.append(f'{self.indent * 2}stream.writeString({param_name}.{field_name});')
        lines.append(f'{self.indent}}}')
        lines.append('')

        # Generate decode method
        lines.append(f'{self.indent}static {class_name} decode(XdrDataInputStream stream) {{')
        lines.append(f'{self.indent * 2}return {class_name}(stream.readString());')
        lines.append(f'{self.indent}}}')
        lines.append('}')

        return '\n'.join(lines)

    def _generate_opaque_typedef(self, typedef: XdrTypedef) -> str:
        """Generate wrapper for opaque typedef.

        Example: typedef opaque EncryptedBody<64000>;
        Generates a wrapper class with Uint8List field.
        Example: typedef opaque DataValue<64>; -> field name: dataValue

        Args:
            typedef: XdrTypedef node

        Returns:
            Generated Dart code
        """
        class_name = self.type_mapper.get_dart_class_name(typedef.name)

        # Use camelCase version of typedef name as field name
        # DataValue -> dataValue, EncryptedBody -> encryptedBody
        field_name = typedef.name[0].lower() + typedef.name[1:] if len(typedef.name) > 1 else typedef.name.lower()

        lines = []
        lines.append(f'class {class_name} {{')
        lines.append(f'{self.indent}Uint8List _{field_name};')
        lines.append(f'{self.indent}Uint8List get {field_name} => this._{field_name};')
        lines.append(f'{self.indent}set {field_name}(Uint8List value) => this._{field_name} = value;')
        lines.append('')
        lines.append(f'{self.indent}{class_name}(this._{field_name});')
        lines.append('')

        # Generate encode method
        param_name = f'encoded{class_name[3:]}'  # Remove 'Xdr' prefix
        lines.append(f'{self.indent}static void encode(XdrDataOutputStream stream, {class_name} {param_name}) {{')
        lines.append(f'{self.indent * 2}stream.writeInt({param_name}.{field_name}.length);')
        lines.append(f'{self.indent * 2}stream.write({param_name}.{field_name});')
        lines.append(f'{self.indent}}}')
        lines.append('')

        # Generate decode method
        lines.append(f'{self.indent}static {class_name} decode(XdrDataInputStream stream) {{')
        lines.append(f'{self.indent * 2}int size = stream.readInt();')
        lines.append(f'{self.indent * 2}return {class_name}(stream.readBytes(size));')
        lines.append(f'{self.indent}}}')
        lines.append('}')

        return '\n'.join(lines)

    def _generate_optional_typedef(self, typedef: XdrTypedef, base_type: str) -> str:
        """Generate wrapper for optional typedef.

        Example: typedef AccountID* SponsorshipDescriptor;
        Generates a wrapper class with nullable field.

        Args:
            typedef: XdrTypedef node
            base_type: The base type name (without *)

        Returns:
            Generated Dart code
        """
        class_name = self.type_mapper.get_dart_class_name(typedef.name)
        dart_base_type = self.type_mapper.get_dart_class_name(base_type)

        # Use simplified field name based on base type
        field_name = base_type[0].lower() + base_type[1:] if len(base_type) > 1 else base_type.lower()

        lines = []
        lines.append(f'class {class_name} {{')
        lines.append(f'{self.indent}{dart_base_type}? _{field_name};')
        lines.append(f'{self.indent}{dart_base_type}? get {field_name} => this._{field_name};')
        lines.append(f'{self.indent}set {field_name}({dart_base_type}? value) => this._{field_name} = value;')
        lines.append('')
        lines.append(f'{self.indent}{class_name}(this._{field_name});')
        lines.append('')

        # Generate encode method
        param_name = f'encoded{class_name[3:]}'  # Remove 'Xdr' prefix
        lines.append(f'{self.indent}static void encode(XdrDataOutputStream stream, {class_name} {param_name}) {{')
        lines.append(f'{self.indent * 2}if ({param_name}.{field_name} != null) {{')
        lines.append(f'{self.indent * 3}stream.writeInt(1);')
        lines.append(f'{self.indent * 3}{dart_base_type}.encode(stream, {param_name}.{field_name}!);')
        lines.append(f'{self.indent * 2}}} else {{')
        lines.append(f'{self.indent * 3}stream.writeInt(0);')
        lines.append(f'{self.indent * 2}}}')
        lines.append(f'{self.indent}}}')
        lines.append('')

        # Generate decode method
        lines.append(f'{self.indent}static {class_name} decode(XdrDataInputStream stream) {{')
        lines.append(f'{self.indent * 2}int present = stream.readInt();')
        lines.append(f'{self.indent * 2}if (present != 0) {{')
        lines.append(f'{self.indent * 3}return {class_name}({dart_base_type}.decode(stream));')
        lines.append(f'{self.indent * 2}}}')
        lines.append(f'{self.indent * 2}return {class_name}(null);')
        lines.append(f'{self.indent}}}')
        lines.append('}')

        return '\n'.join(lines)

    def _generate_field_declaration(self, field: XdrField,
                                    force_nullable: bool = False) -> List[str]:
        """Generate field declaration, getter, and setter.

        Args:
            field: XdrField node
            force_nullable: Force field to be nullable (for union variants)

        Returns:
            List of declaration lines
        """
        dart_type = self._get_dart_type(field)
        field_name = self._snake_to_camel(field.name)

        # Union variant fields are always nullable
        if force_nullable and not dart_type.endswith('?'):
            dart_type += '?'

        lines = []
        lines.append(f'{dart_type} _{field_name};')
        lines.append(f'{dart_type} get {field_name} => this._{field_name};')
        lines.append(f'set {field_name}({dart_type} value) => this._{field_name} = value;')

        return lines

    def _generate_field_encode(self, field: XdrField, obj_name: str,
                               force_non_null: bool = False) -> str:
        """Generate encode statement for a field.

        Args:
            field: XdrField node
            obj_name: Name of the object variable (e.g., 'encoded')
            force_non_null: Add ! operator for non-null assertion

        Returns:
            Encode statement
        """
        field_name = self._snake_to_camel(field.name)
        field_access = f'{obj_name}.{field_name}'
        if force_non_null:
            field_access += '!'

        # Handle optional fields
        if field.is_optional:
            return self._generate_optional_encode(field, obj_name)

        # Handle opaque arrays specially (they are Uint8List)
        if field.type_name == 'opaque' and field.is_array():
            # Fixed size opaque - just write the bytes directly
            if field.is_fixed_array:
                return f'stream.write({field_access});'
            # Variable size opaque - write length then bytes
            else:
                lines = []
                lines.append(f'int {field_name}Size = {field_access}.length;')
                lines.append(f'{self.indent * 2}stream.writeInt({field_name}Size);')
                lines.append(f'{self.indent * 2}stream.write({field_access});')
                return '\n'.join(lines)

        # Handle non-opaque arrays (typed arrays)
        if field.is_array():
            return self._generate_array_encode(field, obj_name)

        # Handle bool primitive type specially
        if field.type_name == 'bool':
            return f'stream.writeInt({field_access} ? 1 : 0);'

        # Handle primitive types that need direct stream writes
        if field.type_name in ['string', 'String']:
            # Apply non-null assertion if needed (for union variants)
            if force_non_null and not field_access.endswith('!'):
                field_access += '!'
            return f'stream.writeString({field_access});'

        # Get dart type before encode call
        dart_type = self.type_mapper.map_type(field.type_name)

        # Don't call encode() on Uint8List - it's a Dart primitive, use stream.write()
        if dart_type == 'Uint8List':
            return f'stream.write({field_access});'

        # Handle wrapper types and custom types
        return f'{dart_type}.encode(stream, {field_access});'

    def _generate_field_decode(self, field: XdrField) -> str:
        """Generate decode statement for a field.

        Args:
            field: XdrField node

        Returns:
            Decode expression (right-hand side only)
        """
        # Handle bool primitive type specially
        if field.type_name == 'bool':
            return 'stream.readInt() != 0'

        # Handle primitive string
        if field.type_name in ['string', 'String']:
            return 'stream.readString()'

        # Handle opaque (raw bytes)
        if field.type_name == 'opaque':
            # Fixed size opaque
            if field.is_fixed_array:
                size = field.array_size or 0
                return f'stream.readBytes({size})'
            # Variable size opaque
            else:
                return f'stream.readBytes(stream.readInt())'

        # Get dart type before decode call
        dart_type = self.type_mapper.map_type(field.type_name)

        # Don't call decode() on Uint8List - it's a Dart primitive
        # Check if this is a raw byte array typedef (like AssetCode4, AssetCode12)
        if dart_type == 'Uint8List':
            # Check if we have size information from typedef
            size = self.type_mapper.get_raw_byte_array_size(field.type_name)
            if size is not None:
                # Fixed size typedef like AssetCode4[4]
                return f'stream.readBytes({size})'
            else:
                # Variable size - need to read length prefix
                return f'stream.readBytes(stream.readInt())'

        # Handle wrapper types and custom types
        return f'{dart_type}.decode(stream)'

    def _generate_array_decode_inline(self, field: XdrField, var_name: str,
                                      dart_type: str) -> List[str]:
        """Generate inline decode statements for array field.

        Pattern for array with optional elements:
        ```dart
        int pSize = stream.readInt();
        List<XdrAccountID?> xSignerSponsoringIDs = List<XdrAccountID?>.empty(growable: true);
        for (int i = 0; i < pSize; i++) {
          int sponsoringIDPresent = stream.readInt();
          if (sponsoringIDPresent != 0) {
            xSignerSponsoringIDs.add(XdrAccountID.decode(stream));
          } else {
            xSignerSponsoringIDs.add(null);
          }
        }
        ```

        Args:
            field: XdrField node
            var_name: Variable name to use
            dart_type: Complete Dart type (List<ElementType> or List<ElementType?>)

        Returns:
            List of decode statements
        """
        element_type = self.type_mapper.map_type(field.type_name)
        field_name = self._snake_to_camel(field.name)
        lines = []

        # Check if elements are optional
        has_optional_elements = hasattr(field, 'optional_elements') and field.optional_elements

        # Read size (for variable arrays)
        if field.is_variable_array:
            lines.append(f'int {field_name}Size = stream.readInt();')
            size_var = f'{field_name}Size'
        else:
            size_var = str(field.array_size or 0)

        # Create empty list - use correct type with optional marker if needed
        if has_optional_elements:
            lines.append(f'{dart_type} {var_name} = List<{element_type}?>.empty(growable: true);')
        else:
            lines.append(f'{dart_type} {var_name} = List<{element_type}>.empty(growable: true);')

        # Loop to decode elements
        lines.append(f'for (int i = 0; i < {size_var}; i++) {{')

        if has_optional_elements:
            # Handle optional elements - read presence indicator
            presence_var = f'{field_name[0]}{field_name[1:].capitalize()}Present' if len(field_name) > 1 else f'{field_name}Present'
            lines.append(f'{self.indent}int {presence_var} = stream.readInt();')
            lines.append(f'{self.indent}if ({presence_var} != 0) {{')
            lines.append(f'{self.indent * 2}{var_name}.add({element_type}.decode(stream));')
            lines.append(f'{self.indent}}} else {{')
            lines.append(f'{self.indent * 2}{var_name}.add(null);')
            lines.append(f'{self.indent}}}')
        else:
            # Normal non-optional elements
            lines.append(f'{self.indent}{var_name}.add({element_type}.decode(stream));')

        lines.append('}')

        return lines

    def _generate_optional_decode_inline(self, field: XdrField, var_name: str,
                                         dart_type: str) -> List[str]:
        """Generate inline decode statements for optional field.

        Args:
            field: XdrField node
            var_name: Variable name to use
            dart_type: Complete Dart type (TypeName?)

        Returns:
            List of decode statements
        """
        base_type = dart_type.rstrip('?')
        field_name = self._snake_to_camel(field.name)
        lines = []

        # Declare nullable variable
        lines.append(f'{dart_type} {var_name};')

        # Check presence indicator
        lines.append(f'int {field_name}Present = stream.readInt();')
        lines.append(f'if ({field_name}Present != 0) {{')

        # Decode if present
        decode_expr = self._generate_field_decode(field)
        lines.append(f'{self.indent}{var_name} = {decode_expr};')
        lines.append('}')

        return lines

    def _generate_optional_encode(self, field: XdrField, obj_name: str) -> str:
        """Generate encode statement for optional field.

        Pattern:
        ```dart
        if (encoded.fieldName != null) {
          stream.writeInt(1);
          FieldType.encode(stream, encoded.fieldName!);
        } else {
          stream.writeInt(0);
        }
        ```

        Args:
            field: XdrField node
            obj_name: Name of object variable

        Returns:
            Multi-line encode statement
        """
        field_name = self._snake_to_camel(field.name)
        field_access = f'{obj_name}.{field_name}'
        dart_type = self.type_mapper.map_type(field.type_name)

        # Build the if statement (will be split across lines by caller)
        lines = []
        lines.append(f'if ({field_access} != null) {{')
        lines.append(f'{self.indent * 3}stream.writeInt(1);')
        lines.append(f'{self.indent * 3}{dart_type}.encode(stream, {field_access}!);')
        lines.append(f'{self.indent * 2}}} else {{')
        lines.append(f'{self.indent * 3}stream.writeInt(0);')
        lines.append(f'{self.indent * 2}}}')

        return '\n'.join(lines)

    def _generate_array_encode(self, field: XdrField, obj_name: str) -> str:
        """Generate encode statement for array field.

        Pattern for variable array:
        ```dart
        int fieldNameSize = encoded.fieldName.length;
        stream.writeInt(fieldNameSize);
        for (int i = 0; i < fieldNameSize; i++) {
          ElementType.encode(stream, encoded.fieldName[i]);
        }
        ```

        Pattern for array with optional elements:
        ```dart
        int pSize = encoded.signerSponsoringIDs.length;
        stream.writeInt(pSize);
        for (int i = 0; i < pSize; i++) {
          if (encoded.signerSponsoringIDs[i] != null) {
            stream.writeInt(1);
            XdrAccountID.encode(stream, encoded.signerSponsoringIDs[i]);
          } else {
            stream.writeInt(0);
          }
        }
        ```

        Args:
            field: XdrField node
            obj_name: Name of object variable

        Returns:
            Multi-line encode statement
        """
        field_name = self._snake_to_camel(field.name)
        field_access = f'{obj_name}.{field_name}'
        element_type = self.type_mapper.map_type(field.type_name)

        lines = []

        # Check if elements are optional
        has_optional_elements = hasattr(field, 'optional_elements') and field.optional_elements

        # Variable arrays need length prefix
        if field.is_variable_array:
            lines.append(f'int {field_name}Size = {field_access}.length;')
            lines.append(f'{self.indent * 2}stream.writeInt({field_name}Size);')
            lines.append(f'{self.indent * 2}for (int i = 0; i < {field_name}Size; i++) {{')
        else:
            # Fixed arrays don't write length
            size = field.array_size or 0
            lines.append(f'for (int i = 0; i < {size}; i++) {{')

        # Encode element - handle optional elements
        if has_optional_elements:
            lines.append(f'{self.indent * 3}if ({field_access}[i] != null) {{')
            lines.append(f'{self.indent * 4}stream.writeInt(1);')
            lines.append(f'{self.indent * 4}{element_type}.encode(stream, {field_access}[i]);')
            lines.append(f'{self.indent * 3}}} else {{')
            lines.append(f'{self.indent * 4}stream.writeInt(0);')
            lines.append(f'{self.indent * 3}}}')
        else:
            lines.append(f'{self.indent * 3}{element_type}.encode(stream, {field_access}[i]);')

        lines.append(f'{self.indent * 2}}}')

        return '\n'.join(lines)

    def _get_parent_union_fields(self, parent_class: str) -> Set[str]:
        """Get field names from parent union class.

        Args:
            parent_class: Parent class name (e.g., 'XdrAsset')

        Returns:
            Set of field names in parent union (camelCase)
        """
        # Hardcoded parent field mappings for known inheritance cases
        # This maps parent class names to their union variant field names
        PARENT_UNION_FIELDS = {
            'XdrAsset': {'alphaNum4', 'alphaNum12'},  # XdrAsset has these variant fields
            # Add more parent classes here as needed
        }

        return PARENT_UNION_FIELDS.get(parent_class, set())

    def _get_dart_type(self, field: XdrField) -> str:
        """Get Dart type for a field including array/optional modifiers.

        Args:
            field: XdrField node

        Returns:
            Complete Dart type string
        """
        base_type = self.type_mapper.map_type(field.type_name)

        # Handle arrays
        if field.is_array():
            # For opaque arrays, use Uint8List for the bytes themselves
            if field.type_name == 'opaque':
                return 'Uint8List'
            # For typed arrays, check if elements are optional
            # Check if field has optional_elements attribute
            if hasattr(field, 'optional_elements') and field.optional_elements:
                return f'List<{base_type}?>'
            # For typed arrays, use List<Type>
            return f'List<{base_type}>'

        # Handle optional (already handled by map_type for pointer types)
        if field.is_optional and not base_type.endswith('?'):
            return f'{base_type}?'

        return base_type

    def generate_file_header(self, version: str) -> str:
        """Generate file header with copyright and version info.

        Args:
            version: XDR version string (e.g., 'v25.0')

        Returns:
            Header comment block
        """
        lines = []
        lines.append('// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.')
        lines.append('// Use of this source code is governed by a license that can be')
        lines.append('// found in the LICENSE file.')
        lines.append('//')
        lines.append(f'// Generated from stellar-xdr {version}')
        lines.append('// DO NOT EDIT - Custom methods preserved in CUSTOM_CODE sections')
        lines.append('')

        return '\n'.join(lines)

    def generate_imports(self, filename: str,
                        used_types: Set[str],
                        needs_uint8list: bool = False) -> List[str]:
        """Generate import statements for a file.

        Preserves original import order:
        1. dart: imports (only if needed)
        2. local imports (sorted alphabetically)

        Args:
            filename: Target filename (e.g., 'xdr_memo.dart')
            used_types: Set of Dart class names used in this file
            needs_uint8list: Whether the file uses Uint8List (for opaque/binary fields)

        Returns:
            List of import statements
        """
        imports = []

        # Add dart:typed_data FIRST if file uses Uint8List (matches original order)
        if needs_uint8list:
            imports.append("import 'dart:typed_data';")

        # Determine which other XDR files are needed
        needed_files = set()
        for type_name in used_types:
            target_file = self.file_mapper.get_target_file(type_name)
            if target_file and target_file != filename:
                needed_files.add(target_file)

        # Add xdr_data_io.dart to the list
        needed_files.add('xdr_data_io.dart')

        # Add imports for all needed files (sorted)
        for file in sorted(needed_files):
            imports.append(f"import '{file}';")

        return imports

    def _needs_uint8list(self, definitions: List) -> bool:
        """Check if any definition uses Uint8List (opaque/binary fields).

        Args:
            definitions: List of XDR definitions

        Returns:
            True if Uint8List is needed
        """
        for defn in definitions:
            if isinstance(defn, XdrStruct):
                for field in defn.fields:
                    if field.type_name == 'opaque':
                        return True
            elif isinstance(defn, XdrUnion):
                for case in defn.cases:
                    if case.field and case.field.type_name == 'opaque':
                        return True
            elif isinstance(defn, XdrTypedef):
                # Check if typedef is for opaque type
                if defn.is_opaque:
                    return True
        return False

    def generate_file(self, filename: str, definitions: List,
                     version: str) -> str:
        """Generate complete Dart file with imports and definitions.

        Args:
            filename: Target filename
            definitions: List of XDR definition nodes (enums, structs, unions)
            version: XDR version string

        Returns:
            Complete Dart file content
        """
        lines = []

        # Add header
        lines.append(self.generate_file_header(version))

        # Collect all used types for imports
        used_types = set()
        for defn in definitions:
            # Add logic to collect used types from definitions
            pass

        # Check if Uint8List is needed
        needs_uint8list = self._needs_uint8list(definitions)

        # Add imports
        imports = self.generate_imports(filename, used_types, needs_uint8list)
        for imp in imports:
            lines.append(imp)

        lines.append('')

        # Generate each definition
        for defn in definitions:
            if isinstance(defn, XdrEnum):
                lines.append(self.generate_enum(defn))
            elif isinstance(defn, XdrStruct):
                lines.append(self.generate_struct(defn))
            elif isinstance(defn, XdrUnion):
                lines.append(self.generate_union(defn))
            elif isinstance(defn, XdrTypedef):
                typedef_code = self.generate_typedef(defn)
                if typedef_code:  # Only add if there's actual code
                    lines.append(typedef_code)

            lines.append('')  # Blank line between definitions

        return '\n'.join(lines)


def get_dart_generator(type_mapper: Optional[TypeMapper] = None,
                       file_mapper: Optional[FileMapper] = None) -> DartGenerator:
    """Get a DartGenerator instance.

    Args:
        type_mapper: Optional type mapper
        file_mapper: Optional file mapper

    Returns:
        DartGenerator instance
    """
    return DartGenerator(type_mapper, file_mapper)
