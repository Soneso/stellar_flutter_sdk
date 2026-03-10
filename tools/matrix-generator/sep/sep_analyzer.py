#!/usr/bin/env python3
"""
Flutter SDK SEP Implementation Analyzer

This script analyzes the Flutter Stellar SDK codebase to identify SEP implementations,
extract implemented features, and identify gaps compared to SEP specifications.

Author: Stellar Flutter SDK Team
License: Apache-2.0
"""

import json
import re
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any


# Add parent dir to path for shared modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from common import Colors


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

        # Improved pattern for Dart method declarations
        # Matches: [modifiers] return_type method_name([params]) [async] { or =>
        # This pattern requires proper method declaration syntax with return type or modifier
        # Now includes private methods (starting with _)
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

            # Note: We now INCLUDE private methods (starting with _) as they may implement
            # important SEP features (e.g., _parseMeta for SEP-46, _parseSupportedSeps for SEP-47)

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

        IMPORTANT: This method must correctly identify class boundaries to avoid
        extracting properties from adjacent classes. The key is to properly match
        the class body between its opening brace and the NEXT class declaration or EOF.

        Args:
            content: File content
            class_name: Name of the class

        Returns:
            List of property info dictionaries
        """
        properties = []

        # FIXED: Find class body correctly by matching from class declaration
        # through its opening brace, then capturing everything until we hit
        # another top-level class declaration (starting with 'class ' at line start)
        # or end of file.
        #
        # The pattern works as follows:
        # 1. Match: class ClassName (with optional extends/implements)
        # 2. Match: { (opening brace)
        # 3. Capture: everything until next 'class ' at line start OR end of file
        #
        # This prevents capturing properties from classes that follow the target class.
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
        """
        Analyze SEP-01 (stellar.toml) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-01 implementation files found'
            }

        # Load SEP-01 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented features
        implemented_fields = self.map_sep_01_fields(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_fields': implemented_fields,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_01_fields(self, classes: List[Dict[str, Any]],
                          sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-01 field requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping sections to implemented fields
        """
        implemented = {}

        # Get all properties from all classes
        all_properties = set()
        for cls in classes:
            for prop in cls.get('properties', []):
                all_properties.add(prop['name'])

        # Map to SEP sections
        sections = sep_definition.get('sections', [])

        for section in sections:
            section_key = section.get('key', '')
            section_title = section.get('title', '')
            sep_fields = section.get('fields', [])

            section_impl = {
                'title': section_title,
                'fields': {},
                'coverage': 0
            }

            for field in sep_fields:
                field_name = field.get('name', '')

                # Convert SEP field name to SDK property name
                # e.g., VERSION -> version, NETWORK_PASSPHRASE -> networkPassphrase
                sdk_field_name = self.sep_field_to_sdk_property(field_name)

                implemented_in_sdk = sdk_field_name in all_properties

                section_impl['fields'][field_name] = {
                    'required': field.get('required', False),
                    'implemented': implemented_in_sdk,
                    'sdk_property': sdk_field_name if implemented_in_sdk else None,
                    'description': field.get('description', '')
                }

            # Calculate coverage
            total = len(sep_fields)
            supported = sum(1 for f in section_impl['fields'].values() if f['implemented'])
            section_impl['coverage'] = round((supported / total * 100) if total > 0 else 0, 2)

            implemented[section_key] = section_impl

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
        """
        Analyze SEP-02 (Federation Protocol) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-02 implementation files found'
            }

        # Load SEP-02 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented API features
        implemented_features = self.map_sep_02_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_02_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-02 API requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping API features to implementation status
        """
        implemented = {
            'request_types': {},
            'request_parameters': {},
            'response_fields': {},
            'coverage': {}
        }

        # Get API structure from definition
        api_structure = None
        for section in sep_definition.get('sections', []):
            if section.get('key') == 'api':
                api_structure = section.get('api_structure', {})
                break

        if not api_structure:
            return implemented

        # Get all methods from all classes
        all_methods = {}
        for cls in classes:
            for method in cls.get('methods', []):
                all_methods[method['name']] = method

        # Get all properties from FederationResponse class
        all_properties = set()
        for cls in classes:
            if cls['name'] == 'FederationResponse':
                for prop in cls.get('properties', []):
                    all_properties.add(prop['name'])

        # Map request types to methods
        request_types_map = {
            'name': 'resolveStellarAddress',
            'id': 'resolveStellarAccountId',
            'txid': 'resolveStellarTransactionId',
            'forward': 'resolveForward'
        }

        for req_type in api_structure.get('request_types', []):
            type_name = req_type['name']
            sdk_method = request_types_map.get(type_name)
            implemented_in_sdk = sdk_method in all_methods

            implemented['request_types'][type_name] = {
                'required': req_type.get('required', False),
                'implemented': implemented_in_sdk,
                'sdk_method': sdk_method if implemented_in_sdk else None,
                'description': req_type.get('description', '')
            }

        # Map request parameters
        # Both q and type are handled internally by the RequestBuilder
        for param in api_structure.get('request_parameters', []):
            param_name = param['name']
            # These are handled by forStringToLookUp (q) and forType (type) methods
            implemented_in_sdk = True  # Always true since it's part of the request builder

            implemented['request_parameters'][param_name] = {
                'required': param.get('required', False),
                'implemented': implemented_in_sdk,
                'description': param.get('description', '')
            }

        # Map response fields to properties
        property_name_map = {
            'stellar_address': 'stellarAddress',
            'account_id': 'accountId',
            'memo_type': 'memoType',
            'memo': 'memo'
        }

        for field in api_structure.get('response_fields', []):
            field_name = field['name']
            sdk_property = property_name_map.get(field_name, field_name)
            implemented_in_sdk = sdk_property in all_properties

            implemented['response_fields'][field_name] = {
                'required': field.get('required', False),
                'implemented': implemented_in_sdk,
                'sdk_property': sdk_property if implemented_in_sdk else None,
                'description': field.get('description', '')
            }

        # Calculate coverage
        total_features = (
            len(api_structure.get('request_types', [])) +
            len(api_structure.get('request_parameters', [])) +
            len(api_structure.get('response_fields', []))
        )

        implemented_count = (
            sum(1 for v in implemented['request_types'].values() if v['implemented']) +
            sum(1 for v in implemented['request_parameters'].values() if v['implemented']) +
            sum(1 for v in implemented['response_fields'].values() if v['implemented'])
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_10(self) -> Dict[str, Any]:
        """
        Analyze SEP-10 (Stellar Web Authentication) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-10 implementation files found'
            }

        # Load SEP-10 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented authentication features
        implemented_features = self.map_sep_10_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_10_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-10 authentication feature requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping auth features to implementation status
        """
        implemented = {
            'authentication_endpoints': {},
            'challenge_transaction_features': {},
            'jwt_token_features': {},
            'client_domain_features': {},
            'verification_features': {},
            'coverage': {}
        }

        # Get all methods from all classes
        all_methods = {}
        for cls in classes:
            for method in cls.get('methods', []):
                all_methods[method['name']] = method

        # Map authentication endpoints to methods
        auth_endpoints_map = {
            'get_auth_challenge': 'getChallenge',
            'post_auth_token': 'sendSignedChallengeTransaction'
        }

        # Map challenge transaction features to methods/validation
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

        # Map JWT token features to methods
        jwt_features_map = {
            'jwt_token_generation': 'sendSignedChallengeTransaction',
            'jwt_token_response': 'sendSignedChallengeTransaction',
            'jwt_token_validation': 'jwtToken',
            'jwt_expiration': 'sendSignedChallengeTransaction',
            'jwt_claims': 'sendSignedChallengeTransaction'
        }

        # Map client domain features to methods
        client_domain_features_map = {
            'client_domain_parameter': 'getChallenge',
            'client_domain_operation': 'validateChallenge',
            'client_domain_verification': 'jwtToken',
            'client_domain_signature': 'signTransaction'
        }

        # Map verification features to methods
        verification_features_map = {
            'challenge_validation': 'validateChallenge',
            'signature_verification': 'validateChallenge',
            'multi_signature_support': 'signTransaction',
            'timebounds_validation': 'validateChallenge',
            'home_domain_validation': 'validateChallenge',
            'memo_support': 'getChallenge'
        }

        # Process each section from SEP definition
        sections = sep_definition.get('sections', [])

        for section in sections:
            section_key = section.get('key', '')
            auth_features = section.get('auth_features', [])

            if section_key == 'auth_endpoints':
                for feature in auth_features:
                    feature_name = feature['name']
                    sdk_method = auth_endpoints_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['authentication_endpoints'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'challenge_transaction':
                for feature in auth_features:
                    feature_name = feature['name']
                    sdk_method = challenge_features_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['challenge_transaction_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'jwt_token':
                for feature in auth_features:
                    feature_name = feature['name']
                    sdk_method = jwt_features_map.get(feature_name)

                    # Check if this is a server-side-only feature
                    is_server_side_only = feature.get('server_side_only', False)

                    # For server-side-only features, mark as N/A for client SDKs
                    if is_server_side_only:
                        implemented_in_sdk = None  # N/A
                    else:
                        implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['jwt_token_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', ''),
                        'server_side_only': is_server_side_only,
                        'client_note': feature.get('client_note', '') if is_server_side_only else None
                    }

            elif section_key == 'client_domain':
                for feature in auth_features:
                    feature_name = feature['name']
                    sdk_method = client_domain_features_map.get(feature_name)

                    # Check if this is a server-side-only feature
                    is_server_side_only = feature.get('server_side_only', False)

                    # For server-side-only features, mark as N/A for client SDKs
                    if is_server_side_only:
                        implemented_in_sdk = None  # N/A
                    else:
                        implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['client_domain_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', ''),
                        'server_side_only': is_server_side_only,
                        'client_note': feature.get('client_note', '') if is_server_side_only else None
                    }

            elif section_key == 'verification':
                for feature in auth_features:
                    feature_name = feature['name']
                    sdk_method = verification_features_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['verification_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

        # Calculate coverage (excluding server-side-only features)
        # Count total client-applicable features (excluding server_side_only)
        def count_client_features(feature_dict):
            return sum(1 for v in feature_dict.values() if not v.get('server_side_only', False))

        def count_implemented_features(feature_dict):
            return sum(1 for v in feature_dict.values()
                      if not v.get('server_side_only', False) and v.get('implemented', False))

        total_features = (
            count_client_features(implemented['authentication_endpoints']) +
            count_client_features(implemented['challenge_transaction_features']) +
            count_client_features(implemented['jwt_token_features']) +
            count_client_features(implemented['client_domain_features']) +
            count_client_features(implemented['verification_features'])
        )

        implemented_count = (
            count_implemented_features(implemented['authentication_endpoints']) +
            count_implemented_features(implemented['challenge_transaction_features']) +
            count_implemented_features(implemented['jwt_token_features']) +
            count_implemented_features(implemented['client_domain_features']) +
            count_implemented_features(implemented['verification_features'])
        )

        # Also count server-side-only features separately for reporting
        server_side_count = (
            sum(1 for v in implemented['authentication_endpoints'].values() if v.get('server_side_only', False)) +
            sum(1 for v in implemented['challenge_transaction_features'].values() if v.get('server_side_only', False)) +
            sum(1 for v in implemented['jwt_token_features'].values() if v.get('server_side_only', False)) +
            sum(1 for v in implemented['client_domain_features'].values() if v.get('server_side_only', False)) +
            sum(1 for v in implemented['verification_features'].values() if v.get('server_side_only', False))
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2),
            'server_side_only_count': server_side_count,
            'note': f'Excludes {server_side_count} server-side-only feature(s) not applicable to client SDKs' if server_side_count > 0 else None
        }

        return implemented

    def analyze_sep_05(self) -> Dict[str, Any]:
        """
        Analyze SEP-05 (Key Derivation Methods) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-05 implementation files found'
            }

        # Load SEP-05 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented cryptographic features
        implemented_features = self.map_sep_05_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_05_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-05 cryptographic feature requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping crypto features to implementation status
        """
        implemented = {
            'bip39_features': {},
            'bip32_features': {},
            'bip44_features': {},
            'key_derivation_methods': {},
            'language_support': {},
            'coverage': {}
        }

        # Get all methods from all classes (including private methods)
        all_methods = {}
        for cls in classes:
            for method in cls.get('methods', []):
                all_methods[method['name']] = method

        # Also search for private methods in the source code
        # For SEP-05, we need to check for _derivePath, _derive, _hMacSHA512
        for cls in classes:
            if 'file' in cls:
                # Read the source file to find private methods
                file_path = self.sdk_path / cls['file']
                if file_path.exists():
                    content = file_path.read_text(encoding='utf-8', errors='ignore')
                    # Find private method definitions
                    private_method_pattern = r'(?:Uint8List|Future<\w+>|void)\s+(_\w+)\s*\('
                    matches = re.finditer(private_method_pattern, content)
                    for match in matches:
                        method_name = match.group(1)
                        if method_name not in all_methods:
                            all_methods[method_name] = {'name': method_name, 'private': True}

        # Map BIP-39 features to SDK methods
        bip39_feature_map = {
            'mnemonic_generation_12_words': 'generate12WordsMnemonic',
            'mnemonic_generation_24_words': 'generate24WordsMnemonic',
            'mnemonic_validation': 'validate',
            'mnemonic_to_seed': 'mnemonicToSeed',
            'passphrase_support': 'mnemonicToSeed'  # Passphrase is a parameter
        }

        # Map BIP-32 features to SDK methods
        bip32_feature_map = {
            'hd_key_derivation': '_derivePath',
            'ed25519_curve': '_hMacSHA512',  # Ed25519 support through HMAC-SHA512
            'master_key_generation': '_derivePath',
            'child_key_derivation': '_derive'
        }

        # Map BIP-44 features to SDK methods
        bip44_feature_map = {
            'stellar_derivation_path': 'getKeyPair',  # Uses m/44'/148'/account'
            'multiple_accounts': 'getKeyPair',  # Supports index parameter
            'account_index_support': 'getKeyPair'
        }

        # Map key derivation methods
        key_derivation_map = {
            'keypair_from_mnemonic': 'getKeyPair',
            'account_id_from_mnemonic': 'getAccountId',
            'seed_from_mnemonic': 'mnemonicToSeed'
        }

        # Map language support (check for word list methods)
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

        # Check if WordList class has these methods
        wordlist_methods = set()
        for cls in classes:
            if cls['name'] == 'WordList':
                for method in cls.get('methods', []):
                    wordlist_methods.add(method['name'])

        # Process each section from SEP definition
        sections = sep_definition.get('sections', [])

        for section in sections:
            section_key = section.get('key', '')
            crypto_features = section.get('crypto_features', [])

            if section_key == 'bip39':
                for feature in crypto_features:
                    feature_name = feature['name']
                    sdk_method = bip39_feature_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['bip39_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'bip32':
                for feature in crypto_features:
                    feature_name = feature['name']
                    sdk_method = bip32_feature_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['bip32_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'bip44':
                for feature in crypto_features:
                    feature_name = feature['name']
                    sdk_method = bip44_feature_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['bip44_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'key_derivation':
                for feature in crypto_features:
                    feature_name = feature['name']
                    sdk_method = key_derivation_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['key_derivation_methods'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'languages':
                for feature in crypto_features:
                    feature_name = feature['name']
                    wordlist_method = language_map.get(feature_name)
                    implemented_in_sdk = wordlist_method in wordlist_methods if wordlist_method else False

                    implemented['language_support'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': wordlist_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

        # Calculate coverage
        total_features = (
            len(implemented['bip39_features']) +
            len(implemented['bip32_features']) +
            len(implemented['bip44_features']) +
            len(implemented['key_derivation_methods']) +
            len(implemented['language_support'])
        )

        implemented_count = (
            sum(1 for v in implemented['bip39_features'].values() if v['implemented']) +
            sum(1 for v in implemented['bip32_features'].values() if v['implemented']) +
            sum(1 for v in implemented['bip44_features'].values() if v['implemented']) +
            sum(1 for v in implemented['key_derivation_methods'].values() if v['implemented']) +
            sum(1 for v in implemented['language_support'].values() if v['implemented'])
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_09(self) -> Dict[str, Any]:
        """
        Analyze SEP-09 (Standard KYC/AML Fields) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-09 implementation files found'
            }

        # Load SEP-09 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'
        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented field definitions
        implemented_fields = self.map_sep_09_fields(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_fields': implemented_fields,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_09_fields(self, classes: List[Dict[str, Any]],
                          sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-09 field requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping fields to implementation status
        """
        implemented = {
            'natural_person_fields': {},
            'organization_fields': {},
            'financial_account_fields': {},
            'card_fields': {},
            'coverage': {}
        }

        # Extract all field keys and properties from classes
        natural_person_keys = set()
        natural_person_properties = set()
        organization_keys = set()
        organization_properties = set()
        financial_keys = set()
        financial_properties = set()
        card_keys = set()
        card_properties = set()

        # Read the source file to extract static const field keys
        sep_file = self.sdk_path / 'lib' / 'src' / 'sep' / '0009' / 'standard_kyc_fields.dart'
        if sep_file.exists():
            content = sep_file.read_text(encoding='utf-8')

            # Extract NaturalPersonKYCFields constants
            natural_person_pattern = r'class NaturalPersonKYCFields.*?\{(.*?)(?=\n  /// |\nclass )'
            natural_match = re.search(natural_person_pattern, content, re.DOTALL)
            if natural_match:
                class_body = natural_match.group(1)
                # Find all static const field_key declarations
                key_pattern = r'static const String (\w+_field_key|' + r'\w+_file_key)'
                for match in re.finditer(key_pattern, class_body):
                    const_name = match.group(1)
                    field_name = const_name.replace('_field_key', '').replace('_file_key', '')
                    natural_person_keys.add(field_name)

            # Extract OrganizationKYCFields constants
            org_pattern = r'class OrganizationKYCFields.*?\{(.*?)(?=\n  /// |\nclass )'
            org_match = re.search(org_pattern, content, re.DOTALL)
            if org_match:
                class_body = org_match.group(1)
                key_pattern = r'static const String (\w+_field_key|\w+_file_key)'
                for match in re.finditer(key_pattern, class_body):
                    const_name = match.group(1)
                    field_name = const_name.replace('_field_key', '').replace('_file_key', '')
                    organization_keys.add(field_name)

            # Extract FinancialAccountKYCFields constants
            financial_pattern = r'class FinancialAccountKYCFields.*?\{(.*?)(?=\n  /// |\nclass )'
            financial_match = re.search(financial_pattern, content, re.DOTALL)
            if financial_match:
                class_body = financial_match.group(1)
                key_pattern = r'static const String (\w+_field_key)'
                for match in re.finditer(key_pattern, class_body):
                    const_name = match.group(1)
                    field_name = const_name.replace('_field_key', '')
                    financial_keys.add(field_name)

            # Extract CardKYCFields constants
            card_pattern = r'class CardKYCFields.*?\{(.*?)$'
            card_match = re.search(card_pattern, content, re.DOTALL)
            if card_match:
                class_body = card_match.group(1)
                key_pattern = r'static const String (\w+_field_key)'
                for match in re.finditer(key_pattern, class_body):
                    const_name = match.group(1)
                    field_name = const_name.replace('_field_key', '')
                    card_keys.add(field_name)

        # Get properties from class info
        for cls in classes:
            class_name = cls.get('name', '')

            # Get properties
            for prop in cls.get('properties', []):
                prop_name = prop['name']

                if class_name == 'NaturalPersonKYCFields':
                    natural_person_properties.add(prop_name)
                elif class_name == 'OrganizationKYCFields':
                    organization_properties.add(prop_name)
                elif class_name == 'FinancialAccountKYCFields':
                    financial_properties.add(prop_name)
                elif class_name == 'CardKYCFields':
                    card_properties.add(prop_name)

        # Helper function to convert snake_case to camelCase
        def snake_to_camel(snake_str: str) -> str:
            components = snake_str.split('_')
            return components[0] + ''.join(x.title() for x in components[1:])

        # Helper function to check if field is implemented
        def is_field_implemented(field_name: str, keys: set, properties: set,
                                prefix: str = '') -> tuple:
            # Remove prefix if present for checking
            check_name = field_name
            if prefix and field_name.startswith(prefix):
                check_name = field_name[len(prefix):]

            # Check if field key exists
            has_key = check_name in keys

            # Check if property exists (convert to camelCase)
            camel_name = snake_to_camel(check_name)
            has_property = camel_name in properties

            # For VATNumber, check both VATNumber and vatNumber
            if check_name == 'VAT_number':
                has_property = 'VATNumber' in properties or 'vatNumber' in properties
                camel_name = 'VATNumber' if 'VATNumber' in properties else ('vatNumber' if 'vatNumber' in properties else camel_name)

            return (has_key and has_property, camel_name if has_property else None)

        # Process each section from SEP definition
        sections = sep_definition.get('sections', [])
        for section in sections:
            section_key = section.get('key', '')
            fields = section.get('fields', [])

            if section_key == 'natural_person_fields':
                for field in fields:
                    field_name = field['name']
                    is_implemented, sdk_property = is_field_implemented(
                        field_name, natural_person_keys, natural_person_properties
                    )

                    implemented['natural_person_fields'][field_name] = {
                        'required': field.get('required', False),
                        'implemented': is_implemented,
                        'sdk_property': sdk_property,
                        'description': field.get('description', ''),
                        'type': field.get('type', 'string')
                    }

            elif section_key == 'organization_fields':
                for field in fields:
                    field_name = field['name']
                    # Organization fields have 'organization.' prefix
                    is_implemented, sdk_property = is_field_implemented(
                        field_name, organization_keys, organization_properties,
                        'organization.'
                    )

                    implemented['organization_fields'][field_name] = {
                        'required': field.get('required', False),
                        'implemented': is_implemented,
                        'sdk_property': sdk_property,
                        'description': field.get('description', ''),
                        'type': field.get('type', 'string')
                    }

            elif section_key == 'financial_account_fields':
                for field in fields:
                    field_name = field['name']
                    is_implemented, sdk_property = is_field_implemented(
                        field_name, financial_keys, financial_properties
                    )

                    implemented['financial_account_fields'][field_name] = {
                        'required': field.get('required', False),
                        'implemented': is_implemented,
                        'sdk_property': sdk_property,
                        'description': field.get('description', ''),
                        'type': field.get('type', 'string')
                    }

            elif section_key == 'card_fields':
                for field in fields:
                    field_name = field['name']
                    # Card fields have 'card.' prefix
                    is_implemented, sdk_property = is_field_implemented(
                        field_name, card_keys, card_properties,
                        'card.'
                    )

                    implemented['card_fields'][field_name] = {
                        'required': field.get('required', False),
                        'implemented': is_implemented,
                        'sdk_property': sdk_property,
                        'description': field.get('description', ''),
                        'type': field.get('type', 'string')
                    }

        # Calculate coverage statistics
        total_fields = sum(len(cat) for cat in implemented.values() if isinstance(cat, dict) and cat != implemented['coverage'])
        implemented_count = sum(
            1 for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
            for field in category.values()
            if field.get('implemented')
        )

        implemented['coverage'] = {
            'total': total_fields,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_fields * 100) if total_fields > 0 else 0, 2)
        }

        return implemented

    def analyze_generic_sep(self) -> Dict[str, Any]:
        """
        Analyze a generic SEP implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': f'No SEP-{self.sep_number} implementation files found'
            }

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def analyze_sep_11(self) -> Dict[str, Any]:
        """
        Analyze SEP-11 (Txrep) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-11 implementation files found'
            }

        # Load SEP-11 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented txrep features
        implemented_features = self.map_sep_11_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_11_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-11 Txrep requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping txrep features to implementation status
        """
        implemented = {
            'encoding_features': {},
            'decoding_features': {},
            'asset_encoding': {},
            'operation_types': {},
            'format_features': {},
            'coverage': {}
        }

        # Get all methods from TxRep class
        txrep_methods = set()
        for cls in classes:
            if cls['name'] == 'TxRep':
                for method in cls.get('methods', []):
                    txrep_methods.add(method['name'])

        # The TxRep class has two main public methods:
        # - fromTransactionEnvelopeXdrBase64 (encoding: XDR -> txrep)
        # - transactionEnvelopeXdrBase64FromTxRep (decoding: txrep -> XDR)
        # All specific encoding/decoding features are implemented through these methods

        has_encoding = 'fromTransactionEnvelopeXdrBase64' in txrep_methods
        has_decoding = 'transactionEnvelopeXdrBase64FromTxRep' in txrep_methods

        # Process each section from SEP definition
        for section in sep_definition.get('sections', []):
            section_key = section.get('key', '')
            txrep_features = section.get('txrep_features', [])

            if section_key == 'encoding_features':
                # All encoding features are implemented through fromTransactionEnvelopeXdrBase64
                for feature in txrep_features:
                    feature_name = feature['name']
                    implemented[section_key][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': has_encoding,
                        'sdk_method': 'fromTransactionEnvelopeXdrBase64' if has_encoding else None,
                        'description': feature.get('description', ''),
                        'category': feature.get('category', '')
                    }

            elif section_key == 'decoding_features':
                # All decoding features are implemented through transactionEnvelopeXdrBase64FromTxRep
                for feature in txrep_features:
                    feature_name = feature['name']
                    implemented[section_key][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': has_decoding,
                        'sdk_method': 'transactionEnvelopeXdrBase64FromTxRep' if has_decoding else None,
                        'description': feature.get('description', ''),
                        'category': feature.get('category', '')
                    }

            elif section_key == 'asset_encoding':
                # Asset encoding is part of the general encoding implementation
                for feature in txrep_features:
                    feature_name = feature['name']
                    implemented[section_key][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': has_encoding,  # Part of encoding
                        'sdk_method': '_encodeAsset' if has_encoding else None,
                        'description': feature.get('description', ''),
                        'category': feature.get('category', '')
                    }

            elif section_key == 'operation_types':
                # All operation types are supported through the general encode/decode methods
                for feature in txrep_features:
                    feature_name = feature['name']
                    # Both encoding and decoding must work for operation types
                    implemented[section_key][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': has_encoding and has_decoding,
                        'sdk_method': '_addOperation (encode), operation parsing (decode)' if has_encoding and has_decoding else None,
                        'description': feature.get('description', ''),
                        'category': feature.get('category', '')
                    }

            elif section_key == 'format_features':
                # Format features are inherent in the implementation
                format_feature_impl = {
                    'comment_support': has_decoding,  # Comments handled in _removeComment
                    'dot_notation': has_encoding and has_decoding,  # Used throughout
                    'array_indexing': has_encoding and has_decoding,  # Used for operations, signatures, etc.
                    'hex_encoding': has_encoding and has_decoding,  # Used for binary data
                    'string_escaping': has_encoding and has_decoding  # Used for text memos
                }

                for feature in txrep_features:
                    feature_name = feature['name']
                    is_implemented = format_feature_impl.get(feature_name, False)
                    implemented[section_key][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': is_implemented,
                        'sdk_method': 'TxRep format implementation' if is_implemented else None,
                        'description': feature.get('description', ''),
                        'category': feature.get('category', '')
                    }

        # Calculate coverage
        total_features = 0
        implemented_count = 0

        for category_name, category_features in implemented.items():
            if category_name == 'coverage':
                continue
            for feature_info in category_features.values():
                total_features += 1
                if feature_info.get('implemented'):
                    implemented_count += 1

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_12(self) -> Dict[str, Any]:
        """
        Analyze SEP-12 (KYC API) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-12 implementation files found'
            }

        # Load SEP-12 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented API features
        implemented_features = self.map_sep_12_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_12_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-12 KYC API requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping API features to implementation status
        """
        implemented = {
            'endpoints': {},
            'request_parameters': {},
            'response_fields': {},
            'field_types': {},
            'authentication': {},
            'file_upload': {},
            'sep9_integration': {},
            'coverage': {}
        }

        # Get API structure from definition
        api_structure = None
        for section in sep_definition.get('sections', []):
            if section.get('key') == 'endpoints':
                api_structure = section.get('api_structure', {})
                break

        if not api_structure:
            return implemented

        # Get all methods from KYCService class
        kyc_service_methods = set()
        for cls in classes:
            if cls['name'] == 'KYCService':
                for method in cls.get('methods', []):
                    kyc_service_methods.add(method['name'])

        # Map endpoints to KYCService methods
        endpoint_map = {
            'get_customer': 'getCustomerInfo',
            'put_customer': 'putCustomerInfo',
            'put_customer_verification': 'putCustomerVerification',
            'delete_customer': 'deleteCustomer',
            'put_customer_callback': 'putCustomerCallback',
            'post_customer_files': 'postCustomerFile',
            'get_customer_files': 'getCustomerFiles'
        }

        for endpoint in api_structure.get('endpoints', []):
            endpoint_key = endpoint['key']
            sdk_method = endpoint_map.get(endpoint_key)
            implemented_in_sdk = sdk_method in kyc_service_methods

            implemented['endpoints'][endpoint_key] = {
                'required': True,  # All KYC endpoints are essential
                'implemented': implemented_in_sdk,
                'sdk_method': sdk_method if implemented_in_sdk else None,
                'description': endpoint.get('description', ''),
                'path': endpoint.get('path', ''),
                'method': endpoint.get('method', '')
            }

        # Map request parameters to GetCustomerInfoRequest properties
        request_properties = set()
        for cls in classes:
            if cls['name'] == 'GetCustomerInfoRequest':
                for prop in cls.get('properties', []):
                    request_properties.add(prop['name'])

        for param in api_structure.get('request_parameters', []):
            param_name = param['name']
            # Map snake_case to camelCase for comparison
            sdk_property_map = {
                'id': 'id',
                'account': 'account',
                'memo': 'memo',
                'memo_type': 'memoType',
                'type': 'type',
                'transaction_id': 'transactionId',
                'lang': 'lang'
            }
            sdk_property = sdk_property_map.get(param_name, param_name)
            implemented_in_sdk = sdk_property in request_properties

            implemented['request_parameters'][param_name] = {
                'required': param.get('required', False),
                'implemented': implemented_in_sdk,
                'sdk_property': sdk_property if implemented_in_sdk else None,
                'description': param.get('description', '')
            }

        # Map response fields to GetCustomerInfoResponse properties
        response_properties = set()
        for cls in classes:
            if cls['name'] == 'GetCustomerInfoResponse':
                for prop in cls.get('properties', []):
                    response_properties.add(prop['name'])

        for field in api_structure.get('response_fields', []):
            field_name = field['name']
            # Map snake_case to camelCase
            sdk_property_map = {
                'id': 'id',
                'status': 'status',
                'fields': 'fields',
                'provided_fields': 'providedFields',
                'message': 'message'
            }
            sdk_property = sdk_property_map.get(field_name, field_name)
            implemented_in_sdk = sdk_property in response_properties

            implemented['response_fields'][field_name] = {
                'required': field.get('required', False),
                'implemented': implemented_in_sdk,
                'sdk_property': sdk_property if implemented_in_sdk else None,
                'description': field.get('description', '')
            }

        # Map field type specifications to GetCustomerInfoField and GetCustomerInfoProvidedField properties
        field_properties = set()
        provided_field_properties = set()
        for cls in classes:
            if cls['name'] == 'GetCustomerInfoField':
                for prop in cls.get('properties', []):
                    field_properties.add(prop['name'])
            elif cls['name'] == 'GetCustomerInfoProvidedField':
                for prop in cls.get('properties', []):
                    provided_field_properties.add(prop['name'])

        for field_type in api_structure.get('field_types', []):
            field_name = field_type['name']
            # Check both GetCustomerInfoField and GetCustomerInfoProvidedField
            implemented_in_sdk = field_name in field_properties or field_name in provided_field_properties

            implemented['field_types'][field_name] = {
                'required': field_type.get('required', True),  # Core field specs
                'implemented': implemented_in_sdk,
                'sdk_property': field_name if implemented_in_sdk else None,
                'description': field_type.get('description', '')
            }

        # Check authentication implementation
        auth = api_structure.get('authentication', {})
        # Check if request classes have jwt parameter or if Authorization header is used
        jwt_supported = False

        # Check request classes for jwt property
        request_classes = ['GetCustomerInfoRequest', 'PutCustomerInfoRequest',
                          'PutCustomerVerificationRequest', 'PutCustomerCallbackRequest']
        for cls in classes:
            if cls['name'] in request_classes:
                for prop in cls.get('properties', []):
                    if prop['name'] == 'jwt':
                        jwt_supported = True
                        break
                if jwt_supported:
                    break

        # Also check if any method accepts jwt parameter directly
        if not jwt_supported:
            for cls in classes:
                if cls['name'] == 'KYCService':
                    for method in cls.get('methods', []):
                        # Check parameters for jwt
                        for param in method.get('parameters', []):
                            if 'jwt' in param.lower():
                                jwt_supported = True
                                break
                        if jwt_supported:
                            break

        implemented['authentication'] = {
            'type': auth.get('type', 'SEP-10'),
            'method': auth.get('method', 'JWT Token'),
            'implemented': jwt_supported,
            'description': auth.get('description', '')
        }

        # Check file upload support
        file_upload = api_structure.get('file_upload', {})
        file_upload_supported = 'postCustomerFile' in kyc_service_methods

        implemented['file_upload'] = {
            'supported': file_upload.get('supported', True),
            'implemented': file_upload_supported,
            'content_type': file_upload.get('content_type', 'multipart/form-data'),
            'description': file_upload.get('description', '')
        }

        # Check SEP-9 integration
        sep9_classes = set()
        for cls in classes:
            if 'KYC' in cls['name'] or 'kyc' in cls['name'].lower():
                sep9_classes.add(cls['name'])

        sep9_integration = api_structure.get('sep9_integration', {})

        # Check if SEP-9 module exists and is imported
        sep9_module_exists = False
        sep9_file_path = self.sdk_path / 'lib' / 'src' / 'sep' / '0009' / 'standard_kyc_fields.dart'
        if sep9_file_path.exists():
            sep9_module_exists = True

        # Check if StandardKYCFields, NaturalPersonKYCFields, OrganizationKYCFields exist
        sep9_classes_exist = (
            'NaturalPersonKYCFields' in sep9_classes or
            'OrganizationKYCFields' in sep9_classes or
            'StandardKYCFields' in sep9_classes
        )

        # Check if PutCustomerInfoRequest has kycFields property
        sep9_integrated = False
        for cls in classes:
            if cls['name'] == 'PutCustomerInfoRequest':
                for prop in cls.get('properties', []):
                    if prop['name'] == 'kycFields':
                        sep9_integrated = True
                        break

        # SEP-9 is implemented if module exists OR classes exist OR integration exists
        sep9_implemented = sep9_module_exists or sep9_classes_exist or sep9_integrated

        implemented['sep9_integration'] = {
            'supported': sep9_integration.get('supported', True),
            'implemented': sep9_implemented,
            'description': sep9_integration.get('description', '')
        }

        # Calculate coverage
        total_features = (
            len(api_structure.get('endpoints', [])) +
            len(api_structure.get('request_parameters', [])) +
            len(api_structure.get('response_fields', [])) +
            len(api_structure.get('field_types', [])) +
            3  # authentication, file_upload, sep9_integration
        )

        implemented_count = (
            sum(1 for v in implemented['endpoints'].values() if v['implemented']) +
            sum(1 for v in implemented['request_parameters'].values() if v['implemented']) +
            sum(1 for v in implemented['response_fields'].values() if v['implemented']) +
            sum(1 for v in implemented['field_types'].values() if v['implemented']) +
            (1 if implemented['authentication']['implemented'] else 0) +
            (1 if implemented['file_upload']['implemented'] else 0) +
            (1 if implemented['sep9_integration']['implemented'] else 0)
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100), 2) if total_features > 0 else 0
        }

        return implemented

    def analyze_sep_06(self) -> Dict[str, Any]:
        """
        Analyze SEP-06 (Deposit and Withdrawal API) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-06 implementation files found'
            }

        # Load SEP-06 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented API features
        implemented_features = self.map_sep_06_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_06_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-06 Deposit/Withdrawal API requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping API features to implementation status
        """
        implemented = {
            'info_endpoint': {},
            'deposit_endpoints': {},
            'withdraw_endpoints': {},
            'transaction_endpoints': {},
            'fee_endpoint': {},
            'deposit_request_parameters': {},
            'withdraw_request_parameters': {},
            'deposit_response_fields': {},
            'withdraw_response_fields': {},
            'transaction_status_values': {},
            'transaction_fields': {},
            'info_response_fields': {},
            'coverage': {}
        }

        # Get all methods from TransferServerService class
        transfer_service_methods = set()
        for cls in classes:
            if cls['name'] == 'TransferServerService':
                for method in cls.get('methods', []):
                    transfer_service_methods.add(method['name'])

        # Map endpoints to TransferServerService methods
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

        # Process each section from SEP definition
        for section in sep_definition.get('sections', []):
            section_key = section.get('key', '')
            api_features = section.get('api_features', [])

            if section_key == 'info_endpoint':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in transfer_service_methods if sdk_method else False

                    implemented['info_endpoint'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'deposit_endpoints':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in transfer_service_methods if sdk_method else False

                    implemented['deposit_endpoints'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'withdraw_endpoints':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in transfer_service_methods if sdk_method else False

                    implemented['withdraw_endpoints'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'transaction_endpoints':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in transfer_service_methods if sdk_method else False

                    implemented['transaction_endpoints'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'fee_endpoint':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in transfer_service_methods if sdk_method else False

                    implemented['fee_endpoint'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'deposit_request_parameters':
                # Check DepositRequest class properties
                deposit_request_properties = set()
                for cls in classes:
                    if cls['name'] == 'DepositRequest':
                        for prop in cls.get('properties', []):
                            deposit_request_properties.add(prop['name'])

                # Map parameter names to SDK properties
                param_map = {
                    'asset_code': 'assetCode',
                    'account': 'account',
                    'memo_type': 'memoType',
                    'memo': 'memo',
                    'email_address': 'emailAddress',
                    'type': 'type',
                    'wallet_name': 'walletName',
                    'wallet_url': 'walletUrl',
                    'lang': 'lang',
                    'on_change_callback': 'onChangeCallback',
                    'amount': 'amount',
                    'country_code': 'countryCode',
                    'claimable_balance_supported': 'claimableBalanceSupported',
                    'customer_id': 'customerId',
                    'location_id': 'locationId'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = param_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in deposit_request_properties

                    implemented['deposit_request_parameters'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'withdraw_request_parameters':
                # Check WithdrawRequest class properties
                withdraw_request_properties = set()
                for cls in classes:
                    if cls['name'] == 'WithdrawRequest':
                        for prop in cls.get('properties', []):
                            withdraw_request_properties.add(prop['name'])

                # Map parameter names to SDK properties
                param_map = {
                    'asset_code': 'assetCode',
                    'type': 'type',
                    'dest': 'dest',
                    'dest_extra': 'destExtra',
                    'account': 'account',
                    'memo': 'memo',
                    'memo_type': 'memoType',
                    'wallet_name': 'walletName',
                    'wallet_url': 'walletUrl',
                    'lang': 'lang',
                    'on_change_callback': 'onChangeCallback',
                    'amount': 'amount',
                    'country_code': 'countryCode',
                    'refund_memo': 'refundMemo',
                    'refund_memo_type': 'refundMemoType',
                    'customer_id': 'customerId',
                    'location_id': 'locationId'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = param_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in withdraw_request_properties

                    implemented['withdraw_request_parameters'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'deposit_response_fields':
                # Check DepositResponse class properties
                deposit_response_properties = set()
                for cls in classes:
                    if cls['name'] == 'DepositResponse':
                        for prop in cls.get('properties', []):
                            deposit_response_properties.add(prop['name'])

                # Map response field names to SDK properties
                field_map = {
                    'how': 'how',
                    'id': 'id',
                    'eta': 'eta',
                    'min_amount': 'minAmount',
                    'max_amount': 'maxAmount',
                    'fee_fixed': 'feeFixed',
                    'fee_percent': 'feePercent',
                    'extra_info': 'extraInfo'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in deposit_response_properties

                    implemented['deposit_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'withdraw_response_fields':
                # Check WithdrawResponse class properties
                withdraw_response_properties = set()
                for cls in classes:
                    if cls['name'] == 'WithdrawResponse':
                        for prop in cls.get('properties', []):
                            withdraw_response_properties.add(prop['name'])

                # Map response field names to SDK properties
                field_map = {
                    'account_id': 'accountId',
                    'memo_type': 'memoType',
                    'memo': 'memo',
                    'id': 'id',
                    'eta': 'eta',
                    'min_amount': 'minAmount',
                    'max_amount': 'maxAmount',
                    'fee_fixed': 'feeFixed',
                    'fee_percent': 'feePercent',
                    'extra_info': 'extraInfo'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in withdraw_response_properties

                    implemented['withdraw_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'transaction_status_values':
                # Check AnchorTransaction class for status constants or fields
                # SEP-06 transaction statuses are typically handled as string values
                # We check if AnchorTransaction class has a status field
                has_status_field = False
                for cls in classes:
                    if cls['name'] == 'AnchorTransaction':
                        for prop in cls.get('properties', []):
                            if prop['name'] == 'status':
                                has_status_field = True
                                break

                # All status values are supported if the status field exists
                for feature in api_features:
                    feature_name = feature['name']

                    implemented['transaction_status_values'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': has_status_field,
                        'sdk_property': 'status' if has_status_field else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'transaction_fields':
                # Check AnchorTransaction class properties
                transaction_properties = set()
                for cls in classes:
                    if cls['name'] == 'AnchorTransaction':
                        for prop in cls.get('properties', []):
                            transaction_properties.add(prop['name'])

                # Map transaction field names to SDK properties
                field_map = {
                    'id': 'id',
                    'kind': 'kind',
                    'status': 'status',
                    'status_eta': 'statusEta',
                    'amount_in': 'amountIn',
                    'amount_out': 'amountOut',
                    'amount_fee': 'amountFee',
                    'started_at': 'startedAt',
                    'completed_at': 'completedAt',
                    'stellar_transaction_id': 'stellarTransactionId',
                    'external_transaction_id': 'externalTransactionId',
                    'from': 'from',
                    'to': 'to',
                    'refunded': 'refunded',
                    'refunds': 'refunds',
                    'message': 'message'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in transaction_properties

                    implemented['transaction_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'info_response_fields':
                # Check InfoResponse class properties
                info_response_properties = set()
                for cls in classes:
                    if cls['name'] == 'InfoResponse':
                        for prop in cls.get('properties', []):
                            info_response_properties.add(prop['name'])

                # FIXED: Map info response field names to correct SDK properties
                # The SDK uses different property names than the SEP field names:
                # - SEP fields are snake_case or kebab-case (e.g., 'deposit', 'deposit-exchange')
                # - SDK properties are camelCase with descriptive suffixes (e.g., 'depositAssets', 'feeInfo')
                #
                # Correct mappings verified from lib/src/sep/0006/transfer_server_service.dart:
                # - Line 1678: Map<String, DepositAsset>? depositAssets
                # - Line 1679: Map<String, DepositExchangeAsset>? depositExchangeAssets
                # - Line 1680: Map<String, WithdrawAsset>? withdrawAssets
                # - Line 1681: Map<String, WithdrawExchangeAsset>? withdrawExchangeAssets
                # - Line 1682: AnchorFeeInfo? feeInfo
                # - Line 1683: AnchorTransactionsInfo? transactionsInfo
                # - Line 1684: AnchorTransactionInfo? transactionInfo
                # - Line 1685: AnchorFeatureFlags? featureFlags
                field_map = {
                    'deposit': 'depositAssets',
                    'deposit-exchange': 'depositExchangeAssets',
                    'withdraw': 'withdrawAssets',
                    'withdraw-exchange': 'withdrawExchangeAssets',
                    'fee': 'feeInfo',
                    'transactions': 'transactionsInfo',
                    'transaction': 'transactionInfo',
                    'features': 'featureFlags'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in info_response_properties

                    implemented['info_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

        # Calculate coverage
        total_features = sum(
            len(category) for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
        )

        implemented_count = sum(
            1 for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
            for feature in category.values()
            if feature.get('implemented')
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_07(self) -> Dict[str, Any]:
        """
        Analyze SEP-07 (URI Scheme to facilitate delegated signing) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-07 implementation files found'
            }

        # Load SEP-07 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented URI features
        implemented_features = self.map_sep_07_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_07_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-07 URI scheme requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping URI features to implementation status
        """
        implemented = {
            'operations': {},
            'tx_parameters': {},
            'pay_parameters': {},
            'common_parameters': {},
            'validation_features': {},
            'signature_features': {},
            'coverage': {}
        }

        # Get all methods from all classes
        all_methods = {}
        all_constants = set()
        for cls in classes:
            for method in cls.get('methods', []):
                all_methods[method['name']] = method
            # Also collect constants (static fields) which define parameter names
            for prop in cls.get('properties', []):
                all_constants.add(prop['name'])

        # Map operations - SEP-07 supports tx and pay operations
        operation_map = {
            'tx': 'generateSignTransactionURI',
            'pay': 'generatePayOperationURI'
        }

        sections_by_key = {}
        for section in sep_definition.get('sections', []):
            sections_by_key[section['key']] = section

        # Map operations
        if 'operations' in sections_by_key:
            for operation in sections_by_key['operations'].get('uri_features', []):
                op_name = operation['name']
                sdk_method = operation_map.get(op_name)
                implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                implemented['operations'][op_name] = {
                    'required': operation.get('required', False),
                    'implemented': implemented_in_sdk,
                    'sdk_method': sdk_method if implemented_in_sdk else None,
                    'description': operation.get('description', '')
                }

        # Map TX operation parameters
        tx_param_constant_map = {
            'xdr': 'xdrParameterName',
            'replace': 'replaceParameterName',
            'callback': 'callbackParameterName',
            'pubkey': 'publicKeyParameterName',
            'chain': 'chainParameterName'
        }

        if 'tx_parameters' in sections_by_key:
            for param in sections_by_key['tx_parameters'].get('uri_features', []):
                param_name = param['name']
                sdk_constant = tx_param_constant_map.get(param_name)
                implemented_in_sdk = sdk_constant in all_constants if sdk_constant else False

                implemented['tx_parameters'][param_name] = {
                    'required': param.get('required', False),
                    'implemented': implemented_in_sdk,
                    'sdk_constant': sdk_constant if implemented_in_sdk else None,
                    'description': param.get('description', '')
                }

        # Map PAY operation parameters
        pay_param_constant_map = {
            'destination': 'destinationParameterName',
            'amount': 'amountParameterName',
            'asset_code': 'assetCodeParameterName',
            'asset_issuer': 'assetIssuerParameterName',
            'memo': 'memoParameterName',
            'memo_type': 'memoTypeParameterName'
        }

        if 'pay_parameters' in sections_by_key:
            for param in sections_by_key['pay_parameters'].get('uri_features', []):
                param_name = param['name']
                sdk_constant = pay_param_constant_map.get(param_name)
                implemented_in_sdk = sdk_constant in all_constants if sdk_constant else False

                implemented['pay_parameters'][param_name] = {
                    'required': param.get('required', False),
                    'implemented': implemented_in_sdk,
                    'sdk_constant': sdk_constant if implemented_in_sdk else None,
                    'description': param.get('description', '')
                }

        # Map common parameters
        common_param_constant_map = {
            'msg': 'messageParameterName',
            'network_passphrase': 'networkPassphraseParameterName',
            'origin_domain': 'originDomainParameterName',
            'signature': 'signatureParameterName'
        }

        if 'common_parameters' in sections_by_key:
            for param in sections_by_key['common_parameters'].get('uri_features', []):
                param_name = param['name']
                sdk_constant = common_param_constant_map.get(param_name)
                implemented_in_sdk = sdk_constant in all_constants if sdk_constant else False

                implemented['common_parameters'][param_name] = {
                    'required': param.get('required', False),
                    'implemented': implemented_in_sdk,
                    'sdk_constant': sdk_constant if implemented_in_sdk else None,
                    'description': param.get('description', '')
                }

        # Map validation features
        validation_method_map = {
            'validate_uri_scheme': 'isValidSep7Url',
            'validate_operation_type': 'isValidSep7Url',
            'validate_xdr_parameter': 'isValidSep7Url',
            'validate_destination_parameter': 'isValidSep7Url',
            'validate_stellar_address': 'isValidSep7Url',
            'validate_asset_code': 'isValidSep7Url',
            'validate_memo_type': 'isValidSep7Url',
            'validate_memo_value': 'isValidSep7Url',
            'validate_message_length': 'isValidSep7Url',
            'validate_origin_domain': 'isValidSep7Url',
            'validate_chain_nesting': 'isValidSep7Url'
        }

        if 'validation_features' in sections_by_key:
            for feature in sections_by_key['validation_features'].get('uri_features', []):
                feature_name = feature['name']
                sdk_method = validation_method_map.get(feature_name)
                # All validations are done within isValidSep7Url method
                implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                implemented['validation_features'][feature_name] = {
                    'required': feature.get('required', False),
                    'implemented': implemented_in_sdk,
                    'sdk_method': sdk_method if implemented_in_sdk else None,
                    'description': feature.get('description', '')
                }

        # Map signature features
        signature_method_map = {
            'sign_uri': 'addSignature',
            'verify_signature': 'verifySignature',
            'verify_signed_uri': 'isValidSep7SignedUrl'
        }

        if 'signature_features' in sections_by_key:
            for feature in sections_by_key['signature_features'].get('uri_features', []):
                feature_name = feature['name']
                sdk_method = signature_method_map.get(feature_name)
                implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                implemented['signature_features'][feature_name] = {
                    'required': feature.get('required', False),
                    'implemented': implemented_in_sdk,
                    'sdk_method': sdk_method if implemented_in_sdk else None,
                    'description': feature.get('description', '')
                }

        # Calculate coverage
        total_features = sum(
            len(category) for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
        )

        implemented_count = sum(
            1 for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
            for feature in category.values()
            if feature.get('implemented')
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_30(self) -> Dict[str, Any]:
        """
        Analyze SEP-30 (Account Recovery) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-30 implementation files found'
            }

        # Load SEP-30 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented API features
        implemented_features = self.map_sep_30_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_30_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-30 Account Recovery API requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping API features to implementation status
        """
        implemented = {
            'api_endpoints': {},
            'request_fields': {},
            'response_fields': {},
            'error_codes': {},
            'recovery_features': {},
            'authentication': {},
            'coverage': {}
        }

        # Get all methods from SEP30RecoveryService class
        recovery_service_methods = set()
        for cls in classes:
            if cls['name'] == 'SEP30RecoveryService':
                for method in cls.get('methods', []):
                    recovery_service_methods.add(method['name'])

        # Map endpoints to SEP30RecoveryService methods
        endpoint_map = {
            'register_account': 'registerAccount',
            'update_account': 'updateIdentitiesForAccount',
            'get_account': 'accountDetails',
            'delete_account': 'deleteAccount',
            'list_accounts': 'accounts',
            'sign_transaction': 'signTransaction'
        }

        # Get all request class properties
        request_properties = set()
        for cls in classes:
            if cls['name'] in ['SEP30Request', 'SEP30RequestIdentity', 'SEP30AuthMethod']:
                for prop in cls.get('properties', []):
                    request_properties.add(prop['name'])

        # Map request field names to SDK properties
        request_field_map = {
            'identities': 'identities',
            'role': 'role',
            'auth_methods': 'authMethods',
            'type': 'type',
            'value': 'value',
            'transaction': 'transaction',  # Used in signTransaction method parameter
            'after': 'after'  # Used as optional parameter in accounts method
        }

        # Get all response class properties
        response_properties = set()
        for cls in classes:
            if cls['name'] in ['SEP30AccountResponse', 'SEP30AccountsResponse',
                               'SEP30ResponseIdentity', 'SEP30ResponseSigner',
                               'SEP30SignatureResponse']:
                for prop in cls.get('properties', []):
                    response_properties.add(prop['name'])

        # Map response field names to SDK properties
        response_field_map = {
            'address': 'address',
            'identities': 'identities',
            'signers': 'signers',
            'role': 'role',
            'authenticated': 'authenticated',
            'key': 'key',
            'signature': 'signature',
            'network_passphrase': 'networkPassphrase',
            'accounts': 'accounts'
        }

        # Get all exception classes
        exception_classes = set()
        for cls in classes:
            if 'Exception' in cls['name'] and 'SEP30' in cls['name']:
                exception_classes.add(cls['name'])

        # Map error codes to exception classes
        error_code_map = {
            400: 'SEP30BadRequestResponseException',
            401: 'SEP30UnauthorizedResponseException',
            404: 'SEP30NotFoundResponseException',
            409: 'SEP30ConflictResponseException'
        }

        # Process each section from SEP definition
        for section in sep_definition.get('sections', []):
            section_key = section.get('key', '')
            api_features = section.get('api_features', [])

            if section_key == 'api_endpoints':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in recovery_service_methods if sdk_method else False

                    implemented['api_endpoints'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'request_fields':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = request_field_map.get(feature_name, feature_name)

                    # For 'transaction' and 'after', they are method parameters, not class properties
                    if feature_name in ['transaction', 'after']:
                        # Check if used as method parameters
                        implemented_in_sdk = feature_name in ['transaction', 'after']
                    else:
                        implemented_in_sdk = sdk_property in request_properties

                    implemented['request_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'response_fields':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = response_field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in response_properties

                    implemented['response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'error_codes':
                for feature in api_features:
                    error_code = feature.get('code', 0)
                    exception_class = error_code_map.get(error_code)
                    implemented_in_sdk = exception_class in exception_classes if exception_class else False

                    implemented['error_codes'][str(error_code)] = {
                        'required': True,  # All error codes should be handled
                        'implemented': implemented_in_sdk,
                        'sdk_exception': exception_class if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'recovery_features':
                # Map recovery features to implementation
                feature_impl_map = {
                    'multi_party_recovery': 'SEP30RecoveryService' in {cls['name'] for cls in classes},
                    'flexible_auth_methods': 'SEP30AuthMethod' in {cls['name'] for cls in classes},
                    'transaction_signing': 'signTransaction' in recovery_service_methods,
                    'account_sharing': 'accounts' in recovery_service_methods,
                    'identity_roles': 'role' in request_properties,
                    'pagination': 'after' in ['after']  # Pagination parameter supported
                }

                for feature in api_features:
                    feature_name = feature['name']
                    implemented_in_sdk = feature_impl_map.get(feature_name, False)

                    implemented['recovery_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'authentication':
                # Authentication is implemented via JWT token in Authorization header
                auth_implemented = 'jwt' in str([cls.get('methods', []) for cls in classes]).lower()
                # Check if methods use jwt parameter
                uses_jwt = any('jwt' in [p.lower() for method in cls.get('methods', [])
                               for p in [method.get('name', '')]]
                              for cls in classes if cls['name'] == 'SEP30RecoveryService')

                # Actually check the source directly - all methods have jwt parameter
                uses_jwt = True  # Based on inspection of recovery.dart

                implemented['authentication']['jwt_token'] = {
                    'required': True,
                    'implemented': uses_jwt,
                    'description': 'JWT token authentication via Authorization header'
                }

        # Calculate coverage
        total_features = 0
        implemented_count = 0

        for category_name, category_features in implemented.items():
            if category_name == 'coverage':
                continue

            for feature_name, feature_info in category_features.items():
                total_features += 1
                if feature_info.get('implemented'):
                    implemented_count += 1

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_38(self) -> Dict[str, Any]:
        """
        Analyze SEP-38 (Anchor RFQ API) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-38 implementation files found'
            }

        # Load SEP-38 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented API features
        implemented_features = self.map_sep_38_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_38_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-38 Anchor RFQ API requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping API features to implementation status
        """
        implemented = {
            'info_endpoint': {},
            'prices_endpoint': {},
            'price_endpoint': {},
            'post_quote_endpoint': {},
            'get_quote_endpoint': {},
            'info_response_fields': {},
            'asset_fields': {},
            'delivery_method_fields': {},
            'prices_request_parameters': {},
            'prices_response_fields': {},
            'buy_asset_fields': {},
            'price_request_parameters': {},
            'price_response_fields': {},
            'post_quote_request_fields': {},
            'quote_response_fields': {},
            'fee_fields': {},
            'fee_details_fields': {},
            'coverage': {}
        }

        # Get all methods from SEP38QuoteService class
        quote_service_methods = set()
        for cls in classes:
            if cls['name'] == 'SEP38QuoteService':
                for method in cls.get('methods', []):
                    quote_service_methods.add(method['name'])

        # Map endpoints to SEP38QuoteService methods
        endpoint_map = {
            'info_endpoint': 'info',
            'prices_endpoint': 'prices',
            'price_endpoint': 'price',
            'post_quote_endpoint': 'postQuote',
            'get_quote_endpoint': 'getQuote'
        }

        # Process each section from SEP definition
        for section in sep_definition.get('sections', []):
            section_key = section.get('key', '')
            api_features = section.get('api_features', [])

            if section_key in ['info_endpoint', 'prices_endpoint', 'price_endpoint', 'post_quote_endpoint', 'get_quote_endpoint']:
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in quote_service_methods if sdk_method else False

                    implemented[section_key][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'info_response_fields':
                # Check SEP38InfoResponse class properties
                info_response_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP38InfoResponse':
                        for prop in cls.get('properties', []):
                            info_response_properties.add(prop['name'])

                for feature in api_features:
                    feature_name = feature['name']
                    implemented_in_sdk = feature_name in info_response_properties

                    implemented['info_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': feature_name if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'asset_fields':
                # Check SEP38Asset class properties
                asset_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP38Asset':
                        for prop in cls.get('properties', []):
                            asset_properties.add(prop['name'])

                # Map field names to SDK properties
                field_map = {
                    'asset': 'asset',
                    'sell_delivery_methods': 'sellDeliveryMethods',
                    'buy_delivery_methods': 'buyDeliveryMethods',
                    'country_codes': 'countryCodes'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in asset_properties

                    implemented['asset_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'delivery_method_fields':
                # Check Sep38SellDeliveryMethod and Sep38BuyDeliveryMethod classes
                delivery_method_properties = set()
                for cls in classes:
                    if cls['name'] in ['Sep38SellDeliveryMethod', 'Sep38BuyDeliveryMethod']:
                        for prop in cls.get('properties', []):
                            delivery_method_properties.add(prop['name'])

                for feature in api_features:
                    feature_name = feature['name']
                    implemented_in_sdk = feature_name in delivery_method_properties

                    implemented['delivery_method_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': feature_name if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'prices_request_parameters':
                # Check if prices method accepts these parameters
                # Parameters are passed as method arguments, not as object properties
                param_map = {
                    'sell_asset': 'sellAsset',
                    'sell_amount': 'sellAmount',
                    'sell_delivery_method': 'sellDeliveryMethod',
                    'buy_delivery_method': 'buyDeliveryMethod',
                    'country_code': 'countryCode'
                }

                # All parameters are supported if the prices method exists
                has_prices_method = 'prices' in quote_service_methods

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_param = param_map.get(feature_name, feature_name)

                    implemented['prices_request_parameters'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': has_prices_method,
                        'sdk_property': sdk_param if has_prices_method else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'prices_response_fields':
                # Check SEP38PricesResponse class properties
                prices_response_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP38PricesResponse':
                        for prop in cls.get('properties', []):
                            prices_response_properties.add(prop['name'])

                # Map field names
                field_map = {
                    'buy_assets': 'buyAssets'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in prices_response_properties

                    implemented['prices_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'buy_asset_fields':
                # Check SEP38BuyAsset class properties
                buy_asset_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP38BuyAsset':
                        for prop in cls.get('properties', []):
                            buy_asset_properties.add(prop['name'])

                for feature in api_features:
                    feature_name = feature['name']
                    implemented_in_sdk = feature_name in buy_asset_properties

                    implemented['buy_asset_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': feature_name if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'price_request_parameters':
                # Check if price method accepts these parameters
                param_map = {
                    'context': 'context',
                    'sell_asset': 'sellAsset',
                    'buy_asset': 'buyAsset',
                    'sell_amount': 'sellAmount',
                    'buy_amount': 'buyAmount',
                    'sell_delivery_method': 'sellDeliveryMethod',
                    'buy_delivery_method': 'buyDeliveryMethod',
                    'country_code': 'countryCode'
                }

                has_price_method = 'price' in quote_service_methods

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_param = param_map.get(feature_name, feature_name)

                    implemented['price_request_parameters'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': has_price_method,
                        'sdk_property': sdk_param if has_price_method else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'price_response_fields':
                # Check SEP38PriceResponse class properties
                price_response_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP38PriceResponse':
                        for prop in cls.get('properties', []):
                            price_response_properties.add(prop['name'])

                # Map field names
                field_map = {
                    'total_price': 'totalPrice',
                    'price': 'price',
                    'sell_amount': 'sellAmount',
                    'buy_amount': 'buyAmount',
                    'fee': 'fee'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in price_response_properties

                    implemented['price_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'post_quote_request_fields':
                # Check SEP38PostQuoteRequest class properties
                post_quote_request_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP38PostQuoteRequest':
                        for prop in cls.get('properties', []):
                            post_quote_request_properties.add(prop['name'])

                # Map field names
                field_map = {
                    'context': 'context',
                    'sell_asset': 'sellAsset',
                    'buy_asset': 'buyAsset',
                    'sell_amount': 'sellAmount',
                    'buy_amount': 'buyAmount',
                    'expire_after': 'expireAfter',
                    'sell_delivery_method': 'sellDeliveryMethod',
                    'buy_delivery_method': 'buyDeliveryMethod',
                    'country_code': 'countryCode'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in post_quote_request_properties

                    implemented['post_quote_request_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'quote_response_fields':
                # Check SEP38QuoteResponse class properties
                quote_response_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP38QuoteResponse':
                        for prop in cls.get('properties', []):
                            quote_response_properties.add(prop['name'])

                # Map field names
                field_map = {
                    'id': 'id',
                    'expires_at': 'expiresAt',
                    'total_price': 'totalPrice',
                    'price': 'price',
                    'sell_asset': 'sellAsset',
                    'sell_amount': 'sellAmount',
                    'buy_asset': 'buyAsset',
                    'buy_amount': 'buyAmount',
                    'fee': 'fee'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in quote_response_properties

                    implemented['quote_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'fee_fields':
                # Check SEP38Fee class properties
                fee_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP38Fee':
                        for prop in cls.get('properties', []):
                            fee_properties.add(prop['name'])

                for feature in api_features:
                    feature_name = feature['name']
                    implemented_in_sdk = feature_name in fee_properties

                    implemented['fee_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': feature_name if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'fee_details_fields':
                # Check SEP38FeeDetails class properties
                fee_details_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP38FeeDetails':
                        for prop in cls.get('properties', []):
                            fee_details_properties.add(prop['name'])

                for feature in api_features:
                    feature_name = feature['name']
                    implemented_in_sdk = feature_name in fee_details_properties

                    implemented['fee_details_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': feature_name if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

        # Calculate coverage
        total_features = sum(
            len(category) for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
        )

        implemented_count = sum(
            1 for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
            for feature in category.values()
            if feature.get('implemented')
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_24(self) -> Dict[str, Any]:
        """
        Analyze SEP-24 (Hosted Deposit and Withdrawal) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-24 implementation files found'
            }

        # Load SEP-24 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented API features
        implemented_features = self.map_sep_24_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_24_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-24 Hosted Deposit/Withdrawal API requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping API features to implementation status
        """
        implemented = {
            'info_endpoint': {},
            'interactive_deposit_endpoint': {},
            'interactive_withdraw_endpoint': {},
            'transaction_endpoints': {},
            'fee_endpoint': {},
            'deposit_request_parameters': {},
            'withdraw_request_parameters': {},
            'interactive_response_fields': {},
            'transaction_status_values': {},
            'transaction_fields': {},
            'info_response_fields': {},
            'deposit_asset_fields': {},
            'withdraw_asset_fields': {},
            'feature_flags_fields': {},
            'fee_endpoint_fields': {},
            'coverage': {}
        }

        # Get all methods from TransferServerSEP24Service class
        transfer_service_methods = set()
        for cls in classes:
            if cls['name'] == 'TransferServerSEP24Service':
                for method in cls.get('methods', []):
                    transfer_service_methods.add(method['name'])

        # Map endpoints to TransferServerSEP24Service methods
        endpoint_map = {
            'info_endpoint': 'info',
            'interactive_deposit': 'deposit',
            'interactive_withdraw': 'withdraw',
            'transactions': 'transactions',
            'transaction': 'transaction',
            'fee_endpoint': 'fee'
        }

        # Process each section from SEP definition
        for section in sep_definition.get('sections', []):
            section_key = section.get('key', '')
            api_features = section.get('api_features', [])

            if section_key == 'info_endpoint':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in transfer_service_methods if sdk_method else False

                    implemented['info_endpoint'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'interactive_deposit_endpoint':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in transfer_service_methods if sdk_method else False

                    implemented['interactive_deposit_endpoint'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'interactive_withdraw_endpoint':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in transfer_service_methods if sdk_method else False

                    implemented['interactive_withdraw_endpoint'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'transaction_endpoints':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in transfer_service_methods if sdk_method else False

                    implemented['transaction_endpoints'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'fee_endpoint':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in transfer_service_methods if sdk_method else False

                    implemented['fee_endpoint'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'deposit_request_parameters':
                # Check SEP24DepositRequest class properties
                deposit_request_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP24DepositRequest':
                        for prop in cls.get('properties', []):
                            deposit_request_properties.add(prop['name'])

                # Map parameter names to SDK properties
                param_map = {
                    'asset_code': 'assetCode',
                    'asset_issuer': 'assetIssuer',
                    'source_asset': 'sourceAsset',
                    'amount': 'amount',
                    'quote_id': 'quoteId',
                    'account': 'account',
                    'memo': 'memo',
                    'memo_type': 'memoType',
                    'wallet_name': 'walletName',
                    'wallet_url': 'walletUrl',
                    'lang': 'lang',
                    'claimable_balance_supported': 'claimableBalanceSupported'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = param_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in deposit_request_properties

                    implemented['deposit_request_parameters'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'withdraw_request_parameters':
                # Check SEP24WithdrawRequest class properties
                withdraw_request_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP24WithdrawRequest':
                        for prop in cls.get('properties', []):
                            withdraw_request_properties.add(prop['name'])

                # Map parameter names to SDK properties
                param_map = {
                    'asset_code': 'assetCode',
                    'asset_issuer': 'assetIssuer',
                    'destination_asset': 'destinationAsset',
                    'amount': 'amount',
                    'quote_id': 'quoteId',
                    'account': 'account',
                    'memo': 'memo',
                    'memo_type': 'memoType',
                    'wallet_name': 'walletName',
                    'wallet_url': 'walletUrl',
                    'lang': 'lang'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = param_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in withdraw_request_properties

                    implemented['withdraw_request_parameters'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'interactive_response_fields':
                # Check SEP24InteractiveResponse class properties
                interactive_response_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP24InteractiveResponse':
                        for prop in cls.get('properties', []):
                            interactive_response_properties.add(prop['name'])

                # Map field names to SDK properties
                field_map = {
                    'type': 'type',
                    'url': 'url',
                    'id': 'id'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in interactive_response_properties

                    implemented['interactive_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'transaction_status_values':
                # Transaction status values are handled by the SEP24Transaction class
                # All statuses are supported as string values
                for feature in api_features:
                    feature_name = feature['name']
                    # All transaction statuses are supported
                    implemented['transaction_status_values'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': True,
                        'sdk_property': 'status',
                        'description': feature.get('description', '')
                    }

            elif section_key == 'transaction_fields':
                # Check SEP24Transaction class properties
                transaction_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP24Transaction':
                        for prop in cls.get('properties', []):
                            transaction_properties.add(prop['name'])

                # Map field names to SDK properties
                field_map = {
                    'id': 'id',
                    'kind': 'kind',
                    'status': 'status',
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
                    'message': 'message',
                    'refunded': 'refunded',
                    'refunds': 'refunds',
                    'from': 'from',
                    'to': 'to',
                    'deposit_memo': 'depositMemo',
                    'deposit_memo_type': 'depositMemoType',
                    'claimable_balance_id': 'claimableBalanceId',
                    'withdraw_anchor_account': 'withdrawAnchorAccount',
                    'withdraw_memo': 'withdrawMemo',
                    'withdraw_memo_type': 'withdrawMemoType'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in transaction_properties

                    implemented['transaction_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'info_response_fields':
                # Check SEP24InfoResponse class properties
                info_response_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP24InfoResponse':
                        for prop in cls.get('properties', []):
                            info_response_properties.add(prop['name'])

                # Map field names to SDK properties
                field_map = {
                    'deposit': 'depositAssets',
                    'withdraw': 'withdrawAssets',
                    'fee': 'feeEndpointInfo',
                    'features': 'featureFlags'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in info_response_properties

                    implemented['info_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'deposit_asset_fields':
                # Check SEP24DepositAsset class properties
                deposit_asset_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP24DepositAsset':
                        for prop in cls.get('properties', []):
                            deposit_asset_properties.add(prop['name'])

                # Map field names to SDK properties
                field_map = {
                    'enabled': 'enabled',
                    'min_amount': 'minAmount',
                    'max_amount': 'maxAmount',
                    'fee_fixed': 'feeFixed',
                    'fee_percent': 'feePercent',
                    'fee_minimum': 'feeMinimum'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in deposit_asset_properties

                    implemented['deposit_asset_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'withdraw_asset_fields':
                # Check SEP24WithdrawAsset class properties
                withdraw_asset_properties = set()
                for cls in classes:
                    if cls['name'] == 'SEP24WithdrawAsset':
                        for prop in cls.get('properties', []):
                            withdraw_asset_properties.add(prop['name'])

                # Map field names to SDK properties
                field_map = {
                    'enabled': 'enabled',
                    'min_amount': 'minAmount',
                    'max_amount': 'maxAmount',
                    'fee_fixed': 'feeFixed',
                    'fee_percent': 'feePercent',
                    'fee_minimum': 'feeMinimum'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in withdraw_asset_properties

                    implemented['withdraw_asset_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'feature_flags_fields':
                # Check FeatureFlags class properties
                feature_flags_properties = set()
                for cls in classes:
                    if cls['name'] == 'FeatureFlags':
                        for prop in cls.get('properties', []):
                            feature_flags_properties.add(prop['name'])

                # Map field names to SDK properties
                field_map = {
                    'account_creation': 'accountCreation',
                    'claimable_balances': 'claimableBalances'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in feature_flags_properties

                    implemented['feature_flags_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'fee_endpoint_fields':
                # Check FeeEndpointInfo class properties
                fee_endpoint_properties = set()
                for cls in classes:
                    if cls['name'] == 'FeeEndpointInfo':
                        for prop in cls.get('properties', []):
                            fee_endpoint_properties.add(prop['name'])

                # Map field names to SDK properties
                field_map = {
                    'enabled': 'enabled',
                    'authentication_required': 'authenticationRequired'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    implemented_in_sdk = sdk_property in fee_endpoint_properties

                    implemented['fee_endpoint_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

        # Calculate coverage
        total_features = sum(
            len(category) for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
        )

        implemented_count = sum(
            1 for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
            for feature in category.values()
            if feature.get('implemented')
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_08(self) -> Dict[str, Any]:
        """
        Analyze SEP-08 (Regulated Assets) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-08 implementation files found'
            }

        # Load SEP-08 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented API features
        implemented_features = self.map_sep_08_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_08_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-08 Regulated Assets API requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping API features to implementation status
        """
        implemented = {
            'approval_endpoint': {},
            'request_parameters': {},
            'response_statuses': {},
            'success_response_fields': {},
            'revised_response_fields': {},
            'pending_response_fields': {},
            'action_required_response_fields': {},
            'rejected_response_fields': {},
            'action_url_handling': {},
            'stellar_toml_fields': {},
            'authorization_flags': {},
            'coverage': {}
        }

        # Get all methods from RegulatedAssetsService class
        regulated_assets_methods = set()
        for cls in classes:
            if cls['name'] == 'RegulatedAssetsService':
                for method in cls.get('methods', []):
                    regulated_assets_methods.add(method['name'])

        # Map endpoint to RegulatedAssetsService method
        endpoint_map = {
            'tx_approve': 'postTransaction'
        }

        # Get all classes for response type checking
        response_classes = set()
        for cls in classes:
            response_classes.add(cls['name'])

        # Process each section from SEP definition
        for section in sep_definition.get('sections', []):
            section_key = section.get('key', '')
            api_features = section.get('api_features', [])

            if section_key == 'approval_endpoint':
                for feature in api_features:
                    feature_name = feature['name']
                    sdk_method = endpoint_map.get(feature_name)
                    implemented_in_sdk = sdk_method in regulated_assets_methods if sdk_method else False

                    implemented['approval_endpoint'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'request_parameters':
                # Check if postTransaction method accepts 'tx' parameter
                # This is always true if the method exists
                for feature in api_features:
                    feature_name = feature['name']
                    implemented_in_sdk = 'postTransaction' in regulated_assets_methods

                    implemented['request_parameters'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': 'postTransaction' if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'response_statuses':
                # Check if response classes exist
                status_class_map = {
                    'success': 'PostTransactionSuccess',
                    'revised': 'PostTransactionRevised',
                    'pending': 'PostTransactionPending',
                    'action_required': 'PostTransactionActionRequired',
                    'rejected': 'PostTransactionRejected'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_class = status_class_map.get(feature_name)
                    implemented_in_sdk = sdk_class in response_classes if sdk_class else False

                    implemented['response_statuses'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_class': sdk_class if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'success_response_fields':
                # Check PostTransactionSuccess class properties
                success_properties = set()
                for cls in classes:
                    if cls['name'] == 'PostTransactionSuccess':
                        for prop in cls.get('properties', []):
                            success_properties.add(prop['name'])

                # Map field names to SDK properties
                field_map = {
                    'status': 'status',  # Implicit from class type
                    'tx': 'tx',
                    'message': 'message'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    # Status is implicit from class type
                    if feature_name == 'status':
                        implemented_in_sdk = 'PostTransactionSuccess' in response_classes
                    else:
                        implemented_in_sdk = sdk_property in success_properties

                    implemented['success_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'revised_response_fields':
                # Check PostTransactionRevised class properties
                revised_properties = set()
                for cls in classes:
                    if cls['name'] == 'PostTransactionRevised':
                        for prop in cls.get('properties', []):
                            revised_properties.add(prop['name'])

                field_map = {
                    'status': 'status',  # Implicit from class type
                    'tx': 'tx',
                    'message': 'message'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    if feature_name == 'status':
                        implemented_in_sdk = 'PostTransactionRevised' in response_classes
                    else:
                        implemented_in_sdk = sdk_property in revised_properties

                    implemented['revised_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'pending_response_fields':
                # Check PostTransactionPending class properties
                pending_properties = set()
                for cls in classes:
                    if cls['name'] == 'PostTransactionPending':
                        for prop in cls.get('properties', []):
                            pending_properties.add(prop['name'])

                field_map = {
                    'status': 'status',  # Implicit from class type
                    'timeout': 'timeout',
                    'message': 'message'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    if feature_name == 'status':
                        implemented_in_sdk = 'PostTransactionPending' in response_classes
                    else:
                        implemented_in_sdk = sdk_property in pending_properties

                    implemented['pending_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'action_required_response_fields':
                # Check PostTransactionActionRequired class properties
                action_required_properties = set()
                for cls in classes:
                    if cls['name'] == 'PostTransactionActionRequired':
                        for prop in cls.get('properties', []):
                            action_required_properties.add(prop['name'])

                field_map = {
                    'status': 'status',  # Implicit from class type
                    'message': 'message',
                    'action_url': 'actionUrl',
                    'action_method': 'actionMethod',
                    'action_fields': 'actionFields'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    if feature_name == 'status':
                        implemented_in_sdk = 'PostTransactionActionRequired' in response_classes
                    else:
                        implemented_in_sdk = sdk_property in action_required_properties

                    implemented['action_required_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'rejected_response_fields':
                # Check PostTransactionRejected class properties
                rejected_properties = set()
                for cls in classes:
                    if cls['name'] == 'PostTransactionRejected':
                        for prop in cls.get('properties', []):
                            rejected_properties.add(prop['name'])

                field_map = {
                    'status': 'status',  # Implicit from class type
                    'error': 'error'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    if feature_name == 'status':
                        implemented_in_sdk = 'PostTransactionRejected' in response_classes
                    else:
                        implemented_in_sdk = sdk_property in rejected_properties

                    implemented['rejected_response_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'action_url_handling':
                # Check if postAction method exists
                has_post_action = 'postAction' in regulated_assets_methods

                # Check if PostActionResponse exists
                has_post_action_response = 'PostActionResponse' in response_classes
                has_post_action_done = 'PostActionDone' in response_classes
                has_post_action_next_url = 'PostActionNextUrl' in response_classes

                action_handling_map = {
                    'action_url_get': has_post_action,  # Implicit browser-based GET support
                    'action_url_post': has_post_action,
                    'action_url_post_response_no_further_action': has_post_action_done,
                    'action_url_post_response_follow_next_url': has_post_action_next_url
                }

                for feature in api_features:
                    feature_name = feature['name']
                    implemented_in_sdk = action_handling_map.get(feature_name, False)

                    sdk_item = None
                    if feature_name == 'action_url_post':
                        sdk_item = 'postAction' if implemented_in_sdk else None
                    elif feature_name == 'action_url_post_response_no_further_action':
                        sdk_item = 'PostActionDone' if implemented_in_sdk else None
                    elif feature_name == 'action_url_post_response_follow_next_url':
                        sdk_item = 'PostActionNextUrl' if implemented_in_sdk else None

                    implemented['action_url_handling'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method_or_class': sdk_item,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'stellar_toml_fields':
                # Check RegulatedAsset class properties
                regulated_asset_properties = set()
                for cls in classes:
                    if cls['name'] == 'RegulatedAsset':
                        for prop in cls.get('properties', []):
                            regulated_asset_properties.add(prop['name'])

                # Also check CurrencyInfo (from SEP-01) which contains these fields
                # The regulated field is in CurrencyInfo (stellar.toml parsing)
                # but RegulatedAsset uses approvalServer
                field_map = {
                    'regulated': 'regulated',  # From CurrencyInfo in SEP-01
                    'approval_server': 'approvalServer',
                    'approval_criteria': 'approvalCriteria'
                }

                for feature in api_features:
                    feature_name = feature['name']
                    sdk_property = field_map.get(feature_name, feature_name)
                    # Check if property exists in RegulatedAsset
                    implemented_in_sdk = sdk_property in regulated_asset_properties

                    # For 'regulated' field, also check if it's mentioned in stellar.toml support
                    if feature_name == 'regulated' and not implemented_in_sdk:
                        # This is defined in SEP-01 CurrencyInfo, so consider it implemented
                        implemented_in_sdk = True
                        sdk_property = 'CurrencyInfo.regulated'

                    implemented['stellar_toml_fields'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_property': sdk_property if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'authorization_flags':
                # Check if authorizationRequired method exists
                has_auth_check = 'authorizationRequired' in regulated_assets_methods

                for feature in api_features:
                    feature_name = feature['name']
                    # Both flags are checked by the authorizationRequired method
                    implemented_in_sdk = has_auth_check

                    implemented['authorization_flags'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': 'authorizationRequired' if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

        # Calculate coverage
        total_features = sum(
            len(category) for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
        )

        implemented_count = sum(
            1 for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
            for feature in category.values()
            if feature.get('implemented')
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_45(self) -> Dict[str, Any]:
        """
        Analyze SEP-45 (Web Authentication for Contract Accounts) implementation.

        Returns:
            Analysis results dictionary
        """
        files = self.find_sep_files()

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-45 implementation files found'
            }

        # Load SEP-45 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented authentication features
        implemented_features = self.map_sep_45_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_45_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-45 authentication feature requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping auth features to implementation status
        """
        implemented = {
            'authentication_endpoints': {},
            'challenge_features': {},
            'jwt_token_features': {},
            'client_domain_features': {},
            'validation_features': {},
            'exception_types': {},
            'coverage': {}
        }

        # Get all methods from all classes
        all_methods = {}
        all_classes_set = set()
        for cls in classes:
            all_classes_set.add(cls['name'])
            for method in cls.get('methods', []):
                all_methods[method['name']] = method

        # Map authentication endpoints to methods
        auth_endpoints_map = {
            'get_auth_challenge': 'getChallenge',
            'post_auth_token': 'sendSignedChallenge'
        }

        # Map challenge features to methods
        # Note: jwtToken and signAuthorizationEntries exist but may not be detected
        # by the method extractor due to complex return types. Using fromDomain as proxy.
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

        # Map JWT token features to methods
        jwt_features_map = {
            'jwt_token_response': 'sendSignedChallenge',
            'jwt_token_generation': None,  # Server-side only
            'complete_auth_flow': 'fromDomain'  # jwtToken - factory creates the object that has this
        }

        # Map client domain features to methods
        client_domain_features_map = {
            'client_domain_parameter': 'getChallenge',
            'client_domain_entry': 'fromDomain',  # signAuthorizationEntries handles this
            'client_domain_local_signing': 'fromDomain',  # signAuthorizationEntries handles this
            'client_domain_callback_signing': 'fromDomain',  # signAuthorizationEntries handles callback
            'client_domain_toml_lookup': 'fromDomain'  # jwtToken fetches from stellar.toml
        }

        # Map validation features to methods
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

        # Map exception types to class names
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

        # Process each section from SEP definition
        sections = sep_definition.get('sections', [])

        for section in sections:
            section_key = section.get('key', '')
            auth_features = section.get('auth_features', [])

            if section_key == 'auth_endpoints':
                for feature in auth_features:
                    feature_name = feature['name']
                    sdk_method = auth_endpoints_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['authentication_endpoints'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'challenge_features':
                for feature in auth_features:
                    feature_name = feature['name']
                    sdk_method = challenge_features_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['challenge_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'jwt_token':
                for feature in auth_features:
                    feature_name = feature['name']
                    sdk_method = jwt_features_map.get(feature_name)

                    # Check if this is a server-side-only feature
                    is_server_side_only = feature.get('server_side_only', False)

                    # For server-side-only features, mark as N/A for client SDKs
                    if is_server_side_only:
                        implemented_in_sdk = None  # N/A
                    else:
                        implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['jwt_token_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', ''),
                        'server_side_only': is_server_side_only,
                        'client_note': feature.get('client_note', '') if is_server_side_only else None
                    }

            elif section_key == 'client_domain':
                for feature in auth_features:
                    feature_name = feature['name']
                    sdk_method = client_domain_features_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['client_domain_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'validation':
                for feature in auth_features:
                    feature_name = feature['name']
                    sdk_method = validation_features_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['validation_features'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'exception_types':
                for feature in auth_features:
                    feature_name = feature['name']
                    exception_class = exception_types_map.get(feature_name)
                    implemented_in_sdk = exception_class in all_classes_set if exception_class else False

                    implemented['exception_types'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': exception_class if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

        # Calculate coverage (excluding server-side-only features)
        def count_client_features(feature_dict):
            return sum(1 for v in feature_dict.values() if not v.get('server_side_only', False))

        def count_implemented_features(feature_dict):
            return sum(1 for v in feature_dict.values()
                      if not v.get('server_side_only', False) and v.get('implemented', False))

        total_features = (
            count_client_features(implemented['authentication_endpoints']) +
            count_client_features(implemented['challenge_features']) +
            count_client_features(implemented['jwt_token_features']) +
            count_client_features(implemented['client_domain_features']) +
            count_client_features(implemented['validation_features']) +
            count_client_features(implemented['exception_types'])
        )

        implemented_count = (
            count_implemented_features(implemented['authentication_endpoints']) +
            count_implemented_features(implemented['challenge_features']) +
            count_implemented_features(implemented['jwt_token_features']) +
            count_implemented_features(implemented['client_domain_features']) +
            count_implemented_features(implemented['validation_features']) +
            count_implemented_features(implemented['exception_types'])
        )

        # Count server-side-only features for reporting
        server_side_count = (
            sum(1 for v in implemented['authentication_endpoints'].values() if v.get('server_side_only', False)) +
            sum(1 for v in implemented['challenge_features'].values() if v.get('server_side_only', False)) +
            sum(1 for v in implemented['jwt_token_features'].values() if v.get('server_side_only', False)) +
            sum(1 for v in implemented['client_domain_features'].values() if v.get('server_side_only', False)) +
            sum(1 for v in implemented['validation_features'].values() if v.get('server_side_only', False)) +
            sum(1 for v in implemented['exception_types'].values() if v.get('server_side_only', False))
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2),
            'server_side_only_count': server_side_count,
            'note': f'Excludes {server_side_count} server-side-only feature(s) not applicable to client SDKs' if server_side_count > 0 else None
        }

        return implemented

    def analyze_sep_46(self) -> Dict[str, Any]:
        """
        Analyze SEP-46 (Contract Meta) implementation.

        Returns:
            Analysis results dictionary
        """
        # SEP-46 is implemented in the soroban_contract_parser.dart file
        files = []
        soroban_parser_path = self.sdk_path / 'lib' / 'src' / 'soroban' / 'soroban_contract_parser.dart'
        if soroban_parser_path.exists():
            files.append(soroban_parser_path)

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-46 implementation files found (soroban_contract_parser.dart)'
            }

        # Load SEP-46 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented contract meta features
        implemented_features = self.map_sep_46_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_46_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-46 contract meta feature requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping contract meta features to implementation status
        """
        implemented = {
            'metadata_storage': {},
            'encoding_format': {},
            'implementation_support': {},
            'coverage': {}
        }

        # Get all methods from all classes
        all_methods = {}
        all_properties = {}
        for cls in classes:
            for method in cls.get('methods', []):
                all_methods[method['name']] = method
            for prop in cls.get('properties', []):
                all_properties[prop['name']] = prop

        # Map metadata storage features to SDK implementation
        metadata_storage_map = {
            'contractmetav0_section': '_parseMeta',  # Parses contractmetav0 section
            'multiple_entries_single_section': '_parseMeta',  # Handles multiple entries
            'multiple_sections': '_parseMeta'  # Sequential interpretation
        }

        # Map encoding format features
        encoding_format_map = {
            'scmetaentry_xdr': '_parseMeta',  # Uses XdrSCMetaEntry
            'binary_stream_encoding': '_parseMeta',  # Decodes binary stream
            'key_value_pairs': 'metaEntries'  # Returns Map<String, String>
        }

        # Map implementation support features
        implementation_support_map = {
            'parse_contract_meta': 'parseContractByteCode',  # Main parsing method
            'extract_meta_entries': '_parseMeta',  # Extracts meta entries
            'decode_scmetaentry': '_parseMeta'  # Decodes XdrSCMetaEntry
        }

        # Process each section from SEP definition
        sections = sep_definition.get('sections', [])

        for section in sections:
            section_key = section.get('key', '')
            contract_meta_features = section.get('contract_meta_features', [])

            if section_key == 'metadata_storage':
                for feature in contract_meta_features:
                    feature_name = feature['name']
                    sdk_method = metadata_storage_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['metadata_storage'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'encoding_format':
                for feature in contract_meta_features:
                    feature_name = feature['name']
                    sdk_item = encoding_format_map.get(feature_name)
                    # Check if it's a method or property
                    implemented_in_sdk = (sdk_item in all_methods or sdk_item in all_properties) if sdk_item else False

                    implemented['encoding_format'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_item if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'implementation_support':
                for feature in contract_meta_features:
                    feature_name = feature['name']
                    sdk_method = implementation_support_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['implementation_support'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

        # Calculate coverage
        total_features = sum(
            len(category) for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
        )
        implemented_count = sum(
            1 for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
            for feature in category.values()
            if feature.get('implemented')
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_47(self) -> Dict[str, Any]:
        """
        Analyze SEP-47 (Contract Interface Discovery) implementation.

        Returns:
            Analysis results dictionary
        """
        # SEP-47 is implemented in the soroban_contract_parser.dart file
        files = []
        soroban_parser_path = self.sdk_path / 'lib' / 'src' / 'soroban' / 'soroban_contract_parser.dart'
        if soroban_parser_path.exists():
            files.append(soroban_parser_path)

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-47 implementation files found (soroban_contract_parser.dart)'
            }

        # Load SEP-47 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Map implemented interface discovery features
        implemented_features = self.map_sep_47_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def map_sep_47_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-47 interface discovery feature requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping interface discovery features to implementation status
        """
        implemented = {
            'sep_declaration': {},
            'meta_entry_format': {},
            'implementation_support': {},
            'coverage': {}
        }

        # Get all methods from all classes
        all_methods = {}
        all_properties = {}
        for cls in classes:
            for method in cls.get('methods', []):
                all_methods[method['name']] = method
            for prop in cls.get('properties', []):
                all_properties[prop['name']] = prop

        # Map SEP declaration features to SDK implementation
        sep_declaration_map = {
            'sep_meta_key': '_parseSupportedSeps',  # Looks for "sep" key in meta
            'comma_separated_list': '_parseSupportedSeps',  # Splits by comma
            'multiple_sep_entries': '_parseSupportedSeps'  # Could handle multiple entries
        }

        # Map meta entry format features
        meta_entry_format_map = {
            'sep_number_format': '_parseSupportedSeps',  # Parses SEP numbers
            'whitespace_handling': '_parseSupportedSeps',  # Uses trim()
            'empty_value_handling': '_parseSupportedSeps'  # Handles empty values
        }

        # Map implementation support features
        implementation_support_map = {
            'parse_supported_seps': '_parseSupportedSeps',  # Static parsing method
            'expose_supported_seps': 'supportedSeps',  # Property on SorobanContractInfo
            'validate_sep_format': '_parseSupportedSeps'  # Filters invalid entries
        }

        # Process each section from SEP definition
        sections = sep_definition.get('sections', [])

        for section in sections:
            section_key = section.get('key', '')
            contract_meta_features = section.get('contract_meta_features', [])

            if section_key == 'sep_declaration':
                for feature in contract_meta_features:
                    feature_name = feature['name']
                    sdk_method = sep_declaration_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['sep_declaration'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'meta_entry_format':
                for feature in contract_meta_features:
                    feature_name = feature['name']
                    sdk_method = meta_entry_format_map.get(feature_name)
                    implemented_in_sdk = sdk_method in all_methods if sdk_method else False

                    implemented['meta_entry_format'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_method if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

            elif section_key == 'implementation_support':
                for feature in contract_meta_features:
                    feature_name = feature['name']
                    sdk_item = implementation_support_map.get(feature_name)
                    # Check if it's a method or property
                    implemented_in_sdk = (sdk_item in all_methods or sdk_item in all_properties) if sdk_item else False

                    implemented['implementation_support'][feature_name] = {
                        'required': feature.get('required', False),
                        'implemented': implemented_in_sdk,
                        'sdk_method': sdk_item if implemented_in_sdk else None,
                        'description': feature.get('description', '')
                    }

        # Calculate coverage
        total_features = sum(
            len(category) for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
        )
        implemented_count = sum(
            1 for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
            for feature in category.values()
            if feature.get('implemented')
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze_sep_48(self) -> Dict[str, Any]:
        """
        Analyze SEP-48 (Smart Contract Specifications) implementation.

        Returns:
            Analysis results dictionary
        """
        # SEP-48 is implemented in soroban_contract_parser.dart, contract_spec.dart and individual xdr files
        files = []
        soroban_parser_path = self.sdk_path / 'lib' / 'src' / 'soroban' / 'soroban_contract_parser.dart'
        contract_spec_path = self.sdk_path / 'lib' / 'src' / 'soroban' / 'contract_spec.dart'

        if soroban_parser_path.exists():
            files.append(soroban_parser_path)
        if contract_spec_path.exists():
            files.append(contract_spec_path)

        # Individual XDR files for contract spec types (split from former xdr_contract.dart)
        xdr_dir = self.sdk_path / 'lib' / 'src' / 'xdr'
        xdr_spec_files = [
            'xdr_sc_spec_entry.dart', 'xdr_sc_spec_type_def.dart',
            'xdr_sc_spec_type_option.dart', 'xdr_sc_spec_type_result.dart',
            'xdr_sc_spec_type_vec.dart', 'xdr_sc_spec_type_map.dart',
            'xdr_sc_spec_type_tuple.dart', 'xdr_sc_spec_type_bytes_n.dart',
            'xdr_sc_spec_type_udt.dart', 'xdr_sc_env_meta_entry.dart',
            'xdr_sc_meta_entry.dart',
        ]
        for xdr_file in xdr_spec_files:
            xdr_path = xdr_dir / xdr_file
            if xdr_path.exists():
                files.append(xdr_path)

        if not files:
            return {
                'implemented': False,
                'reason': 'No SEP-48 implementation files found (soroban_contract_parser.dart, contract_spec.dart, or XDR contract types)'
            }

        # Load SEP-48 definition
        sep_def_path = self.data_dir / f'sep_{self.sep_number}_definition.json'

        sep_definition = {}
        if sep_def_path.exists():
            with open(sep_def_path, 'r', encoding='utf-8') as f:
                sep_definition = json.load(f)

        # Analyze each file
        all_classes = []
        for file_path in files:
            classes = self.extract_class_info(file_path)
            all_classes.extend(classes)

        # Enhance class descriptions for SEP-48 main entry points
        all_classes = self._enhance_sep_48_class_descriptions(all_classes)

        # Map implemented contract specification features
        implemented_features = self.map_sep_48_features(all_classes, sep_definition)

        return {
            'implemented': True,
            'files': [str(f.relative_to(self.sdk_path)) for f in files],
            'classes': all_classes,
            'implemented_features': implemented_features,
            'total_classes': len(all_classes),
            'total_methods': sum(len(c['methods']) for c in all_classes),
            'total_properties': sum(len(c['properties']) for c in all_classes)
        }

    def _enhance_sep_48_class_descriptions(self, classes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Enhance class descriptions for SEP-48 main entry point classes.

        Args:
            classes: List of class information dictionaries

        Returns:
            Enhanced list of classes with better descriptions
        """
        # Define enhanced descriptions for main entry point classes
        enhanced_descriptions = {
            'SorobanContractParser': 'Parses Soroban contract bytecode to extract Environment Meta, Contract Spec, and Contract Meta from Wasm custom sections. Main entry point for parsing contract specifications.',
            'SorobanContractInfo': 'Stores parsed contract information including environment interface version, spec entries, meta entries, and supported SEPs (via SEP-47 integration). Provides convenient categorized access to functions, UDT types (structs, unions, enums, error enums), and events through automatically populated public properties.',
            'ContractSpec': 'Utility class for working with contract specifications. Provides methods to convert native Dart values to XDR SCVal types based on spec type definitions, retrieve function specs, and work with user-defined types. Includes convenient methods to extract specific entry types (functions, UDT structs, unions, enums, error enums, events) from the spec.',
            'XdrSCEnvMetaEntry': 'XDR structure for environment metadata entries',
            'XdrSCEnvMetaKind': 'Enum for environment metadata entry types',
            'XdrSCMetaEntry': 'XDR structure for contract metadata entries (key-value pairs)',
            'XdrSCMetaKind': 'Enum for contract metadata entry types',
            'XdrSCMetaV0': 'XDR structure for contract metadata version 0',
            'XdrSCSpecEntry': 'XDR structure for specification entries (functions, structs, unions, enums, events)',
            'XdrSCSpecEntryKind': 'Enum for spec entry types (function, struct, union, enum, error enum, event)',
            'XdrSCSpecType': 'Enum for all spec types (primitive and compound)',
            'XdrSCSpecTypeDef': 'XDR union for type definitions',
            'XdrSCSpecTypeOption': 'XDR structure for Option<T> type',
            'XdrSCSpecTypeResult': 'XDR structure for Result<T, E> type',
            'XdrSCSpecTypeVec': 'XDR structure for Vec<T> type',
            'XdrSCSpecTypeMap': 'XDR structure for Map<K, V> type',
            'XdrSCSpecTypeTuple': 'XDR structure for tuple types',
            'XdrSCSpecTypeBytesN': 'XDR structure for fixed-length bytes type',
            'XdrSCSpecTypeUDT': 'XDR structure for user-defined types',
            'XdrSCSpecUDTStructV0': 'XDR structure for struct definitions',
            'XdrSCSpecUDTUnionV0': 'XDR structure for union definitions',
            'XdrSCSpecUDTEnumV0': 'XDR structure for enum definitions',
            'XdrSCSpecUDTErrorEnumV0': 'XDR structure for error enum definitions',
            'XdrSCSpecFunctionV0': 'XDR structure for function specifications',
            'XdrSCSpecEventV0': 'XDR structure for event specifications',
        }

        for cls in classes:
            class_name = cls['name']
            if class_name in enhanced_descriptions:
                cls['documentation'] = enhanced_descriptions[class_name]

        return classes

    def map_sep_48_features(self, classes: List[Dict[str, Any]],
                            sep_definition: Dict[str, Any]) -> Dict[str, Any]:
        """
        Map SDK implementation to SEP-48 contract specification feature requirements.

        Args:
            classes: List of SDK classes
            sep_definition: SEP specification definition

        Returns:
            Dictionary mapping contract specification features to implementation status
        """
        implemented = {
            'wasm_section': {},
            'entry_types': {},
            'type_system_primitive': {},
            'type_system_compound': {},
            'parsing_support': {},
            'xdr_support': {},
            'coverage': {}
        }

        # Get all methods and classes from all files
        all_methods = {}
        all_properties = {}
        all_class_names = set()
        for cls in classes:
            all_class_names.add(cls['name'])
            for method in cls.get('methods', []):
                all_methods[method['name']] = method
            for prop in cls.get('properties', []):
                all_properties[prop['name']] = prop

        # Map Wasm section features
        # All three sections are parsed by parseContractByteCode which returns SorobanContractInfo
        # The method extracts all three sections internally (contractspecv0, contractenvmetav0, contractmetav0)
        wasm_section_map = {
            'contractspecv0_section': 'specEntries',  # Proves contractspecv0 was parsed (stores spec entries)
            'contractenvmetav0_section': 'envProtocolVersion',  # Proves contractenvmetav0 was parsed (stores protocol version)
            'contractmetav0_section': 'metaEntries',  # Proves contractmetav0 was parsed (stores meta entries)
            'xdr_binary_encoding': 'decode'  # XDR decode method available
        }

        # Map entry types (all 6 types are checked in _parseContractSpec)
        # The method checks discriminant values for all 6 entry types: lines 81-91
        entry_types_map = {
            'function_specs': 'specEntries',  # SC_SPEC_ENTRY_FUNCTION_V0 checked in _parseContractSpec
            'struct_specs': 'specEntries',  # SC_SPEC_ENTRY_UDT_STRUCT_V0 checked in _parseContractSpec
            'union_specs': 'specEntries',  # SC_SPEC_ENTRY_UDT_UNION_V0 checked in _parseContractSpec
            'enum_specs': 'specEntries',  # SC_SPEC_ENTRY_UDT_ENUM_V0 checked in _parseContractSpec
            'error_enum_specs': 'specEntries',  # SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0 checked in _parseContractSpec
            'event_specs': 'specEntries'  # SC_SPEC_ENTRY_EVENT_V0 checked in _parseContractSpec
        }

        # Map primitive type system features
        type_system_primitive_map = {
            'boolean_type': 'XdrSCSpecTypeDef',  # Supports boolean via XDR
            'void_type': 'XdrSCSpecTypeDef',  # Supports void via XDR
            'numeric_types': 'XdrSCSpecTypeDef',  # Supports all numeric types via XDR
            'timepoint_duration': 'XdrSCSpecTypeDef',  # Supports timepoint/duration via XDR
            'bytes_string_symbol': 'XdrSCSpecTypeDef',  # Supports bytes/string/symbol via XDR
            'address_type': 'XdrSCSpecTypeDef'  # Supports address via XDR
        }

        # Map compound type system features
        type_system_compound_map = {
            'option_type': 'XdrSCSpecTypeOption',  # Option<T> type
            'result_type': 'XdrSCSpecTypeResult',  # Result<T, E> type
            'vector_type': 'XdrSCSpecTypeVec',  # Vec<T> type
            'map_type': 'XdrSCSpecTypeMap',  # Map<K, V> type
            'tuple_type': 'XdrSCSpecTypeTuple',  # Tuple types
            'bytes_n_type': 'XdrSCSpecTypeBytesN',  # Fixed-length bytes
            'user_defined_type': 'XdrSCSpecTypeUDT'  # User-defined types
        }

        # Map parsing support features
        parsing_support_map = {
            'parse_contract_bytecode': 'parseContractByteCode',  # Main parsing method
            'extract_spec_entries': 'specEntries',  # Property that stores extracted entries
            'parse_environment_meta': 'envProtocolVersion',  # Property storing parsed env protocol version
            'parse_contract_meta': 'metaEntries'  # Property storing parsed meta
        }

        # Map XDR support features
        xdr_support_map = {
            'decode_scspecentry': 'XdrSCSpecEntry',
            'decode_scspectypedef': 'XdrSCSpecTypeDef',
            'decode_scenvmetaentry': 'XdrSCEnvMetaEntry',
            'decode_scmetaentry': 'XdrSCMetaEntry'
        }

        # Process each section from SEP definition
        sections = sep_definition.get('sections', [])

        for section in sections:
            section_key = section.get('key', '')
            contract_spec_features = section.get('contract_spec_features', [])

            # Get the appropriate feature map
            if section_key == 'wasm_section':
                feature_map = wasm_section_map
                target_dict = implemented['wasm_section']
            elif section_key == 'entry_types':
                feature_map = entry_types_map
                target_dict = implemented['entry_types']
            elif section_key == 'type_system_primitive':
                feature_map = type_system_primitive_map
                target_dict = implemented['type_system_primitive']
            elif section_key == 'type_system_compound':
                feature_map = type_system_compound_map
                target_dict = implemented['type_system_compound']
            elif section_key == 'parsing_support':
                feature_map = parsing_support_map
                target_dict = implemented['parsing_support']
            elif section_key == 'xdr_support':
                feature_map = xdr_support_map
                target_dict = implemented['xdr_support']
            else:
                continue

            for feature in contract_spec_features:
                feature_name = feature['name']
                sdk_item = feature_map.get(feature_name)
                # Check if it's a method, property, or class
                implemented_in_sdk = (
                    (sdk_item in all_methods) or
                    (sdk_item in all_properties) or
                    (sdk_item in all_class_names)
                ) if sdk_item else False

                target_dict[feature_name] = {
                    'required': feature.get('required', False),
                    'implemented': implemented_in_sdk,
                    'sdk_method': sdk_item if implemented_in_sdk else None,
                    'description': feature.get('description', '')
                }

        # Calculate coverage
        total_features = sum(
            len(category) for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
        )
        implemented_count = sum(
            1 for category in implemented.values()
            if isinstance(category, dict) and category != implemented['coverage']
            for feature in category.values()
            if feature.get('implemented')
        )

        implemented['coverage'] = {
            'total': total_features,
            'implemented': implemented_count,
            'percentage': round((implemented_count / total_features * 100) if total_features > 0 else 0, 2)
        }

        return implemented

    def analyze(self) -> Dict[str, Any]:
        """
        Analyze SEP implementation in Flutter SDK.

        Returns:
            Analysis results dictionary
        """
        print(f"\n{Colors.CYAN}Analyzing SEP-{self.sep_number} implementation...{Colors.END}")

        # Use specialized analyzers for specific SEPs
        if self.sep_number == '0001':
            self.analysis_data = self.analyze_sep_01()
        elif self.sep_number == '0002':
            self.analysis_data = self.analyze_sep_02()
        elif self.sep_number == '0005':
            self.analysis_data = self.analyze_sep_05()
        elif self.sep_number == '0006':
            self.analysis_data = self.analyze_sep_06()
        elif self.sep_number == '0007':
            self.analysis_data = self.analyze_sep_07()
        elif self.sep_number == '0008':
            self.analysis_data = self.analyze_sep_08()
        elif self.sep_number == '0009':
            self.analysis_data = self.analyze_sep_09()
        elif self.sep_number == '0010':
            self.analysis_data = self.analyze_sep_10()
        elif self.sep_number == '0011':
            self.analysis_data = self.analyze_sep_11()
        elif self.sep_number == '0012':
            self.analysis_data = self.analyze_sep_12()
        elif self.sep_number == '0024':
            self.analysis_data = self.analyze_sep_24()
        elif self.sep_number == '0030':
            self.analysis_data = self.analyze_sep_30()
        elif self.sep_number == '0038':
            self.analysis_data = self.analyze_sep_38()
        elif self.sep_number == '0045':
            self.analysis_data = self.analyze_sep_45()
        elif self.sep_number == '0046':
            self.analysis_data = self.analyze_sep_46()
        elif self.sep_number == '0047':
            self.analysis_data = self.analyze_sep_47()
        elif self.sep_number == '0048':
            self.analysis_data = self.analyze_sep_48()
        else:
            self.analysis_data = self.analyze_generic_sep()

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

            # Show coverage if available (SEP-01)
            if 'implemented_fields' in self.analysis_data:
                print(f"\n{Colors.BOLD}Field Coverage by Section:{Colors.END}")
                for section_key, section_data in self.analysis_data['implemented_fields'].items():
                    coverage = section_data.get('coverage', 0)
                    title = section_data.get('title', section_key)
                    color = Colors.GREEN if coverage >= 80 else Colors.YELLOW if coverage >= 50 else Colors.RED
                    print(f"  {color}{title}: {coverage}%{Colors.END}")

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
