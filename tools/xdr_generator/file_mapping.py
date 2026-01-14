"""File mapping system for XDR types to Dart output files.

Analyzes existing Dart XDR files to determine which types belong in which files,
and provides inheritance configuration for special cases.
"""

import os
import re
from typing import Dict, List, Set, Tuple, Optional
from pathlib import Path


class FileMapper:
    """Maps XDR types to their target Dart files."""

    # Inheritance configuration for types that extend others
    INHERITANCE_CONFIG: Dict[str, Dict] = {
        'XdrTrustlineAsset': {
            'extends': 'XdrAsset',
            'additional_fields': {
                'ASSET_TYPE_POOL_SHARE': [('poolId', 'XdrHash', True)]
            }
        },
        'XdrChangeTrustAsset': {
            'extends': 'XdrAsset',
            'additional_fields': {
                'ASSET_TYPE_POOL_SHARE': [('liquidityPool', 'XdrLiquidityPoolParameters', True)]
            }
        }
    }

    def __init__(self, xdr_dir: Optional[str] = None):
        """Initialize the file mapper.

        Args:
            xdr_dir: Path to the XDR directory (defaults to lib/src/xdr/)
        """
        self.xdr_dir = xdr_dir
        self.type_to_file: Dict[str, str] = {}
        self.file_to_types: Dict[str, List[str]] = {}
        self._build_type_to_file_map()

    def _build_type_to_file_map(self):
        """Build mapping by analyzing existing Dart files."""
        if not self.xdr_dir:
            # Default path relative to this file
            script_dir = Path(__file__).parent.parent.parent
            self.xdr_dir = str(script_dir / 'lib' / 'src' / 'xdr')

        if not os.path.exists(self.xdr_dir):
            # Cannot build map without directory
            return

        # Pattern to match class declarations
        class_pattern = re.compile(r'^class\s+(Xdr\w+)', re.MULTILINE)

        # Scan all xdr_*.dart files
        for filename in sorted(os.listdir(self.xdr_dir)):
            if not filename.startswith('xdr_') or not filename.endswith('.dart'):
                continue

            # Skip xdr_data_io.dart as it's infrastructure
            if filename == 'xdr_data_io.dart':
                continue

            filepath = os.path.join(self.xdr_dir, filename)

            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Find all class declarations
                classes = class_pattern.findall(content)

                # Map each class to this file
                for class_name in classes:
                    self.type_to_file[class_name] = filename
                    self.file_to_types.setdefault(filename, []).append(class_name)

            except Exception as e:
                # Skip files that can't be read
                print(f"Warning: Could not read {filename}: {e}")
                continue

    def get_target_file(self, dart_class_name: str) -> Optional[str]:
        """Get target file for a Dart class.

        Args:
            dart_class_name: The Dart class name (e.g., 'XdrAsset')

        Returns:
            Filename (e.g., 'xdr_asset.dart') or None if not found
        """
        return self.type_to_file.get(dart_class_name)

    def get_types_for_file(self, filename: str) -> List[str]:
        """Get all types that belong in a file.

        Args:
            filename: The Dart filename (e.g., 'xdr_asset.dart')

        Returns:
            List of Dart class names
        """
        return self.file_to_types.get(filename, [])

    def get_inheritance_config(self, class_name: str) -> Optional[Dict]:
        """Get inheritance configuration for a class.

        Args:
            class_name: The Dart class name

        Returns:
            Inheritance config dict or None
        """
        return self.INHERITANCE_CONFIG.get(class_name)

    def extends_class(self, class_name: str) -> Optional[str]:
        """Get the parent class name if this class extends another.

        Args:
            class_name: The Dart class name

        Returns:
            Parent class name or None
        """
        config = self.get_inheritance_config(class_name)
        if config:
            return config.get('extends')
        return None

    def get_additional_fields(self, class_name: str) -> Dict[str, List[Tuple]]:
        """Get additional fields for inherited classes.

        Args:
            class_name: The Dart class name

        Returns:
            Dict mapping discriminant values to field specs
        """
        config = self.get_inheritance_config(class_name)
        if config:
            return config.get('additional_fields', {})
        return {}

    def assign_type_to_file(self, class_name: str, filename: str):
        """Manually assign a type to a file.

        Args:
            class_name: The Dart class name
            filename: The target filename
        """
        self.type_to_file[class_name] = filename
        self.file_to_types.setdefault(filename, []).append(class_name)

    def get_all_files(self) -> List[str]:
        """Get all Dart XDR files.

        Returns:
            List of filenames
        """
        return sorted(self.file_to_types.keys())

    def get_all_types(self) -> List[str]:
        """Get all known Dart types.

        Returns:
            List of Dart class names
        """
        return sorted(self.type_to_file.keys())

    def infer_file_for_type(self, type_name: str) -> str:
        """Infer the target file for a new type based on naming patterns.

        Args:
            type_name: The Dart class name (e.g., 'XdrNewType')

        Returns:
            Suggested filename (e.g., 'xdr_other.dart')
        """
        # Remove Xdr prefix and convert to snake_case
        name = type_name[3:] if type_name.startswith('Xdr') else type_name

        # Patterns for file assignment
        patterns = {
            'xdr_account.dart': [
                'Account', 'Muxed', 'Threshold', 'Signer', 'Sponsor',
                'ClaimableBalance', 'BumpSequence', 'CreateAccount',
                'Inflation', 'ManageData', 'SetOptions', 'LiquidityPool'
            ],
            'xdr_asset.dart': [
                'Asset', 'AlphaNum'
            ],
            'xdr_auth.dart': [
                'Auth', 'Authenticated'
            ],
            'xdr_bucket.dart': [
                'Bucket'
            ],
            'xdr_contract.dart': [
                'SC', 'Contract', 'Soroban', 'Host', 'Invoke', 'Footprint',
                'Restore', 'Extend'
            ],
            'xdr_data_entry.dart': [
                'DataEntry', 'DataValue'
            ],
            'xdr_history.dart': [
                'History'
            ],
            'xdr_ledger.dart': [
                'Ledger', 'Claim', 'Config', 'TTL', 'State', 'Eviction',
                'Extension'  # Most extension types are ledger-related
            ],
            'xdr_memo.dart': [
                'Memo'
            ],
            'xdr_network.dart': [
                'Node', 'Peer', 'IP'
            ],
            'xdr_offer.dart': [
                'Offer'
            ],
            'xdr_operation.dart': [
                'Operation'
            ],
            'xdr_payment.dart': [
                'Payment', 'PathPayment'
            ],
            'xdr_scp.dart': [
                'SCP', 'Ballot', 'Envelope', 'Nomination', 'Quorum'
            ],
            'xdr_signing.dart': [
                'Signer', 'Signature', 'Decorated', 'SignatureHint'
            ],
            'xdr_transaction.dart': [
                'Transaction', 'FeeBump', 'Envelope', 'Meta', 'Result',
                'TimeBounds', 'Precondition', 'HashID', 'Event', 'Diagnostic'
            ],
            'xdr_trustline.dart': [
                'Trust', 'AllowTrust', 'ChangeTrust', 'Clawback', 'SetTrustLineFlags'
            ],
            'xdr_type.dart': [
                'Int32', 'Int64', 'Uint32', 'Uint64', 'String32', 'String64',
                'Hash', 'Curve25519', 'Hmac', 'PublicKey', 'CryptoKey', 'Value',
                'UpgradeType', 'BigInt64', 'Uint256'
            ],
            'xdr_error.dart': [
                'Error'
            ],
            'xdr_other.dart': [
                'BinaryFuse', 'Filter'  # Miscellaneous types
            ],
        }

        # Try to match patterns
        for filename, keywords in patterns.items():
            for keyword in keywords:
                if keyword in name:
                    return filename

        # Default to xdr_other.dart
        return 'xdr_other.dart'

    def get_file_stats(self) -> Dict[str, int]:
        """Get statistics about types per file.

        Returns:
            Dict mapping filename to type count
        """
        return {f: len(types) for f, types in self.file_to_types.items()}

    def validate_mapping(self) -> List[str]:
        """Validate the type-to-file mapping.

        Returns:
            List of validation warnings
        """
        warnings = []

        # Check for duplicate type assignments
        type_counts: Dict[str, int] = {}
        for types in self.file_to_types.values():
            for t in types:
                type_counts[t] = type_counts.get(t, 0) + 1

        for type_name, count in type_counts.items():
            if count > 1:
                warnings.append(f"Type '{type_name}' appears in {count} files")

        return warnings


# Global instance for convenience
_default_mapper: Optional[FileMapper] = None


def get_file_mapper(xdr_dir: Optional[str] = None) -> FileMapper:
    """Get the default FileMapper instance.

    Args:
        xdr_dir: Optional XDR directory path

    Returns:
        The default FileMapper
    """
    global _default_mapper
    if _default_mapper is None:
        _default_mapper = FileMapper(xdr_dir)
    return _default_mapper
