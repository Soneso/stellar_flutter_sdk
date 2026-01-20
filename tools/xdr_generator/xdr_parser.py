"""
XDR Parser

Parses XDR token stream into an Abstract Syntax Tree (AST).

Implements a recursive descent parser for XDR syntax, handling:
- Type definitions (typedef)
- Enumerations (enum)
- Structures (struct)
- Discriminated unions (union)
- Constants (const)
- Namespaces

Grammar handled:
    file          := namespace? definition*
    definition    := const | typedef | enum | struct | union
    const         := 'const' IDENTIFIER '=' NUMBER ';'
    typedef       := 'typedef' type_spec IDENTIFIER ';'
    enum          := 'enum' IDENTIFIER '{' enum_value (',' enum_value)* '}' ';'
    struct        := 'struct' IDENTIFIER '{' field* '}' ';'
    union         := 'union' IDENTIFIER 'switch' '(' type IDENTIFIER ')' '{' case* '}' ';'
"""

from typing import List, Optional
from .xdr_lexer import Token
from .xdr_ast import (
    XdrFile, XdrConstant, XdrTypedef, XdrEnum, XdrEnumValue,
    XdrStruct, XdrUnion, XdrField, XdrUnionCase
)


class XdrParseError(Exception):
    """Raised when parser encounters invalid syntax."""
    pass


class XdrParser:
    """
    Recursive descent parser for XDR syntax.

    Converts a token stream into an Abstract Syntax Tree.
    """

    def __init__(self, tokens: List[Token], filename: str = "<unknown>"):
        """
        Initialize parser with token stream.

        Args:
            tokens: List of tokens from lexer
            filename: Source filename (for error reporting)
        """
        self.tokens = tokens
        self.filename = filename
        self.pos = 0
        self.current_file: Optional[XdrFile] = None  # Reference to file being built

    def parse(self) -> XdrFile:
        """
        Parse the entire token stream into an XDR file AST.

        Returns:
            XdrFile containing all parsed definitions

        Raises:
            XdrParseError: If syntax errors are encountered
        """
        xdr_file = XdrFile(filename=self.filename)
        self.current_file = xdr_file  # Store reference for inline struct registration

        # Parse optional namespace
        if self._check_keyword('namespace'):
            xdr_file.namespace = self._parse_namespace()

        # Parse definitions until EOF
        while not self._at_end():
            # Skip any standalone semicolons
            if self._check_symbol(';'):
                self._advance()
                continue

            if self._check_keyword('const'):
                xdr_file.constants.append(self._parse_const())
            elif self._check_keyword('typedef'):
                xdr_file.typedefs.append(self._parse_typedef())
            elif self._check_keyword('enum'):
                xdr_file.enums.append(self._parse_enum())
            elif self._check_keyword('struct'):
                xdr_file.structs.append(self._parse_struct())
            elif self._check_keyword('union'):
                xdr_file.unions.append(self._parse_union())
            elif self._check_symbol('}'):
                # End of namespace
                self._consume_symbol('}')
                if self._check_symbol(';'):
                    self._advance()
                break
            else:
                token = self._current()
                raise XdrParseError(
                    f"{self.filename}:{token.line}:{token.column}: "
                    f"Unexpected token: {token.type} '{token.value}'"
                )

        return xdr_file

    def _parse_namespace(self) -> str:
        """
        Parse namespace declaration.

        Syntax: namespace IDENTIFIER { ... }
        """
        self._consume_keyword('namespace')
        name = self._consume_identifier()
        self._consume_symbol('{')
        return name

    def _parse_const(self) -> XdrConstant:
        """
        Parse constant definition.

        Syntax: const IDENTIFIER = NUMBER;
        """
        line = self._current().line
        self._consume_keyword('const')
        name = self._consume_identifier()
        self._consume_symbol('=')
        value = self._parse_number()
        self._consume_symbol(';')

        return XdrConstant(name=name, value=value, line=line)

    def _parse_typedef(self) -> XdrTypedef:
        """
        Parse typedef declaration.

        Handles various forms:
        - typedef uint64 TimePoint;
        - typedef opaque Hash[32];
        - typedef opaque Value<>;
        - typedef string string32<32>;
        - typedef AccountID* SponsorshipDescriptor;  (optional pointer)
        """
        line = self._current().line
        self._consume_keyword('typedef')

        # Check for special types
        is_opaque = False
        is_string = False
        underlying_type = ''

        if self._check_keyword('opaque'):
            is_opaque = True
            underlying_type = 'opaque'
            self._advance()
        elif self._check_keyword('string'):
            is_string = True
            underlying_type = 'string'
            self._advance()
        elif self._check_keyword('unsigned'):
            # Handle 'unsigned int' or 'unsigned hyper'
            self._advance()
            if self._check_keyword('int'):
                underlying_type = 'uint32'
                self._advance()
            elif self._check_keyword('hyper'):
                underlying_type = 'uint64'
                self._advance()
            else:
                raise XdrParseError(
                    f"{self.filename}:{self._current().line}: "
                    "Expected 'int' or 'hyper' after 'unsigned'"
                )
        elif self._check_keyword('int'):
            underlying_type = 'int32'
            self._advance()
        elif self._check_keyword('hyper'):
            underlying_type = 'int64'
            self._advance()
        else:
            # Regular type reference
            underlying_type = self._consume_identifier()

        # Check for optional pointer (*)
        is_optional = False
        if self._check_symbol('*'):
            is_optional = True
            self._advance()

        # Get the new type name
        name = self._consume_identifier()

        # Check for array/size specifiers
        size = None
        size_ref = None
        is_variable = False
        is_fixed = False

        if self._check_symbol('['):
            # Fixed array: [N]
            is_fixed = True
            self._advance()
            if self._current().type == 'NUMBER':
                size = self._parse_number()
            else:
                size_ref = self._consume_identifier()
            self._consume_symbol(']')
        elif self._check_symbol('<'):
            # Variable array: <N> or <>
            is_variable = True
            self._advance()
            if not self._check_symbol('>'):
                if self._current().type == 'NUMBER':
                    size = self._parse_number()
                else:
                    size_ref = self._consume_identifier()
            self._consume_symbol('>')

        self._consume_symbol(';')

        # If optional pointer, encode it in the type name
        if is_optional:
            underlying_type = f"{underlying_type}*"

        return XdrTypedef(
            name=name,
            underlying_type=underlying_type,
            is_opaque=is_opaque,
            is_string=is_string,
            size=size,
            size_ref=size_ref,
            is_variable=is_variable,
            is_fixed=is_fixed,
            line=line
        )

    def _parse_enum(self) -> XdrEnum:
        """
        Parse enum definition.

        Syntax:
            enum MemoType {
                MEMO_NONE = 0,
                MEMO_TEXT = 1
            };

        Also handles enum values that reference other constants:
            enum PublicKeyType {
                PUBLIC_KEY_TYPE_ED25519 = KEY_TYPE_ED25519
            };
        """
        line = self._current().line
        self._consume_keyword('enum')
        name = self._consume_identifier()
        self._consume_symbol('{')

        values = []
        while not self._check_symbol('}'):
            value_line = self._current().line
            value_name = self._consume_identifier()
            self._consume_symbol('=')

            # Value can be a number or a reference to another constant
            value_int = None
            value_ref = None
            if self._current().type == 'NUMBER':
                value_int = self._parse_number()
            else:
                # Reference to another enum/const - store reference name
                value_ref = self._consume_identifier()

            values.append(XdrEnumValue(
                name=value_name,
                value=value_int,
                value_ref=value_ref,
                line=value_line
            ))

            # Comma is optional before }
            if self._check_symbol(','):
                self._advance()

        self._consume_symbol('}')
        self._consume_symbol(';')

        return XdrEnum(name=name, values=values, line=line)

    def _parse_struct(self) -> XdrStruct:
        """
        Parse struct definition.

        Syntax:
            struct AssetAlphaNum4 {
                AssetCode4 assetCode;
                AccountID issuer;
            };
        """
        line = self._current().line
        self._consume_keyword('struct')
        name = self._consume_identifier()
        self._consume_symbol('{')

        fields = []
        while not self._check_symbol('}'):
            fields.append(self._parse_field(parent_struct_name=name))

        self._consume_symbol('}')
        self._consume_symbol(';')

        return XdrStruct(name=name, fields=fields, line=line)

    def _parse_union(self) -> XdrUnion:
        """
        Parse union definition.

        Syntax:
            union Asset switch (AssetType type) {
            case ASSET_TYPE_NATIVE:
                void;
            case ASSET_TYPE_CREDIT_ALPHANUM4:
                AssetAlphaNum4 alphaNum4;
            default:
                void;
            };

        Also handles anonymous unions:
            union switch (int v) { ... }
        """
        line = self._current().line
        self._consume_keyword('union')

        # Check if this is a named or anonymous union
        name = ""
        if self._current().type == 'IDENTIFIER':
            name = self._consume_identifier()

        self._consume_keyword('switch')
        self._consume_symbol('(')

        # Parse discriminant type (can be 'int' keyword or identifier)
        if self._check_keyword('int'):
            discriminant_type = 'int'
            self._advance()
        else:
            discriminant_type = self._consume_identifier()

        discriminant_name = self._consume_identifier()

        self._consume_symbol(')')
        self._consume_symbol('{')

        # Parse cases
        cases = []
        while not self._check_symbol('}'):
            cases.append(self._parse_union_case(parent_union_name=name))

        self._consume_symbol('}')
        self._consume_symbol(';')

        return XdrUnion(
            name=name,
            discriminant_name=discriminant_name,
            discriminant_type=discriminant_type,
            cases=cases,
            line=line
        )

    def _parse_union_case(self, parent_union_name: Optional[str] = None) -> XdrUnionCase:
        """
        Parse a single union case.

        Handles:
        - case VALUE: field;
        - case VALUE1: case VALUE2: field;  (multiple cases)
        - default: field;
        - case VALUE: void;

        Args:
            parent_union_name: Name of parent union (for anonymous union naming in cases)
        """
        case_line = self._current().line
        case_values = []
        is_default = False

        # Collect all case labels
        while self._check_keyword('case') or self._check_keyword('default'):
            if self._check_keyword('default'):
                self._advance()
                self._consume_symbol(':')
                is_default = True
                case_values.append('default')
            else:
                self._consume_keyword('case')
                # Case value can be identifier or number (for int discriminant)
                if self._current().type == 'NUMBER':
                    case_values.append(str(self._parse_number()))
                else:
                    case_values.append(self._consume_identifier())
                self._consume_symbol(':')

        # Parse field (or void)
        field = None
        if self._check_keyword('void'):
            self._advance()
            self._consume_symbol(';')
        elif self._check_keyword('struct'):
            # Inline struct definition in union case
            field = self._parse_inline_struct_field(parent_union_name=parent_union_name)
        else:
            field = self._parse_field(parent_struct_name=parent_union_name)

        return XdrUnionCase(
            case_values=case_values,
            field=field,
            is_default=is_default,
            line=case_line
        )

    def _parse_inline_struct_field(self, parent_union_name: Optional[str] = None) -> XdrField:
        """
        Parse inline struct definition within union case.

        Syntax:
            struct {
                uint256 ed25519;
                opaque payload<64>;
            } fieldName;

        Args:
            parent_union_name: Name of parent union (for proper struct naming)
        """
        line = self._current().line
        self._consume_keyword('struct')
        self._consume_symbol('{')

        # We need to peek ahead to get the field name to compute the struct name
        # before parsing fields, so nested structures get proper parent context.
        # Save current position to peek ahead
        saved_pos = self.pos

        # Skip to closing brace to find field name
        brace_count = 1
        while brace_count > 0 and not self._at_end():
            if self._check_symbol('{'):
                brace_count += 1
            elif self._check_symbol('}'):
                brace_count -= 1
            self._advance()

        # Now we're after the '}', get the field name
        field_name = self._consume_identifier()

        # Restore position to parse fields
        self.pos = saved_pos

        # Generate proper struct name BEFORE parsing fields
        # Format: {ParentUnionName}{FieldNamePascalCase}
        # Example: SCEnvMetaEntry + interfaceVersion -> SCEnvMetaEntryInterfaceVersion
        if parent_union_name:
            # Capitalize first letter of field name for PascalCase
            field_name_pascal = field_name[0].upper() + field_name[1:] if field_name else field_name
            struct_name = f'{parent_union_name}{field_name_pascal}'
        else:
            # Fallback to old naming if no parent union name
            struct_name = f'__anon_struct_{field_name}'

        # Note: Inline struct aliasing is applied later by the TypeMapper
        # to share identical structs across different unions

        # Parse struct fields with proper parent context
        inline_fields = []
        while not self._check_symbol('}'):
            inline_fields.append(self._parse_field(parent_struct_name=struct_name))

        self._consume_symbol('}')
        # Consume field name again (we already peeked it)
        self._consume_identifier()
        self._consume_symbol(';')

        # Create synthetic struct for the inline struct
        synthetic_struct = XdrStruct(
            name=struct_name,
            fields=inline_fields,
            line=line
        )

        # Register the synthetic struct so it's available for code generation
        self._register_inline_struct(synthetic_struct)

        # Return field with proper type_name and inline_struct reference
        return XdrField(
            name=field_name,
            type_name=struct_name,
            inline_fields=inline_fields,  # Keep for backward compatibility
            inline_struct=synthetic_struct,
            line=line
        )

    def _parse_field(self, parent_struct_name: Optional[str] = None) -> XdrField:
        """
        Parse a struct field or union case field.

        Handles:
        - TypeName fieldName;
        - TypeName* fieldName;  (optional)
        - TypeName fieldName[N];  (fixed array)
        - TypeName fieldName<N>;  (variable array)
        - TypeName fieldName<>;  (unbounded array)
        - union switch (Type v) { cases } fieldName;  (anonymous union)

        Args:
            parent_struct_name: Name of parent struct (for anonymous union naming)
        """
        line = self._current().line

        # Check for anonymous union
        if self._check_keyword('union'):
            return self._parse_anonymous_union_field(parent_struct_name=parent_struct_name)

        # Parse type (handling primitive types)
        type_name = self._parse_type()

        # Check for optional marker (*)
        is_optional = False
        if self._check_symbol('*'):
            is_optional = True
            self._advance()

        # Parse field name
        field_name = self._consume_identifier()

        # Check for array specifiers
        is_fixed_array = False
        is_variable_array = False
        array_size = None
        array_size_ref = None
        max_length = None

        if self._check_symbol('['):
            # Fixed array
            is_fixed_array = True
            self._advance()
            if self._current().type == 'NUMBER':
                array_size = self._parse_number()
            else:
                array_size_ref = self._consume_identifier()
            self._consume_symbol(']')
        elif self._check_symbol('<'):
            # Variable array or string<N>
            self._advance()
            size = None
            if not self._check_symbol('>'):
                if self._current().type == 'NUMBER':
                    size = self._parse_number()
                else:
                    size_ref = self._consume_identifier()
                    # For const references, we'll treat it same as size
                    array_size_ref = size_ref
            self._consume_symbol('>')

            # Special handling for string<N> - it's NOT an array
            if type_name == 'string':
                max_length = size
                is_variable_array = False
                is_fixed_array = False
            else:
                array_size = size
                is_variable_array = True

        self._consume_symbol(';')

        return XdrField(
            name=field_name,
            type_name=type_name,
            is_optional=is_optional,
            is_variable_array=is_variable_array,
            is_fixed_array=is_fixed_array,
            array_size=array_size,
            array_size_ref=array_size_ref,
            max_length=max_length,
            line=line
        )

    def _parse_anonymous_union_field(self, parent_struct_name: Optional[str] = None) -> XdrField:
        """
        Parse anonymous union as a struct field.

        Syntax:
            union switch (Type v) {
            case X:
                FieldType field;
            }
            fieldName;

        Args:
            parent_struct_name: Name of parent struct (for proper union naming)
        """
        line = self._current().line
        self._consume_keyword('union')
        self._consume_keyword('switch')
        self._consume_symbol('(')

        # Parse discriminant type
        if self._check_keyword('int'):
            discriminant_type = 'int'
            self._advance()
        else:
            discriminant_type = self._consume_identifier()

        discriminant_name = self._consume_identifier()
        self._consume_symbol(')')
        self._consume_symbol('{')

        # We need to peek ahead to get the field name to compute the union name
        # before parsing cases, so nested structures get proper parent context.
        # Save current position to peek ahead
        saved_pos = self.pos

        # Skip to closing brace to find field name
        brace_count = 1
        while brace_count > 0 and not self._at_end():
            if self._check_symbol('{'):
                brace_count += 1
            elif self._check_symbol('}'):
                brace_count -= 1
            self._advance()

        # Now we're after the '}', get the field name
        field_name = self._consume_identifier()

        # Restore position to parse cases
        self.pos = saved_pos

        # Generate proper union name BEFORE parsing cases
        # Format: {ParentStructName}{FieldNamePascalCase}
        # Example: SorobanTransactionData + ext -> SorobanTransactionDataExt
        if parent_struct_name:
            # Capitalize first letter of field name for PascalCase
            field_name_pascal = field_name[0].upper() + field_name[1:] if field_name else field_name
            union_name = f'{parent_struct_name}{field_name_pascal}'
        else:
            # Fallback to old naming if no parent struct name
            union_name = f'__anon_union_{field_name}'

        # Parse cases with proper parent context
        cases = []
        while not self._check_symbol('}'):
            cases.append(self._parse_union_case(parent_union_name=union_name))

        self._consume_symbol('}')

        # Consume field name again (we already peeked it)
        self._consume_identifier()
        self._consume_symbol(';')

        # Create synthetic union for the anonymous union
        synthetic_union = XdrUnion(
            name=union_name,
            discriminant_name=discriminant_name,
            discriminant_type=discriminant_type,
            cases=cases,
            line=line
        )

        # Register the synthetic union for code generation
        self._register_inline_union(synthetic_union)

        # Return field with inline_union preserved
        # Use the union name as the type_name instead of the discriminant type
        return XdrField(
            name=field_name,
            type_name=union_name,
            inline_union=synthetic_union,
            line=line
        )

    def _register_inline_union(self, union: XdrUnion) -> None:
        """
        Register an inline union as a top-level union in the current file.

        Inline unions are synthetic unions created for anonymous union definitions
        in struct fields. They need to be registered so they're available for code
        generation.

        Args:
            union: The synthetic union to register
        """
        if self.current_file is not None:
            self.current_file.unions.append(union)

    def _register_inline_struct(self, struct: XdrStruct) -> None:
        """
        Register an inline struct as a top-level struct in the current file.

        Inline structs are synthetic structs created for inline struct definitions
        in union cases. They need to be registered so they're available for code
        generation.

        Args:
            struct: The synthetic struct to register
        """
        if self.current_file is not None:
            self.current_file.structs.append(struct)

    def _parse_type(self) -> str:
        """
        Parse a type reference.

        Handles:
        - Simple identifiers (TypeName)
        - Primitive types (int, unsigned hyper, etc.)
        - opaque, string, bool
        """
        if self._check_keyword('unsigned'):
            self._advance()
            if self._check_keyword('int'):
                self._advance()
                return 'uint32'
            elif self._check_keyword('hyper'):
                self._advance()
                return 'uint64'
            else:
                raise XdrParseError(
                    f"{self.filename}:{self._current().line}: "
                    "Expected 'int' or 'hyper' after 'unsigned'"
                )
        elif self._check_keyword('int'):
            self._advance()
            return 'int32'
        elif self._check_keyword('hyper'):
            self._advance()
            return 'int64'
        elif self._check_keyword('string'):
            self._advance()
            return 'string'
        elif self._check_keyword('opaque'):
            self._advance()
            return 'opaque'
        elif self._check_keyword('bool'):
            self._advance()
            return 'bool'
        else:
            return self._consume_identifier()

    def _parse_number(self) -> int:
        """
        Parse numeric literal (decimal or hexadecimal).

        Returns:
            Integer value
        """
        token = self._current()
        if token.type != 'NUMBER':
            raise XdrParseError(
                f"{self.filename}:{token.line}:{token.column}: "
                f"Expected number, got {token.type}"
            )

        self._advance()

        # Parse hex or decimal
        value_str = token.value
        if value_str.startswith('0x') or value_str.startswith('0X'):
            return int(value_str, 16)
        else:
            return int(value_str)

    # Helper methods for token navigation

    def _current(self) -> Token:
        """Get current token."""
        if self.pos < len(self.tokens):
            return self.tokens[self.pos]
        # Return EOF token
        return self.tokens[-1]

    def _advance(self) -> Token:
        """Consume and return current token."""
        token = self._current()
        if self.pos < len(self.tokens) - 1:
            self.pos += 1
        return token

    def _at_end(self) -> bool:
        """Check if at end of token stream."""
        return self._current().type == 'EOF'

    def _check_keyword(self, keyword: str) -> bool:
        """Check if current token is a specific keyword."""
        token = self._current()
        return token.type == 'KEYWORD' and token.value == keyword

    def _check_symbol(self, symbol: str) -> bool:
        """Check if current token is a specific symbol."""
        token = self._current()
        return token.type == 'SYMBOL' and token.value == symbol

    def _consume_keyword(self, keyword: str) -> str:
        """Consume and return a specific keyword, or raise error."""
        token = self._current()
        if token.type != 'KEYWORD' or token.value != keyword:
            raise XdrParseError(
                f"{self.filename}:{token.line}:{token.column}: "
                f"Expected keyword '{keyword}', got {token.type} '{token.value}'"
            )
        self._advance()
        return keyword

    def _consume_symbol(self, symbol: str) -> str:
        """Consume and return a specific symbol, or raise error."""
        token = self._current()
        if token.type != 'SYMBOL' or token.value != symbol:
            raise XdrParseError(
                f"{self.filename}:{token.line}:{token.column}: "
                f"Expected symbol '{symbol}', got {token.type} '{token.value}'"
            )
        self._advance()
        return symbol

    def _consume_identifier(self) -> str:
        """Consume and return an identifier, or raise error."""
        token = self._current()
        if token.type != 'IDENTIFIER':
            raise XdrParseError(
                f"{self.filename}:{token.line}:{token.column}: "
                f"Expected identifier, got {token.type} '{token.value}'"
            )
        self._advance()
        return token.value


def parse_xdr_content(content: str, filename: str) -> XdrFile:
    """
    Parse XDR content into an AST.

    Args:
        content: XDR source code
        filename: Source filename (for error reporting)

    Returns:
        XdrFile AST

    Raises:
        XdrParseError: If syntax errors are encountered
    """
    from xdr_lexer import tokenize_xdr

    tokens = tokenize_xdr(content, filename)
    parser = XdrParser(tokens, filename)
    return parser.parse()


def parse_xdr_files(files: dict[str, str]) -> dict[str, XdrFile]:
    """
    Parse multiple XDR files.

    Args:
        files: Dictionary mapping filename to content

    Returns:
        Dictionary mapping filename to XdrFile AST
    """
    return {
        name: parse_xdr_content(content, name)
        for name, content in files.items()
    }
