"""XDR-to-Dart type mapping system.

Maps XDR types to their corresponding Dart types, handling primitives,
wrappers, and special cases according to the existing SDK patterns.
"""

from typing import Dict, Set, Optional
from dataclasses import dataclass


@dataclass
class TypeInfo:
    """Information about a mapped type."""
    dart_type: str
    is_primitive: bool
    needs_wrapper: bool
    underlying_type: Optional[str] = None
    encode_method: Optional[str] = None
    decode_method: Optional[str] = None


class TypeMapper:
    """Maps XDR types to Dart types."""

    # Class name mappings for types that differ from XDR naming conventions
    CLASS_NAME_MAPPINGS: Dict[str, str] = {
        'TrustLineAsset': 'TrustlineAsset',
        'AlphaNum4': 'AssetAlphaNum4',
        'AlphaNum12': 'AssetAlphaNum12',
    }

    # Primitive type wrappers
    PRIMITIVE_TYPES: Dict[str, TypeInfo] = {
        'int32': TypeInfo(
            dart_type='XdrInt32',
            is_primitive=True,
            needs_wrapper=True,
            underlying_type='int',
            encode_method='stream.writeInt()',
            decode_method='stream.readInt()'
        ),
        'uint32': TypeInfo(
            dart_type='XdrUint32',
            is_primitive=True,
            needs_wrapper=True,
            underlying_type='int',
            encode_method='stream.writeInt()',
            decode_method='stream.readInt()'
        ),
        'int64': TypeInfo(
            dart_type='XdrInt64',
            is_primitive=True,
            needs_wrapper=True,
            underlying_type='BigInt',
            encode_method='stream.writeBigInt64()',
            decode_method='stream.readBigInt64Signed()'
        ),
        'uint64': TypeInfo(
            dart_type='XdrUint64',
            is_primitive=True,
            needs_wrapper=True,
            underlying_type='BigInt',
            encode_method='stream.writeBigInt64()',
            decode_method='stream.readBigInt64()'
        ),
        'bool': TypeInfo(
            dart_type='bool',
            is_primitive=True,
            needs_wrapper=False,
            underlying_type='bool',
            encode_method='stream.writeInt(value ? 1 : 0)',
            decode_method='stream.readInt() != 0'
        ),
        'hyper': TypeInfo(  # hyper is int64
            dart_type='XdrInt64',
            is_primitive=True,
            needs_wrapper=True,
            underlying_type='BigInt',
            encode_method='stream.writeBigInt64()',
            decode_method='stream.readBigInt64Signed()'
        ),
        'unsigned hyper': TypeInfo(  # unsigned hyper is uint64
            dart_type='XdrUint64',
            is_primitive=True,
            needs_wrapper=True,
            underlying_type='BigInt',
            encode_method='stream.writeBigInt64()',
            decode_method='stream.readBigInt64()'
        ),
    }

    # Special wrapper types for named opaques and typedefs
    SPECIAL_WRAPPERS: Dict[str, str] = {
        'Hash': 'XdrHash',
        'uint256': 'XdrUint256',
        'Curve25519Public': 'XdrCurve25519Public',
        'Curve25519Secret': 'XdrCurve25519Secret',
        'HmacSha256Key': 'XdrHmacSha256Key',
        'HmacSha256Mac': 'XdrHmacSha256Mac',
        'Thresholds': 'XdrThresholds',
        'Value': 'XdrValue',
        'UpgradeType': 'XdrUpgradeType',
        'String32': 'XdrString32',
        'String64': 'XdrString64',
        'SequenceNumber': 'XdrInt64',   # int64 (signed)
        'TimePoint': 'XdrUint64',       # uint64 (unsigned)
        'Duration': 'XdrUint64',        # uint64 (unsigned)
        'Signature': 'XdrSignature',      # Variable opaque with length prefix
        'SignatureHint': 'XdrSignatureHint',  # Fixed 4-byte array
        'ShortHashSeed': 'XdrShortHashSeed',  # 16-byte opaque struct
    }

    # Typedef aliases that map to existing types
    TYPEDEF_ALIASES: Dict[str, str] = {
        'NodeID': 'XdrPublicKey',
        'AccountID': 'XdrAccountID',
        'PoolID': 'XdrHash',
        'ContractID': 'XdrHash',
    }

    # Raw byte arrays without wrappers (type name -> size in bytes)
    RAW_BYTE_ARRAYS: Dict[str, int] = {
        'AssetCode4': 4,    # 4 bytes, no wrapper
        'AssetCode12': 12,  # 12 bytes, no wrapper
    }

    def __init__(self):
        """Initialize the type mapper."""
        self._custom_type_overrides: Dict[str, str] = {}

    def map_type(self, xdr_type: str, context: Optional[str] = None) -> str:
        """Map XDR type to Dart type.

        Args:
            xdr_type: The XDR type name
            context: Optional context for special handling

        Returns:
            The Dart type name
        """
        # Check custom overrides first
        if xdr_type in self._custom_type_overrides:
            return self._custom_type_overrides[xdr_type]

        # Check typedef aliases
        if xdr_type in self.TYPEDEF_ALIASES:
            return self.TYPEDEF_ALIASES[xdr_type]

        # Check primitive types
        if xdr_type in self.PRIMITIVE_TYPES:
            return self.PRIMITIVE_TYPES[xdr_type].dart_type

        # Check special wrappers
        if xdr_type in self.SPECIAL_WRAPPERS:
            return self.SPECIAL_WRAPPERS[xdr_type]

        # Check raw byte arrays
        if xdr_type in self.RAW_BYTE_ARRAYS:
            return 'Uint8List'

        # Handle opaque types
        if xdr_type == 'opaque':
            return 'Uint8List'

        # Handle string types
        if xdr_type == 'string':
            return 'String'

        # Handle void type
        if xdr_type == 'void':
            return 'void'

        # Default: add Xdr prefix for custom types
        return self.get_dart_class_name(xdr_type)

    def get_dart_class_name(self, xdr_name: str) -> str:
        """Convert XDR name to Dart class name with Xdr prefix.

        Args:
            xdr_name: The XDR type name

        Returns:
            Dart class name (XdrTypeName)
        """
        # Already has Xdr prefix
        if xdr_name.startswith('Xdr'):
            return xdr_name

        # Check if this type has a special class name mapping
        if xdr_name in self.CLASS_NAME_MAPPINGS:
            return f'Xdr{self.CLASS_NAME_MAPPINGS[xdr_name]}'

        # Capitalize first letter and add Xdr prefix
        if xdr_name:
            capitalized = xdr_name[0].upper() + xdr_name[1:]
            return f'Xdr{capitalized}'
        return 'Xdr'

    def is_primitive(self, type_name: str) -> bool:
        """Check if a type is a primitive type.

        Args:
            type_name: The type name to check

        Returns:
            True if the type is primitive
        """
        return type_name in self.PRIMITIVE_TYPES

    def needs_wrapper(self, type_name: str) -> bool:
        """Check if a type needs a wrapper class.

        Args:
            type_name: The type name to check

        Returns:
            True if the type needs a wrapper
        """
        if type_name in self.PRIMITIVE_TYPES:
            return self.PRIMITIVE_TYPES[type_name].needs_wrapper

        return type_name in self.SPECIAL_WRAPPERS

    def get_type_info(self, type_name: str) -> Optional[TypeInfo]:
        """Get detailed information about a type.

        Args:
            type_name: The type name

        Returns:
            TypeInfo if available, None otherwise
        """
        return self.PRIMITIVE_TYPES.get(type_name)

    def add_custom_override(self, xdr_type: str, dart_type: str):
        """Add a custom type mapping override.

        Args:
            xdr_type: The XDR type name
            dart_type: The Dart type to map to
        """
        self._custom_type_overrides[xdr_type] = dart_type

    def map_array_type(self, element_type: str, is_fixed: bool,
                       size: Optional[int] = None) -> str:
        """Map an array type to Dart.

        Args:
            element_type: The XDR element type
            is_fixed: True for fixed-size arrays, False for variable
            size: Optional size for fixed arrays

        Returns:
            Dart array type (List<ElementType>)
        """
        dart_element = self.map_type(element_type)
        return f'List<{dart_element}>'

    def map_optional_type(self, base_type: str) -> str:
        """Map an optional type to Dart nullable.

        Args:
            base_type: The base XDR type

        Returns:
            Dart nullable type (TypeName?)
        """
        dart_type = self.map_type(base_type)
        return f'{dart_type}?'

    def is_special_wrapper(self, type_name: str) -> bool:
        """Check if a type is a special wrapper type.

        Args:
            type_name: The type name to check

        Returns:
            True if it's a special wrapper
        """
        return type_name in self.SPECIAL_WRAPPERS

    def is_raw_byte_array(self, type_name: str) -> bool:
        """Check if a type is a raw byte array without wrapper.

        Args:
            type_name: The type name to check

        Returns:
            True if it's a raw byte array
        """
        return type_name in self.RAW_BYTE_ARRAYS

    def get_raw_byte_array_size(self, type_name: str) -> Optional[int]:
        """Get the size of a raw byte array type.

        Args:
            type_name: The type name to check

        Returns:
            Size in bytes if it's a raw byte array, None otherwise
        """
        return self.RAW_BYTE_ARRAYS.get(type_name)

    def get_value_property(self, type_name: str) -> Optional[str]:
        """Get the property name to access the underlying value of a wrapper type.

        Args:
            type_name: The XDR type name (e.g., 'uint32', 'int64')

        Returns:
            Property name (e.g., 'uint32', 'int64') or None if not a primitive wrapper
        """
        # Map of XDR type to property name
        VALUE_PROPERTIES = {
            'int32': 'int32',
            'uint32': 'uint32',
            'int64': 'int64',
            'uint64': 'uint64',
            'hyper': 'int64',
            'unsigned hyper': 'uint64',
        }
        return VALUE_PROPERTIES.get(type_name)


# Global instance for convenience
_default_mapper: Optional[TypeMapper] = None


def get_type_mapper() -> TypeMapper:
    """Get the default TypeMapper instance.

    Returns:
        The default TypeMapper
    """
    global _default_mapper
    if _default_mapper is None:
        _default_mapper = TypeMapper()
    return _default_mapper
