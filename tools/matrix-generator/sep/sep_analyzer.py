#!/usr/bin/env python3
"""
Flutter SDK SEP Implementation Analyzer

This script analyzes the Flutter Stellar SDK codebase to identify SEP implementations,
extract implemented features, and identify gaps compared to SEP specifications.

Author: Stellar Flutter SDK Team
License: Apache-2.0
"""

import json
import os
import re
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Callable, Container, Dict, List, Any, NamedTuple, Optional, Set, Tuple


# Add parent dir to path for shared modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from common import Colors, evaluate_shift_expression


class StrKeyTypeNames(NamedTuple):
    """SDK names of one SEP-23 key type."""
    version_byte: str  # VersionByte member
    encode: str        # StrKey encode function
    decode: str        # StrKey decode function


# SEP-23 key type, as the specification prints it, to its SDK names. None
# marks a key type the SDK does not implement.
SEP_23_KEY_TYPE_NAMES: Dict[str, Optional[StrKeyTypeNames]] = {
    'STRKEY_PUBKEY': StrKeyTypeNames('ACCOUNT_ID', 'encodeStellarAccountId', 'decodeStellarAccountId'),
    'STRKEY_MUXED': StrKeyTypeNames(
        'MUXED_ACCOUNT_ID', 'encodeStellarMuxedAccountId', 'decodeStellarMuxedAccountId'),
    'STRKEY_PRIVKEY': StrKeyTypeNames('SEED', 'encodeStellarSecretSeed', 'decodeStellarSecretSeed'),
    'STRKEY_PRE_AUTH_TX': StrKeyTypeNames('PRE_AUTH_TX', 'encodePreAuthTx', 'decodePreAuthTx'),
    'STRKEY_HASH_X': StrKeyTypeNames('SHA256_HASH', 'encodeSha256Hash', 'decodeSha256Hash'),
    'STRKEY_SIGNED_PAYLOAD': StrKeyTypeNames(
        'SIGNED_PAYLOAD', 'encodeSignedPayload', 'decodeSignedPayload'),
    'STRKEY_CONTRACT': StrKeyTypeNames('CONTRACT_ID', 'encodeContractId', 'decodeContractId'),
    'STRKEY_LIQUIDITY_POOL': StrKeyTypeNames(
        'LIQUIDITY_POOL', 'encodeLiquidityPoolId', 'decodeLiquidityPoolId'),
    'STRKEY_CLAIMABLE_BALANCE': StrKeyTypeNames(
        'CLAIMABLE_BALANCE', 'encodeClaimableBalanceId', 'decodeClaimableBalanceId'),
}

# Files the SEP-23 analysis reads, relative to the SDK root.
SEP_23_KEY_PAIR_FILE = Path('lib/src/key_pair.dart')
SEP_23_CONSTANTS_FILE = Path('lib/src/constants/stellar_protocol_constants.dart')
SEP_23_TEST_FILE = Path('test/unit/strkey_test.dart')


def read_sep_23_input(path: Path, sdk_root: Path) -> str:
    """
    Read one input of the SEP-23 analysis.

    Raises:
        RuntimeError: If the file is missing, unreadable, or not UTF-8,
            naming the path relative to sdk_root.
    """
    try:
        return path.read_text(encoding='utf-8')
    except (OSError, UnicodeDecodeError) as e:
        reason = e.strerror if isinstance(e, OSError) and e.strerror else str(e)
        shown = Path(os.path.relpath(path, sdk_root)).as_posix()
        raise RuntimeError(f'SEP-23 cannot read {shown}: {reason}') from e


def dart_class_body(source: str, class_name: str, path: Path) -> str:
    """
    Return the text between the braces of a Dart class, by plain brace counting.

    Raises:
        ValueError: If the source declares no such class.
    """
    declaration = re.search(r'\bclass\s+' + re.escape(class_name) + r'\b[^{}]*\{', source)
    if declaration is None:
        raise ValueError(f'SEP-23 class {class_name} not found in {path.as_posix()}')
    depth = 1
    for brace in re.finditer(r'[{}]', source[declaration.end():]):
        depth += 1 if brace.group() == '{' else -1
        if depth == 0:
            return source[declaration.end():declaration.end() + brace.start()]
    return source[declaration.end():]


def class_members(classes: List[Dict[str, Any]], kind: str, *class_names: str) -> Set[str]:
    """
    Names of the methods or properties (kind) of the named classes, or of
    every class when no name is given.
    """
    return {
        member['name']
        for cls in classes
        if not class_names or cls['name'] in class_names
        for member in cls.get(kind, [])
    }


def feature_entry(spec: Dict[str, Any], implemented: Optional[bool], reference_key: str,
                  reference: Optional[str]) -> Dict[str, Any]:
    """Analysis entry of one specified feature; the SDK reference shows only when implemented."""
    return {
        'required': spec.get('required', False),
        'implemented': implemented,
        reference_key: reference if implemented else None,
        'description': spec.get('description', ''),
    }


def map_features(specs: List[Dict[str, Any]], name_map: Dict[str, str], available: Container[str],
                 reference_key: str, fallback_to_name: bool = False) -> Dict[str, Dict[str, Any]]:
    """
    Analysis entries of specified features. A feature is implemented when the
    SDK name that name_map gives it is in available. A feature without a
    mapping is not implemented, or with fallback_to_name looked up by its own
    name.
    """
    entries = {}
    for spec in specs:
        name = spec['name']
        reference = name_map.get(name, name if fallback_to_name else None)
        entries[name] = feature_entry(spec, reference in available, reference_key, reference)
    return entries


def map_properties(specs: List[Dict[str, Any]], name_map: Dict[str, str],
                   classes: List[Dict[str, Any]], *class_names: str) -> Dict[str, Dict[str, Any]]:
    """
    map_features against the properties of the named classes. name_map lists
    the fields whose SDK property has another name; any other field is looked
    up by its own name.
    """
    return map_features(specs, name_map, class_members(classes, 'properties', *class_names),
                        'sdk_property', fallback_to_name=True)


def map_client_features(specs: List[Dict[str, Any]], name_map: Dict[str, str],
                        available: Container[str]) -> Dict[str, Dict[str, Any]]:
    """
    map_features with sdk_method references, for features the definition may
    mark server_side_only. Such a feature is not applicable to a client SDK:
    implemented is None and the entry carries the definition's client note.
    """
    entries = {}
    for spec in specs:
        server_side_only = spec.get('server_side_only', False)
        reference = name_map.get(spec['name'])
        implemented = None if server_side_only else reference in available
        entries[spec['name']] = dict(
            feature_entry(spec, implemented, 'sdk_method', reference),
            server_side_only=server_side_only,
            client_note=spec.get('client_note', '') if server_side_only else None,
        )
    return entries


def analysis_result(files: List[str], classes: List[Dict[str, Any]], features: Dict[str, Any],
                    result_key: str = 'implemented_features') -> Dict[str, Any]:
    """Analysis of an implemented SEP: its files, classes and mapped features."""
    return {
        'implemented': True,
        'files': files,
        'classes': classes,
        result_key: features,
        'total_classes': len(classes),
        'total_methods': sum(len(c['methods']) for c in classes),
        'total_properties': sum(len(c['properties']) for c in classes)
    }


def definition_sections(definition: Dict[str, Any], features_key: str) -> Dict[str, List[Dict[str, Any]]]:
    """Feature list of each section of a SEP definition, by section key."""
    return {
        section.get('key', ''): section.get(features_key, [])
        for section in definition.get('sections', [])
    }


class SEPAnalyzer:
    """Analyzer for Flutter SDK SEP implementations"""

    def __init__(self, sdk_path: str, sep_number: str):
        """
        Initialize SEP analyzer.

        Args:
            sdk_path: Path to Flutter SDK root directory
            sep_number: SEP number to analyze (e.g., '0001')
        """
        self.sdk_path = Path(sdk_path)
        self.sep_number = sep_number.zfill(4)
        self.sep_dir = self.sdk_path / 'lib' / 'src' / 'sep' / self.sep_number
        self.data_dir = Path(__file__).parent.parent / 'data' / 'sep'
        self.analysis_data: Dict[str, Any] = {}

    def find_sep_files(self) -> List[Path]:
        """
        Find all source files related to this SEP.

        Returns:
            List of file paths
        """
        files = []

        # Check if SEP directory exists
        if self.sep_dir.exists() and self.sep_dir.is_dir():
            # Find all .dart files in SEP directory
            files.extend(self.sep_dir.glob('*.dart'))

        return sorted(files)

    def _load_sep_definition(self) -> Dict[str, Any]:
        """The definition sep_parser.py wrote for this SEP."""
        with open(self.data_dir / f'sep_{self.sep_number}_definition.json', 'r', encoding='utf-8') as f:
            return json.load(f)

    def _analyze_class_files(
        self,
        files: List[Path],
        mapper: Callable[[List[Dict[str, Any]], Dict[str, Any]], Dict[str, Any]],
        result_key: str = 'implemented_features',
        reason: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Extract the classes of the given files and map them to the SEP definition.

        Args:
            files: Dart files that implement the SEP
            mapper: Maps the classes and the definition to features
            result_key: Key of the mapped features in the result
            reason: Reason reported when no file exists
        """
        if not files:
            return {
                'implemented': False,
                'reason': reason or f'No SEP-{int(self.sep_number):02d} implementation files found'
            }
        all_classes = [cls for path in files for cls in self.extract_class_info(path)]
        return analysis_result(
            [str(f.relative_to(self.sdk_path)) for f in files], all_classes,
            mapper(all_classes, self._load_sep_definition()), result_key)

    def extract_class_info(self, file_path: Path) -> List[Dict[str, Any]]:
        """
        Extract class information from a Dart file.

        Args:
            file_path: Path to Dart file

        Returns:
            List of class info dictionaries
        """
        classes = []
        content = file_path.read_text(encoding='utf-8')

        # Find class definitions
        class_pattern = r'class\s+(\w+)(?:\s+extends\s+(\w+))?(?:\s+implements\s+([\w,\s]+))?\s*\{'
        matches = re.finditer(class_pattern, content)

        for match in matches:
            class_name = match.group(1)
            extends = match.group(2) if match.group(2) else None
            implements = match.group(3).strip() if match.group(3) else None

            # Find class documentation
            doc_pattern = rf'///\s*(.*?)\nclass\s+{re.escape(class_name)}'
            doc_match = re.search(doc_pattern, content, re.DOTALL)
            documentation = doc_match.group(1).strip() if doc_match else ""

            # Extract methods
            methods = self.extract_methods(content, class_name)

            # Extract properties
            properties = self.extract_properties(content, class_name)

            classes.append({
                'name': class_name,
                'extends': extends,
                'implements': implements,
                'documentation': documentation,
                'methods': methods,
                'properties': properties,
                'file': str(file_path.relative_to(self.sdk_path))
            })

        return classes

    def extract_methods(self, content: str, class_name: str) -> List[Dict[str, str]]:
        """
        Extract method definitions from class.

        Args:
            content: File content
            class_name: Name of the class

        Returns:
            List of method info dictionaries
        """
        methods = []

        # Find class body - match until next class or end of file
        class_pattern = r'class\s+' + re.escape(class_name) + r'[^{]*\{(.*?)(?=\nclass\s+|\Z)'
        class_match = re.search(class_pattern, content, re.DOTALL)

        if not class_match:
            return methods

        class_body = class_match.group(1)

        # Dart language keywords that should be excluded from method detection
        dart_keywords = {
            'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'default',
            'break', 'continue', 'return', 'throw', 'try', 'catch', 'finally',
            'assert', 'new', 'const', 'super', 'this', 'null', 'true', 'false',
            'var', 'final', 'late', 'dynamic', 'void', 'class', 'enum', 'extends',
            'implements', 'with', 'abstract', 'interface', 'mixin', 'typedef',
            'await', 'async', 'sync', 'yield', 'import', 'export', 'library',
            'part', 'of', 'show', 'hide', 'as', 'is', 'in', 'rethrow', 'covariant',
            'static', 'get', 'set', 'operator', 'external', 'factory', 'required'
        }

        # Dart method declarations, private ones included:
        # [modifiers] return_type method_name([params]) [async] { or =>
        method_pattern = r'''
            (?:^|\n)\s*                          # Start of line
            (?:                                   # Modifiers (optional) OR must have return type
                (?:static|final|const|late|external|abstract)\s+
            )*
            (?:                                   # Return type (REQUIRED unless has modifier)
                (?:Future|Stream|FutureOr|void|bool|int|double|String|dynamic|http\.Response|
                   Map|List|Uint8List|[A-Z]\w*(?:<[^>]+>)?)\s+
            )
            (?:                                   # Optional async/sync* modifier before method name
                async\s+|sync\*\s+
            )?
            (_?\w+)                               # Method name including private methods with underscore (captured)
            \s*                                   # Optional whitespace
            \(                                    # Opening parenthesis
            [^)]*                                 # Parameters (non-greedy)
            \)                                    # Closing parenthesis
            \s*                                   # Optional whitespace
            (?:async\s*)?                         # Optional async after params
            (?:\{|=>)                            # Method body start or arrow function (not semicolon - that's abstract)
        '''

        # Find all method-like patterns
        method_matches = re.finditer(method_pattern, class_body, re.VERBOSE | re.MULTILINE)

        for match in method_matches:
            method_name = match.group(1)

            # Skip if it's a Dart keyword
            if method_name in dart_keywords:
                continue

            # Skip constructors (same name as class)
            if method_name == class_name:
                continue

            # Private methods stay: some implement SEP features (_parseMeta for
            # SEP-46, _parseSupportedSeps for SEP-47).

            # Skip if method name starts with a digit (invalid Dart identifier)
            if method_name[0].isdigit():
                continue

            # Verify this looks like a real method by checking the preceding context
            # Real methods should have proper spacing and declaration syntax
            method_start = match.start()
            preceding_text = class_body[:method_start]

            # Get the last 200 characters before the method to check context
            context = preceding_text[-200:] if len(preceding_text) > 200 else preceding_text

            # Skip if this appears inside a control flow statement
            # Look for patterns like "if (", "for (", "while (", etc.
            if re.search(r'\b(?:if|for|while|switch)\s*\([^)]*$', context):
                continue

            # Find method documentation
            doc_lines = []
            for line in reversed(preceding_text.split('\n')):
                line = line.strip()
                if line.startswith('///'):
                    doc_lines.insert(0, line.replace('///', '').strip())
                elif line and not line.startswith('//'):
                    break

            # Only add if we haven't seen this method name already
            # (to avoid duplicates from multiple patterns matching)
            if not any(m['name'] == method_name for m in methods):
                methods.append({
                    'name': method_name,
                    'documentation': ' '.join(doc_lines) if doc_lines else ''
                })

        return methods

    def extract_properties(self, content: str, class_name: str) -> List[Dict[str, str]]:
        """
        Extract property definitions from class.

        Args:
            content: File content
            class_name: Name of the class

        Returns:
            List of property info dictionaries
        """
        properties = []

        # The class body runs from the declaration's opening brace to the next
        # top-level class declaration or the end of the file.
        class_pattern = r'class\s+' + re.escape(class_name) + r'(?:\s+extends\s+\w+)?(?:\s+implements\s+[\w,\s]+)?\s*\{(.*?)(?=^class\s+|\Z)'
        class_match = re.search(class_pattern, content, re.MULTILINE | re.DOTALL)

        if not class_match:
            return properties

        class_body = class_match.group(1)

        # Split into lines to avoid matching inside methods
        lines = class_body.split('\n')
        brace_count = 0

        for line in lines:
            stripped = line.strip()

            # Track braces to know if we're inside a method/constructor
            brace_count += stripped.count('{') - stripped.count('}')

            # If we're inside braces, skip (we're in a method/constructor)
            if brace_count > 0:
                continue

            # Skip empty lines and comments
            if not stripped or stripped.startswith('//'):
                continue

            # Match class-level property declarations
            # Patterns: Type? name; or Type name = value; or static const Type name = value;
            property_pattern = r'^\s*(?:static\s+)?(?:const\s+)?(?:late\s+)?(?:final\s+)?(\w+(?:<[^>]+>)?)\???\s+(\w+)\s*(?:[=;]|$)'
            match = re.match(property_pattern, stripped)

            if match:
                property_type = match.group(1)
                property_name = match.group(2)

                # Skip private properties (starting with _)
                # Skip constructors and class declarations (must check they're not types like String, int, etc.)
                # Allow properties starting with uppercase if they're not common Dart types
                is_likely_type = property_name in ['String', 'int', 'bool', 'double', 'num', 'List', 'Map', 'Set', 'DateTime', 'Uint8List']

                if not property_name.startswith('_') and not is_likely_type:
                    properties.append({
                        'name': property_name,
                        'type': property_type
                    })

        return properties

    def analyze_sep_01(self) -> Dict[str, Any]:
        """Analyze SEP-01 (stellar.toml) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_01_fields, result_key='implemented_fields')

    def map_sep_01_fields(self, classes: List[Dict[str, Any]],
                          sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-01 field requirements."""
        all_properties = class_members(classes, 'properties')
        implemented = {}
        for section in sep_definition.get('sections', []):
            fields = {}
            for field in section.get('fields', []):
                sdk_property = self.sep_field_to_sdk_property(field['name'])
                fields[field['name']] = feature_entry(
                    field, sdk_property in all_properties, 'sdk_property', sdk_property)
            implemented[section.get('key', '')] = {'title': section.get('title', ''), 'fields': fields}
        return implemented

    def sep_field_to_sdk_property(self, sep_field: str) -> str:
        """
        Convert SEP field name to SDK property name.

        Args:
            sep_field: SEP field name (e.g., 'NETWORK_PASSPHRASE')

        Returns:
            SDK property name (e.g., 'networkPassphrase')
        """
        # Known mappings
        mappings = {
            'VERSION': 'version',
            'NETWORK_PASSPHRASE': 'networkPassphrase',
            'FEDERATION_SERVER': 'federationServer',
            'AUTH_SERVER': 'authServer',
            'TRANSFER_SERVER': 'transferServer',
            'TRANSFER_SERVER_SEP0024': 'transferServerSep24',
            'KYC_SERVER': 'kYCServer',
            'WEB_AUTH_ENDPOINT': 'webAuthEndpoint',
            'SIGNING_KEY': 'signingKey',
            'HORIZON_URL': 'horizonUrl',
            'ACCOUNTS': 'accounts',
            'URI_REQUEST_SIGNING_KEY': 'uriRequestSigningKey',
            'DIRECT_PAYMENT_SERVER': 'directPaymentServer',
            'ANCHOR_QUOTE_SERVER': 'anchorQuoteServer',
            'ORG_NAME': 'orgName',
            'ORG_DBA': 'orgDBA',
            'ORG_URL': 'orgUrl',
            'ORG_LOGO': 'orgLogo',
            'ORG_DESCRIPTION': 'orgDescription',
            'ORG_PHYSICAL_ADDRESS': 'orgPhysicalAddress',
            'ORG_PHYSICAL_ADDRESS_ATTESTATION': 'orgPhysicalAddressAttestation',
            'ORG_PHONE_NUMBER': 'orgPhoneNumber',
            'ORG_PHONE_NUMBER_ATTESTATION': 'orgPhoneNumberAttestation',
            'ORG_KEYBASE': 'orgKeybase',
            'ORG_TWITTER': 'orgTwitter',
            'ORG_GITHUB': 'orgGithub',
            'ORG_OFFICIAL_EMAIL': 'orgOfficialEmail',
            'ORG_SUPPORT_EMAIL': 'orgSupportEmail',
            'ORG_LICENSING_AUTHORITY': 'orgLicensingAuthority',
            'ORG_LICENSE_TYPE': 'orgLicenseType',
            'ORG_LICENSE_NUMBER': 'orgLicenseNumber',
            'ALIAS': 'alias',
            'DISPLAY_NAME': 'displayName',
            'PUBLIC_KEY': 'publicKey',
            'HOST': 'host',
            'HISTORY': 'history',
        }

        if sep_field in mappings:
            return mappings[sep_field]

        # Default: convert to camelCase
        parts = sep_field.lower().split('_')
        return parts[0] + ''.join(p.capitalize() for p in parts[1:])

    def analyze_sep_02(self) -> Dict[str, Any]:
        """Analyze SEP-02 (Federation Protocol) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_02_features)

    def map_sep_02_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-02 API requirements."""
        api_structure = next((
            section.get('api_structure', {}) for section in sep_definition.get('sections', [])
            if section.get('key') == 'api'
        ), {})
        request_types_map = {
            'name': 'resolveStellarAddress',
            'id': 'resolveStellarAccountId',
            'txid': 'resolveStellarTransactionId',
            'forward': 'resolveForward'
        }
        response_property_map = {
            'stellar_address': 'stellarAddress',
            'account_id': 'accountId',
            'memo_type': 'memoType'
        }

        return {
            'request_types': map_features(
                api_structure.get('request_types', []), request_types_map,
                class_members(classes, 'methods'), 'sdk_method'),
            # The request builder sets both parameters (forStringToLookUp, forType).
            'request_parameters': {
                param['name']: feature_entry(param, True, 'sdk_property', param['name'])
                for param in api_structure.get('request_parameters', [])
            },
            'response_fields': map_properties(
                api_structure.get('response_fields', []), response_property_map, classes,
                'FederationResponse'),
        }

    def analyze_sep_10(self) -> Dict[str, Any]:
        """Analyze SEP-10 (Stellar Web Authentication) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_10_features)

    def map_sep_10_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-10 authentication feature requirements."""
        all_methods = class_members(classes, 'methods')
        sections = definition_sections(sep_definition, 'auth_features')

        auth_endpoints_map = {
            'get_auth_challenge': 'getChallenge',
            'post_auth_token': 'sendSignedChallengeTransaction'
        }
        challenge_features_map = {
            'challenge_transaction_generation': 'getChallenge',
            'transaction_envelope_format': 'validateChallenge',
            'sequence_number_zero': 'validateChallenge',
            'manage_data_operations': 'validateChallenge',
            'home_domain_operation': 'validateChallenge',
            'web_auth_domain_operation': 'validateChallenge',
            'timebounds_enforcement': 'validateChallenge',
            'server_signature': 'validateChallenge',
            'nonce_generation': 'getChallenge'
        }
        jwt_features_map = {
            'jwt_token_generation': 'sendSignedChallengeTransaction',
            'jwt_token_response': 'sendSignedChallengeTransaction',
            'jwt_token_validation': 'jwtToken',
            'jwt_expiration': 'sendSignedChallengeTransaction',
            'jwt_claims': 'sendSignedChallengeTransaction'
        }
        client_domain_features_map = {
            'client_domain_parameter': 'getChallenge',
            'client_domain_operation': 'validateChallenge',
            'client_domain_verification': 'jwtToken',
            'client_domain_signature': 'signTransaction'
        }
        verification_features_map = {
            'challenge_validation': 'validateChallenge',
            'signature_verification': 'validateChallenge',
            'multi_signature_support': 'signTransaction',
            'timebounds_validation': 'validateChallenge',
            'home_domain_validation': 'validateChallenge',
            'memo_support': 'getChallenge'
        }

        return {
            'authentication_endpoints': map_features(
                sections.get('auth_endpoints', []), auth_endpoints_map, all_methods, 'sdk_method'),
            'challenge_transaction_features': map_features(
                sections.get('challenge_transaction', []), challenge_features_map, all_methods,
                'sdk_method'),
            'jwt_token_features': map_client_features(
                sections.get('jwt_token', []), jwt_features_map, all_methods),
            'client_domain_features': map_client_features(
                sections.get('client_domain', []), client_domain_features_map, all_methods),
            'verification_features': map_features(
                sections.get('verification', []), verification_features_map, all_methods,
                'sdk_method'),
        }

    def analyze_sep_05(self) -> Dict[str, Any]:
        """Analyze SEP-05 (Key Derivation Methods) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_05_features)

    def map_sep_05_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-05 cryptographic feature requirements."""
        all_methods = class_members(classes, 'methods')
        sections = definition_sections(sep_definition, 'crypto_features')

        bip39_feature_map = {
            'mnemonic_generation_12_words': 'generate12WordsMnemonic',
            'mnemonic_generation_24_words': 'generate24WordsMnemonic',
            'mnemonic_validation': 'validate',
            'mnemonic_to_seed': 'mnemonicToSeed',
            'passphrase_support': 'mnemonicToSeed'  # Passphrase is a parameter
        }
        bip32_feature_map = {
            'hd_key_derivation': '_derivePath',
            'ed25519_curve': '_hMacSHA512',  # Ed25519 support through HMAC-SHA512
            'master_key_generation': '_derivePath',
            'child_key_derivation': '_derive'
        }
        bip44_feature_map = {
            'stellar_derivation_path': 'getKeyPair',  # Uses m/44'/148'/account'
            'multiple_accounts': 'getKeyPair',  # Supports index parameter
            'account_index_support': 'getKeyPair'
        }
        key_derivation_map = {
            'keypair_from_mnemonic': 'getKeyPair',
            'account_id_from_mnemonic': 'getAccountId',
            'seed_from_mnemonic': 'mnemonicToSeed'
        }
        # Word list accessors of the WordList class
        language_map = {
            'english': 'englishWords',
            'chinese_simplified': 'chineseSimplifiedWords',
            'chinese_traditional': 'chineseTraditionalWords',
            'french': 'frenchWords',
            'italian': 'italianWords',
            'japanese': 'japaneseWords',
            'korean': 'koreanWords',
            'spanish': 'spanishWords'
        }

        return {
            'bip39_features': map_features(
                sections.get('bip39', []), bip39_feature_map, all_methods, 'sdk_method'),
            'bip32_features': map_features(
                sections.get('bip32', []), bip32_feature_map, all_methods, 'sdk_method'),
            'bip44_features': map_features(
                sections.get('bip44', []), bip44_feature_map, all_methods, 'sdk_method'),
            'key_derivation_methods': map_features(
                sections.get('key_derivation', []), key_derivation_map, all_methods, 'sdk_method'),
            'language_support': map_features(
                sections.get('languages', []), language_map,
                class_members(classes, 'methods', 'WordList'), 'sdk_method'),
        }

    def analyze_sep_09(self) -> Dict[str, Any]:
        """Analyze SEP-09 (Standard KYC/AML Fields) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_09_fields, result_key='implemented_fields')

    def map_sep_09_fields(self, classes: List[Dict[str, Any]],
                          sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-09 field requirements.

        A field is implemented when its class declares both the key constant
        and the property.
        """
        # Class, suffixes of its key constants, and the end of its body.
        kyc_classes = (
            ('NaturalPersonKYCFields', ('_field_key', '_file_key'), r'(?=\n  /// |\nclass )'),
            ('OrganizationKYCFields', ('_field_key', '_file_key'), r'(?=\n  /// |\nclass )'),
            ('FinancialAccountKYCFields', ('_field_key',), r'(?=\n  /// |\nclass )'),
            ('CardKYCFields', ('_field_key',), r'$'),
        )
        field_keys = {class_name: set() for class_name, _, _ in kyc_classes}
        sep_file = self.sdk_path / 'lib' / 'src' / 'sep' / '0009' / 'standard_kyc_fields.dart'
        if sep_file.exists():
            content = sep_file.read_text(encoding='utf-8')
            for class_name, suffixes, body_end in kyc_classes:
                body = re.search(rf'class {class_name}.*?\{{(.*?){body_end}', content, re.DOTALL)
                if not body:
                    continue
                key_pattern = r'static const String (' + '|'.join(rf'\w+{s}' for s in suffixes) + ')'
                for match in re.finditer(key_pattern, body.group(1)):
                    field_keys[class_name].add(
                        match.group(1).replace('_field_key', '').replace('_file_key', ''))

        def snake_to_camel(snake_str: str) -> str:
            components = snake_str.split('_')
            return components[0] + ''.join(x.title() for x in components[1:])

        def entries(fields: List[Dict[str, Any]], class_name: str,
                    prefix: str = '') -> Dict[str, Any]:
            keys = field_keys[class_name]
            properties = class_members(classes, 'properties', class_name)
            result = {}
            for field in fields:
                check_name = field['name']
                if prefix and check_name.startswith(prefix):
                    check_name = check_name[len(prefix):]
                camel_name = snake_to_camel(check_name)
                has_property = camel_name in properties
                # The SDK names this property VATNumber or vatNumber.
                if check_name == 'VAT_number':
                    has_property = 'VATNumber' in properties or 'vatNumber' in properties
                    camel_name = 'VATNumber' if 'VATNumber' in properties else (
                        'vatNumber' if 'vatNumber' in properties else camel_name)
                result[field['name']] = {
                    'required': field.get('required', False),
                    'implemented': check_name in keys and has_property,
                    'sdk_property': camel_name if has_property else None,
                    'description': field.get('description', ''),
                    'type': field.get('type', 'string')
                }
            return result

        sections = definition_sections(sep_definition, 'fields')
        return {
            'natural_person_fields': entries(
                sections.get('natural_person_fields', []), 'NaturalPersonKYCFields'),
            'organization_fields': entries(
                sections.get('organization_fields', []), 'OrganizationKYCFields', 'organization.'),
            'financial_account_fields': entries(
                sections.get('financial_account_fields', []), 'FinancialAccountKYCFields'),
            'card_fields': entries(sections.get('card_fields', []), 'CardKYCFields', 'card.'),
        }

    def analyze_sep_23(self) -> Dict[str, Any]:
        """
        Analyze SEP-23 (Strkeys) implementation.

        Key types are checked against lib/src/key_pair.dart (VersionByte and
        StrKey) and lib/src/constants/stellar_protocol_constants.dart; test
        vectors against test/unit/strkey_test.dart, the one file under test/
        that a SEP analysis reads.

        Raises:
            RuntimeError: If the definition or one of the three files cannot
                be read.
            ValueError: As map_sep_23_features describes.
        """
        sep_definition = json.loads(read_sep_23_input(
            self.data_dir / f'sep_{self.sep_number}_definition.json', self.sdk_path
        ))
        key_pair_content, constants_content, test_content = (
            read_sep_23_input(self.sdk_path / path, self.sdk_path)
            for path in (SEP_23_KEY_PAIR_FILE, SEP_23_CONSTANTS_FILE, SEP_23_TEST_FILE)
        )

        # Report the two SEP-23 classes, each with its role.
        documentation = {
            'StrKey': 'Strkey encoding and decoding: an encode, a decode, and a validity '
                      'check per key type, plus encodeCheck and decodeCheck for any version byte',
            'VersionByte': 'Version byte of each strkey type, bound to its value in '
                           'StellarProtocolConstants',
        }
        all_classes = [
            dict(cls, documentation=documentation[cls['name']])
            for cls in self.extract_class_info(self.sdk_path / SEP_23_KEY_PAIR_FILE)
            if cls['name'] in documentation
        ]

        implemented_features = self.map_sep_23_features(
            key_pair_content, constants_content, test_content, sep_definition
        )

        return analysis_result(
            [SEP_23_KEY_PAIR_FILE.as_posix(), SEP_23_CONSTANTS_FILE.as_posix(),
             SEP_23_TEST_FILE.as_posix()],
            all_classes, implemented_features)

    def map_sep_23_features(self, key_pair_content: str, constants_content: str,
                            test_content: str,
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map the StrKey sources and unit tests to SEP-23 key types and vectors.

        A key type is implemented when the value of its VersionByte member,
        the member's integer argument or the StellarProtocolConstants constant
        it names, equals the base value of the specification. Its encode and
        decode functions must be declared as static methods in
        lib/src/key_pair.dart. Declarations are matched by pattern on the
        source text.

        A test vector is implemented when it appears as a complete quoted
        string literal, '...' or "...", in the unit test file. The closing
        quote is part of the match, because several valid vectors are
        prefixes of invalid ones. Presence is all this proves: it does not
        show that a test asserts the vector or in which direction.

        Raises:
            ValueError: If a class, member, constant, or function it maps is
                absent, a key type has no entry in SEP_23_KEY_TYPE_NAMES, a
                value has a form it cannot evaluate, or the definition lists
                no key type or no test vector.
        """
        implemented = {'strkey_type_features': {}, 'strkey_vector_features': {}}
        key_pair = SEP_23_KEY_PAIR_FILE.as_posix()
        version_bytes = dart_class_body(key_pair_content, 'VersionByte', SEP_23_KEY_PAIR_FILE)
        constants = dart_class_body(
            constants_content, 'StellarProtocolConstants', SEP_23_CONSTANTS_FILE
        )
        # Static method declarations: return type, name, opening parenthesis.
        static_functions = set(re.findall(
            r'\bstatic\s+(?:[\w<>?,]+\s+)+(\w+)\s*\(', key_pair_content
        ))

        def version_byte_value(member: str) -> int:
            declaration = re.search(
                rf'\bstatic\s+const\s+(?:VersionByte\s+)?{member}\s*=\s*(?:const\s+)?'
                rf'VersionByte\._internal\(\s*([^),]*?)\s*,?\s*\)', version_bytes
            )
            if declaration is None:
                raise ValueError(f'SEP-23 VersionByte.{member} not found in {key_pair}')
            label, path, value = f'VersionByte.{member}', key_pair, declaration.group(1)
            reference = re.fullmatch(r'StellarProtocolConstants\.(\w+)', value)
            if reference:
                label, path = (f'StellarProtocolConstants.{reference.group(1)}',
                               SEP_23_CONSTANTS_FILE.as_posix())
                constant = re.search(
                    rf'\bstatic\s+const\s+(?:int\s+)?{reference.group(1)}\s*=\s*([^;]+);',
                    constants
                )
                if constant is None:
                    raise ValueError(f'SEP-23 {label} not found in {path}')
                value = constant.group(1).strip()
            try:
                return evaluate_shift_expression(value)
            except ValueError as e:
                raise ValueError(
                    f'SEP-23 {label} in {path} has a value this reader cannot evaluate: {value!r}'
                ) from e

        def detect_key_type(name: str, base_value: int) -> Optional[str]:
            if name not in SEP_23_KEY_TYPE_NAMES:
                raise ValueError(f'SEP-23 key type {name} has no entry in SEP_23_KEY_TYPE_NAMES')
            names = SEP_23_KEY_TYPE_NAMES[name]
            if names is None:
                return None
            for function in (names.encode, names.decode):
                if function not in static_functions:
                    raise ValueError(f'SEP-23 StrKey.{function} not found in {key_pair}')
            if version_byte_value(names.version_byte) != base_value:
                return None
            return f'StrKey.{names.encode} / {names.decode}'

        for section in sep_definition.get('sections', []):
            for feature in section.get('strkey_type_features', []):
                sdk_method = detect_key_type(feature['name'], feature['base_value'])
                implemented['strkey_type_features'][feature['name']] = feature_entry(
                    feature, sdk_method is not None, 'sdk_method', sdk_method)
            for feature in section.get('strkey_vector_features', []):
                quoted = re.search(r'([\'"])' + re.escape(feature['vector']) + r'\1', test_content)
                sdk_method = SEP_23_TEST_FILE.as_posix() if quoted else None
                # A title's closing period is dropped so the phrase can follow it.
                title = re.sub(r'\.$', '', feature.get('description', ''))
                implemented['strkey_vector_features'][feature['name']] = {
                    'required': feature.get('required', False),
                    'implemented': sdk_method is not None,
                    'sdk_method': sdk_method,
                    'description': f'{title}, quoted in `{SEP_23_TEST_FILE.as_posix()}`'
                }

        for key, features in implemented.items():
            if not features:
                raise ValueError(f'SEP-23 definition lists no {key}')
        return implemented

    def analyze_sep_29(self) -> Dict[str, Any]:
        """
        Analyze SEP-29 (Account Memo Requirements) implementation.

        The SEP-29 check is implemented on the StellarSDK class in
        lib/src/stellar_sdk.dart, which also declares
        AccountRequiresMemoException. Setting the flag uses the manage data
        operation in lib/src/manage_data_operation.dart. Detection is performed
        against the source of those files rather than a SEP source directory.

        Returns:
            Analysis results dictionary
        """
        sdk_path = self.sdk_path / 'lib' / 'src' / 'stellar_sdk.dart'
        manage_data_path = self.sdk_path / 'lib' / 'src' / 'manage_data_operation.dart'

        if not sdk_path.exists():
            return {
                'implemented': False,
                'reason': 'No SEP-29 implementation file found (lib/src/stellar_sdk.dart)'
            }

        sep_definition = self._load_sep_definition()

        content = sdk_path.read_text(encoding='utf-8')
        manage_data_content = ''
        if manage_data_path.exists():
            manage_data_content = manage_data_path.read_text(encoding='utf-8')

        # Restrict reported classes to the SEP-29 entry points.
        all_classes = [
            cls for cls in self.extract_class_info(sdk_path)
            if cls['name'] in ('StellarSDK', 'AccountRequiresMemoException')
        ]
        for cls in all_classes:
            if cls['name'] == 'StellarSDK':
                cls['documentation'] = (
                    'Horizon client with the SEP-29 memo required check '
                    '(checkMemoRequired) run by the submit methods unless '
                    'skipMemoRequiredCheck is true'
                )
            elif cls['name'] == 'AccountRequiresMemoException':
                cls['documentation'] = (
                    'Thrown when a destination account requires a memo and the '
                    'transaction carries none; holds the account id and the '
                    'index of the operation that names it'
                )

        implemented_features = self.map_sep_29_features(
            content, manage_data_content, sep_definition
        )

        files = [str(sdk_path.relative_to(self.sdk_path))]
        if manage_data_content:
            files.append(str(manage_data_path.relative_to(self.sdk_path)))

        return analysis_result(files, all_classes, implemented_features)

    def map_sep_29_features(self, content: str, manage_data_content: str,
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map the StellarSDK source to SEP-29 memo required capability fields.

        Args:
            content: Source of lib/src/stellar_sdk.dart
            manage_data_content: Source of lib/src/manage_data_operation.dart
            sep_definition: SEP-29 specification definition

        Returns:
            Dictionary mapping memo required features to implementation status
        """
        # Submit methods that must expose the skipMemoRequiredCheck parameter.
        submit_methods = {
            'submit_transaction_opt_out': 'submitTransaction',
            'submit_fee_bump_transaction_opt_out': 'submitFeeBumpTransaction',
            'submit_async_transaction_opt_out': 'submitAsyncTransaction',
            'submit_async_fee_bump_transaction_opt_out': 'submitAsyncFeeBumpTransaction',
            'submit_transaction_envelope_opt_out': 'submitTransactionEnvelopeXdrBase64',
            'submit_async_transaction_envelope_opt_out': 'submitAsyncTransactionEnvelopeXdrBase64',
        }

        def detect(name: str) -> Tuple[bool, str]:
            if name == 'memo_required_data_entry':
                if 'config.memo_required' in content and 'checkMemoRequired' in content:
                    return True, 'checkMemoRequired (config.memo_required data entry)'
            elif name == 'set_memo_required_flag':
                if 'class ManageDataOperationBuilder' in manage_data_content:
                    return True, 'ManageDataOperationBuilder'
            elif name == 'payment_destination':
                if 'is PaymentOperation' in content:
                    return True, 'checkMemoRequired (PaymentOperation)'
            elif name == 'path_payment_strict_send_destination':
                if 'is PathPaymentStrictSendOperation' in content:
                    return True, 'checkMemoRequired (PathPaymentStrictSendOperation)'
            elif name == 'path_payment_strict_receive_destination':
                if 'is PathPaymentStrictReceiveOperation' in content:
                    return True, 'checkMemoRequired (PathPaymentStrictReceiveOperation)'
            elif name == 'account_merge_destination':
                if 'is AccountMergeOperation' in content:
                    return True, 'checkMemoRequired (AccountMergeOperation)'
            elif name == 'muxed_destination_exempt':
                if 'destination.id != null' in content:
                    return True, 'checkMemoRequired (muxed destination skipped)'
            elif name == 'memo_present_skips_lookup':
                if 'is MemoNone' in content:
                    return True, 'checkMemoRequired (memo short-circuit)'
            elif name == 'fee_bump_inner_transaction':
                if 'innerTransaction' in content:
                    return True, 'checkMemoRequired (FeeBumpTransaction.innerTransaction)'
            elif name == 'unknown_destination_skipped':
                if 'NetworkConstants.HTTP_NOT_FOUND' in content:
                    return True, 'checkMemoRequired (HTTP 404 skipped)'
            elif name == 'check_memo_required_method':
                if 'Future<void> checkMemoRequired(' in content:
                    return True, 'checkMemoRequired(AbstractTransaction)'
            elif name in submit_methods:
                method = submit_methods[name]
                pattern = r'Future<[^>]+>\s*' + method + r'\([^)]*skipMemoRequiredCheck'
                if re.search(pattern, content):
                    return True, f'{method}(skipMemoRequiredCheck)'
            elif name == 'account_requires_memo_exception':
                if 'class AccountRequiresMemoException' in content and 'operationIndex' in content:
                    return True, 'AccountRequiresMemoException'
            return False, None

        entries = {}
        for feature in definition_sections(sep_definition, 'memo_required_features').get('memo_required', []):
            is_implemented, reference = detect(feature['name'])
            entries[feature['name']] = feature_entry(feature, is_implemented, 'sdk_method', reference)
        return {'memo_required': entries}

    def analyze_sep_53(self) -> Dict[str, Any]:
        """
        Analyze SEP-53 (Sign and Verify Messages) implementation.

        SEP-53 message signing is implemented on the KeyPair class in
        lib/src/key_pair.dart. Detection is performed against the source of that
        file rather than a SEP source directory.

        Returns:
            Analysis results dictionary
        """
        keypair_path = self.sdk_path / 'lib' / 'src' / 'key_pair.dart'

        if not keypair_path.exists():
            return {
                'implemented': False,
                'reason': 'No SEP-53 implementation file found (lib/src/key_pair.dart)'
            }

        sep_definition = self._load_sep_definition()

        content = keypair_path.read_text(encoding='utf-8')

        # Restrict reported classes to the SEP-53 entry point.
        all_classes = [
            cls for cls in self.extract_class_info(keypair_path)
            if cls['name'] == 'KeyPair'
        ]
        for cls in all_classes:
            if cls['name'] == 'KeyPair':
                cls['documentation'] = (
                    'Stellar key pair with SEP-53 message signing and verification '
                    'methods (signMessage, signMessageString, verifyMessage, '
                    'verifyMessageString)'
                )

        implemented_features = self.map_sep_53_features(content, sep_definition)

        return analysis_result(
            [str(keypair_path.relative_to(self.sdk_path))], all_classes, implemented_features)

    def map_sep_53_features(self, content: str,
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map the KeyPair source to SEP-53 message signing capability fields.

        Args:
            content: Source of lib/src/key_pair.dart
            sep_definition: SEP-53 specification definition

        Returns:
            Dictionary mapping message signing features to implementation status
        """
        def detect(name: str) -> Tuple[bool, str]:
            if name == 'message_prefix':
                if "Stellar Signed Message:\\n" in content and '_calculateMessageHash' in content:
                    return True, '_calculateMessageHash (prefix constant)'
            elif name == 'sha256_hashing':
                if 'Util.hash' in content and '_calculateMessageHash' in content:
                    return True, '_calculateMessageHash (SHA-256 hash)'
            elif name == 'sign_message_binary':
                if 'Uint8List signMessage(Uint8List message)' in content:
                    return True, 'signMessage(Uint8List)'
            elif name == 'sign_message_string':
                if 'Uint8List signMessageString(String message)' in content:
                    return True, 'signMessageString(String)'
            elif name == 'verify_message_binary':
                if 'bool verifyMessage(Uint8List message, Uint8List signature)' in content:
                    return True, 'verifyMessage(Uint8List, Uint8List)'
            elif name == 'verify_message_string':
                if 'bool verifyMessageString(String message' in content and 'signature' in content:
                    return True, 'verifyMessageString(String, Uint8List)'
            elif name == 'ed25519_signature':
                if 'Uint8List sign(Uint8List data)' in content and 'Ed25519' in content:
                    return True, 'sign (Ed25519 64-byte signature)'
            elif name == 'utf8_encoding':
                if 'utf8.encode' in content and 'signMessage' in content:
                    return True, 'signMessageString (UTF-8 encoding)'
            return False, None

        entries = {}
        for feature in definition_sections(sep_definition, 'message_signing_features').get('message_signing', []):
            is_implemented, reference = detect(feature['name'])
            entries[feature['name']] = feature_entry(feature, is_implemented, 'sdk_method', reference)
        return {'message_signing': entries}

    def analyze_sep_11(self) -> Dict[str, Any]:
        """Analyze SEP-11 (Txrep) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_11_features)

    def map_sep_11_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-11 Txrep requirements.

        TxRep encodes with fromTransactionEnvelopeXdrBase64 and decodes with
        transactionEnvelopeXdrBase64FromTxRep; every Txrep feature goes through
        one or both of them.
        """
        txrep_methods = class_members(classes, 'methods', 'TxRep')
        has_encoding = 'fromTransactionEnvelopeXdrBase64' in txrep_methods
        has_decoding = 'transactionEnvelopeXdrBase64FromTxRep' in txrep_methods
        format_feature_impl = {
            'comment_support': has_decoding,  # Comments handled in _removeComment
            'dot_notation': has_encoding and has_decoding,  # Used throughout
            'array_indexing': has_encoding and has_decoding,  # Used for operations, signatures, etc.
            'hex_encoding': has_encoding and has_decoding,  # Used for binary data
            'string_escaping': has_encoding and has_decoding  # Used for text memos
        }
        sections = definition_sections(sep_definition, 'txrep_features')

        def entries(section_key: str, is_implemented: Callable[[str], bool],
                    sdk_method: str) -> Dict[str, Any]:
            return {
                feature['name']: dict(
                    feature_entry(feature, is_implemented(feature['name']), 'sdk_method', sdk_method),
                    category=feature.get('category', ''))
                for feature in sections.get(section_key, [])
            }

        return {
            'encoding_features': entries(
                'encoding_features', lambda name: has_encoding, 'fromTransactionEnvelopeXdrBase64'),
            'decoding_features': entries(
                'decoding_features', lambda name: has_decoding, 'transactionEnvelopeXdrBase64FromTxRep'),
            'asset_encoding': entries('asset_encoding', lambda name: has_encoding, '_encodeAsset'),
            'operation_types': entries(
                'operation_types', lambda name: has_encoding and has_decoding,
                '_addOperation (encode), operation parsing (decode)'),
            'format_features': entries(
                'format_features', lambda name: format_feature_impl.get(name, False),
                'TxRep format implementation'),
        }

    def analyze_sep_12(self) -> Dict[str, Any]:
        """Analyze SEP-12 (KYC API) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_12_features)

    def map_sep_12_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-12 KYC API requirements."""
        api_structure = next((
            section.get('api_structure', {}) for section in sep_definition.get('sections', [])
            if section.get('key') == 'endpoints'
        ), {})
        if not api_structure:
            return {key: {} for key in ('endpoints', 'request_parameters', 'response_fields', 'field_types',
                                        'authentication', 'file_upload', 'sep9_integration')}

        kyc_service_methods = class_members(classes, 'methods', 'KYCService')
        endpoint_map = {
            'get_customer': 'getCustomerInfo',
            'put_customer': 'putCustomerInfo',
            'put_customer_verification': 'putCustomerVerification',
            'delete_customer': 'deleteCustomer',
            'put_customer_callback': 'putCustomerCallback',
            'post_customer_files': 'postCustomerFile',
            'get_customer_files': 'getCustomerFiles'
        }

        endpoints = {}
        for endpoint in api_structure.get('endpoints', []):
            sdk_method = endpoint_map.get(endpoint['key'])
            implemented_in_sdk = sdk_method in kyc_service_methods
            endpoints[endpoint['key']] = {
                'required': True,  # Every KYC endpoint counts as required
                'implemented': implemented_in_sdk,
                'sdk_method': sdk_method if implemented_in_sdk else None,
                'description': endpoint.get('description', ''),
                'path': endpoint.get('path', ''),
                'method': endpoint.get('method', '')
            }

        # A field type without a required flag counts as required.
        field_properties = class_members(
            classes, 'properties', 'GetCustomerInfoField', 'GetCustomerInfoProvidedField')
        field_types = {
            field_type['name']: dict(
                feature_entry(field_type, field_type['name'] in field_properties, 'sdk_property',
                              field_type['name']),
                required=field_type.get('required', True))
            for field_type in api_structure.get('field_types', [])
        }

        auth = api_structure.get('authentication', {})
        request_classes = ('GetCustomerInfoRequest', 'PutCustomerInfoRequest',
                           'PutCustomerVerificationRequest', 'PutCustomerCallbackRequest')
        file_upload = api_structure.get('file_upload', {})
        sep9_integration = api_structure.get('sep9_integration', {})
        # SEP-9 counts as integrated when its module, one of its field classes,
        # or the kycFields property of PutCustomerInfoRequest exists.
        sep9_implemented = (
            (self.sdk_path / 'lib' / 'src' / 'sep' / '0009' / 'standard_kyc_fields.dart').exists()
            or bool({'NaturalPersonKYCFields', 'OrganizationKYCFields', 'StandardKYCFields'}
                    & {cls['name'] for cls in classes})
            or 'kycFields' in class_members(classes, 'properties', 'PutCustomerInfoRequest')
        )

        return {
            'endpoints': endpoints,
            'request_parameters': map_properties(
                api_structure.get('request_parameters', []),
                {'memo_type': 'memoType', 'transaction_id': 'transactionId'},
                classes, 'GetCustomerInfoRequest'),
            'response_fields': map_properties(
                api_structure.get('response_fields', []), {'provided_fields': 'providedFields'},
                classes, 'GetCustomerInfoResponse'),
            'field_types': field_types,
            'authentication': {
                'type': auth.get('type', 'SEP-10'),
                'method': auth.get('method', 'JWT Token'),
                'implemented': 'jwt' in class_members(classes, 'properties', *request_classes),
                'description': auth.get('description', '')
            },
            'file_upload': {
                'supported': file_upload.get('supported', True),
                'implemented': 'postCustomerFile' in kyc_service_methods,
                'content_type': file_upload.get('content_type', 'multipart/form-data'),
                'description': file_upload.get('description', '')
            },
            'sep9_integration': {
                'supported': sep9_integration.get('supported', True),
                'implemented': sep9_implemented,
                'description': sep9_integration.get('description', '')
            },
        }

    def analyze_sep_06(self) -> Dict[str, Any]:
        """Analyze SEP-06 (Deposit and Withdrawal API) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_06_features)

    def map_sep_06_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-06 Deposit/Withdrawal API requirements."""
        sections = definition_sections(sep_definition, 'api_features')
        transfer_service_methods = class_members(classes, 'methods', 'TransferServerService')

        endpoint_map = {
            'info_endpoint': 'info',
            'deposit': 'deposit',
            'deposit_exchange': 'depositExchange',
            'withdraw': 'withdraw',
            'withdraw_exchange': 'withdrawExchange',
            'transactions': 'transactions',
            'transaction': 'transaction',
            'patch_transaction': 'patchTransaction',
            'fee_endpoint': 'fee'
        }
        deposit_param_map = {
            'asset_code': 'assetCode',
            'memo_type': 'memoType',
            'email_address': 'emailAddress',
            'wallet_name': 'walletName',
            'wallet_url': 'walletUrl',
            'on_change_callback': 'onChangeCallback',
            'country_code': 'countryCode',
            'claimable_balance_supported': 'claimableBalanceSupported',
            'customer_id': 'customerId',
            'location_id': 'locationId'
        }
        withdraw_param_map = {
            'asset_code': 'assetCode',
            'dest_extra': 'destExtra',
            'memo_type': 'memoType',
            'wallet_name': 'walletName',
            'wallet_url': 'walletUrl',
            'on_change_callback': 'onChangeCallback',
            'country_code': 'countryCode',
            'refund_memo': 'refundMemo',
            'refund_memo_type': 'refundMemoType',
            'customer_id': 'customerId',
            'location_id': 'locationId'
        }
        deposit_response_map = {
            'min_amount': 'minAmount',
            'max_amount': 'maxAmount',
            'fee_fixed': 'feeFixed',
            'fee_percent': 'feePercent',
            'extra_info': 'extraInfo'
        }
        withdraw_response_map = dict(deposit_response_map, account_id='accountId', memo_type='memoType')
        transaction_field_map = {
            'status_eta': 'statusEta',
            'amount_in': 'amountIn',
            'amount_out': 'amountOut',
            'amount_fee': 'amountFee',
            'started_at': 'startedAt',
            'completed_at': 'completedAt',
            'stellar_transaction_id': 'stellarTransactionId',
            'external_transaction_id': 'externalTransactionId'
        }
        # InfoResponse properties that hold each SEP info response field.
        info_response_map = {
            'deposit': 'depositAssets',
            'deposit-exchange': 'depositExchangeAssets',
            'withdraw': 'withdrawAssets',
            'withdraw-exchange': 'withdrawExchangeAssets',
            'fee': 'feeInfo',
            'transactions': 'transactionsInfo',
            'transaction': 'transactionInfo',
            'features': 'featureFlags'
        }

        def endpoints(section_key: str) -> Dict[str, Any]:
            return map_features(sections.get(section_key, []), endpoint_map, transfer_service_methods,
                                'sdk_method')

        # AnchorTransaction holds every status value in its status property.
        has_status_field = 'status' in class_members(classes, 'properties', 'AnchorTransaction')

        return {
            'info_endpoint': endpoints('info_endpoint'),
            'deposit_endpoints': endpoints('deposit_endpoints'),
            'withdraw_endpoints': endpoints('withdraw_endpoints'),
            'transaction_endpoints': endpoints('transaction_endpoints'),
            'fee_endpoint': endpoints('fee_endpoint'),
            'deposit_request_parameters': map_properties(
                sections.get('deposit_request_parameters', []), deposit_param_map, classes,
                'DepositRequest'),
            'withdraw_request_parameters': map_properties(
                sections.get('withdraw_request_parameters', []), withdraw_param_map, classes,
                'WithdrawRequest'),
            'deposit_response_fields': map_properties(
                sections.get('deposit_response_fields', []), deposit_response_map, classes,
                'DepositResponse'),
            'withdraw_response_fields': map_properties(
                sections.get('withdraw_response_fields', []), withdraw_response_map, classes,
                'WithdrawResponse'),
            'transaction_status_values': {
                feature['name']: feature_entry(feature, has_status_field, 'sdk_property', 'status')
                for feature in sections.get('transaction_status_values', [])
            },
            'transaction_fields': map_properties(
                sections.get('transaction_fields', []), transaction_field_map, classes,
                'AnchorTransaction'),
            'info_response_fields': map_properties(
                sections.get('info_response_fields', []), info_response_map, classes, 'InfoResponse'),
        }

    def analyze_sep_07(self) -> Dict[str, Any]:
        """Analyze SEP-07 (URI Scheme to facilitate delegated signing) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_07_features)

    def map_sep_07_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-07 URI scheme requirements."""
        sections = definition_sections(sep_definition, 'uri_features')
        all_methods = class_members(classes, 'methods')
        # The parameter name constants are static fields.
        all_constants = class_members(classes, 'properties')

        operation_map = {
            'tx': 'generateSignTransactionURI',
            'pay': 'generatePayOperationURI'
        }
        tx_param_constant_map = {
            'xdr': 'xdrParameterName',
            'replace': 'replaceParameterName',
            'callback': 'callbackParameterName',
            'pubkey': 'publicKeyParameterName',
            'chain': 'chainParameterName'
        }
        pay_param_constant_map = {
            'destination': 'destinationParameterName',
            'amount': 'amountParameterName',
            'asset_code': 'assetCodeParameterName',
            'asset_issuer': 'assetIssuerParameterName',
            'memo': 'memoParameterName',
            'memo_type': 'memoTypeParameterName'
        }
        common_param_constant_map = {
            'msg': 'messageParameterName',
            'network_passphrase': 'networkPassphraseParameterName',
            'origin_domain': 'originDomainParameterName',
            'signature': 'signatureParameterName'
        }
        # isValidSep7Url performs every validation.
        validation_method_map = {
            name: 'isValidSep7Url' for name in (
                'validate_uri_scheme', 'validate_operation_type', 'validate_xdr_parameter',
                'validate_destination_parameter', 'validate_stellar_address', 'validate_asset_code',
                'validate_memo_type', 'validate_memo_value', 'validate_message_length',
                'validate_origin_domain', 'validate_chain_nesting')
        }
        signature_method_map = {
            'sign_uri': 'addSignature',
            'verify_signature': 'verifySignature',
            'verify_signed_uri': 'isValidSep7SignedUrl'
        }

        return {
            'operations': map_features(
                sections.get('operations', []), operation_map, all_methods, 'sdk_method'),
            'tx_parameters': map_features(
                sections.get('tx_parameters', []), tx_param_constant_map, all_constants, 'sdk_constant'),
            'pay_parameters': map_features(
                sections.get('pay_parameters', []), pay_param_constant_map, all_constants,
                'sdk_constant'),
            'common_parameters': map_features(
                sections.get('common_parameters', []), common_param_constant_map, all_constants,
                'sdk_constant'),
            'validation_features': map_features(
                sections.get('validation_features', []), validation_method_map, all_methods,
                'sdk_method'),
            'signature_features': map_features(
                sections.get('signature_features', []), signature_method_map, all_methods,
                'sdk_method'),
        }

    def analyze_sep_30(self) -> Dict[str, Any]:
        """Analyze SEP-30 (Account Recovery) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_30_features)

    def map_sep_30_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-30 Account Recovery API requirements."""
        sections = definition_sections(sep_definition, 'api_features')
        recovery_service_methods = class_members(classes, 'methods', 'SEP30RecoveryService')
        class_names = {cls['name'] for cls in classes}
        request_properties = class_members(
            classes, 'properties', 'SEP30Request', 'SEP30RequestIdentity', 'SEP30AuthMethod')

        endpoint_map = {
            'register_account': 'registerAccount',
            'update_account': 'updateIdentitiesForAccount',
            'get_account': 'accountDetails',
            'delete_account': 'deleteAccount',
            'list_accounts': 'accounts',
            'sign_transaction': 'signTransaction'
        }
        error_code_map = {
            400: 'SEP30BadRequestResponseException',
            401: 'SEP30UnauthorizedResponseException',
            404: 'SEP30NotFoundResponseException',
            409: 'SEP30ConflictResponseException'
        }

        # transaction and after are parameters of signTransaction and accounts,
        # not request class properties; both count as implemented.
        request_fields = {}
        for feature in sections.get('request_fields', []):
            sdk_property = {'auth_methods': 'authMethods'}.get(feature['name'], feature['name'])
            request_fields[feature['name']] = feature_entry(
                feature,
                feature['name'] in ('transaction', 'after') or sdk_property in request_properties,
                'sdk_property', sdk_property)

        exception_classes = {name for name in class_names if 'Exception' in name and 'SEP30' in name}
        error_codes = {}
        for feature in sections.get('error_codes', []):
            exception_class = error_code_map.get(feature.get('code', 0))
            error_codes[str(feature.get('code', 0))] = dict(
                feature_entry(feature, exception_class in exception_classes, 'sdk_exception',
                              exception_class),
                required=True)  # Every error code counts as required

        recovery_feature_impl = {
            'multi_party_recovery': 'SEP30RecoveryService' in class_names,
            'flexible_auth_methods': 'SEP30AuthMethod' in class_names,
            'transaction_signing': 'signTransaction' in recovery_service_methods,
            'account_sharing': 'accounts' in recovery_service_methods,
            'identity_roles': 'role' in request_properties,
            'pagination': True,  # The after parameter of accounts pages the account list
        }
        recovery_features = {
            feature['name']: {
                'required': feature.get('required', False),
                'implemented': recovery_feature_impl.get(feature['name'], False),
                'description': feature.get('description', '')
            }
            for feature in sections.get('recovery_features', [])
        }

        authentication = {}
        if 'authentication' in sections:
            # Every SEP30RecoveryService request sends the JWT in the Authorization header.
            authentication['jwt_token'] = {
                'required': True,
                'implemented': True,
                'description': 'JWT token authentication via Authorization header'
            }

        return {
            'api_endpoints': map_features(
                sections.get('api_endpoints', []), endpoint_map, recovery_service_methods,
                'sdk_method'),
            'request_fields': request_fields,
            'response_fields': map_properties(
                sections.get('response_fields', []), {'network_passphrase': 'networkPassphrase'},
                classes, 'SEP30AccountResponse', 'SEP30AccountsResponse', 'SEP30ResponseIdentity',
                'SEP30ResponseSigner', 'SEP30SignatureResponse'),
            'error_codes': error_codes,
            'recovery_features': recovery_features,
            'authentication': authentication,
        }

    def analyze_sep_38(self) -> Dict[str, Any]:
        """Analyze SEP-38 (Anchor RFQ API) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_38_features)

    def map_sep_38_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-38 Anchor RFQ API requirements."""
        sections = definition_sections(sep_definition, 'api_features')
        quote_service_methods = class_members(classes, 'methods', 'SEP38QuoteService')

        endpoint_map = {
            'info_endpoint': 'info',
            'prices_endpoint': 'prices',
            'price_endpoint': 'price',
            'post_quote_endpoint': 'postQuote',
            'get_quote_endpoint': 'getQuote'
        }
        prices_param_map = {
            'sell_asset': 'sellAsset',
            'sell_amount': 'sellAmount',
            'sell_delivery_method': 'sellDeliveryMethod',
            'buy_delivery_method': 'buyDeliveryMethod',
            'country_code': 'countryCode'
        }
        price_param_map = dict(prices_param_map, buy_asset='buyAsset', buy_amount='buyAmount')
        post_quote_map = dict(price_param_map, expire_after='expireAfter')
        quote_response_map = {
            'expires_at': 'expiresAt',
            'total_price': 'totalPrice',
            'sell_asset': 'sellAsset',
            'sell_amount': 'sellAmount',
            'buy_asset': 'buyAsset',
            'buy_amount': 'buyAmount'
        }

        def method_parameters(section_key: str, sdk_method: str,
                              name_map: Dict[str, str]) -> Dict[str, Any]:
            """The method takes each parameter as an argument; all count once it exists."""
            has_method = sdk_method in quote_service_methods
            return {
                feature['name']: feature_entry(
                    feature, has_method, 'sdk_property', name_map.get(feature['name'], feature['name']))
                for feature in sections.get(section_key, [])
            }

        result = {
            key: map_features(sections.get(key, []), endpoint_map, quote_service_methods, 'sdk_method')
            for key in ('info_endpoint', 'prices_endpoint', 'price_endpoint', 'post_quote_endpoint',
                        'get_quote_endpoint')
        }
        result.update({
            'info_response_fields': map_properties(
                sections.get('info_response_fields', []), {}, classes, 'SEP38InfoResponse'),
            'asset_fields': map_properties(
                sections.get('asset_fields', []),
                {'sell_delivery_methods': 'sellDeliveryMethods',
                 'buy_delivery_methods': 'buyDeliveryMethods',
                 'country_codes': 'countryCodes'},
                classes, 'SEP38Asset'),
            'delivery_method_fields': map_properties(
                sections.get('delivery_method_fields', []), {}, classes,
                'Sep38SellDeliveryMethod', 'Sep38BuyDeliveryMethod'),
            'prices_request_parameters': method_parameters(
                'prices_request_parameters', 'prices', prices_param_map),
            'prices_response_fields': map_properties(
                sections.get('prices_response_fields', []), {'buy_assets': 'buyAssets'}, classes,
                'SEP38PricesResponse'),
            'buy_asset_fields': map_properties(
                sections.get('buy_asset_fields', []), {}, classes, 'SEP38BuyAsset'),
            'price_request_parameters': method_parameters(
                'price_request_parameters', 'price', price_param_map),
            'price_response_fields': map_properties(
                sections.get('price_response_fields', []),
                {'total_price': 'totalPrice', 'sell_amount': 'sellAmount', 'buy_amount': 'buyAmount'},
                classes, 'SEP38PriceResponse'),
            'post_quote_request_fields': map_properties(
                sections.get('post_quote_request_fields', []), post_quote_map, classes,
                'SEP38PostQuoteRequest'),
            'quote_response_fields': map_properties(
                sections.get('quote_response_fields', []), quote_response_map, classes,
                'SEP38QuoteResponse'),
            'fee_fields': map_properties(sections.get('fee_fields', []), {}, classes, 'SEP38Fee'),
            'fee_details_fields': map_properties(
                sections.get('fee_details_fields', []), {}, classes, 'SEP38FeeDetails'),
        })
        return result

    def analyze_sep_24(self) -> Dict[str, Any]:
        """Analyze SEP-24 (Hosted Deposit and Withdrawal) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_24_features)

    def map_sep_24_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-24 Hosted Deposit/Withdrawal API requirements."""
        sections = definition_sections(sep_definition, 'api_features')
        transfer_service_methods = class_members(classes, 'methods', 'TransferServerSEP24Service')

        endpoint_map = {
            'info_endpoint': 'info',
            'interactive_deposit': 'deposit',
            'interactive_withdraw': 'withdraw',
            'transactions': 'transactions',
            'transaction': 'transaction',
            'fee_endpoint': 'fee'
        }
        request_param_map = {
            'asset_code': 'assetCode',
            'asset_issuer': 'assetIssuer',
            'quote_id': 'quoteId',
            'memo_type': 'memoType',
            'wallet_name': 'walletName',
            'wallet_url': 'walletUrl'
        }
        transaction_field_map = {
            'status_eta': 'statusEta',
            'kyc_verified': 'kycVerified',
            'more_info_url': 'moreInfoUrl',
            'amount_in': 'amountIn',
            'amount_in_asset': 'amountInAsset',
            'amount_out': 'amountOut',
            'amount_out_asset': 'amountOutAsset',
            'amount_fee': 'amountFee',
            'amount_fee_asset': 'amountFeeAsset',
            'quote_id': 'quoteId',
            'started_at': 'startedAt',
            'completed_at': 'completedAt',
            'updated_at': 'updatedAt',
            'user_action_required_by': 'userActionRequiredBy',
            'stellar_transaction_id': 'stellarTransactionId',
            'external_transaction_id': 'externalTransactionId',
            'deposit_memo': 'depositMemo',
            'deposit_memo_type': 'depositMemoType',
            'claimable_balance_id': 'claimableBalanceId',
            'withdraw_anchor_account': 'withdrawAnchorAccount',
            'withdraw_memo': 'withdrawMemo',
            'withdraw_memo_type': 'withdrawMemoType'
        }
        asset_field_map = {
            'min_amount': 'minAmount',
            'max_amount': 'maxAmount',
            'fee_fixed': 'feeFixed',
            'fee_percent': 'feePercent',
            'fee_minimum': 'feeMinimum'
        }

        def endpoints(section_key: str) -> Dict[str, Any]:
            return map_features(sections.get(section_key, []), endpoint_map, transfer_service_methods,
                                'sdk_method')

        def fields(section_key: str, name_map: Dict[str, str], class_name: str) -> Dict[str, Any]:
            return map_properties(sections.get(section_key, []), name_map, classes, class_name)

        return {
            'info_endpoint': endpoints('info_endpoint'),
            'interactive_deposit_endpoint': endpoints('interactive_deposit_endpoint'),
            'interactive_withdraw_endpoint': endpoints('interactive_withdraw_endpoint'),
            'transaction_endpoints': endpoints('transaction_endpoints'),
            'fee_endpoint': endpoints('fee_endpoint'),
            'deposit_request_parameters': fields(
                'deposit_request_parameters',
                dict(request_param_map, source_asset='sourceAsset',
                     claimable_balance_supported='claimableBalanceSupported'),
                'SEP24DepositRequest'),
            'withdraw_request_parameters': fields(
                'withdraw_request_parameters',
                dict(request_param_map, destination_asset='destinationAsset'),
                'SEP24WithdrawRequest'),
            'interactive_response_fields': fields(
                'interactive_response_fields', {}, 'SEP24InteractiveResponse'),
            # SEP24Transaction holds every status value in its status property.
            'transaction_status_values': {
                feature['name']: feature_entry(feature, True, 'sdk_property', 'status')
                for feature in sections.get('transaction_status_values', [])
            },
            'transaction_fields': fields('transaction_fields', transaction_field_map, 'SEP24Transaction'),
            'info_response_fields': fields(
                'info_response_fields',
                {'deposit': 'depositAssets', 'withdraw': 'withdrawAssets', 'fee': 'feeEndpointInfo',
                 'features': 'featureFlags'},
                'SEP24InfoResponse'),
            'deposit_asset_fields': fields('deposit_asset_fields', asset_field_map, 'SEP24DepositAsset'),
            'withdraw_asset_fields': fields('withdraw_asset_fields', asset_field_map, 'SEP24WithdrawAsset'),
            'feature_flags_fields': fields(
                'feature_flags_fields',
                {'account_creation': 'accountCreation', 'claimable_balances': 'claimableBalances'},
                'FeatureFlags'),
            'fee_endpoint_fields': fields(
                'fee_endpoint_fields', {'authentication_required': 'authenticationRequired'},
                'FeeEndpointInfo'),
        }

    def analyze_sep_08(self) -> Dict[str, Any]:
        """Analyze SEP-08 (Regulated Assets) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_08_features)

    def map_sep_08_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-08 Regulated Assets API requirements."""
        sections = definition_sections(sep_definition, 'api_features')
        regulated_assets_methods = class_members(classes, 'methods', 'RegulatedAssetsService')
        class_names = {cls['name'] for cls in classes}

        status_class_map = {
            'success': 'PostTransactionSuccess',
            'revised': 'PostTransactionRevised',
            'pending': 'PostTransactionPending',
            'action_required': 'PostTransactionActionRequired',
            'rejected': 'PostTransactionRejected'
        }

        def response_fields(section_key: str, class_name: str,
                            name_map: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
            """The response class itself stands for the status field."""
            properties = class_members(classes, 'properties', class_name)
            entries = {}
            for feature in sections.get(section_key, []):
                sdk_property = (name_map or {}).get(feature['name'], feature['name'])
                implemented_in_sdk = (class_name in class_names if feature['name'] == 'status'
                                      else sdk_property in properties)
                entries[feature['name']] = feature_entry(
                    feature, implemented_in_sdk, 'sdk_property', sdk_property)
            return entries

        # postAction covers both action URL requests; PostActionDone and
        # PostActionNextUrl are its two responses.
        has_post_action = 'postAction' in regulated_assets_methods
        action_handling = {
            'action_url_get': (has_post_action, None),
            'action_url_post': (has_post_action, 'postAction'),
            'action_url_post_response_no_further_action': ('PostActionDone' in class_names, 'PostActionDone'),
            'action_url_post_response_follow_next_url': (
                'PostActionNextUrl' in class_names, 'PostActionNextUrl'),
        }

        action_url_handling = {}
        for feature in sections.get('action_url_handling', []):
            is_implemented, reference = action_handling.get(feature['name'], (False, None))
            action_url_handling[feature['name']] = feature_entry(
                feature, is_implemented, 'sdk_method_or_class', reference)

        # regulated is a CurrencyInfo field of the SEP-01 stellar.toml, which
        # the SDK parses; it counts as implemented without a RegulatedAsset property.
        stellar_toml_fields = map_properties(
            sections.get('stellar_toml_fields', []),
            {'approval_server': 'approvalServer', 'approval_criteria': 'approvalCriteria'},
            classes, 'RegulatedAsset')
        for name, entry in stellar_toml_fields.items():
            if name == 'regulated' and not entry['implemented']:
                entry.update(implemented=True, sdk_property='CurrencyInfo.regulated')

        has_post_transaction = 'postTransaction' in regulated_assets_methods
        # authorizationRequired checks both authorization flags.
        has_auth_check = 'authorizationRequired' in regulated_assets_methods

        return {
            'approval_endpoint': map_features(
                sections.get('approval_endpoint', []), {'tx_approve': 'postTransaction'},
                regulated_assets_methods, 'sdk_method'),
            # postTransaction takes the tx parameter.
            'request_parameters': {
                feature['name']: feature_entry(feature, has_post_transaction, 'sdk_method', 'postTransaction')
                for feature in sections.get('request_parameters', [])
            },
            'response_statuses': map_features(
                sections.get('response_statuses', []), status_class_map, class_names, 'sdk_class'),
            'success_response_fields': response_fields('success_response_fields', 'PostTransactionSuccess'),
            'revised_response_fields': response_fields('revised_response_fields', 'PostTransactionRevised'),
            'pending_response_fields': response_fields('pending_response_fields', 'PostTransactionPending'),
            'action_required_response_fields': response_fields(
                'action_required_response_fields', 'PostTransactionActionRequired',
                {'action_url': 'actionUrl', 'action_method': 'actionMethod',
                 'action_fields': 'actionFields'}),
            'rejected_response_fields': response_fields('rejected_response_fields', 'PostTransactionRejected'),
            'action_url_handling': action_url_handling,
            'stellar_toml_fields': stellar_toml_fields,
            'authorization_flags': {
                feature['name']: feature_entry(feature, has_auth_check, 'sdk_method', 'authorizationRequired')
                for feature in sections.get('authorization_flags', [])
            },
        }

    def analyze_sep_45(self) -> Dict[str, Any]:
        """Analyze SEP-45 (Web Authentication for Contract Accounts) implementation."""
        return self._analyze_class_files(self.find_sep_files(), self.map_sep_45_features)

    def map_sep_45_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-45 authentication feature requirements."""
        all_methods = class_members(classes, 'methods')
        sections = definition_sections(sep_definition, 'auth_features')

        auth_endpoints_map = {
            'get_auth_challenge': 'getChallenge',
            'post_auth_token': 'sendSignedChallenge'
        }
        # jwtToken and signAuthorizationEntries exist but the method extractor
        # misses them (complex return types); fromDomain stands in for them.
        challenge_features_map = {
            'authorization_entry_decoding': 'decodeAuthorizationEntries',
            'authorization_entry_encoding': 'sendSignedChallenge',
            'contract_invocation_parsing': 'validateChallenge',
            'signature_expiration_ledger': 'fromDomain',  # jwtToken handles this via sorobanRpcUrl
            'auto_signature_expiration': 'fromDomain',  # jwtToken handles this via sorobanRpcUrl
            'nonce_consistency': 'validateChallenge',
            'server_entry_signing': 'validateChallenge',
            'client_entry_signing': 'fromDomain'  # signAuthorizationEntries called from jwtToken
        }
        jwt_features_map = {
            'jwt_token_response': 'sendSignedChallenge',
            'jwt_token_generation': None,  # Server-side only
            'complete_auth_flow': 'fromDomain'  # jwtToken - factory creates the object that has this
        }
        client_domain_features_map = {
            'client_domain_parameter': 'getChallenge',
            'client_domain_entry': 'fromDomain',  # signAuthorizationEntries handles this
            'client_domain_local_signing': 'fromDomain',  # signAuthorizationEntries handles this
            'client_domain_callback_signing': 'fromDomain',  # signAuthorizationEntries handles callback
            'client_domain_toml_lookup': 'fromDomain'  # jwtToken fetches from stellar.toml
        }
        validation_features_map = {
            'contract_address_validation': 'validateChallenge',
            'function_name_validation': 'validateChallenge',
            'sub_invocations_check': 'validateChallenge',
            'server_signature_verification': 'validateChallenge',
            'server_entry_presence': 'validateChallenge',
            'client_entry_presence': 'validateChallenge',
            'home_domain_validation': 'validateChallenge',
            'web_auth_domain_validation': 'validateChallenge',
            'account_validation': 'validateChallenge',
            'network_passphrase_validation': 'fromDomain'  # jwtToken validates this
        }
        exception_types_map = {
            'invalid_contract_address_exception': 'ContractChallengeValidationErrorInvalidContractAddress',
            'invalid_function_name_exception': 'ContractChallengeValidationErrorInvalidFunctionName',
            'sub_invocations_exception': 'ContractChallengeValidationErrorSubInvocationsFound',
            'invalid_server_signature_exception': 'ContractChallengeValidationErrorInvalidServerSignature',
            'missing_server_entry_exception': 'ContractChallengeValidationErrorMissingServerEntry',
            'missing_client_entry_exception': 'ContractChallengeValidationErrorMissingClientEntry',
            'challenge_request_error_exception': 'ContractChallengeRequestErrorResponse',
            'submit_challenge_error_exception': 'SubmitContractChallengeErrorResponseException'
        }

        return {
            'authentication_endpoints': map_features(
                sections.get('auth_endpoints', []), auth_endpoints_map, all_methods, 'sdk_method'),
            'challenge_features': map_features(
                sections.get('challenge_features', []), challenge_features_map, all_methods,
                'sdk_method'),
            'jwt_token_features': map_client_features(
                sections.get('jwt_token', []), jwt_features_map, all_methods),
            'client_domain_features': map_features(
                sections.get('client_domain', []), client_domain_features_map, all_methods,
                'sdk_method'),
            'validation_features': map_features(
                sections.get('validation', []), validation_features_map, all_methods, 'sdk_method'),
            'exception_types': map_features(
                sections.get('exception_types', []), exception_types_map,
                {cls['name'] for cls in classes}, 'sdk_method'),
        }

    def analyze_sep_46(self) -> Dict[str, Any]:
        """Analyze SEP-46 (Contract Meta) implementation."""
        parser_path = self.sdk_path / 'lib' / 'src' / 'soroban' / 'soroban_contract_parser.dart'
        return self._analyze_class_files(
            [parser_path] if parser_path.exists() else [], self.map_sep_46_features,
            reason='No SEP-46 implementation files found (soroban_contract_parser.dart)')

    def map_sep_46_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-46 contract meta feature requirements."""
        sections = definition_sections(sep_definition, 'contract_meta_features')
        all_methods = class_members(classes, 'methods')

        metadata_storage_map = {
            'contractmetav0_section': '_parseMeta',  # Parses contractmetav0 section
            'multiple_entries_single_section': '_parseMeta',  # Handles multiple entries
            'multiple_sections': '_parseMeta'  # Sequential interpretation
        }
        encoding_format_map = {
            'scmetaentry_xdr': '_parseMeta',  # Uses XdrSCMetaEntry
            'binary_stream_encoding': '_parseMeta',  # Decodes binary stream
            'key_value_pairs': 'metaEntries'  # Returns Map<String, String>
        }
        implementation_support_map = {
            'parse_contract_meta': 'parseContractByteCode',  # Main parsing method
            'extract_meta_entries': '_parseMeta',  # Extracts meta entries
            'decode_scmetaentry': '_parseMeta'  # Decodes XdrSCMetaEntry
        }

        return {
            'metadata_storage': map_features(
                sections.get('metadata_storage', []), metadata_storage_map, all_methods, 'sdk_method'),
            'encoding_format': map_features(
                sections.get('encoding_format', []), encoding_format_map,
                all_methods | class_members(classes, 'properties'), 'sdk_method'),
            'implementation_support': map_features(
                sections.get('implementation_support', []), implementation_support_map, all_methods,
                'sdk_method'),
        }

    def analyze_sep_47(self) -> Dict[str, Any]:
        """Analyze SEP-47 (Contract Interface Discovery) implementation."""
        parser_path = self.sdk_path / 'lib' / 'src' / 'soroban' / 'soroban_contract_parser.dart'
        return self._analyze_class_files(
            [parser_path] if parser_path.exists() else [], self.map_sep_47_features,
            reason='No SEP-47 implementation files found (soroban_contract_parser.dart)')

    def map_sep_47_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """Map SDK implementation to SEP-47 interface discovery feature requirements."""
        sections = definition_sections(sep_definition, 'contract_meta_features')
        all_methods = class_members(classes, 'methods')

        sep_declaration_map = {
            'sep_meta_key': '_parseSupportedSeps',  # Looks for "sep" key in meta
            'comma_separated_list': '_parseSupportedSeps',  # Splits by comma
            'multiple_sep_entries': '_parseSupportedSeps'  # Could handle multiple entries
        }
        meta_entry_format_map = {
            'sep_number_format': '_parseSupportedSeps',  # Parses SEP numbers
            'whitespace_handling': '_parseSupportedSeps',  # Uses trim()
            'empty_value_handling': '_parseSupportedSeps'  # Handles empty values
        }
        implementation_support_map = {
            'parse_supported_seps': '_parseSupportedSeps',  # Static parsing method
            'expose_supported_seps': 'supportedSeps',  # Property on SorobanContractInfo
            'validate_sep_format': '_parseSupportedSeps'  # Filters invalid entries
        }

        return {
            'sep_declaration': map_features(
                sections.get('sep_declaration', []), sep_declaration_map, all_methods, 'sdk_method'),
            'meta_entry_format': map_features(
                sections.get('meta_entry_format', []), meta_entry_format_map, all_methods, 'sdk_method'),
            'implementation_support': map_features(
                sections.get('implementation_support', []), implementation_support_map,
                all_methods | class_members(classes, 'properties'), 'sdk_method'),
        }

    def analyze_sep_48(self) -> Dict[str, Any]:
        """
        Analyze SEP-48 (Smart Contract Specifications) implementation.

        SEP-48 spans the contract parser, contract_spec.dart and the XDR files
        of the contract spec types.
        """
        soroban_dir = self.sdk_path / 'lib' / 'src' / 'soroban'
        xdr_dir = self.sdk_path / 'lib' / 'src' / 'xdr'
        candidates = [soroban_dir / 'soroban_contract_parser.dart', soroban_dir / 'contract_spec.dart'] + [
            xdr_dir / name for name in (
                'xdr_sc_spec_entry.dart', 'xdr_sc_spec_type_def.dart',
                'xdr_sc_spec_type_option.dart', 'xdr_sc_spec_type_result.dart',
                'xdr_sc_spec_type_vec.dart', 'xdr_sc_spec_type_map.dart',
                'xdr_sc_spec_type_tuple.dart', 'xdr_sc_spec_type_bytes_n.dart',
                'xdr_sc_spec_type_udt.dart', 'xdr_sc_env_meta_entry.dart',
                'xdr_sc_meta_entry.dart',
            )
        ]
        return self._analyze_class_files(
            [path for path in candidates if path.exists()], self.map_sep_48_features,
            reason='No SEP-48 implementation files found (soroban_contract_parser.dart, '
                   'contract_spec.dart, or XDR contract types)')

    def map_sep_48_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-48 contract specification feature requirements.

        A feature maps to a method, property or class name.
        """
        sections = definition_sections(sep_definition, 'contract_spec_features')
        available = (class_members(classes, 'methods') | class_members(classes, 'properties')
                     | {cls['name'] for cls in classes})

        # parseContractByteCode parses all three custom sections into SorobanContractInfo.
        wasm_section_map = {
            'contractspecv0_section': 'specEntries',  # Proves contractspecv0 was parsed (stores spec entries)
            'contractenvmetav0_section': 'envProtocolVersion',  # Proves contractenvmetav0 was parsed (stores protocol version)
            'contractmetav0_section': 'metaEntries',  # Proves contractmetav0 was parsed (stores meta entries)
            'xdr_binary_encoding': 'decode'  # XDR decode method available
        }
        # _parseContractSpec checks the discriminant of all six entry types.
        entry_types_map = {
            'function_specs': 'specEntries',  # SC_SPEC_ENTRY_FUNCTION_V0 checked in _parseContractSpec
            'struct_specs': 'specEntries',  # SC_SPEC_ENTRY_UDT_STRUCT_V0 checked in _parseContractSpec
            'union_specs': 'specEntries',  # SC_SPEC_ENTRY_UDT_UNION_V0 checked in _parseContractSpec
            'enum_specs': 'specEntries',  # SC_SPEC_ENTRY_UDT_ENUM_V0 checked in _parseContractSpec
            'error_enum_specs': 'specEntries',  # SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0 checked in _parseContractSpec
            'event_specs': 'specEntries'  # SC_SPEC_ENTRY_EVENT_V0 checked in _parseContractSpec
        }
        type_system_primitive_map = {
            'boolean_type': 'XdrSCSpecTypeDef',  # Supports boolean via XDR
            'void_type': 'XdrSCSpecTypeDef',  # Supports void via XDR
            'numeric_types': 'XdrSCSpecTypeDef',  # Supports all numeric types via XDR
            'timepoint_duration': 'XdrSCSpecTypeDef',  # Supports timepoint/duration via XDR
            'bytes_string_symbol': 'XdrSCSpecTypeDef',  # Supports bytes/string/symbol via XDR
            'address_type': 'XdrSCSpecTypeDef'  # Supports address via XDR
        }
        type_system_compound_map = {
            'option_type': 'XdrSCSpecTypeOption',  # Option<T> type
            'result_type': 'XdrSCSpecTypeResult',  # Result<T, E> type
            'vector_type': 'XdrSCSpecTypeVec',  # Vec<T> type
            'map_type': 'XdrSCSpecTypeMap',  # Map<K, V> type
            'tuple_type': 'XdrSCSpecTypeTuple',  # Tuple types
            'bytes_n_type': 'XdrSCSpecTypeBytesN',  # Fixed-length bytes
            'user_defined_type': 'XdrSCSpecTypeUDT'  # User-defined types
        }
        parsing_support_map = {
            'parse_contract_bytecode': 'parseContractByteCode',  # Main parsing method
            'extract_spec_entries': 'specEntries',  # Property that stores extracted entries
            'parse_environment_meta': 'envProtocolVersion',  # Property storing parsed env protocol version
            'parse_contract_meta': 'metaEntries'  # Property storing parsed meta
        }
        xdr_support_map = {
            'decode_scspecentry': 'XdrSCSpecEntry',
            'decode_scspectypedef': 'XdrSCSpecTypeDef',
            'decode_scenvmetaentry': 'XdrSCEnvMetaEntry',
            'decode_scmetaentry': 'XdrSCMetaEntry'
        }

        return {
            key: map_features(sections.get(key, []), name_map, available, 'sdk_method')
            for key, name_map in (
                ('wasm_section', wasm_section_map),
                ('entry_types', entry_types_map),
                ('type_system_primitive', type_system_primitive_map),
                ('type_system_compound', type_system_compound_map),
                ('parsing_support', parsing_support_map),
                ('xdr_support', xdr_support_map),
            )
        }

    @staticmethod
    def sep_51_detections() -> Dict[str, Tuple[str, Tuple[str, ...], str]]:
        """
        Locate each SEP-51 mapping rule in the SDK source.

        Maps a feature name to the file that carries the rule, the source
        fragments that must all be present for the rule to count as
        implemented, and the SDK symbol to report. The runtime helper holds the
        rules that are stated once; a generated type is named where the rule is
        only observable at a field or arm.

        Returns:
            Dictionary of feature name to (relative path, probes, SDK symbol)
        """
        helper = 'lib/src/xdr/xdr_json_helper.dart'

        return {
            # XDR data types
            'integer_32': (
                'lib/src/xdr/xdr_int32.dart',
                ('XdrJsonHelper.int32(', 'XdrJsonHelper.readInt32('),
                'XdrInt32.toXdrJsonValue / fromXdrJsonValue',
            ),
            'unsigned_integer_32': (
                'lib/src/xdr/xdr_uint32.dart',
                ('XdrJsonHelper.uint32(', 'XdrJsonHelper.readUint32('),
                'XdrUint32.toXdrJsonValue / fromXdrJsonValue',
            ),
            'hyper_integer': (
                'lib/src/xdr/xdr_int64.dart',
                ('XdrJsonHelper.int64(', 'XdrJsonHelper.readInt64('),
                'XdrInt64.toXdrJsonValue / fromXdrJsonValue',
            ),
            'unsigned_hyper_integer': (
                'lib/src/xdr/xdr_uint64.dart',
                ('XdrJsonHelper.uint64(', 'XdrJsonHelper.readUint64('),
                'XdrUint64.toXdrJsonValue / fromXdrJsonValue',
            ),
            'hyper_number_input': (
                helper,
                ('static BigInt readInt64(', '} else if (value is num) {',
                 '_maxExactJsonInteger'),
                'XdrJsonHelper.readInt64 (JSON number accepted below 2^53)',
            ),
            'unsigned_hyper_number_input': (
                helper,
                ('static BigInt readUint64(', '} else if (value is num) {',
                 '_maxExactJsonInteger'),
                'XdrJsonHelper.readUint64 (JSON number accepted below 2^53)',
            ),
            'boolean': (
                'lib/src/xdr/xdr_sc_val_base.dart',
                ('XdrJsonHelper.boolean(_b!)', 'XdrJsonHelper.readBoolean('),
                'XdrSCVal bool arm',
            ),
            'opaque_fixed': (
                'lib/src/xdr/xdr_hash.dart',
                ("XdrJsonHelper.hex(_hash, type: 'XdrHash')",
                 'expectedLength: 32'),
                'XdrHash.toXdrJsonValue / fromXdrJsonValue',
            ),
            'opaque_variable': (
                'lib/src/xdr/xdr_data_value.dart',
                ("XdrJsonHelper.hex(_dataValue, type: 'XdrDataValue'",
                 "XdrJsonHelper.readHex(value, type: 'XdrDataValue'"),
                'XdrDataValue.toXdrJsonValue / fromXdrJsonValue',
            ),
            'string_escaping': (
                helper,
                ('static String escapedString(',
                 'static String readEscapedString(',
                 r"buffer.write(r'\x');"),
                'XdrJsonHelper.escapedString / readEscapedString',
            ),
            'array_fixed': (
                'lib/src/xdr/xdr_ledger_header.dart',
                ("key: 'skip_list',", 'fixedLength: 4,'),
                'XdrLedgerHeader.skipList (readArray fixedLength)',
            ),
            'array_variable': (
                'lib/src/xdr/xdr_account_entry_v2.dart',
                ('XdrJsonHelper.array<XdrAccountID?>(',
                 'XdrJsonHelper.readArray('),
                'XdrAccountEntryV2.signerSponsoringIDs',
            ),
            'enum': (
                'lib/src/xdr/xdr_asset_type.dart',
                ("return 'credit_alphanum4';", "case 'credit_alphanum4':"),
                'XdrAssetType.toXdrJsonValue / fromXdrJsonValue',
            ),
            'struct': (
                'lib/src/xdr/xdr_time_bounds.dart',
                ("'min_time': _minTime.toXdrJsonValue(),",
                 "allowedKeys: const <String>{'min_time', 'max_time'},"),
                'XdrTimeBounds.toXdrJsonValue / fromXdrJsonValue',
            ),
            'union_void_arm': (
                'lib/src/xdr/xdr_asset.dart',
                ("return 'native';", "case 'native':"),
                'XdrAsset native arm',
            ),
            'union_value_arm': (
                'lib/src/xdr/xdr_asset.dart',
                ("'credit_alphanum4': _alphaNum4!.toXdrJsonValue(),",
                 'XdrJsonHelper.readSingleKeyObject('),
                'XdrAsset credit_alphanum4 arm',
            ),
            'union_integer_cases': (
                'lib/src/xdr/xdr_extension_point.dart',
                ("return 'v0';", "case 'v0':"),
                'XdrExtensionPoint.toXdrJsonValue / fromXdrJsonValue',
            ),
            'void': (
                'lib/src/xdr/xdr_sc_val_base.dart',
                ("return 'void';", "case 'void':"),
                'XdrSCVal void arm (no value emitted)',
            ),
            'optional': (
                'lib/src/xdr/xdr_contract_event.dart',
                ("'contract_id': _hash == null ? null :",),
                'XdrContractEvent.contractID (null when absent)',
            ),

            # Stellar-specific types
            'sc_address': (
                'lib/src/xdr/xdr_sc_address_base.dart',
                ('StrKey.encodeContractId(_contractId!.hash)',
                 'StrKey.encodeLiquidityPoolId(_liquidityPoolId!.hash)',
                 "XdrJsonHelper.readStrKeyPrefix(value, type: 'XdrSCAddress')"),
                'XdrSCAddress.toXdrJsonValue / fromXdrJsonValueAs',
            ),
            'account_id': (
                'lib/src/xdr/xdr_account_id_base.dart',
                ('_accountID.toXdrJsonValue()',
                 'XdrPublicKey.fromXdrJsonValue(value)'),
                'XdrAccountID (delegates to XdrPublicKey)',
            ),
            'contract_id': (
                'lib/src/xdr/xdr_contract_event.dart',
                ('StrKey.encodeContractId(',
                 'decode: StrKey.decodeContractId,'),
                'XdrContractEvent.contractID (C strkey)',
            ),
            'muxed_account': (
                'lib/src/xdr/xdr_muxed_account.dart',
                ('StrKey.encodeStellarAccountId(_ed25519!.uint256)',
                 '_med25519!.toXdrJsonValue()',
                 "XdrJsonHelper.readStrKeyPrefix(value, type: 'XdrMuxedAccount')"),
                'XdrMuxedAccount.toXdrJsonValue / fromXdrJsonValue',
            ),
            'muxed_account_med25519': (
                'lib/src/xdr/xdr_muxed_account_med25519_base.dart',
                ('StrKey.encodeStellarMuxedAccountId(',
                 'decode: StrKey.decodeStellarMuxedAccountId,'),
                'XdrMuxedAccountMed25519.toXdrJsonValue / fromXdrJsonValue',
            ),
            'muxed_ed25519_account': (
                'lib/src/xdr/xdr_sc_address_base.dart',
                ('_muxedAccount!.toXdrJsonValue()',
                 'XdrMuxedAccountMed25519.fromXdrJsonValue('),
                'XdrSCAddress muxed arm (XdrMuxedAccountMed25519)',
            ),
            'pool_id': (
                'lib/src/xdr/xdr_trustline_asset_base.dart',
                ('StrKey.encodeLiquidityPoolId(_liquidityPoolID!.hash)',
                 'decode: StrKey.decodeLiquidityPoolId,'),
                'XdrTrustlineAsset pool_share arm (L strkey)',
            ),
            'claimable_balance_id': (
                'lib/src/xdr/xdr_claimable_balance_id_base.dart',
                ('StrKey.encodeClaimableBalanceId(',
                 'decode: StrKey.decodeClaimableBalanceId,'),
                'XdrClaimableBalanceID.toXdrJsonValue / fromXdrJsonValue',
            ),
            'public_key': (
                'lib/src/xdr/xdr_public_key_base.dart',
                ('StrKey.encodeStellarAccountId(_ed25519!.uint256)',
                 'decode: StrKey.decodeStellarAccountId,'),
                'XdrPublicKey.toXdrJsonValue / fromXdrJsonValueAs',
            ),
            'node_id': (
                'lib/src/xdr/xdr_node_id.dart',
                ('_nodeID.toXdrJsonValue()',
                 'XdrPublicKey.fromXdrJsonValue(value)'),
                'XdrNodeID (delegates to XdrPublicKey)',
            ),
            'signer_key': (
                'lib/src/xdr/xdr_signer_key.dart',
                ('StrKey.encodeStellarAccountId(', 'StrKey.encodePreAuthTx(',
                 'StrKey.encodeSha256Hash(',
                 "XdrJsonHelper.readStrKeyPrefix(value, type: 'XdrSignerKey')"),
                'XdrSignerKey.toXdrJsonValue / fromXdrJsonValue',
            ),
            'signer_key_ed25519_signed_payload': (
                'lib/src/xdr/xdr_signed_payload.dart',
                ('XdrJsonHelper.checkSignedPayloadLength(',
                 'VersionByte.SIGNED_PAYLOAD',
                 'XdrJsonHelper.readSignedPayloadRegion('),
                'XdrSignedPayload.toXdrJsonValue / fromXdrJsonValue',
            ),
            'asset_code': (
                'lib/src/xdr/xdr_allow_trust_op_asset.dart',
                ('XdrJsonHelper.assetCode4(', 'XdrJsonHelper.assetCode12(',
                 'XdrJsonHelper.readAssetCode4(',
                 'XdrJsonHelper.readAssetCode12('),
                'XdrAllowTrustOpAsset (bare string by arm)',
            ),
            'asset_code_4': (
                helper,
                ('static String assetCode4(',
                 'static Uint8List readAssetCode4('),
                'XdrJsonHelper.assetCode4 / readAssetCode4',
            ),
            'asset_code_12': (
                helper,
                ('static String assetCode12(',
                 'static Uint8List readAssetCode12(',
                 '_assetCode12MinRendered = 5'),
                'XdrJsonHelper.assetCode12 / readAssetCode12',
            ),
            'int128_parts': (
                'lib/src/xdr/xdr_int128_parts_base.dart',
                ('XdrJsonHelper.partsToDecimalString(',
                 'XdrJsonHelper.decimalStringToParts('),
                'XdrInt128Parts.toXdrJsonValue / fromXdrJsonValue',
            ),
            'uint128_parts': (
                'lib/src/xdr/xdr_u_int128_parts_base.dart',
                ('XdrJsonHelper.partsToDecimalString(',
                 'XdrJsonHelper.decimalStringToParts('),
                'XdrUInt128Parts.toXdrJsonValue / fromXdrJsonValue',
            ),
            'int256_parts': (
                'lib/src/xdr/xdr_int256_parts_base.dart',
                ('XdrJsonHelper.partsToDecimalString(',
                 'XdrJsonHelper.decimalStringToParts('),
                'XdrInt256Parts.toXdrJsonValue / fromXdrJsonValue',
            ),
            'uint256_parts': (
                'lib/src/xdr/xdr_u_int256_parts_base.dart',
                ('XdrJsonHelper.partsToDecimalString(',
                 'XdrJsonHelper.decimalStringToParts('),
                'XdrUInt256Parts.toXdrJsonValue / fromXdrJsonValue',
            ),

            # JSON schema
            'schema_property': (
                helper,
                ('static Map<String, dynamic> stripSchema(',
                 "schemaKey = r'$schema'"),
                'XdrJsonHelper.stripSchema',
            ),
        }

    def analyze_sep_51(self) -> Dict[str, Any]:
        """
        Analyze SEP-51 (XDR-JSON) implementation.

        SEP-51 has no service package. Every rule the specification states once
        lives once in lib/src/xdr/xdr_json_helper.dart, and every generated XDR
        type carries toXdrJson, toXdrJsonValue, fromXdrJson and
        fromXdrJsonValue over it. Detection therefore runs against that runtime
        plus the generated types that exercise each mapping rule, rather than
        against a SEP source directory.

        Returns:
            Analysis results dictionary
        """
        helper_rel = 'lib/src/xdr/xdr_json_helper.dart'
        helper_path = self.sdk_path / helper_rel

        if not helper_path.exists():
            return {
                'implemented': False,
                'reason': f'No SEP-51 implementation file found ({helper_rel})'
            }

        detections = self.sep_51_detections()

        sources: Dict[str, str] = {}
        files: List[Path] = []
        for rel_path in sorted({entry[0] for entry in detections.values()}):
            path = self.sdk_path / rel_path
            if not path.exists():
                continue
            sources[rel_path] = path.read_text(encoding='utf-8')
            files.append(path)

        sep_definition = self._load_sep_definition()

        # Restrict reported classes to the SEP-51 runtime entry point. The
        # generated types are read for detection but each carries its own XDR
        # structure, not a SEP-51 surface of its own.
        all_classes = [
            cls for cls in self.extract_class_info(helper_path)
            if cls['name'] == 'XdrJsonHelper'
        ]
        for cls in all_classes:
            cls['documentation'] = (
                'Runtime for SEP-51 XDR-JSON encoding and decoding. Every '
                'generated XDR type carries toXdrJson, toXdrJsonValue, '
                'fromXdrJson and fromXdrJsonValue over it.'
            )

        implemented_features = self.map_sep_51_features(sources, sep_definition)

        return analysis_result(
            [str(f.relative_to(self.sdk_path)) for f in files], all_classes, implemented_features)

    def map_sep_51_features(self, sources: Dict[str, str],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map the SDK source to the SEP-51 mapping rules.

        Args:
            sources: Relative path to source text, for every probed file
            sep_definition: SEP-51 specification definition

        Returns:
            Dictionary mapping XDR-JSON features to implementation status
        """
        detections = self.sep_51_detections()

        def detect(name: str) -> Tuple[bool, Any]:
            entry = detections.get(name)
            if entry is None:
                return False, None
            rel_path, probes, sdk_symbol = entry
            content = sources.get(rel_path)
            if content is None:
                return False, None
            if all(probe in content for probe in probes):
                return True, sdk_symbol
            return False, None

        sections = definition_sections(sep_definition, 'xdr_json_features')
        implemented = {}
        for key in ('xdr_data_types', 'stellar_specific_types', 'json_schema'):
            entries = {}
            for feature in sections.get(key, []):
                is_implemented, reference = detect(feature['name'])
                entries[feature['name']] = feature_entry(feature, is_implemented, 'sdk_method', reference)
            implemented[key] = entries
        return implemented

    def analyze(self) -> Dict[str, Any]:
        """
        Analyze SEP implementation in Flutter SDK.

        Returns:
            Analysis results dictionary

        Raises:
            ValueError: If no analysis is defined for the SEP number.
        """
        analyze_sep = getattr(self, f'analyze_sep_{int(self.sep_number):02d}', None)
        if analyze_sep is None:
            raise ValueError(f"No analysis defined for SEP-{self.sep_number}")

        print(f"\n{Colors.CYAN}Analyzing SEP-{self.sep_number} implementation...{Colors.END}")
        self.analysis_data = analyze_sep()

        # Add metadata
        self.analysis_data['metadata'] = {
            'sep_number': self.sep_number,
            'analyzed_at': datetime.now().isoformat(),
            'sdk_path': str(self.sdk_path),
        }

        if self.analysis_data.get('implemented'):
            print(f"{Colors.GREEN}✓ Found {self.analysis_data.get('total_classes', 0)} classes{Colors.END}")
        else:
            print(f"{Colors.YELLOW}⚠ {self.analysis_data.get('reason', 'Not implemented')}{Colors.END}")

        return self.analysis_data

    def save_to_file(self, output_path: str) -> None:
        """
        Save analysis data to JSON file.

        Args:
            output_path: Path to output JSON file
        """
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(self.analysis_data, f, indent=2, ensure_ascii=False)

        print(f"{Colors.GREEN}✓ Saved to {output_path}{Colors.END}")

    def print_summary(self) -> None:
        """Print analysis summary"""
        if not self.analysis_data:
            print(f"{Colors.YELLOW}No analysis data available{Colors.END}")
            return

        print(f"\n{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.HEADER}SEP-{self.sep_number} Analysis Summary{Colors.END}")
        print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")

        if not self.analysis_data.get('implemented'):
            print(f"{Colors.YELLOW}Status: Not Implemented{Colors.END}")
            print(f"Reason: {self.analysis_data.get('reason', 'Unknown')}")
        else:
            print(f"{Colors.GREEN}Status: Implemented{Colors.END}\n")

            print(f"{Colors.BOLD}Files:{Colors.END} {len(self.analysis_data.get('files', []))}")
            for file in self.analysis_data.get('files', []):
                print(f"  - {file}")

            print(f"\n{Colors.BOLD}Classes:{Colors.END} {self.analysis_data.get('total_classes', 0)}")
            print(f"{Colors.BOLD}Methods:{Colors.END} {self.analysis_data.get('total_methods', 0)}")
            print(f"{Colors.BOLD}Properties:{Colors.END} {self.analysis_data.get('total_properties', 0)}")

        print(f"\n{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        sep_number = '0001'  # Default to SEP-01
        print(f"{Colors.YELLOW}No SEP number provided, using default: {sep_number}{Colors.END}")
    else:
        sep_number = sys.argv[1]

    print(f"\n{Colors.BOLD}{Colors.HEADER}Flutter SDK SEP Implementation Analyzer{Colors.END}")
    print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")

    # Define paths
    project_root = Path(__file__).parent.parent.parent.parent  # Go up to SDK root
    output_path = Path(__file__).parent.parent / 'data' / 'sep' / f'flutter_sep_{sep_number}_implementation.json'

    # Create analyzer
    analyzer = SEPAnalyzer(str(project_root), sep_number)

    try:
        # Analyze SEP implementation
        analyzer.analyze()

        # Save to file
        analyzer.save_to_file(str(output_path))

        # Print summary
        analyzer.print_summary()

        print(f"{Colors.GREEN}✓ SEP-{sep_number} analysis complete!{Colors.END}\n")
        return 0

    except Exception as e:
        print(f"\n{Colors.RED}✗ Error: {str(e)}{Colors.END}")
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    # Check if we're in a TTY (for colors)
    if not sys.stdout.isatty():
        Colors.disable()

    sys.exit(main())
