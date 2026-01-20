"""
XDR Abstract Syntax Tree Node Definitions

Defines the AST structure for parsed XDR files.
Uses dataclasses for clean, immutable node representations.

These nodes represent the complete structure of XDR type definitions
as they appear in the stellar-xdr repository.
"""

from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class XdrConstant:
    """
    Represents a constant definition.

    Example XDR:
        const MAX_SIGNERS = 20;
    """
    name: str
    value: int
    line: int = 0  # Source line number for error reporting


@dataclass
class XdrEnumValue:
    """
    Represents a single value in an enum definition.

    Example XDR:
        MEMO_NONE = 0
        PUBLIC_KEY_TYPE_ED25519 = KEY_TYPE_ED25519  # value_ref case
    """
    name: str
    value: Optional[int] = None  # None if needs resolution
    value_ref: Optional[str] = None  # Reference to another constant/enum
    line: int = 0


@dataclass
class XdrEnum:
    """
    Represents an enum type definition.

    Example XDR:
        enum MemoType {
            MEMO_NONE = 0,
            MEMO_TEXT = 1
        };
    """
    name: str
    values: List[XdrEnumValue]
    line: int = 0


@dataclass
class XdrField:
    """
    Represents a field in a struct or union case.

    Handles all XDR field variations:
    - Simple: TypeName fieldName;
    - Optional: TypeName* fieldName;
    - Fixed array: TypeName fieldName[N];
    - Variable array: TypeName fieldName<N>;
    - Unbounded array: TypeName fieldName<>;
    - Inline struct: struct { ... } fieldName;
    - Anonymous union: union switch (Type v) { ... } fieldName;
    """
    name: str
    type_name: str
    is_optional: bool = False           # TypeName* (nullable)
    is_variable_array: bool = False     # TypeName<N>
    is_fixed_array: bool = False        # TypeName[N]
    array_size: Optional[int] = None    # Size if specified as integer
    array_size_ref: Optional[str] = None  # Size if specified as const reference
    max_length: Optional[int] = None    # Max length for string<N>
    inline_fields: Optional[List['XdrField']] = None  # For inline struct definitions
    inline_union: Optional['XdrUnion'] = None  # For anonymous union definitions
    inline_struct: Optional['XdrStruct'] = None  # For inline struct definitions (synthetic struct)
    line: int = 0

    def is_array(self) -> bool:
        """Check if field is any type of array (excludes string<N>)."""
        if self.type_name == 'string':
            return False  # string<N> is NOT an array
        return self.is_variable_array or self.is_fixed_array

    def is_unbounded_array(self) -> bool:
        """Check if field is unbounded array (no size specified)."""
        return self.is_variable_array and self.array_size is None and self.array_size_ref is None


@dataclass
class XdrStruct:
    """
    Represents a struct type definition.

    Example XDR:
        struct AssetAlphaNum4 {
            AssetCode4 assetCode;
            AccountID issuer;
        };
    """
    name: str
    fields: List[XdrField]
    line: int = 0


@dataclass
class XdrUnionCase:
    """
    Represents a single case in a union definition.

    Handles:
    - Single case: case VALUE: field;
    - Multiple cases: case VALUE1: case VALUE2: field;
    - Default case: default: field;
    - Void case: case VALUE: void;
    """
    case_values: List[str]  # Can have multiple case labels for same arm
    field: Optional[XdrField]  # None for void cases
    is_default: bool = False
    line: int = 0


@dataclass
class XdrUnion:
    """
    Represents a union (discriminated union) type definition.

    Example XDR:
        union Asset switch (AssetType type) {
        case ASSET_TYPE_NATIVE:
            void;
        case ASSET_TYPE_CREDIT_ALPHANUM4:
            AssetAlphaNum4 alphaNum4;
        };

    The discriminant can be any enum type or 'int'.
    """
    name: str
    discriminant_name: str  # Parameter name (e.g., 'type')
    discriminant_type: str  # Type name (e.g., 'AssetType' or 'int')
    cases: List[XdrUnionCase]
    line: int = 0


@dataclass
class XdrTypedef:
    """
    Represents a typedef declaration.

    Handles various typedef forms:
    - Simple: typedef uint64 TimePoint;
    - Fixed opaque: typedef opaque Hash[32];
    - Variable opaque: typedef opaque Value<>;
    - String: typedef string string32<32>;
    """
    name: str
    underlying_type: str
    is_opaque: bool = False  # opaque type
    is_string: bool = False  # string type
    size: Optional[int] = None  # Size for arrays/strings
    size_ref: Optional[str] = None  # Size reference to constant
    is_variable: bool = False  # <> vs []
    is_fixed: bool = False  # [] vs <>
    line: int = 0


@dataclass
class XdrNamespace:
    """
    Represents a namespace declaration.

    Example XDR:
        namespace stellar {
            // definitions
        }
    """
    name: str
    line: int = 0


@dataclass
class XdrFile:
    """
    Represents a complete parsed XDR file.

    Contains all top-level definitions found in the file.
    """
    filename: str
    namespace: Optional[str] = None  # Namespace if defined
    constants: List[XdrConstant] = field(default_factory=list)
    typedefs: List[XdrTypedef] = field(default_factory=list)
    enums: List[XdrEnum] = field(default_factory=list)
    structs: List[XdrStruct] = field(default_factory=list)
    unions: List[XdrUnion] = field(default_factory=list)

    def all_type_names(self) -> List[str]:
        """Return all defined type names in this file."""
        names = []
        names.extend([t.name for t in self.typedefs])
        names.extend([e.name for e in self.enums])
        names.extend([s.name for s in self.structs])
        names.extend([u.name for u in self.unions])
        return names

    def count_definitions(self) -> tuple[int, int, int, int, int]:
        """Return (constants, typedefs, enums, structs, unions) counts."""
        return (
            len(self.constants),
            len(self.typedefs),
            len(self.enums),
            len(self.structs),
            len(self.unions)
        )

    def resolve_references(self, all_files: Optional[List['XdrFile']] = None) -> None:
        """
        Resolve all constant and enum value references.

        This method performs a two-phase resolution:
        1. Build a symbol table of all constants and enum values
        2. Resolve all enum values that reference other symbols

        Args:
            all_files: List of all parsed XDR files for cross-file resolution.
                      If None, only resolve within this file.
        """
        # Build symbol table
        symbol_table: dict[str, int] = {}

        # Add constants from this file
        for const in self.constants:
            symbol_table[const.name] = const.value

        # Add enum values from this file
        for enum in self.enums:
            for enum_val in enum.values:
                if enum_val.value is not None:
                    symbol_table[enum_val.name] = enum_val.value

        # Add symbols from other files if provided
        if all_files:
            for xdr_file in all_files:
                if xdr_file is self:
                    continue
                for const in xdr_file.constants:
                    symbol_table[const.name] = const.value
                for enum in xdr_file.enums:
                    for enum_val in enum.values:
                        if enum_val.value is not None:
                            symbol_table[enum_val.name] = enum_val.value

        # Resolve enum value references
        for enum in self.enums:
            for enum_val in enum.values:
                if enum_val.value_ref is not None:
                    # Look up the reference
                    if enum_val.value_ref in symbol_table:
                        enum_val.value = symbol_table[enum_val.value_ref]
                    else:
                        # Leave as None if reference not found (error handling)
                        pass
