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
            value_str = enum_val.value if enum_val.value is not None else '0'
            lines.append(f'{self.indent}static const {enum_val.name} = const {class_name}._internal({value_str});')

        lines.append('')

        # Generate decode method
        lines.append(f'{self.indent}static {class_name} decode(XdrDataInputStream stream) {{')
        lines.append(f'{self.indent * 2}int value = stream.readInt();')
        lines.append(f'{self.indent * 2}switch (value) {{')
        for enum_val in enum.values:
            value_str = enum_val.value if enum_val.value is not None else '0'
            lines.append(f'{self.indent * 3}case {value_str}:')
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
        class_name = self.type_mapper.get_dart_class_name(struct.name)

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
            optional_params = ', '.join([f'this._{field.name}' for field in struct.fields])
            lines.append(f'{self.indent}{class_name}([{optional_params}]);')
        else:
            # Normal constructor with required parameters
            constructor_params = ', '.join([f'this._{field.name}' for field in struct.fields])
            lines.append(f'{self.indent}{class_name}({constructor_params});')
        lines.append('')

        # Generate encode method
        # Use camelCase version of class name for parameter (e.g., encodedAssetAlphaNum4)
        param_name = f'encoded{class_name[3:]}'  # Remove 'Xdr' prefix
        lines.append(f'{self.indent}static void encode(')
        lines.append(f'{self.indent * 3}XdrDataOutputStream stream, {class_name} {param_name}) {{')
        for field in struct.fields:
            encode_stmt = self._generate_field_encode(field, param_name)
            lines.append(f'{self.indent * 2}{encode_stmt}')
        lines.append(f'{self.indent}}}')
        lines.append('')

        # Generate decode method
        lines.append(f'{self.indent}static {class_name} decode(XdrDataInputStream stream) {{')

        # Check if this is a simple or complex struct
        has_complex_fields = any(
            (field.is_array() and field.type_name != 'opaque') or field.is_optional
            for field in struct.fields
        )

        if not has_complex_fields and len(struct.fields) <= 2:
            # Simple struct - only declare size vars if needed, inline decode in constructor
            decoded_name = f'decoded{class_name[3:]}'  # Remove 'Xdr' prefix

            # Declare size variables for fixed opaque arrays
            for field in struct.fields:
                if field.type_name == 'opaque' and field.is_fixed_array:
                    size = field.array_size or 0
                    lines.append(f'{self.indent * 2}int {field.name}size = {size};')

            # Build inline decode expressions
            inline_params = []
            for field in struct.fields:
                if field.type_name == 'opaque' and field.is_fixed_array:
                    inline_params.append(f'stream.readBytes({field.name}size)')
                else:
                    inline_params.append(self._generate_field_decode(field))

            lines.append(f'{self.indent * 2}{class_name} {decoded_name} = {class_name}(')
            lines.append(f'{self.indent * 4}{", ".join(inline_params)});')
            lines.append(f'{self.indent * 2}return {decoded_name};')
        else:
            # Complex struct - decode each field to intermediate variables
            decode_vars = []

            for field in struct.fields:
                dart_type = self._get_dart_type(field)
                var_name = f'x{field.name[0].upper()}{field.name[1:]}'  # xFieldName

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
                        lines.append(f'{self.indent * 2}int {field.name}size = {size};')
                        decode_stmt = f'stream.readBytes({field.name}size)'
                    else:
                        decode_stmt = self._generate_field_decode(field)

                    lines.append(f'{self.indent * 2}{dart_type} {var_name} = {decode_stmt};')

                decode_vars.append(var_name)

            # Return with intermediate variables
            decoded_name = f'decoded{class_name[3:]}'
            return_params = ', '.join(decode_vars)
            lines.append(f'{self.indent * 2}{class_name} {decoded_name} = {class_name}({return_params});')
            lines.append(f'{self.indent * 2}return {decoded_name};')

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

        # Check if discriminant is int or enum type
        is_int_discriminant = union.discriminant_type.lower() in ['int', 'integer']
        if is_int_discriminant:
            discriminant_type = 'int'
        else:
            discriminant_type = self.type_mapper.get_dart_class_name(union.discriminant_type)

        lines = []
        lines.append(f'class {class_name} {{')
        # Constructor on next line after class declaration
        lines.append(f'{self.indent}{class_name}(this._{union.discriminant_name});')

        # Discriminant field
        lines.append(f'{self.indent}{discriminant_type} _{union.discriminant_name};')
        lines.append(f'{self.indent}{discriminant_type} get discriminant => this._{union.discriminant_name};')
        lines.append(f'{self.indent}set discriminant({discriminant_type} value) => this._{union.discriminant_name} = value;')
        lines.append('')

        # Collect all unique variant fields (all are nullable)
        variant_fields: Dict[str, XdrField] = {}
        for case in union.cases:
            if case.field and not case.field.name == 'void':
                if case.field.name not in variant_fields:
                    variant_fields[case.field.name] = case.field

        # Generate variant field declarations (all nullable)
        for field_name, field in variant_fields.items():
            field_decls = self._generate_field_declaration(field, force_nullable=True)
            for decl in field_decls:
                lines.append(f'{self.indent}{decl}')
            if field_name != list(variant_fields.keys())[-1]:
                lines.append('')

        if variant_fields:
            lines.append('')

        # Generate encode method
        # Use camelCase version for parameter (e.g., encodedMemo)
        param_name = f'encoded{class_name[3:]}'  # Remove 'Xdr' prefix
        lines.append(f'{self.indent}static void encode(XdrDataOutputStream stream, {class_name} {param_name}) {{')

        # Write discriminant - different for int vs enum
        if is_int_discriminant:
            lines.append(f'{self.indent * 2}stream.writeInt({param_name}.discriminant);')
        else:
            lines.append(f'{self.indent * 2}stream.writeInt({param_name}.discriminant.value);')

        lines.append(f'{self.indent * 2}switch ({param_name}.discriminant) {{')

        for case in union.cases:
            # Generate case labels
            for case_value in case.case_values:
                if is_int_discriminant:
                    # Use raw int values
                    lines.append(f'{self.indent * 3}case {case_value}:')
                else:
                    # Use enum constants
                    lines.append(f'{self.indent * 3}case {discriminant_type}.{case_value}:')

            # Generate case body
            if case.field and case.field.type_name != 'void':
                encode_stmt = self._generate_field_encode(case.field, param_name, force_non_null=True)
                lines.append(f'{self.indent * 4}{encode_stmt}')
                lines.append(f'{self.indent * 4}break;')
            else:
                # Void case - no encoding
                lines.append(f'{self.indent * 4}break;')

        # Add default case for robustness
        lines.append(f'{self.indent * 3}default:')
        lines.append(f'{self.indent * 4}break;')

        lines.append(f'{self.indent * 2}}}')
        lines.append(f'{self.indent}}}')
        lines.append('')

        # Generate decode method
        decoded_name = f'decoded{class_name[3:]}'  # Remove 'Xdr' prefix
        lines.append(f'{self.indent}static {class_name} decode(XdrDataInputStream stream) {{')

        # Decode discriminant - different for int vs enum
        if is_int_discriminant:
            lines.append(f'{self.indent * 2}int discriminant = stream.readInt();')
            lines.append(f'{self.indent * 2}{class_name} {decoded_name} = {class_name}(discriminant);')
        else:
            lines.append(f'{self.indent * 2}{class_name} {decoded_name} = {class_name}({discriminant_type}.decode(stream));')

        lines.append(f'{self.indent * 2}switch ({decoded_name}.discriminant) {{')

        for case in union.cases:
            # Generate case labels
            for case_value in case.case_values:
                if is_int_discriminant:
                    # Use raw int values
                    lines.append(f'{self.indent * 3}case {case_value}:')
                else:
                    # Use enum constants
                    lines.append(f'{self.indent * 3}case {discriminant_type}.{case_value}:')

            # Generate case body
            if case.field and case.field.type_name != 'void':
                decode_stmt = self._generate_field_decode(case.field)
                lines.append(f'{self.indent * 4}{decoded_name}.{case.field.name} = {decode_stmt};')
                lines.append(f'{self.indent * 4}break;')
            else:
                # Void case - no decoding
                lines.append(f'{self.indent * 4}break;')

        # Add default case for robustness
        lines.append(f'{self.indent * 3}default:')
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
        # Most typedefs are handled by type_mapping.py
        # Only generate wrappers for special cases that aren't already defined

        # Check if this is a special wrapper type
        if typedef.name in self.type_mapper.SPECIAL_WRAPPERS:
            # These are manually implemented in xdr_type.dart
            return ''

        # Check if this is a typedef alias
        if typedef.name in self.type_mapper.TYPEDEF_ALIASES:
            # These are just type aliases, no wrapper class needed
            return ''

        # For other typedefs, we might not need to generate anything
        # as they're typically handled by existing types
        return ''

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

        # Union variant fields are always nullable
        if force_nullable and not dart_type.endswith('?'):
            dart_type += '?'

        lines = []
        lines.append(f'{dart_type} _{field.name};')
        lines.append(f'{dart_type} get {field.name} => this._{field.name};')
        lines.append(f'set {field.name}({dart_type} value) => this._{field.name} = value;')

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
        field_access = f'{obj_name}.{field.name}'
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
                lines.append(f'int {field.name}Size = {field_access}.length;')
                lines.append(f'{self.indent * 2}stream.writeInt({field.name}Size);')
                lines.append(f'{self.indent * 2}stream.write({field_access});')
                return '\n'.join(lines)

        # Handle non-opaque arrays (typed arrays)
        if field.is_array():
            return self._generate_array_encode(field, obj_name)

        # Handle primitive types that need direct stream writes
        if field.type_name in ['string', 'String']:
            # Apply non-null assertion if needed (for union variants)
            if force_non_null and not field_access.endswith('!'):
                field_access += '!'
            return f'stream.writeString({field_access});'

        # Handle wrapper types and custom types
        dart_type = self.type_mapper.map_type(field.type_name)
        return f'{dart_type}.encode(stream, {field_access});'

    def _generate_field_decode(self, field: XdrField) -> str:
        """Generate decode statement for a field.

        Args:
            field: XdrField node

        Returns:
            Decode expression (right-hand side only)
        """
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

        # Handle wrapper types and custom types
        dart_type = self.type_mapper.map_type(field.type_name)
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
        lines = []

        # Check if elements are optional
        has_optional_elements = hasattr(field, 'optional_elements') and field.optional_elements

        # Read size (for variable arrays)
        if field.is_variable_array:
            lines.append(f'int {field.name}Size = stream.readInt();')
            size_var = f'{field.name}Size'
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
            presence_var = f'{field.name[0]}{field.name[1:].capitalize()}Present' if len(field.name) > 1 else f'{field.name}Present'
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
        lines = []

        # Declare nullable variable
        lines.append(f'{dart_type} {var_name};')

        # Check presence indicator
        lines.append(f'int {field.name}Present = stream.readInt();')
        lines.append(f'if ({field.name}Present != 0) {{')

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
        field_access = f'{obj_name}.{field.name}'
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
        field_access = f'{obj_name}.{field.name}'
        element_type = self.type_mapper.map_type(field.type_name)

        lines = []

        # Check if elements are optional
        has_optional_elements = hasattr(field, 'optional_elements') and field.optional_elements

        # Variable arrays need length prefix
        if field.is_variable_array:
            lines.append(f'int {field.name}Size = {field_access}.length;')
            lines.append(f'{self.indent * 2}stream.writeInt({field.name}Size);')
            lines.append(f'{self.indent * 2}for (int i = 0; i < {field.name}Size; i++) {{')
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
                        used_types: Set[str]) -> List[str]:
        """Generate import statements for a file.

        Args:
            filename: Target filename (e.g., 'xdr_memo.dart')
            used_types: Set of Dart class names used in this file

        Returns:
            List of import statements
        """
        imports = []

        # Always include core imports
        imports.append("import 'dart:typed_data';")
        imports.append("import 'xdr_data_io.dart';")

        # Determine which other XDR files are needed
        needed_files = set()
        for type_name in used_types:
            target_file = self.file_mapper.get_target_file(type_name)
            if target_file and target_file != filename:
                needed_files.add(target_file)

        # Add imports for needed files
        for file in sorted(needed_files):
            imports.append(f"import '{file}';")

        return imports

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

        # Add imports
        imports = self.generate_imports(filename, used_types)
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
