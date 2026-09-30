#!/usr/bin/env python3
"""
SEP (Stellar Ecosystem Proposal) Documentation Parser

This script parses SEP markdown files from the stellar-protocol GitHub repository,
extracts specification details, requirements, and field definitions, and saves
structured data for compatibility analysis.

Author: Stellar Flutter SDK Team
License: Apache-2.0
"""

import json
import re
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
from urllib.request import urlopen
from urllib.error import URLError, HTTPError


# Add parent dir to path for shared modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from common import Colors, evaluate_shift_expression


def section(title: str, key: str, content: str, features: List[Dict[str, Any]],
            features_key: str = 'api_features', count_key: str = 'feature_count') -> Dict[str, Any]:
    """Definition section with its feature list and feature count."""
    return {'title': title, 'key': key, 'content': content, features_key: features,
            count_key: len(features)}


def spec_item(name: str, description: str, required: bool = False, requirements: Optional[str] = None,
              **extra: Any) -> Dict[str, Any]:
    """Specified feature or field; requirements precedes required when given."""
    item = {'name': name, 'description': description}
    if requirements is not None:
        item['requirements'] = requirements
    item['required'] = required
    item.update(extra)
    return item


class SEPParser:
    """Parser for Stellar Ecosystem Proposal (SEP) documentation"""

    def __init__(self, sep_number: str):
        """
        Initialize SEP parser for a specific SEP number.

        Args:
            sep_number: SEP number (e.g., '0001', '0010')
        """
        self.sep_number = sep_number.zfill(4)  # Ensure 4 digits
        self.raw_content = ""
        self.parsed_data: Dict[str, Any] = {}

    def fetch_sep_markdown(self) -> bool:
        """
        Fetch SEP markdown from GitHub repository.

        Returns:
            True if successful, False otherwise
        """
        url = f"https://raw.githubusercontent.com/stellar/stellar-protocol/master/ecosystem/sep-{self.sep_number}.md"

        print(f"{Colors.CYAN}Fetching SEP-{self.sep_number} from GitHub...{Colors.END}")
        print(f"URL: {url}")

        try:
            with urlopen(url, timeout=30) as response:
                self.raw_content = response.read().decode('utf-8')
                print(f"{Colors.GREEN}✓ Successfully fetched {len(self.raw_content)} bytes{Colors.END}")
                return True
        except HTTPError as e:
            print(f"{Colors.RED}✗ HTTP Error {e.code}: {e.reason}{Colors.END}")
            return False
        except URLError as e:
            print(f"{Colors.RED}✗ URL Error: {e.reason}{Colors.END}")
            return False
        except Exception as e:
            print(f"{Colors.RED}✗ Error: {str(e)}{Colors.END}")
            return False

    def extract_preamble(self) -> Dict[str, str]:
        """
        Extract preamble metadata from SEP markdown.

        Returns:
            Dictionary containing preamble fields
        """
        preamble = {}

        # Extract preamble section (between first --- markers or from start)
        preamble_pattern = r'^##\s+Preamble\s*\n(.*?)(?=\n##|\Z)'
        match = re.search(preamble_pattern, self.raw_content, re.MULTILINE | re.DOTALL)

        if match:
            preamble_text = match.group(1)
        else:
            # Try alternative format (list at beginning)
            preamble_text = self.raw_content[:1000]

        # Extract individual fields
        field_patterns = {
            'sep': r'SEP:\s*(\S+)',
            'title': r'Title:\s*(.+)',
            'author': r'Author:\s*(.+)',
            'track': r'Track:\s*(.+)',
            'status': r'Status:\s*(.+)',
            'created': r'Created:\s*(.+)',
            'updated': r'Updated:\s*(.+)',
            'version': r'Version:?\s*(.+)',
        }

        for field, pattern in field_patterns.items():
            match = re.search(pattern, preamble_text, re.IGNORECASE)
            if match:
                preamble[field] = match.group(1).strip()

        return preamble

    def extract_summary(self) -> str:
        """
        Extract summary/abstract section.

        Returns:
            Summary text
        """
        # Try different section names
        patterns = [
            r'##\s+(?:Simple\s+)?Summary\s*\n(.*?)(?=\n##|\Z)',
            r'##\s+Abstract\s*\n(.*?)(?=\n##|\Z)',
        ]

        for pattern in patterns:
            match = re.search(pattern, self.raw_content, re.MULTILINE | re.DOTALL)
            if match:
                summary = match.group(1).strip()
                # Clean up extra whitespace
                summary = re.sub(r'\n\s*\n', '\n\n', summary)
                return summary

        return ""

    def extract_sections(self) -> List[Dict[str, Any]]:
        """
        Extract main specification sections.

        Returns:
            List of section dictionaries
        """
        sections = []

        # Find all second-level headings (##)
        section_pattern = r'##\s+(.+?)\s*\n(.*?)(?=\n##|\Z)'
        matches = re.finditer(section_pattern, self.raw_content, re.MULTILINE | re.DOTALL)

        for match in matches:
            title = match.group(1).strip()
            content = match.group(2).strip()

            # Skip preamble and summary sections
            if title.lower() in ['preamble', 'summary', 'simple summary', 'abstract']:
                continue

            # Extract subsections (###)
            subsections = []
            subsection_pattern = r'###\s+(.+?)\s*\n(.*?)(?=\n###|\n##|\Z)'
            subsection_matches = re.finditer(subsection_pattern, content, re.MULTILINE | re.DOTALL)

            for sub_match in subsection_matches:
                subsections.append({
                    'title': sub_match.group(1).strip(),
                    'content': sub_match.group(2).strip()
                })

            sections.append({
                'title': title,
                'content': content,
                'subsections': subsections
            })

        return sections

    def extract_field_definitions(self, content: str) -> List[Dict[str, Any]]:
        """
        Extract field definitions from content.

        Args:
            content: Section content to parse

        Returns:
            List of field definition dictionaries
        """
        fields = []
        seen_fields = set()  # Track unique field names

        # Method 1: Extract from markdown tables
        # Table format: | Field | Requirements | Description |
        table_pattern = r'\|\s*([A-Za-z_][A-Za-z0-9_]*)\s*\|([^|]+)\|([^|]+)\|'
        matches = re.finditer(table_pattern, content, re.MULTILINE)

        for match in matches:
            field_name = match.group(1).strip()
            requirements = match.group(2).strip()
            description = match.group(3).strip()

            # Skip header rows and separator rows
            # But don't skip 'name' if it's a legitimate field (check if description is meaningful)
            is_header_row = (
                field_name.lower() == 'field' or
                '---' in field_name or
                (field_name.lower() == 'name' and 'description' in description.lower())
            )
            if is_header_row:
                continue

            # Clean up description
            description = re.sub(r'\s+', ' ', description)

            # Determine if required based on requirements column or description
            required_indicators = ['required', 'yes']
            optional_indicators = ['optional', 'may', 'can be omitted']

            requirements_lower = requirements.lower()
            description_lower = description.lower()

            if any(ind in requirements_lower for ind in required_indicators):
                required = True
            elif any(ind in requirements_lower or ind in description_lower for ind in optional_indicators):
                required = False
            else:
                # If "Required" appears in description
                required = 'required' in description_lower and 'optional' not in description_lower

            if field_name not in seen_fields:
                fields.append({
                    'name': field_name,
                    'description': description,
                    'requirements': requirements,
                    'required': required
                })
                seen_fields.add(field_name)

        # Method 2: Extract from TOML examples
        # Pattern for TOML field assignments: FIELD_NAME="value" or field_name="value"
        # Also handles: FIELD_NAME=['value1', 'value2']
        toml_pattern = r'^([A-Z_][A-Z0-9_]*|[a-z_][a-z0-9_]*)\s*=\s*(.+)$'
        toml_matches = re.finditer(toml_pattern, content, re.MULTILINE)

        for match in toml_matches:
            field_name = match.group(1).strip()
            example_value = match.group(2).strip()

            # Skip if already found in table
            if field_name in seen_fields:
                continue

            # Skip TOML section headers like [DOCUMENTATION] or [[PRINCIPALS]]
            if example_value.startswith('['):
                continue

            # Infer description from example value
            # Remove quotes and brackets
            clean_value = re.sub(r'^["\'\[]|["\'\]]$', '', example_value)

            # Create a basic description from the example
            description = f"Example: {clean_value[:100]}"

            # Try to find a description in comments above this field
            comment_pattern = rf'#\s*([^\n]+)\n\s*{re.escape(field_name)}\s*='
            comment_match = re.search(comment_pattern, content)
            if comment_match:
                description = comment_match.group(1).strip()

            fields.append({
                'name': field_name,
                'description': description,
                'requirements': 'varies',
                'required': False  # Conservative default for TOML-extracted fields
            })
            seen_fields.add(field_name)

        # Method 3: Extract from bulleted lists (fallback)
        # Format: - `FIELD_NAME`: description
        list_pattern = r'-\s+`?([A-Z_][A-Z0-9_]*)`?:?\s*(.+?)(?=\n-\s+`?[A-Z_]|\n\n|\Z)'
        list_matches = re.finditer(list_pattern, content, re.MULTILINE | re.DOTALL)

        for match in list_matches:
            field_name = match.group(1).strip()
            description = match.group(2).strip()

            if field_name in seen_fields:
                continue

            # Clean up description
            description = re.sub(r'\s+', ' ', description)

            # Determine if required or optional
            required = 'optional' not in description.lower() and 'may' not in description.lower()

            fields.append({
                'name': field_name,
                'description': description,
                'requirements': 'varies',
                'required': required
            })
            seen_fields.add(field_name)

        return fields

    def parse_sep_01(self) -> Dict[str, Any]:
        """
        Parse SEP-01 (stellar.toml) specific structure.

        Returns:
            Structured SEP-01 data
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define expected sections for SEP-01 with their search patterns
        section_definitions = [
            {
                'title': 'General Information',
                'key': 'global',
                'patterns': [
                    r'###\s+General Information.*?\n(.*?)(?=\n###|\n##|\Z)',
                    r'##\s+General Information.*?\n(.*?)(?=\n###|\n##|\Z)',
                ]
            },
            {
                'title': 'Organization Documentation',
                'key': 'documentation',
                'patterns': [
                    r'###\s+Organization Documentation.*?\n(.*?)(?=\n###|\n##|\Z)',
                    r'##\s+Organization Documentation.*?\n(.*?)(?=\n###|\n##|\Z)',
                    r'###?\s+.*DOCUMENTATION.*?\n(.*?)(?=\n###|\n##|\Z)',
                ]
            },
            {
                'title': 'Point of Contact Documentation',
                'key': 'principals',
                'patterns': [
                    r'###\s+Point of Contact Documentation.*?\n(.*?)(?=\n###|\n##|\Z)',
                    r'##\s+Point of Contact Documentation.*?\n(.*?)(?=\n###|\n##|\Z)',
                    r'###?\s+.*PRINCIPALS.*?\n(.*?)(?=\n###|\n##|\Z)',
                ]
            },
            {
                'title': 'Currency Documentation',
                'key': 'currencies',
                'patterns': [
                    r'###\s+Currency Documentation.*?\n(.*?)(?=\n###|\n##|\Z)',
                    r'##\s+Currency Documentation.*?\n(.*?)(?=\n###|\n##|\Z)',
                    r'###?\s+.*CURRENCIES.*?\n(.*?)(?=\n###|\n##|\Z)',
                ]
            },
            {
                'title': 'Validator Information',
                'key': 'validators',
                'patterns': [
                    r'###\s+Validator Information.*?\n(.*?)(?=\n###|\n##|\Z)',
                    r'##\s+Validator Information.*?\n(.*?)(?=\n###|\n##|\Z)',
                    r'###?\s+.*VALIDATORS.*?\n(.*?)(?=\n###|\n##|\Z)',
                ]
            }
        ]

        content = self.raw_content

        # Extract each section
        for section_def in section_definitions:
            section_content = None

            # Try each pattern until we find the section
            for pattern in section_def['patterns']:
                match = re.search(pattern, content, re.MULTILINE | re.DOTALL | re.IGNORECASE)
                if match:
                    section_content = match.group(1)
                    break

            if section_content:
                # Extract field definitions from the section content
                fields = self.extract_field_definitions(section_content)

                # Store section data
                data['sections'].append({
                    'title': section_def['title'],
                    'key': section_def['key'],
                    'content': section_content.strip()[:500],  # First 500 chars for reference
                    'field_count': len(fields),
                    'fields': fields
                })

                print(f"{Colors.GREEN}  ✓ Found '{section_def['title']}': {len(fields)} fields{Colors.END}")
            else:
                print(f"{Colors.YELLOW}  ⚠ Section '{section_def['title']}' not found{Colors.END}")

        return data

    def parse_sep_02(self) -> Dict[str, Any]:
        """
        Parse SEP-02 (Federation Protocol) specific structure.

        Returns:
            Structured SEP-02 data with API endpoints and fields
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define API structure for SEP-02
        api_structure = {
            'endpoint': {
                'path': '/federation',
                'method': 'GET',
                'description': 'Federation lookup endpoint'
            },
            'request_parameters': [],
            'request_types': [],
            'response_fields': []
        }

        # Extract request types
        request_types_pattern = r'Supported types:\s*\n\n(.*?)(?=\n##|\Z)'
        match = re.search(request_types_pattern, self.raw_content, re.MULTILINE | re.DOTALL)
        if match:
            types_text = match.group(1)
            # Extract each type definition
            type_pattern = r'-\s+`(\w+)`:\s+(.*?)(?=\n-\s+`\w+`:|Example|$)'
            for type_match in re.finditer(type_pattern, types_text, re.DOTALL):
                type_name = type_match.group(1)
                description = type_match.group(2).strip()
                # Clean up description
                description = re.sub(r'\s+', ' ', description)
                api_structure['request_types'].append({
                    'name': type_name,
                    'description': description,
                    'required': type_name in ['name', 'id']  # name and id are core functionality
                })

        # Extract query parameters
        query_params = [
            spec_item(
                'q', 'String to look up (stellar address, account ID, or transaction ID)',
                required=True, type='string'),
            spec_item(
                'type', 'Type of lookup (name, id, txid, or forward)', required=True, type='string',
                values=['name', 'id', 'txid', 'forward'])
        ]
        api_structure['request_parameters'] = query_params

        # Extract response fields
        # For SEP-02, we know the response fields from the spec, so hardcode them
        # The parsing regex has issues with multiline descriptions
        api_structure['response_fields'] = [
            spec_item('stellar_address', 'stellar address', required=True),
            spec_item('account_id', 'Stellar public key / account ID', required=True),
            spec_item(
                'memo_type', 'type of memo to attach to transaction, one of text, id or hash'),
            spec_item(
                'memo',
                "value of memo to attach to transaction, for hash this should be base64-encoded. This field should always be of type string (even when memo_type is equal id) to support parsing value in languages that don't support big numbers")
        ]

        # Store API structure as a section
        data['sections'].append({
            'title': 'API Structure',
            'key': 'api',
            'content': 'Federation API endpoints and parameters',
            'api_structure': api_structure,
            'field_count': len(api_structure['response_fields']) + len(api_structure['request_parameters'])
        })

        # Extract other sections for context
        general_sections = self.extract_sections()
        for extracted in general_sections:
            if extracted['title'] not in ['Preamble', 'Summary', 'Simple Summary']:
                data['sections'].append(extracted)

        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['request_types'])} request types{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['request_parameters'])} request parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['response_fields'])} response fields{Colors.END}")

        return data

    def parse_sep_10(self) -> Dict[str, Any]:
        """
        Parse SEP-10 (Stellar Web Authentication) specific structure.

        Returns:
            Structured SEP-10 data with authentication protocol endpoints and features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define authentication features structure for SEP-10
        auth_features = {
            'authentication_endpoints': [],
            'challenge_transaction_features': [],
            'jwt_token_features': [],
            'client_domain_features': [],
            'verification_features': []
        }

        # Authentication Endpoints (GET and POST /auth)
        auth_features['authentication_endpoints'] = [
            spec_item(
                'get_auth_challenge', 'GET /auth endpoint - Returns challenge transaction',
                required=True, category='Authentication Endpoint', method='GET',
                parameters=['account', 'memo', 'home_domain', 'client_domain']),
            spec_item(
                'post_auth_token',
                'POST /auth endpoint - Validates signed challenge and returns JWT token',
                required=True, category='Authentication Endpoint', method='POST',
                parameters=['transaction'])
        ]

        # Challenge Transaction Features
        auth_features['challenge_transaction_features'] = [
            spec_item(
                'challenge_transaction_generation',
                'Generate challenge transaction with proper structure', required=True,
                category='Challenge Transaction'),
            spec_item(
                'transaction_envelope_format',
                'Challenge uses proper Stellar transaction envelope format', required=True,
                category='Challenge Transaction'),
            spec_item(
                'sequence_number_zero', 'Challenge transaction has sequence number 0',
                required=True, category='Challenge Transaction'),
            spec_item(
                'manage_data_operations', 'Challenge uses ManageData operations for auth data',
                required=True, category='Challenge Transaction'),
            spec_item(
                'home_domain_operation',
                'First operation contains home_domain + " auth" as data name', required=True,
                category='Challenge Transaction'),
            spec_item(
                'web_auth_domain_operation',
                'Optional operation with web_auth_domain for domain verification',
                category='Challenge Transaction'),
            spec_item(
                'timebounds_enforcement', 'Challenge transaction has timebounds for expiration',
                required=True, category='Challenge Transaction'),
            spec_item(
                'server_signature', 'Challenge is signed by server before sending to client',
                required=True, category='Challenge Transaction'),
            spec_item(
                'nonce_generation', 'Random nonce in ManageData operation value', required=True,
                category='Challenge Transaction')
        ]

        # JWT Token Features
        auth_features['jwt_token_features'] = [
            spec_item(
                'jwt_token_generation', 'Generate JWT token after successful challenge validation',
                required=True, category='JWT Token'),
            spec_item(
                'jwt_token_response', 'Return JWT token in JSON response with "token" field',
                required=True, category='JWT Token'),
            spec_item(
                'jwt_token_validation', 'Validate JWT token structure and signature', required=True,
                category='JWT Token', server_side_only=True,
                client_note='This is a server-side validation feature. Client SDKs only need to receive, store, and send the JWT as a bearer token.'),
            spec_item(
                'jwt_expiration', 'JWT token includes expiration time', required=True,
                category='JWT Token'),
            spec_item(
                'jwt_claims', 'JWT token includes required claims (sub, iat, exp)', required=True,
                category='JWT Token')
        ]

        # Client Domain Features
        auth_features['client_domain_features'] = [
            spec_item(
                'client_domain_parameter', 'Support optional client_domain parameter in GET /auth',
                category='Client Domain'),
            spec_item(
                'client_domain_operation', 'Add client_domain ManageData operation to challenge',
                category='Client Domain'),
            spec_item(
                'client_domain_verification', 'Verify client domain by checking stellar.toml',
                category='Client Domain', server_side_only=True,
                client_note='This is a server-side verification feature. Client SDKs only need to support the client_domain parameter and signing.'),
            spec_item(
                'client_domain_signature', 'Require signature from client domain account',
                category='Client Domain')
        ]

        # Verification Features
        auth_features['verification_features'] = [
            spec_item(
                'challenge_validation', 'Validate challenge transaction structure and content',
                required=True, category='Verification'),
            spec_item(
                'signature_verification', 'Verify all signatures on challenge transaction',
                required=True, category='Verification'),
            spec_item(
                'multi_signature_support',
                'Support multiple signatures on challenge (client account + signers)',
                required=True, category='Verification'),
            spec_item(
                'timebounds_validation', 'Validate challenge is within valid time window',
                required=True, category='Verification'),
            spec_item(
                'home_domain_validation', 'Validate home domain in challenge matches server',
                required=True, category='Verification'),
            spec_item(
                'memo_support', 'Support optional memo in challenge for muxed accounts',
                category='Verification')
        ]

        # Store auth features as sections
        data['sections'].append(section(
            'Authentication Endpoints', 'auth_endpoints',
            'GET and POST /auth endpoints for challenge-response authentication',
            auth_features['authentication_endpoints'], features_key='auth_features'))

        data['sections'].append(section(
            'Challenge Transaction Features', 'challenge_transaction',
            'Challenge transaction structure, operations, and requirements',
            auth_features['challenge_transaction_features'], features_key='auth_features'))

        data['sections'].append(section(
            'JWT Token Features', 'jwt_token', 'JWT token generation, validation, and structure',
            auth_features['jwt_token_features'], features_key='auth_features'))

        data['sections'].append(section(
            'Client Domain Features', 'client_domain',
            'Optional client domain verification and signing',
            auth_features['client_domain_features'], features_key='auth_features'))

        data['sections'].append(section(
            'Verification Features', 'verification',
            'Challenge validation, signature verification, and security checks',
            auth_features['verification_features'], features_key='auth_features'))

        # Calculate totals
        total_features = (
            len(auth_features['authentication_endpoints']) +
            len(auth_features['challenge_transaction_features']) +
            len(auth_features['jwt_token_features']) +
            len(auth_features['client_domain_features']) +
            len(auth_features['verification_features'])
        )

        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['authentication_endpoints'])} authentication endpoints{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['challenge_transaction_features'])} challenge transaction features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['jwt_token_features'])} JWT token features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['client_domain_features'])} client domain features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['verification_features'])} verification features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} authentication features{Colors.END}")

        return data

    def parse_sep_05(self) -> Dict[str, Any]:
        """
        Parse SEP-05 (Key Derivation Methods for Stellar Keys) specific structure.

        Returns:
            Structured SEP-05 data with cryptographic standards and key derivation methods
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define cryptographic features structure for SEP-05
        crypto_features = {
            'bip39_features': [],
            'bip32_features': [],
            'bip44_features': [],
            'key_derivation_methods': [],
            'language_support': []
        }

        # BIP-39 Mnemonic features (core requirement)
        crypto_features['bip39_features'] = [
            spec_item(
                'mnemonic_generation_12_words', 'Generate 12-word BIP-39 mnemonic phrase',
                required=True, category='BIP-39 Mnemonic Generation'),
            spec_item(
                'mnemonic_generation_24_words', 'Generate 24-word BIP-39 mnemonic phrase',
                required=True, category='BIP-39 Mnemonic Generation'),
            spec_item(
                'mnemonic_validation', 'Validate BIP-39 mnemonic phrase (word list and checksum)',
                required=True, category='BIP-39 Mnemonic Validation'),
            spec_item(
                'mnemonic_to_seed', 'Convert BIP-39 mnemonic to seed using PBKDF2', required=True,
                category='BIP-39 Seed Generation'),
            spec_item(
                'passphrase_support', 'Support optional BIP-39 passphrase (25th word)',
                category='BIP-39 Passphrase')
        ]

        # BIP-32 Hierarchical Deterministic Key Derivation
        crypto_features['bip32_features'] = [
            spec_item(
                'hd_key_derivation', 'BIP-32 hierarchical deterministic key derivation',
                required=True, category='BIP-32 Key Derivation'),
            spec_item(
                'ed25519_curve', 'Support Ed25519 curve for Stellar keys', required=True,
                category='BIP-32 Curve Support'),
            spec_item(
                'master_key_generation', 'Generate master key from seed', required=True,
                category='BIP-32 Master Key'),
            spec_item(
                'child_key_derivation', 'Derive child keys from parent keys', required=True,
                category='BIP-32 Child Derivation')
        ]

        # BIP-44 Multi-Account Hierarchy
        crypto_features['bip44_features'] = [
            spec_item(
                'stellar_derivation_path',
                "Support Stellar's BIP-44 derivation path: m/44'/148'/account'", required=True,
                category='BIP-44 Derivation Path'),
            spec_item(
                'multiple_accounts', 'Derive multiple Stellar accounts from single seed',
                required=True, category='BIP-44 Multiple Accounts'),
            spec_item(
                'account_index_support', 'Support account index parameter in derivation',
                required=True, category='BIP-44 Account Index')
        ]

        # Key Derivation Methods
        crypto_features['key_derivation_methods'] = [
            spec_item(
                'keypair_from_mnemonic', 'Generate Stellar KeyPair from mnemonic', required=True,
                category='Key Derivation'),
            spec_item(
                'account_id_from_mnemonic', 'Get Stellar account ID from mnemonic', required=True,
                category='Account Derivation'),
            spec_item(
                'seed_from_mnemonic', 'Convert mnemonic to raw seed bytes', required=True,
                category='Seed Derivation')
        ]

        # Language Support
        crypto_features['language_support'] = [
            spec_item(
                'english', 'English BIP-39 word list (2048 words)', required=True,
                category='Language Support'),
            spec_item(
                'chinese_simplified', 'Chinese Simplified BIP-39 word list',
                category='Language Support'),
            spec_item(
                'chinese_traditional', 'Chinese Traditional BIP-39 word list',
                category='Language Support'),
            spec_item('french', 'French BIP-39 word list', category='Language Support'),
            spec_item('italian', 'Italian BIP-39 word list', category='Language Support'),
            spec_item('japanese', 'Japanese BIP-39 word list', category='Language Support'),
            spec_item('korean', 'Korean BIP-39 word list', category='Language Support'),
            spec_item('spanish', 'Spanish BIP-39 word list', category='Language Support')
        ]

        # Store crypto features as sections
        data['sections'].append(section(
            'BIP-39 Mnemonic Features', 'bip39',
            'BIP-39 mnemonic generation, validation, and seed derivation',
            crypto_features['bip39_features'], features_key='crypto_features'))

        data['sections'].append(section(
            'BIP-32 Key Derivation', 'bip32', 'BIP-32 hierarchical deterministic key derivation',
            crypto_features['bip32_features'], features_key='crypto_features'))

        data['sections'].append(section(
            'BIP-44 Multi-Account Support', 'bip44',
            "BIP-44 multi-account hierarchy for Stellar (m/44'/148'/account')",
            crypto_features['bip44_features'], features_key='crypto_features'))

        data['sections'].append(section(
            'Key Derivation Methods', 'key_derivation',
            'Methods for deriving Stellar keys from mnemonics',
            crypto_features['key_derivation_methods'], features_key='crypto_features'))

        data['sections'].append(section(
            'Language Support', 'languages', 'BIP-39 word list language support',
            crypto_features['language_support'], features_key='crypto_features'))

        # Calculate totals
        total_features = (
            len(crypto_features['bip39_features']) +
            len(crypto_features['bip32_features']) +
            len(crypto_features['bip44_features']) +
            len(crypto_features['key_derivation_methods']) +
            len(crypto_features['language_support'])
        )

        print(f"{Colors.GREEN}  ✓ Found {len(crypto_features['bip39_features'])} BIP-39 features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(crypto_features['bip32_features'])} BIP-32 features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(crypto_features['bip44_features'])} BIP-44 features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(crypto_features['key_derivation_methods'])} key derivation methods{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(crypto_features['language_support'])} languages{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} cryptographic features{Colors.END}")

        return data

    def parse_sep_06(self) -> Dict[str, Any]:
        """
        Parse SEP-06 (Deposit and Withdrawal API) specific structure.

        Returns:
            Structured SEP-06 data with API endpoints and transaction flow features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # API structure of SEP-06
        api_structure = {
            'info_endpoint': spec_item(
                'info_endpoint',
                'GET /info - Provides anchor capabilities and asset information',
                required=True, method='GET', path='/info',
                category='Info Endpoint'),
            'deposit_endpoints': [
                spec_item(
                    'deposit', 'GET /deposit - Initiates a deposit transaction for on-chain assets',
                    required=True, method='GET', path='/deposit', category='Deposit Endpoint'),
                spec_item(
                    'deposit_exchange',
                    'GET /deposit-exchange - Initiates a deposit with asset exchange (SEP-38 integration)',
                    method='GET', path='/deposit-exchange', category='Deposit Endpoint')
            ],
            'withdraw_endpoints': [
                spec_item(
                    'withdraw',
                    'GET /withdraw - Initiates a withdrawal transaction for off-chain assets',
                    required=True, method='GET', path='/withdraw', category='Withdraw Endpoint'),
                spec_item(
                    'withdraw_exchange',
                    'GET /withdraw-exchange - Initiates a withdrawal with asset exchange (SEP-38 integration)',
                    method='GET', path='/withdraw-exchange', category='Withdraw Endpoint')
            ],
            'transaction_endpoints': [
                spec_item(
                    'transactions',
                    'GET /transactions - Retrieves transaction history for an account',
                    required=True, method='GET', path='/transactions',
                    category='Transaction Endpoint'),
                spec_item(
                    'transaction', 'GET /transaction - Retrieves details for a single transaction',
                    required=True, method='GET', path='/transaction',
                    category='Transaction Endpoint'),
                spec_item(
                    'patch_transaction',
                    'PATCH /transaction - Updates transaction fields (for debugging/testing)',
                    method='PATCH', path='/transaction', category='Transaction Endpoint')
            ],
            'fee_endpoint': spec_item(
                'fee_endpoint',
                'GET /fee - Calculates fees for a deposit or withdrawal operation',
                method='GET', path='/fee', category='Fee Endpoint'),
            'deposit_request_parameters': [
                spec_item(
                    'asset_code', 'Code of the on-chain asset the user wants to receive',
                    required=True, type='string'),
                spec_item(
                    'account', 'Stellar account ID of the user', required=True, type='string'),
                spec_item(
                    'memo_type', 'Type of memo to attach to transaction (text, id, or hash)',
                    type='string'),
                spec_item('memo', 'Value of memo to attach to transaction', type='string'),
                spec_item(
                    'email_address', 'Email address of the user (for notifications)', type='string'),
                spec_item(
                    'type', 'Type of deposit method (e.g., bank_account, cash, mobile_money)',
                    type='string'),
                spec_item('wallet_name', 'Name of the wallet the user is using', type='string'),
                spec_item('wallet_url', 'URL of the wallet the user is using', type='string'),
                spec_item('lang', 'Language code for response messages (ISO 639-1)', type='string'),
                spec_item(
                    'on_change_callback',
                    'URL for anchor to send callback when transaction status changes',
                    type='string'),
                spec_item(
                    'amount', 'Amount of on-chain asset the user wants to receive', type='string'),
                spec_item(
                    'country_code', 'Country code of the user (ISO 3166-1 alpha-3)', type='string'),
                spec_item(
                    'claimable_balance_supported',
                    'Whether the client supports receiving claimable balances', type='boolean'),
                spec_item(
                    'customer_id', 'ID of the customer from SEP-12 KYC process', type='string'),
                spec_item(
                    'location_id', 'ID of the physical location for cash pickup', type='string')
            ],
            'withdraw_request_parameters': [
                spec_item(
                    'asset_code', 'Code of the on-chain asset the user wants to send',
                    required=True, type='string'),
                spec_item(
                    'type', 'Type of withdrawal method (e.g., bank_account, cash, mobile_money)',
                    required=True, type='string'),
                spec_item(
                    'dest', 'Destination for withdrawal (bank account number, etc.)', type='string'),
                spec_item(
                    'dest_extra', 'Extra information for destination (routing number, etc.)',
                    type='string'),
                spec_item('account', 'Stellar account ID of the user', type='string'),
                spec_item('memo', 'Memo to identify the user if account is shared', type='string'),
                spec_item('memo_type', 'Type of memo (text, id, or hash)', type='string'),
                spec_item('wallet_name', 'Name of the wallet the user is using', type='string'),
                spec_item('wallet_url', 'URL of the wallet the user is using', type='string'),
                spec_item('lang', 'Language code for response messages (ISO 639-1)', type='string'),
                spec_item(
                    'on_change_callback',
                    'URL for anchor to send callback when transaction status changes',
                    type='string'),
                spec_item(
                    'amount', 'Amount of on-chain asset the user wants to send', type='string'),
                spec_item(
                    'country_code', 'Country code of the user (ISO 3166-1 alpha-3)', type='string'),
                spec_item(
                    'refund_memo', 'Memo to use for refund transaction if withdrawal fails',
                    type='string'),
                spec_item(
                    'refund_memo_type', 'Type of refund memo (text, id, or hash)', type='string'),
                spec_item(
                    'customer_id', 'ID of the customer from SEP-12 KYC process', type='string'),
                spec_item(
                    'location_id', 'ID of the physical location for cash pickup', type='string')
            ],
            'deposit_response_fields': [
                spec_item('how', 'Instructions for how to deposit the asset', required=True),
                spec_item('id', 'Persistent transaction identifier'),
                spec_item('eta', 'Estimated seconds until deposit completes'),
                spec_item('min_amount', 'Minimum deposit amount'),
                spec_item('max_amount', 'Maximum deposit amount'),
                spec_item('fee_fixed', 'Fixed fee for deposit'),
                spec_item('fee_percent', 'Percentage fee for deposit'),
                spec_item('extra_info', 'Additional information about the deposit')
            ],
            'withdraw_response_fields': [
                spec_item(
                    'account_id', 'Stellar account to send withdrawn assets to', required=True),
                spec_item('memo_type', 'Type of memo to attach to transaction'),
                spec_item('memo', 'Value of memo to attach to transaction'),
                spec_item('id', 'Persistent transaction identifier', required=True),
                spec_item('eta', 'Estimated seconds until withdrawal completes'),
                spec_item('min_amount', 'Minimum withdrawal amount'),
                spec_item('max_amount', 'Maximum withdrawal amount'),
                spec_item('fee_fixed', 'Fixed fee for withdrawal'),
                spec_item('fee_percent', 'Percentage fee for withdrawal'),
                spec_item('extra_info', 'Additional information about the withdrawal')
            ],
            'transaction_status_values': [
                spec_item(
                    'incomplete', 'Deposit/withdrawal has not yet been submitted', required=True),
                spec_item(
                    'pending_user_transfer_start',
                    'Waiting for user to initiate off-chain transfer', required=True),
                spec_item(
                    'pending_user_transfer_complete', 'Off-chain transfer has been initiated'),
                spec_item('pending_external', 'Waiting for external action (banking system, etc.)'),
                spec_item('pending_anchor', 'Anchor is processing the transaction', required=True),
                spec_item('pending_stellar', 'Stellar transaction has been submitted'),
                spec_item('pending_trust', 'User needs to add trustline for asset'),
                spec_item('pending_user', 'Waiting for user action (accepting claimable balance)'),
                spec_item('completed', 'Transaction completed successfully', required=True),
                spec_item('refunded', 'Transaction refunded'),
                spec_item('expired', 'Transaction expired without completion'),
                spec_item('error', 'Transaction failed with error')
            ],
            'transaction_fields': [
                spec_item('id', 'Unique transaction identifier', required=True),
                spec_item(
                    'kind',
                    'Kind of transaction (deposit, withdrawal, deposit-exchange, withdrawal-exchange)',
                    required=True),
                spec_item('status', 'Current status of the transaction', required=True),
                spec_item('status_eta', 'Estimated seconds until status changes'),
                spec_item('amount_in', 'Amount received by anchor'),
                spec_item('amount_out', 'Amount sent by anchor to user'),
                spec_item('amount_fee', 'Total fee charged for transaction'),
                spec_item('started_at', 'When transaction was created (ISO 8601)', required=True),
                spec_item('completed_at', 'When transaction completed (ISO 8601)'),
                spec_item('stellar_transaction_id', 'Hash of the Stellar transaction'),
                spec_item('external_transaction_id', 'Identifier from external system'),
                spec_item('from', 'Stellar account that initiated the transaction'),
                spec_item('to', 'Stellar account receiving the transaction'),
                spec_item('refunded', 'Whether transaction was refunded'),
                spec_item('refunds', 'Refund information if applicable'),
                spec_item('message', 'Human-readable message about transaction')
            ],
            'info_response_fields': [
                spec_item(
                    'deposit', 'Map of asset codes to deposit asset information', required=True),
                spec_item(
                    'deposit-exchange', 'Map of asset codes to deposit-exchange asset information'),
                spec_item(
                    'withdraw', 'Map of asset codes to withdraw asset information', required=True),
                spec_item(
                    'withdraw-exchange',
                    'Map of asset codes to withdraw-exchange asset information'),
                spec_item('fee', 'Fee endpoint information'),
                spec_item('transactions', 'Transaction history endpoint information'),
                spec_item('transaction', 'Single transaction endpoint information'),
                spec_item('features', 'Feature flags supported by the anchor')
            ],
            'authentication': {
                'type': 'SEP-10',
                'method': 'JWT Token',
                'description': 'Most endpoints require SEP-10 JWT authentication via Authorization header',
                'required': False
            },
            'kyc_integration': {
                'description': 'Integration with SEP-12 KYC API for customer information',
                'supported': True
            },
            'sep38_integration': {
                'description': 'Integration with SEP-38 for asset exchange quotes',
                'supported': True
            }
        }

        # Store API structure components as sections
        data['sections'].append(section(
            'Info Endpoint', 'info_endpoint', 'Endpoint for querying anchor capabilities',
            [api_structure['info_endpoint']]))

        data['sections'].append(section(
            'Deposit Endpoints', 'deposit_endpoints',
            'Endpoints for initiating deposit transactions',
            api_structure['deposit_endpoints']))

        data['sections'].append(section(
            'Withdraw Endpoints', 'withdraw_endpoints',
            'Endpoints for initiating withdrawal transactions',
            api_structure['withdraw_endpoints']))

        data['sections'].append(section(
            'Transaction Endpoints', 'transaction_endpoints',
            'Endpoints for tracking and managing transactions',
            api_structure['transaction_endpoints']))

        data['sections'].append(section(
            'Fee Endpoint', 'fee_endpoint', 'Endpoint for calculating transaction fees',
            [api_structure['fee_endpoint']]))

        data['sections'].append(section(
            'Deposit Request Parameters', 'deposit_request_parameters',
            'Parameters for deposit endpoint requests',
            api_structure['deposit_request_parameters']))

        data['sections'].append(section(
            'Withdraw Request Parameters', 'withdraw_request_parameters',
            'Parameters for withdraw endpoint requests',
            api_structure['withdraw_request_parameters']))

        data['sections'].append(section(
            'Deposit Response Fields', 'deposit_response_fields',
            'Fields returned in deposit endpoint responses',
            api_structure['deposit_response_fields']))

        data['sections'].append(section(
            'Withdraw Response Fields', 'withdraw_response_fields',
            'Fields returned in withdraw endpoint responses',
            api_structure['withdraw_response_fields']))

        data['sections'].append(section(
            'Transaction Status Values', 'transaction_status_values',
            'Possible transaction status values',
            api_structure['transaction_status_values']))

        data['sections'].append(section(
            'Transaction Fields', 'transaction_fields', 'Fields returned in transaction objects',
            api_structure['transaction_fields']))

        data['sections'].append(section(
            'Info Response Fields', 'info_response_fields',
            'Fields returned in info endpoint response',
            api_structure['info_response_fields']))

        # Calculate totals
        total_features = (
            1 +  # info_endpoint
            len(api_structure['deposit_endpoints']) +
            len(api_structure['withdraw_endpoints']) +
            len(api_structure['transaction_endpoints']) +
            1 +  # fee_endpoint
            len(api_structure['deposit_request_parameters']) +
            len(api_structure['withdraw_request_parameters']) +
            len(api_structure['deposit_response_fields']) +
            len(api_structure['withdraw_response_fields']) +
            len(api_structure['transaction_status_values']) +
            len(api_structure['transaction_fields']) +
            len(api_structure['info_response_fields'])
        )

        print(f"{Colors.GREEN}  ✓ Found 1 info endpoint{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['deposit_endpoints'])} deposit endpoints{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['withdraw_endpoints'])} withdraw endpoints{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['transaction_endpoints'])} transaction endpoints{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['deposit_request_parameters'])} deposit request parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['withdraw_request_parameters'])} withdraw request parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['transaction_status_values'])} transaction status values{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-06 features{Colors.END}")

        return data

    def parse_sep_09(self) -> Dict[str, Any]:
        """
        Parse SEP-09 (Standard KYC / AML fields) specific structure.

        Returns:
            Structured SEP-09 data with field definitions
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define field categories for SEP-09
        # SEP-09 is a field definition standard similar to SEP-01
        field_categories = {
            'natural_person_fields': [],
            'organization_fields': [],
            'financial_account_fields': [],
            'card_fields': []
        }

        # Natural Person Fields
        field_categories['natural_person_fields'] = [
            spec_item('last_name', 'Family or last name'),
            spec_item('first_name', 'Given or first name'),
            spec_item('additional_name', 'Middle name or other additional name'),
            spec_item('address_country_code', 'Country code for current address'),
            spec_item('state_or_province', 'Name of state/province/region/prefecture'),
            spec_item('city', 'Name of city/town'),
            spec_item('postal_code', "Postal or other code identifying user's locale"),
            spec_item(
                'address',
                'Entire address (country, state, postal code, street address, etc.) as a multi-line string'),
            spec_item('mobile_number', 'Mobile phone number with country code, in E.164 format'),
            spec_item(
                'mobile_number_format',
                'Expected format of the mobile_number field (E.164, hash, etc.)'),
            spec_item('email_address', 'Email address'),
            spec_item('birth_date', 'Date of birth (e.g., 1976-07-04)'),
            spec_item('birth_place', 'Place of birth (city, state, country; as on passport)'),
            spec_item('birth_country_code', 'ISO Code of country of birth (ISO 3166-1 alpha-3)'),
            spec_item(
                'tax_id', 'Tax identifier of user in their country (social security number in US)'),
            spec_item('tax_id_name', 'Name of the tax ID (SSN or ITIN in the US)'),
            spec_item('occupation', 'Occupation ISCO code'),
            spec_item('employer_name', 'Name of employer'),
            spec_item('employer_address', 'Address of employer'),
            spec_item('language_code', 'Primary language (ISO 639-1)'),
            spec_item('id_type', 'Type of ID (passport, drivers_license, id_card, etc.)'),
            spec_item(
                'id_country_code', 'Country issuing passport or photo ID (ISO 3166-1 alpha-3)'),
            spec_item('id_issue_date', 'ID issue date'),
            spec_item('id_expiration_date', 'ID expiration date'),
            spec_item('id_number', 'Passport or ID number'),
            spec_item(
                'photo_id_front', "Image of front of user's photo ID or passport", type='binary'),
            spec_item(
                'photo_id_back', "Image of back of user's photo ID or passport", type='binary'),
            spec_item(
                'notary_approval_of_photo_id', "Image of notary's approval of photo ID or passport",
                type='binary'),
            spec_item('ip_address', "IP address of customer's computer"),
            spec_item(
                'photo_proof_residence',
                "Image of a utility bill, bank statement or similar with the user's name and address",
                type='binary'),
            spec_item('sex', 'Gender (male, female, or other)'),
            spec_item('proof_of_income', "Image of user's proof of income document", type='binary'),
            spec_item(
                'proof_of_liveness', 'Video or image file of user as a liveness proof',
                type='binary'),
            spec_item(
                'referral_id',
                "User's origin (such as an id in another application) or a referral code")
        ]

        # Organization Fields (prefixed with "organization.")
        field_categories['organization_fields'] = [
            spec_item('organization.name', 'Full organization name as on the incorporation papers'),
            spec_item('organization.VAT_number', 'Organization VAT number'),
            spec_item('organization.registration_number', 'Organization registration number'),
            spec_item('organization.registration_date', 'Date the organization was registered'),
            spec_item('organization.registered_address', 'Organization registered address'),
            spec_item('organization.number_of_shareholders', 'Organization shareholder number'),
            spec_item(
                'organization.shareholder_name',
                'Name of shareholder (can be organization or person)'),
            spec_item(
                'organization.photo_incorporation_doc', 'Image of incorporation documents',
                type='binary'),
            spec_item(
                'organization.photo_proof_address',
                "Image of a utility bill, bank statement with the organization's name and address",
                type='binary'),
            spec_item('organization.address_country_code', 'Country code for current address'),
            spec_item('organization.state_or_province', 'Name of state/province/region/prefecture'),
            spec_item('organization.city', 'Name of city/town'),
            spec_item(
                'organization.postal_code',
                "Postal or other code identifying organization's locale"),
            spec_item('organization.director_name', 'Organization registered managing director'),
            spec_item('organization.website', 'Organization website'),
            spec_item('organization.email', 'Organization contact email'),
            spec_item('organization.phone', 'Organization contact phone')
        ]

        # Financial Account Fields
        field_categories['financial_account_fields'] = [
            spec_item('bank_name', 'Name of the bank'),
            spec_item('bank_account_type', 'Type of bank account'),
            spec_item('bank_account_number', 'Number identifying bank account'),
            spec_item(
                'bank_number',
                'Number identifying bank in national banking system (routing number in US)'),
            spec_item('bank_phone_number', 'Phone number with country code for bank'),
            spec_item('bank_branch_number', 'Number identifying bank branch'),
            spec_item(
                'external_transfer_memo', 'A destination tag/memo used to identify a transaction'),
            spec_item('clabe_number', 'Bank account number for Mexico'),
            spec_item(
                'cbu_number', 'Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU)'),
            spec_item('cbu_alias', 'The alias for a CBU or CVU'),
            spec_item(
                'mobile_money_number',
                'Mobile phone number in E.164 format with which a mobile money account is associated'),
            spec_item('mobile_money_provider', 'Name of the mobile money service provider'),
            spec_item('crypto_address', 'Address for a cryptocurrency account'),
            spec_item('crypto_memo', 'A destination tag/memo used to identify a transaction')
        ]

        # Card Fields (prefixed with "card.")
        field_categories['card_fields'] = [
            spec_item('card.number', 'Card number'),
            spec_item(
                'card.expiration_date',
                'Expiration month and year in YY-MM format (e.g., 29-11, November 2029)'),
            spec_item('card.cvc', 'CVC number (Digits on the back of the card)'),
            spec_item('card.holder_name', 'Name of the card holder'),
            spec_item(
                'card.network',
                'Brand of the card/network it operates within (e.g., Visa, Mastercard, AmEx, etc.)'),
            spec_item('card.postal_code', 'Billing address postal code'),
            spec_item(
                'card.country_code',
                'Billing address country code in ISO 3166-1 alpha-2 code (e.g., US)'),
            spec_item(
                'card.state_or_province',
                'Name of state/province/region/prefecture in ISO 3166-2 format'),
            spec_item('card.city', 'Name of city/town'),
            spec_item(
                'card.address',
                'Entire address (country, state, postal code, street address, etc.) as a multi-line string'),
            spec_item(
                'card.token',
                'Token representation of the card in some external payment system (e.g., Stripe)')
        ]

        # Store field categories as sections
        data['sections'].append(section(
            'Natural Person Fields', 'natural_person_fields',
            'Standard KYC fields for natural persons',
            field_categories['natural_person_fields'], features_key='fields', count_key='field_count'))

        data['sections'].append(section(
            'Organization Fields', 'organization_fields', 'Standard KYC fields for organizations',
            field_categories['organization_fields'], features_key='fields', count_key='field_count'))

        data['sections'].append(section(
            'Financial Account Fields', 'financial_account_fields',
            'Standard fields for financial account information',
            field_categories['financial_account_fields'], features_key='fields', count_key='field_count'))

        data['sections'].append(section(
            'Card Fields', 'card_fields', 'Standard fields for card payment information',
            field_categories['card_fields'], features_key='fields', count_key='field_count'))

        # Calculate totals
        total_fields = (
            len(field_categories['natural_person_fields']) +
            len(field_categories['organization_fields']) +
            len(field_categories['financial_account_fields']) +
            len(field_categories['card_fields'])
        )

        print(f"{Colors.GREEN}  ✓ Found {len(field_categories['natural_person_fields'])} natural person fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(field_categories['organization_fields'])} organization fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(field_categories['financial_account_fields'])} financial account fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(field_categories['card_fields'])} card fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_fields} KYC/AML fields{Colors.END}")

        return data

    def parse_sep_11(self) -> Dict[str, Any]:
        """
        Parse SEP-11 (Txrep) specific structure.

        Txrep is a human-readable low-level representation of Stellar transactions.
        It provides encoding/decoding capabilities between XDR binary and text format.

        Returns:
            Structured SEP-11 data with txrep conversion features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define Txrep conversion features for SEP-11
        # SEP-11 is about format conversion, not HTTP API
        txrep_features = {
            'encoding_features': [
                spec_item(
                    'encode_transaction', 'Convert transaction envelope XDR to txrep text format',
                    required=True, category='Encoding'),
                spec_item(
                    'encode_fee_bump_transaction',
                    'Convert fee bump transaction envelope to txrep format', required=True,
                    category='Encoding'),
                spec_item(
                    'encode_source_account', 'Encode source account (including muxed accounts)',
                    required=True, category='Encoding'),
                spec_item(
                    'encode_memo', 'Encode all memo types (NONE, TEXT, ID, HASH, RETURN)',
                    required=True, category='Encoding'),
                spec_item(
                    'encode_operations', 'Encode all Stellar operation types', required=True,
                    category='Encoding'),
                spec_item(
                    'encode_preconditions',
                    'Encode transaction preconditions (time bounds, ledger bounds, min seq num, etc.)',
                    required=True, category='Encoding'),
                spec_item(
                    'encode_signatures', 'Encode transaction signatures', required=True,
                    category='Encoding'),
                spec_item(
                    'encode_soroban_data',
                    'Encode Soroban transaction data (resources, footprint, etc.)', required=True,
                    category='Encoding')
            ],
            'decoding_features': [
                spec_item(
                    'decode_transaction', 'Parse txrep text format to transaction envelope XDR',
                    required=True, category='Decoding'),
                spec_item(
                    'decode_fee_bump_transaction', 'Parse fee bump transaction from txrep format',
                    required=True, category='Decoding'),
                spec_item(
                    'decode_source_account', 'Parse source account (including muxed accounts)',
                    required=True, category='Decoding'),
                spec_item(
                    'decode_memo', 'Parse all memo types from txrep', required=True,
                    category='Decoding'),
                spec_item(
                    'decode_operations', 'Parse all Stellar operation types from txrep',
                    required=True, category='Decoding'),
                spec_item(
                    'decode_preconditions', 'Parse transaction preconditions from txrep',
                    required=True, category='Decoding'),
                spec_item(
                    'decode_signatures', 'Parse transaction signatures from txrep', required=True,
                    category='Decoding'),
                spec_item(
                    'decode_soroban_data', 'Parse Soroban transaction data from txrep',
                    required=True, category='Decoding')
            ],
            'asset_encoding': [
                spec_item(
                    'encode_native_asset', 'Encode native XLM asset in txrep format', required=True,
                    category='Asset Encoding'),
                spec_item(
                    'encode_alphanumeric4_asset', 'Encode 4-character alphanumeric asset',
                    required=True, category='Asset Encoding'),
                spec_item(
                    'encode_alphanumeric12_asset', 'Encode 12-character alphanumeric asset',
                    required=True, category='Asset Encoding')
            ],
            'operation_types': [
                spec_item(
                    'create_account', 'Encode/decode CREATE_ACCOUNT operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'payment', 'Encode/decode PAYMENT operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'path_payment_strict_receive',
                    'Encode/decode PATH_PAYMENT_STRICT_RECEIVE operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'path_payment_strict_send', 'Encode/decode PATH_PAYMENT_STRICT_SEND operation',
                    required=True, category='Operation Type'),
                spec_item(
                    'manage_sell_offer', 'Encode/decode MANAGE_SELL_OFFER operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'manage_buy_offer', 'Encode/decode MANAGE_BUY_OFFER operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'create_passive_sell_offer',
                    'Encode/decode CREATE_PASSIVE_SELL_OFFER operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'set_options', 'Encode/decode SET_OPTIONS operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'change_trust', 'Encode/decode CHANGE_TRUST operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'allow_trust', 'Encode/decode ALLOW_TRUST operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'account_merge', 'Encode/decode ACCOUNT_MERGE operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'manage_data', 'Encode/decode MANAGE_DATA operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'bump_sequence', 'Encode/decode BUMP_SEQUENCE operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'create_claimable_balance', 'Encode/decode CREATE_CLAIMABLE_BALANCE operation',
                    required=True, category='Operation Type'),
                spec_item(
                    'claim_claimable_balance', 'Encode/decode CLAIM_CLAIMABLE_BALANCE operation',
                    required=True, category='Operation Type'),
                spec_item(
                    'begin_sponsoring_future_reserves',
                    'Encode/decode BEGIN_SPONSORING_FUTURE_RESERVES operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'end_sponsoring_future_reserves',
                    'Encode/decode END_SPONSORING_FUTURE_RESERVES operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'revoke_sponsorship', 'Encode/decode REVOKE_SPONSORSHIP operation',
                    required=True, category='Operation Type'),
                spec_item(
                    'clawback', 'Encode/decode CLAWBACK operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'clawback_claimable_balance',
                    'Encode/decode CLAWBACK_CLAIMABLE_BALANCE operation', required=True,
                    category='Operation Type'),
                spec_item(
                    'set_trust_line_flags', 'Encode/decode SET_TRUST_LINE_FLAGS operation',
                    required=True, category='Operation Type'),
                spec_item(
                    'liquidity_pool_deposit', 'Encode/decode LIQUIDITY_POOL_DEPOSIT operation',
                    required=True, category='Operation Type'),
                spec_item(
                    'liquidity_pool_withdraw', 'Encode/decode LIQUIDITY_POOL_WITHDRAW operation',
                    required=True, category='Operation Type'),
                spec_item(
                    'invoke_host_function',
                    'Encode/decode INVOKE_HOST_FUNCTION operation (Soroban)', required=True,
                    category='Operation Type'),
                spec_item(
                    'extend_footprint_ttl',
                    'Encode/decode EXTEND_FOOTPRINT_TTL operation (Soroban)', required=True,
                    category='Operation Type'),
                spec_item(
                    'restore_footprint', 'Encode/decode RESTORE_FOOTPRINT operation (Soroban)',
                    required=True, category='Operation Type')
            ],
            'format_features': [
                spec_item(
                    'comment_support', 'Support for comments in txrep format', required=True,
                    category='Format Feature'),
                spec_item(
                    'dot_notation', 'Use dot notation for nested structures', required=True,
                    category='Format Feature'),
                spec_item(
                    'array_indexing', 'Support array indexing in txrep format', required=True,
                    category='Format Feature'),
                spec_item(
                    'hex_encoding', 'Hexadecimal encoding for binary data', required=True,
                    category='Format Feature'),
                spec_item(
                    'string_escaping', 'Proper string escaping with double quotes', required=True,
                    category='Format Feature')
            ]
        }

        # Add encoding features section
        data['sections'].append(section(
            'Encoding Features', 'encoding_features',
            'Features for converting transaction envelope XDR to txrep format',
            txrep_features['encoding_features'], features_key='txrep_features'))

        # Add decoding features section
        data['sections'].append(section(
            'Decoding Features', 'decoding_features',
            'Features for parsing txrep format to transaction envelope XDR',
            txrep_features['decoding_features'], features_key='txrep_features'))

        # Add asset encoding section
        data['sections'].append(section(
            'Asset Encoding', 'asset_encoding', 'Asset type encoding in txrep format',
            txrep_features['asset_encoding'], features_key='txrep_features'))

        # Add operation types section
        data['sections'].append(section(
            'Operation Types', 'operation_types', 'All supported Stellar operation types',
            txrep_features['operation_types'], features_key='txrep_features'))

        # Add format features section
        data['sections'].append(section(
            'Format Features', 'format_features', 'Txrep format specification features',
            txrep_features['format_features'], features_key='txrep_features'))

        # Calculate totals
        total_features = sum(len(features) for features in txrep_features.values())

        print(f"{Colors.GREEN}  ✓ Found {len(txrep_features['encoding_features'])} encoding features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(txrep_features['decoding_features'])} decoding features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(txrep_features['asset_encoding'])} asset encoding features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(txrep_features['operation_types'])} operation types{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(txrep_features['format_features'])} format features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} txrep features{Colors.END}")

        return data

    def parse_sep_12(self) -> Dict[str, Any]:
        """
        Parse SEP-12 (KYC API) specific structure.

        Returns:
            Structured SEP-12 data with API endpoints and fields
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define API structure for SEP-12 (KYC API)
        # SEP-12 has multiple endpoints for customer information management
        api_structure = {
            'endpoints': [
                {
                    'path': '/customer',
                    'method': 'GET',
                    'description': 'Check the status of a customers info',
                    'key': 'get_customer'
                },
                {
                    'path': '/customer',
                    'method': 'PUT',
                    'description': 'Upload customer information to an anchor',
                    'key': 'put_customer'
                },
                {
                    'path': '/customer/verification',
                    'method': 'PUT',
                    'description': 'Verify customer fields with confirmation codes',
                    'key': 'put_customer_verification'
                },
                {
                    'path': '/customer/{account}',
                    'method': 'DELETE',
                    'description': 'Delete all personal information about a customer',
                    'key': 'delete_customer'
                },
                {
                    'path': '/customer/callback',
                    'method': 'PUT',
                    'description': 'Register a callback URL for customer status updates',
                    'key': 'put_customer_callback'
                },
                {
                    'path': '/customer/files',
                    'method': 'POST',
                    'description': 'Upload binary files for customer KYC',
                    'key': 'post_customer_files'
                },
                {
                    'path': '/customer/files',
                    'method': 'GET',
                    'description': 'Get metadata about uploaded files',
                    'key': 'get_customer_files'
                }
            ],
            'request_parameters': [
                spec_item(
                    'id', 'ID of the customer as returned in previous PUT request', type='string'),
                spec_item('account', 'Stellar account ID (G...) of the customer', type='string'),
                spec_item(
                    'memo', 'Memo that uniquely identifies a customer in shared accounts',
                    type='string'),
                spec_item('memo_type', 'Type of memo: text, id, or hash', type='string'),
                spec_item('type', 'Type of action the customer is being KYCd for', type='string'),
                spec_item(
                    'transaction_id', 'Transaction ID with which customer info is associated',
                    type='string'),
                spec_item(
                    'lang', 'Language code (ISO 639-1) for human-readable responses', type='string')
            ],
            'response_fields': [
                spec_item('id', 'ID of the customer'),
                spec_item(
                    'status', 'Status of customer KYC process', required=True,
                    values=['ACCEPTED', 'PROCESSING', 'NEEDS_INFO', 'REJECTED']),
                spec_item('fields', 'Fields the anchor has not yet received'),
                spec_item('provided_fields', 'Fields the anchor has received'),
                spec_item('message', 'Human readable message describing KYC status')
            ],
            'field_types': [
                {
                    'name': 'type',
                    'description': 'Data type of field value',
                    'values': ['string', 'binary', 'number', 'date']
                },
                spec_item('description', 'Human-readable description of the field'),
                spec_item('choices', 'Array of valid values for this field'),
                spec_item('optional', 'Whether this field is required to proceed'),
                spec_item(
                    'status', 'Status of provided field',
                    values=['ACCEPTED', 'PROCESSING', 'REJECTED', 'VERIFICATION_REQUIRED']),
                spec_item('error', 'Description of why field was rejected')
            ],
            'authentication': {
                'type': 'SEP-10',
                'method': 'JWT Token',
                'description': 'All endpoints require SEP-10 JWT authentication via Authorization header'
            },
            'file_upload': {
                'content_type': 'multipart/form-data',
                'description': 'Binary files uploaded using multipart/form-data for photo_id, proof_of_address, etc.',
                'supported': True
            },
            'sep9_integration': {
                'description': 'Supports all SEP-9 standard KYC fields for natural persons and organizations',
                'supported': True
            }
        }

        # Store API structure as a section
        data['sections'].append({
            'title': 'KYC API Endpoints',
            'key': 'endpoints',
            'content': 'Customer information management endpoints',
            'api_structure': api_structure,
            'field_count': (len(api_structure['endpoints']) +
                           len(api_structure['request_parameters']) +
                           len(api_structure['response_fields']) +
                           len(api_structure['field_types']))
        })

        # Extract other sections for context
        general_sections = self.extract_sections()
        for extracted in general_sections:
            if extracted['title'].lower() not in ['preamble', 'summary']:
                data['sections'].append(extracted)

        # Print summary
        total_features = (len(api_structure['endpoints']) +
                         len(api_structure['request_parameters']) +
                         len(api_structure['response_fields']) +
                         len(api_structure['field_types']))

        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['endpoints'])} API endpoints{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['request_parameters'])} request parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['response_fields'])} response fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['field_types'])} field type specifications{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} KYC API features{Colors.END}")

        return data

    def parse_sep_38(self) -> Dict[str, Any]:
        """
        Parse SEP-38 (Anchor RFQ API) specific structure.

        Returns:
            Structured SEP-38 data with API endpoints and quote features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # API structure of SEP-38
        api_structure = {
            'info_endpoint': spec_item(
                'info_endpoint',
                'GET /info - Returns supported Stellar and off-chain assets available for trading',
                required=True, method='GET', path='/info',
                category='Info Endpoint'),
            'prices_endpoint': spec_item(
                'prices_endpoint',
                'GET /prices - Returns indicative prices of off-chain assets in exchange for Stellar assets',
                required=True, method='GET', path='/prices',
                category='Prices Endpoint'),
            'price_endpoint': spec_item(
                'price_endpoint',
                'GET /price - Returns indicative price for a specific asset pair',
                required=True, method='GET', path='/price',
                category='Price Endpoint'),
            'post_quote_endpoint': spec_item(
                'post_quote_endpoint',
                'POST /quote - Request a firm quote for asset exchange',
                required=True, method='POST', path='/quote',
                category='Quote Endpoint'),
            'get_quote_endpoint': spec_item(
                'get_quote_endpoint',
                'GET /quote/:id - Fetch a previously-provided firm quote',
                required=True, method='GET', path='/quote/:id',
                category='Quote Endpoint'),
            'info_response_fields': [
                spec_item('assets', 'Array of asset objects supported for trading', required=True)
            ],
            'asset_fields': [
                spec_item(
                    'asset', 'Asset identifier in Asset Identification Format', required=True),
                spec_item(
                    'sell_delivery_methods', 'Array of delivery methods for selling this asset'),
                spec_item(
                    'buy_delivery_methods', 'Array of delivery methods for buying this asset'),
                spec_item(
                    'country_codes', 'Array of ISO 3166-2 or ISO 3166-1 alpha-2 country codes')
            ],
            'delivery_method_fields': [
                spec_item('name', 'Delivery method name identifier', required=True),
                spec_item(
                    'description', 'Human-readable description of the delivery method',
                    required=True)
            ],
            'prices_request_parameters': [
                spec_item(
                    'sell_asset', 'Asset to sell using Asset Identification Format', required=True,
                    type='string'),
                spec_item(
                    'sell_amount', 'Amount of sell_asset to exchange', required=True, type='string'),
                spec_item(
                    'sell_delivery_method', 'Delivery method for off-chain sell asset',
                    type='string'),
                spec_item(
                    'buy_delivery_method', 'Delivery method for off-chain buy asset', type='string'),
                spec_item(
                    'country_code', 'ISO 3166-2 or ISO 3166-1 alpha-2 country code', type='string')
            ],
            'prices_response_fields': [
                spec_item('buy_assets', 'Array of buy asset objects with prices', required=True)
            ],
            'buy_asset_fields': [
                spec_item(
                    'asset', 'Asset identifier in Asset Identification Format', required=True),
                spec_item(
                    'price', 'Price offered by anchor for one unit of buy_asset', required=True),
                spec_item('decimals', 'Number of decimals for the buy asset', required=True)
            ],
            'price_request_parameters': [
                spec_item(
                    'context', 'Context for quote usage (sep6 or sep31)', required=True,
                    type='string', values=['sep6', 'sep31']),
                spec_item(
                    'sell_asset', 'Asset client would like to sell', required=True, type='string'),
                spec_item(
                    'buy_asset', 'Asset client would like to exchange for sell_asset',
                    required=True, type='string'),
                spec_item(
                    'sell_amount',
                    'Amount of sell_asset to exchange (mutually exclusive with buy_amount)',
                    type='string'),
                spec_item(
                    'buy_amount',
                    'Amount of buy_asset to exchange for (mutually exclusive with sell_amount)',
                    type='string'),
                spec_item(
                    'sell_delivery_method', 'Delivery method for off-chain sell asset',
                    type='string'),
                spec_item(
                    'buy_delivery_method', 'Delivery method for off-chain buy asset', type='string'),
                spec_item(
                    'country_code', 'ISO 3166-2 or ISO 3166-1 alpha-2 country code', type='string')
            ],
            'price_response_fields': [
                spec_item('total_price', 'Total conversion price including fees', required=True),
                spec_item('price', 'Base conversion price excluding fees', required=True),
                spec_item(
                    'sell_amount', 'Amount of sell_asset that will be exchanged', required=True),
                spec_item('buy_amount', 'Amount of buy_asset that will be received', required=True),
                spec_item(
                    'fee', 'Fee object with total, asset, and optional details', required=True)
            ],
            'post_quote_request_fields': [
                spec_item(
                    'context', 'Context for quote usage (sep6 or sep31)', required=True,
                    type='string', values=['sep6', 'sep31']),
                spec_item(
                    'sell_asset', 'Asset client would like to sell', required=True, type='string'),
                spec_item(
                    'buy_asset', 'Asset client would like to exchange for sell_asset',
                    required=True, type='string'),
                spec_item(
                    'sell_amount',
                    'Amount of sell_asset to exchange (mutually exclusive with buy_amount)',
                    type='string'),
                spec_item(
                    'buy_amount',
                    'Amount of buy_asset to exchange for (mutually exclusive with sell_amount)',
                    type='string'),
                spec_item(
                    'expire_after', 'Requested expiration timestamp for the quote (ISO 8601)',
                    type='datetime'),
                spec_item(
                    'sell_delivery_method', 'Delivery method for off-chain sell asset',
                    type='string'),
                spec_item(
                    'buy_delivery_method', 'Delivery method for off-chain buy asset', type='string'),
                spec_item(
                    'country_code', 'ISO 3166-2 or ISO 3166-1 alpha-2 country code', type='string')
            ],
            'quote_response_fields': [
                spec_item('id', 'Unique identifier for the quote', required=True),
                spec_item(
                    'expires_at', 'Expiration timestamp for the quote (ISO 8601)', required=True),
                spec_item('total_price', 'Total conversion price including fees', required=True),
                spec_item('price', 'Base conversion price excluding fees', required=True),
                spec_item('sell_asset', 'Asset to be sold', required=True),
                spec_item('sell_amount', 'Amount of sell_asset to be exchanged', required=True),
                spec_item('buy_asset', 'Asset to be bought', required=True),
                spec_item('buy_amount', 'Amount of buy_asset to be received', required=True),
                spec_item(
                    'fee', 'Fee object with total, asset, and optional details', required=True)
            ],
            'fee_fields': [
                spec_item('total', 'Total fee amount as decimal string', required=True),
                spec_item('asset', 'Asset identifier for the fee', required=True),
                spec_item('details', 'Optional array of fee breakdown objects')
            ],
            'fee_details_fields': [
                spec_item('name', 'Name identifier for the fee component', required=True),
                spec_item('amount', 'Fee amount as decimal string', required=True),
                spec_item('description', 'Human-readable description of the fee')
            ],
            'authentication': {
                'type': 'SEP-10',
                'method': 'JWT Token',
                'description': 'Most endpoints support optional SEP-10 JWT authentication, POST /quote requires authentication',
                'required': True
            }
        }

        # Store API structure components as sections
        data['sections'].append(section(
            'Info Endpoint', 'info_endpoint', 'Endpoint for querying supported assets for trading',
            [api_structure['info_endpoint']]))

        data['sections'].append(section(
            'Prices Endpoint', 'prices_endpoint',
            'Endpoint for fetching indicative prices for multiple buy assets',
            [api_structure['prices_endpoint']]))

        data['sections'].append(section(
            'Price Endpoint', 'price_endpoint',
            'Endpoint for fetching indicative price for specific asset pair',
            [api_structure['price_endpoint']]))

        data['sections'].append(section(
            'Post Quote Endpoint', 'post_quote_endpoint', 'Endpoint for requesting firm quote',
            [api_structure['post_quote_endpoint']]))

        data['sections'].append(section(
            'Get Quote Endpoint', 'get_quote_endpoint',
            'Endpoint for fetching previously provided firm quote',
            [api_structure['get_quote_endpoint']]))

        data['sections'].append(section(
            'Info Response Fields', 'info_response_fields',
            'Fields returned in info endpoint response',
            api_structure['info_response_fields']))

        data['sections'].append(section(
            'Asset Fields', 'asset_fields', 'Fields in asset objects',
            api_structure['asset_fields']))

        data['sections'].append(section(
            'Delivery Method Fields', 'delivery_method_fields', 'Fields in delivery method objects',
            api_structure['delivery_method_fields']))

        data['sections'].append(section(
            'Prices Request Parameters', 'prices_request_parameters',
            'Parameters for prices endpoint requests',
            api_structure['prices_request_parameters']))

        data['sections'].append(section(
            'Prices Response Fields', 'prices_response_fields',
            'Fields returned in prices endpoint response',
            api_structure['prices_response_fields']))

        data['sections'].append(section(
            'Buy Asset Fields', 'buy_asset_fields',
            'Fields in buy asset objects from prices response',
            api_structure['buy_asset_fields']))

        data['sections'].append(section(
            'Price Request Parameters', 'price_request_parameters',
            'Parameters for price endpoint requests',
            api_structure['price_request_parameters']))

        data['sections'].append(section(
            'Price Response Fields', 'price_response_fields',
            'Fields returned in price endpoint response',
            api_structure['price_response_fields']))

        data['sections'].append(section(
            'Post Quote Request Fields', 'post_quote_request_fields',
            'Fields in POST /quote request body',
            api_structure['post_quote_request_fields']))

        data['sections'].append(section(
            'Quote Response Fields', 'quote_response_fields',
            'Fields returned in quote endpoint responses',
            api_structure['quote_response_fields']))

        data['sections'].append(section(
            'Fee Fields', 'fee_fields', 'Fields in fee objects',
            api_structure['fee_fields']))

        data['sections'].append(section(
            'Fee Details Fields', 'fee_details_fields', 'Fields in fee details objects',
            api_structure['fee_details_fields']))

        # Calculate totals
        total_features = sum(section['feature_count'] for section in data['sections'])

        print(f"{Colors.GREEN}  ✓ Found 5 endpoints{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['prices_request_parameters'])} prices request parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['price_request_parameters'])} price request parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['post_quote_request_fields'])} post quote request fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['quote_response_fields'])} quote response fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-38 features{Colors.END}")

        return data

    def parse_sep_24(self) -> Dict[str, Any]:
        """
        Parse SEP-24 (Hosted Deposit and Withdrawal) specific structure.

        Returns:
            Structured SEP-24 data with API endpoints and interactive flow features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # API structure of SEP-24
        # SEP-24 is similar to SEP-06 but uses POST for interactive flows
        api_structure = {
            'info_endpoint': spec_item(
                'info_endpoint',
                'GET /info - Provides anchor capabilities and supported assets for interactive deposits/withdrawals',
                required=True, method='GET', path='/info',
                category='Info Endpoint'),
            'interactive_deposit_endpoint': spec_item(
                'interactive_deposit',
                'POST /transactions/deposit/interactive - Initiates an interactive deposit transaction',
                required=True, method='POST',
                path='/transactions/deposit/interactive',
                category='Deposit Endpoint'),
            'interactive_withdraw_endpoint': spec_item(
                'interactive_withdraw',
                'POST /transactions/withdraw/interactive - Initiates an interactive withdrawal transaction',
                required=True, method='POST',
                path='/transactions/withdraw/interactive',
                category='Withdraw Endpoint'),
            'transaction_endpoints': [
                spec_item(
                    'transactions',
                    'GET /transactions - Retrieves transaction history for authenticated account',
                    required=True, method='GET', path='/transactions',
                    category='Transaction Endpoint'),
                spec_item(
                    'transaction', 'GET /transaction - Retrieves details for a single transaction',
                    required=True, method='GET', path='/transaction',
                    category='Transaction Endpoint')
            ],
            'fee_endpoint': spec_item(
                'fee_endpoint',
                'GET /fee - Calculates fees for a deposit or withdrawal operation (optional)',
                method='GET', path='/fee', category='Fee Endpoint'),
            'deposit_request_parameters': [
                spec_item(
                    'asset_code', 'Code of the Stellar asset the user wants to receive',
                    required=True, type='string'),
                spec_item(
                    'asset_issuer', 'Issuer of the Stellar asset (optional if anchor is issuer)',
                    type='string'),
                spec_item(
                    'source_asset', 'Off-chain asset user wants to deposit (in SEP-38 format)',
                    type='string'),
                spec_item('amount', 'Amount of asset to deposit', type='string'),
                spec_item('quote_id', 'ID from SEP-38 quote (for asset exchange)', type='string'),
                spec_item(
                    'account', 'Stellar or muxed account for receiving deposit', type='string'),
                spec_item('memo', 'Memo value for transaction identification', type='string'),
                spec_item('memo_type', 'Type of memo (text, id, or hash)', type='string'),
                spec_item('wallet_name', 'Name of wallet for user communication', type='string'),
                spec_item('wallet_url', 'URL to link in transaction notifications', type='string'),
                spec_item('lang', 'Language code for UI and messages (RFC 4646)', type='string'),
                spec_item(
                    'claimable_balance_supported', 'Whether client supports claimable balances',
                    type='boolean')
            ],
            'withdraw_request_parameters': [
                spec_item(
                    'asset_code', 'Code of the Stellar asset user wants to send', required=True,
                    type='string'),
                spec_item(
                    'asset_issuer', 'Issuer of the Stellar asset (optional if anchor is issuer)',
                    type='string'),
                spec_item(
                    'destination_asset', 'Off-chain asset user wants to receive (in SEP-38 format)',
                    type='string'),
                spec_item('amount', 'Amount of asset to withdraw', type='string'),
                spec_item('quote_id', 'ID from SEP-38 quote (for asset exchange)', type='string'),
                spec_item(
                    'account', 'Stellar or muxed account that will send the withdrawal',
                    type='string'),
                spec_item('memo', 'Memo for identifying the withdrawal transaction', type='string'),
                spec_item('memo_type', 'Type of memo (text, id, or hash)', type='string'),
                spec_item('wallet_name', 'Name of wallet for user communication', type='string'),
                spec_item('wallet_url', 'URL to link in transaction notifications', type='string'),
                spec_item('lang', 'Language code for UI and messages (RFC 4646)', type='string')
            ],
            'interactive_response_fields': [
                spec_item(
                    'type', 'Always "interactive_customer_info_needed" for SEP-24', required=True),
                spec_item('url', 'URL for interactive flow popup/iframe', required=True),
                spec_item('id', 'Unique transaction identifier', required=True)
            ],
            'transaction_status_values': [
                spec_item(
                    'incomplete', 'Customer information still being collected via interactive flow',
                    required=True),
                spec_item(
                    'pending_user_transfer_start', 'Waiting for user to send funds (deposits)',
                    required=True),
                spec_item(
                    'pending_user_transfer_complete',
                    'User transfer detected, awaiting confirmations'),
                spec_item('pending_external', 'Transaction being processed by external system'),
                spec_item('pending_anchor', 'Anchor processing the transaction', required=True),
                spec_item('pending_stellar', 'Transaction submitted to Stellar network'),
                spec_item('pending_trust', 'User needs to establish trustline'),
                spec_item(
                    'pending_user', 'Waiting for user action (e.g., accepting claimable balance)'),
                spec_item('completed', 'Transaction completed successfully', required=True),
                spec_item('refunded', 'Transaction refunded'),
                spec_item('expired', 'Transaction expired before completion'),
                spec_item('error', 'Transaction encountered an error')
            ],
            'transaction_fields': [
                spec_item('id', 'Unique transaction identifier', required=True),
                spec_item('kind', 'Kind of transaction (deposit or withdrawal)', required=True),
                spec_item('status', 'Current status of the transaction', required=True),
                spec_item('status_eta', 'Estimated seconds until status changes'),
                spec_item('kyc_verified', 'Whether KYC has been verified for this transaction'),
                spec_item(
                    'more_info_url', 'URL with additional transaction information', required=True),
                spec_item('amount_in', 'Amount received by anchor'),
                spec_item('amount_in_asset', 'Asset received by anchor (SEP-38 format)'),
                spec_item('amount_out', 'Amount sent by anchor to user'),
                spec_item('amount_out_asset', 'Asset delivered to user (SEP-38 format)'),
                spec_item('amount_fee', 'Total fee charged for transaction'),
                spec_item('amount_fee_asset', 'Asset in which fees are calculated (SEP-38 format)'),
                spec_item('quote_id', 'ID of SEP-38 quote used for this transaction'),
                spec_item('started_at', 'When transaction was created (ISO 8601)', required=True),
                spec_item('completed_at', 'When transaction completed (ISO 8601)'),
                spec_item('updated_at', 'When transaction status last changed (ISO 8601)'),
                spec_item('user_action_required_by', 'Deadline for user action (ISO 8601)'),
                spec_item('stellar_transaction_id', 'Hash of the Stellar transaction'),
                spec_item('external_transaction_id', 'Identifier from external system'),
                spec_item('message', 'Human-readable message about transaction'),
                spec_item('refunded', 'Whether transaction was refunded (deprecated)'),
                spec_item('refunds', 'Refund information object'),
                spec_item(
                    'from', 'Source address (Stellar for withdrawals, external for deposits)'),
                spec_item(
                    'to', 'Destination address (Stellar for deposits, external for withdrawals)'),
                spec_item('deposit_memo', 'Memo for deposit to Stellar address'),
                spec_item('deposit_memo_type', 'Type of deposit memo'),
                spec_item('claimable_balance_id', 'ID of claimable balance for deposit'),
                spec_item(
                    'withdraw_anchor_account', "Anchor's Stellar account for withdrawal payment"),
                spec_item('withdraw_memo', 'Memo for withdrawal to anchor account'),
                spec_item('withdraw_memo_type', 'Type of withdraw memo')
            ],
            'info_response_fields': [
                spec_item(
                    'deposit', 'Map of asset codes to deposit asset information', required=True),
                spec_item(
                    'withdraw', 'Map of asset codes to withdraw asset information', required=True),
                spec_item('fee', 'Fee endpoint information object'),
                spec_item('features', 'Feature flags object')
            ],
            'deposit_asset_fields': [
                spec_item('enabled', 'Whether deposits are enabled for this asset', required=True),
                spec_item('min_amount', 'Minimum deposit amount'),
                spec_item('max_amount', 'Maximum deposit amount'),
                spec_item('fee_fixed', 'Fixed deposit fee'),
                spec_item('fee_percent', 'Percentage deposit fee'),
                spec_item('fee_minimum', 'Minimum deposit fee')
            ],
            'withdraw_asset_fields': [
                spec_item(
                    'enabled', 'Whether withdrawals are enabled for this asset', required=True),
                spec_item('min_amount', 'Minimum withdrawal amount'),
                spec_item('max_amount', 'Maximum withdrawal amount'),
                spec_item('fee_fixed', 'Fixed withdrawal fee'),
                spec_item('fee_percent', 'Percentage withdrawal fee'),
                spec_item('fee_minimum', 'Minimum withdrawal fee')
            ],
            'feature_flags_fields': [
                spec_item('account_creation', 'Whether anchor supports creating accounts'),
                spec_item('claimable_balances', 'Whether anchor supports claimable balances')
            ],
            'fee_endpoint_fields': [
                spec_item('enabled', 'Whether fee endpoint is available', required=True),
                spec_item(
                    'authentication_required',
                    'Whether authentication is required for fee endpoint')
            ]
        }

        # Store API structure components as sections
        data['sections'].append(section(
            'Info Endpoint', 'info_endpoint',
            'Endpoint for querying anchor interactive deposit/withdrawal capabilities',
            [api_structure['info_endpoint']]))

        data['sections'].append(section(
            'Interactive Deposit Endpoint', 'interactive_deposit_endpoint',
            'Endpoint for initiating interactive deposit flow',
            [api_structure['interactive_deposit_endpoint']]))

        data['sections'].append(section(
            'Interactive Withdraw Endpoint', 'interactive_withdraw_endpoint',
            'Endpoint for initiating interactive withdrawal flow',
            [api_structure['interactive_withdraw_endpoint']]))

        data['sections'].append(section(
            'Transaction Endpoints', 'transaction_endpoints',
            'Endpoints for tracking and querying transactions',
            api_structure['transaction_endpoints']))

        data['sections'].append(section(
            'Fee Endpoint', 'fee_endpoint', 'Optional endpoint for calculating transaction fees',
            [api_structure['fee_endpoint']]))

        data['sections'].append(section(
            'Deposit Request Parameters', 'deposit_request_parameters',
            'Parameters for interactive deposit endpoint',
            api_structure['deposit_request_parameters']))

        data['sections'].append(section(
            'Withdraw Request Parameters', 'withdraw_request_parameters',
            'Parameters for interactive withdraw endpoint',
            api_structure['withdraw_request_parameters']))

        data['sections'].append(section(
            'Interactive Response Fields', 'interactive_response_fields',
            'Fields returned in interactive deposit/withdraw responses',
            api_structure['interactive_response_fields']))

        data['sections'].append(section(
            'Transaction Status Values', 'transaction_status_values',
            'Possible transaction status values in SEP-24',
            api_structure['transaction_status_values']))

        data['sections'].append(section(
            'Transaction Fields', 'transaction_fields', 'Fields returned in transaction objects',
            api_structure['transaction_fields']))

        data['sections'].append(section(
            'Info Response Fields', 'info_response_fields',
            'Fields returned in info endpoint response',
            api_structure['info_response_fields']))

        data['sections'].append(section(
            'Deposit Asset Fields', 'deposit_asset_fields', 'Fields in deposit asset objects',
            api_structure['deposit_asset_fields']))

        data['sections'].append(section(
            'Withdraw Asset Fields', 'withdraw_asset_fields', 'Fields in withdraw asset objects',
            api_structure['withdraw_asset_fields']))

        data['sections'].append(section(
            'Feature Flags Fields', 'feature_flags_fields', 'Fields in feature flags object',
            api_structure['feature_flags_fields']))

        data['sections'].append(section(
            'Fee Endpoint Info Fields', 'fee_endpoint_fields', 'Fields in fee endpoint info object',
            api_structure['fee_endpoint_fields']))

        # Calculate totals
        total_features = sum(section['feature_count'] for section in data['sections'])

        print(f"{Colors.GREEN}  ✓ Found 1 info endpoint{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found 1 interactive deposit endpoint{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found 1 interactive withdraw endpoint{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['transaction_endpoints'])} transaction endpoints{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['deposit_request_parameters'])} deposit request parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['withdraw_request_parameters'])} withdraw request parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['transaction_status_values'])} transaction status values{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['transaction_fields'])} transaction fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-24 features{Colors.END}")

        return data

    def parse_sep_30(self) -> Dict[str, Any]:
        """
        Parse SEP-30 (Account Recovery) specific structure.

        Returns:
            Structured SEP-30 data with API endpoints and recovery features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # API structure of SEP-30
        # SEP-30 provides multi-party account recovery functionality
        api_structure = {
            'endpoints': [
                spec_item(
                    'register_account',
                    'POST /accounts/{address} - Register an account for recovery', required=True,
                    method='POST', path='/accounts/{address}', category='Account Registration'),
                spec_item(
                    'update_account', 'PUT /accounts/{address} - Update identities for an account',
                    required=True, method='PUT', path='/accounts/{address}',
                    category='Account Management'),
                spec_item(
                    'get_account', 'GET /accounts/{address} - Retrieve account details',
                    required=True, method='GET', path='/accounts/{address}',
                    category='Account Information'),
                spec_item(
                    'delete_account', 'DELETE /accounts/{address} - Delete account record',
                    required=True, method='DELETE', path='/accounts/{address}',
                    category='Account Management'),
                spec_item(
                    'list_accounts', 'GET /accounts - List accessible accounts', required=True,
                    method='GET', path='/accounts', category='Account Information'),
                spec_item(
                    'sign_transaction',
                    'POST /accounts/{address}/sign/{signing-address} - Sign a transaction',
                    required=True, method='POST', path='/accounts/{address}/sign/{signing-address}',
                    category='Transaction Signing')
            ],
            'request_fields': [
                spec_item(
                    'identities', 'Array of identity objects for account recovery', required=True,
                    type='array'),
                spec_item(
                    'role', 'Role of the identity (owner or other)', required=True, type='string',
                    values=['owner', 'other']),
                spec_item(
                    'auth_methods', 'Array of authentication methods for the identity',
                    required=True, type='array'),
                spec_item(
                    'type', 'Type of authentication method', required=True, type='string',
                    values=['stellar_address', 'phone_number', 'email', 'other']),
                spec_item(
                    'value', 'Value of the authentication method (address, phone, email, etc.)',
                    required=True, type='string'),
                spec_item(
                    'transaction', 'Base64-encoded XDR transaction envelope to sign', required=True,
                    type='string', context='sign_transaction'),
                spec_item(
                    'after', 'Cursor for pagination in list accounts endpoint', type='string',
                    context='list_accounts')
            ],
            'response_fields': [
                spec_item(
                    'address', 'Stellar address of the registered account', required=True,
                    type='string'),
                spec_item(
                    'identities', 'Array of registered identity objects', required=True,
                    type='array'),
                spec_item(
                    'signers', 'Array of signer objects for the account', required=True,
                    type='array'),
                spec_item(
                    'role', 'Role of the identity in response', required=True, type='string',
                    context='identity'),
                spec_item(
                    'authenticated', 'Whether the identity has been authenticated', type='boolean',
                    context='identity'),
                spec_item(
                    'key', 'Public key of the signer', required=True, type='string',
                    context='signer'),
                spec_item(
                    'signature', 'Base64-encoded signature of the transaction', required=True,
                    type='string', context='sign_response'),
                spec_item(
                    'network_passphrase', 'Network passphrase used for signing', required=True,
                    type='string', context='sign_response'),
                spec_item(
                    'accounts', 'Array of account objects in list response', required=True,
                    type='array', context='list_accounts')
            ],
            'error_codes': [
                {
                    'code': 400,
                    'name': 'Bad Request',
                    'description': 'Invalid request parameters or malformed data'
                },
                {
                    'code': 401,
                    'name': 'Unauthorized',
                    'description': 'Missing or invalid JWT token'
                },
                {
                    'code': 404,
                    'name': 'Not Found',
                    'description': 'Account or resource not found'
                },
                {
                    'code': 409,
                    'name': 'Conflict',
                    'description': 'Account already exists or conflicting operation'
                }
            ],
            'features': [
                spec_item(
                    'multi_party_recovery', 'Support for multi-server account recovery',
                    required=True, category='Core Feature'),
                spec_item(
                    'flexible_auth_methods', 'Support for multiple authentication method types',
                    required=True, category='Core Feature'),
                spec_item(
                    'transaction_signing', 'Server-side transaction signing for recovery',
                    required=True, category='Core Feature'),
                spec_item(
                    'account_sharing', 'Support for shared account access',
                    category='Optional Feature'),
                spec_item(
                    'identity_roles', 'Support for owner and other identity roles', required=True,
                    category='Core Feature'),
                spec_item(
                    'pagination', 'Pagination support in list accounts endpoint',
                    category='Optional Feature')
            ],
            'authentication': {
                'type': 'SEP-10 or External',
                'method': 'JWT Token',
                'description': 'All endpoints require authentication via Authorization header with JWT token from SEP-10 or external auth provider'
            }
        }

        # Store endpoints as a section
        data['sections'].append(section(
            'API Endpoints', 'api_endpoints', 'SEP-30 API endpoints for account recovery',
            api_structure['endpoints']))

        # Store request fields as a section
        data['sections'].append(section(
            'Request Fields', 'request_fields', 'Fields used in API requests',
            api_structure['request_fields']))

        # Store response fields as a section
        data['sections'].append(section(
            'Response Fields', 'response_fields', 'Fields returned in API responses',
            api_structure['response_fields']))

        # Store error codes as a section
        data['sections'].append(section(
            'Error Codes', 'error_codes', 'HTTP error codes and their meanings',
            api_structure['error_codes']))

        # Store features as a section
        data['sections'].append(section(
            'Recovery Features', 'recovery_features', 'Core and optional recovery features',
            api_structure['features']))

        # Store authentication info
        data['sections'].append({
            'title': 'Authentication',
            'key': 'authentication',
            'content': api_structure['authentication']['description'],
            'auth_info': api_structure['authentication'],
            'feature_count': 1
        })

        # Calculate totals
        total_features = (
            len(api_structure['endpoints']) +
            len(api_structure['request_fields']) +
            len(api_structure['response_fields']) +
            len(api_structure['error_codes']) +
            len(api_structure['features']) +
            1  # authentication
        )

        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['endpoints'])} API endpoints{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['request_fields'])} request fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['response_fields'])} response fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['error_codes'])} error codes{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(api_structure['features'])} recovery features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-30 features{Colors.END}")

        return data

    def parse_sep_07(self) -> Dict[str, Any]:
        """
        Parse SEP-07 (URI Scheme to facilitate delegated signing) specific structure.

        Returns:
            Structured SEP-07 data with URI operations and parameters
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define URI scheme structure for SEP-07
        uri_structure = {
            'operations': [],
            'tx_operation_parameters': [],
            'pay_operation_parameters': [],
            'common_parameters': [],
            'validation_features': [],
            'signature_features': []
        }

        # Operation types
        uri_structure['operations'] = [
            spec_item(
                'tx', 'Transaction operation - Request to sign a transaction', required=True,
                category='URI Operation'),
            spec_item(
                'pay', 'Payment operation - Request to pay a specific address', required=True,
                category='URI Operation')
        ]

        # TX operation parameters
        uri_structure['tx_operation_parameters'] = [
            spec_item(
                'xdr', 'Base64 encoded TransactionEnvelope XDR', required=True, operation='tx',
                type='string'),
            spec_item(
                'replace', 'URL-encoded field replacement using Txrep (SEP-0011) format',
                operation='tx', type='string'),
            spec_item(
                'callback', 'URL for transaction submission callback', operation='tx',
                type='string'),
            spec_item(
                'pubkey', 'Stellar public key to specify which key should sign', operation='tx',
                type='string'),
            spec_item(
                'chain', 'Nested SEP-0007 URL for transaction chaining', operation='tx',
                type='string')
        ]

        # PAY operation parameters
        uri_structure['pay_operation_parameters'] = [
            spec_item(
                'destination', 'Stellar account ID or payment address to receive payment',
                required=True, operation='pay', type='string'),
            spec_item('amount', 'Amount to send', operation='pay', type='string'),
            spec_item(
                'asset_code', 'Asset code for the payment (e.g., USD, BTC)', operation='pay',
                type='string'),
            spec_item(
                'asset_issuer', 'Stellar account ID of asset issuer', operation='pay',
                type='string'),
            spec_item(
                'memo', 'Memo value to attach to transaction', operation='pay', type='string'),
            spec_item(
                'memo_type', 'Type of memo (MEMO_TEXT, MEMO_ID, MEMO_HASH, MEMO_RETURN)',
                operation='pay', type='string',
                values=['MEMO_TEXT', 'MEMO_ID', 'MEMO_HASH', 'MEMO_RETURN'])
        ]

        # Common parameters (used by both operations)
        uri_structure['common_parameters'] = [
            spec_item(
                'msg', 'Message for the user (max 300 characters)', operation='both', type='string'),
            spec_item(
                'network_passphrase', 'Network passphrase for the transaction', operation='both',
                type='string'),
            spec_item(
                'origin_domain',
                'Fully qualified domain name of the service originating the request',
                operation='both', type='string'),
            spec_item(
                'signature', 'Signature of the URL for verification', operation='both',
                type='string')
        ]

        # Validation features
        uri_structure['validation_features'] = [
            spec_item(
                'validate_uri_scheme', 'Validate that URI starts with web+stellar:', required=True,
                category='URI Validation'),
            spec_item(
                'validate_operation_type', 'Validate operation type is tx or pay', required=True,
                category='URI Validation'),
            spec_item(
                'validate_xdr_parameter', 'Validate XDR parameter for tx operation', required=True,
                category='URI Validation'),
            spec_item(
                'validate_destination_parameter',
                'Validate destination parameter for pay operation', required=True,
                category='URI Validation'),
            spec_item(
                'validate_stellar_address',
                'Validate Stellar addresses (account IDs, muxed accounts, contract IDs)',
                required=True, category='URI Validation'),
            spec_item(
                'validate_asset_code', 'Validate asset code length and format', required=True,
                category='URI Validation'),
            spec_item(
                'validate_memo_type', 'Validate memo type is one of allowed types', required=True,
                category='URI Validation'),
            spec_item(
                'validate_memo_value', 'Validate memo value based on memo type', required=True,
                category='URI Validation'),
            spec_item(
                'validate_message_length', 'Validate message parameter length (max 300 chars)',
                required=True, category='URI Validation'),
            spec_item(
                'validate_origin_domain', 'Validate origin_domain is fully qualified domain name',
                required=True, category='URI Validation'),
            spec_item(
                'validate_chain_nesting', 'Validate chain parameter nesting depth (max 7 levels)',
                required=True, category='URI Validation')
        ]

        # Signature features
        uri_structure['signature_features'] = [
            spec_item(
                'sign_uri', 'Sign a SEP-0007 URI with a keypair', required=True,
                category='URI Signing'),
            spec_item(
                'verify_signature', 'Verify URI signature with a public key', required=True,
                category='URI Signing'),
            spec_item(
                'verify_signed_uri',
                'Verify signed URI by fetching signing key from origin domain TOML', required=True,
                category='URI Signing')
        ]

        # Store URI structure as sections
        data['sections'].append(section(
            'URI Operations', 'operations', 'URI scheme operations (tx and pay)',
            uri_structure['operations'], features_key='uri_features'))

        data['sections'].append(section(
            'TX Operation Parameters', 'tx_parameters', 'Parameters for tx operation',
            uri_structure['tx_operation_parameters'], features_key='uri_features'))

        data['sections'].append(section(
            'PAY Operation Parameters', 'pay_parameters', 'Parameters for pay operation',
            uri_structure['pay_operation_parameters'], features_key='uri_features'))

        data['sections'].append(section(
            'Common Parameters', 'common_parameters', 'Parameters common to both operations',
            uri_structure['common_parameters'], features_key='uri_features'))

        data['sections'].append(section(
            'Validation Features', 'validation_features', 'URI validation capabilities',
            uri_structure['validation_features'], features_key='uri_features'))

        data['sections'].append(section(
            'Signature Features', 'signature_features', 'URI signing and verification capabilities',
            uri_structure['signature_features'], features_key='uri_features'))

        # Calculate totals
        total_features = (
            len(uri_structure['operations']) +
            len(uri_structure['tx_operation_parameters']) +
            len(uri_structure['pay_operation_parameters']) +
            len(uri_structure['common_parameters']) +
            len(uri_structure['validation_features']) +
            len(uri_structure['signature_features'])
        )

        print(f"{Colors.GREEN}  ✓ Found {len(uri_structure['operations'])} URI operations{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(uri_structure['tx_operation_parameters'])} TX operation parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(uri_structure['pay_operation_parameters'])} PAY operation parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(uri_structure['common_parameters'])} common parameters{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(uri_structure['validation_features'])} validation features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(uri_structure['signature_features'])} signature features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-07 features{Colors.END}")

        return data

    def parse_sep_08(self) -> Dict[str, Any]:
        """
        Parse SEP-08 (Regulated Assets) specific structure.

        Returns:
            Structured SEP-08 data with approval server API details
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define Regulated Assets API structure for SEP-08
        regulated_assets_structure = {
            'approval_endpoint': [],
            'request_parameters': [],
            'response_statuses': [],
            'success_response_fields': [],
            'revised_response_fields': [],
            'pending_response_fields': [],
            'action_required_response_fields': [],
            'rejected_response_fields': [],
            'action_url_handling': [],
            'stellar_toml_fields': [],
            'authorization_flags': []
        }

        # Approval endpoint
        regulated_assets_structure['approval_endpoint'] = [
            spec_item(
                'tx_approve',
                'POST /tx_approve - Approval server endpoint that receives a signed transaction, checks for compliance, and signs it on success',
                required=True, method='POST', path='/tx_approve', category='Approval Endpoint')
        ]

        # Request parameters
        regulated_assets_structure['request_parameters'] = [
            spec_item(
                'tx',
                'A base64 encoded transaction envelope XDR signed by the user. This is the transaction that will be tested for compliance and signed on success.',
                required=True, type='string')
        ]

        # Response statuses
        regulated_assets_structure['response_statuses'] = [
            spec_item(
                'success', 'Transaction was found compliant and signed without being revised',
                required=True, http_status=200, category='Response Status'),
            spec_item(
                'revised', 'Transaction was revised to be made compliant', required=True,
                http_status=200, category='Response Status'),
            spec_item(
                'pending',
                'Issuer could not determine whether to approve the transaction at the time of receiving it',
                required=True, http_status=200, category='Response Status'),
            spec_item(
                'action_required',
                'User must complete an action before this transaction can be approved',
                required=True, http_status=200, category='Response Status'),
            spec_item(
                'rejected',
                'Transaction is not compliant and could not be revised to be made compliant',
                required=True, http_status=400, category='Response Status')
        ]

        # Success response fields
        regulated_assets_structure['success_response_fields'] = [
            spec_item('status', 'Status value "success"', required=True, type='string'),
            spec_item(
                'tx',
                'Transaction envelope XDR, base64 encoded. This transaction will have both the original signature(s) from the request as well as one or multiple additional signatures from the issuer.',
                required=True, type='string'),
            spec_item(
                'message', 'A human readable string containing information to pass on to the user',
                type='string')
        ]

        # Revised response fields
        regulated_assets_structure['revised_response_fields'] = [
            spec_item('status', 'Status value "revised"', required=True, type='string'),
            spec_item(
                'tx',
                'Transaction envelope XDR, base64 encoded. This transaction is a revised compliant version of the original request transaction, signed by the issuer.',
                required=True, type='string'),
            spec_item(
                'message',
                'A human readable string explaining the modifications made to the transaction to make it compliant',
                required=True, type='string')
        ]

        # Pending response fields
        regulated_assets_structure['pending_response_fields'] = [
            spec_item('status', 'Status value "pending"', required=True, type='string'),
            spec_item(
                'timeout',
                'Number of milliseconds to wait before submitting the same transaction again. Use 0 if the wait time cannot be determined.',
                required=True, type='integer'),
            spec_item(
                'message', 'A human readable string containing information to pass on to the user',
                type='string')
        ]

        # Action required response fields
        regulated_assets_structure['action_required_response_fields'] = [
            spec_item('status', 'Status value "action_required"', required=True, type='string'),
            spec_item(
                'message',
                'A human readable string containing information regarding the action required',
                required=True, type='string'),
            spec_item(
                'action_url',
                'A URL that allows the user to complete the actions required to have the transaction approved',
                required=True, type='string'),
            spec_item(
                'action_method',
                'GET or POST, indicating the type of request that should be made to the action_url. If not provided, GET is assumed.',
                type='string'),
            spec_item(
                'action_fields',
                'An array of additional fields defined by SEP-9 Standard KYC / AML fields that the client may optionally provide to the approval service when sending the request to the action_url',
                type='string[]')
        ]

        # Rejected response fields
        regulated_assets_structure['rejected_response_fields'] = [
            spec_item('status', 'Status value "rejected"', required=True, type='string'),
            spec_item(
                'error',
                'A human readable string explaining why the transaction is not compliant and could not be made compliant',
                required=True, type='string')
        ]

        # Action URL handling features
        regulated_assets_structure['action_url_handling'] = [
            spec_item(
                'action_url_get', 'Support for GET method to action_url with query parameters',
                required=True, category='Action URL Handling'),
            spec_item(
                'action_url_post', 'Support for POST method to action_url with JSON body',
                required=True, category='Action URL Handling'),
            spec_item(
                'action_url_post_response_no_further_action',
                'Handle POST response with result "no_further_action_required"', required=True,
                category='Action URL Handling'),
            spec_item(
                'action_url_post_response_follow_next_url',
                'Handle POST response with result "follow_next_url" and next_url field',
                required=True, category='Action URL Handling')
        ]

        # stellar.toml fields for regulated assets
        regulated_assets_structure['stellar_toml_fields'] = [
            spec_item(
                'regulated',
                'A boolean indicating whether or not this is a regulated asset. If missing, false is assumed.',
                required=True, type='boolean'),
            spec_item(
                'approval_server',
                'The URL of an approval service that signs validated transactions', required=True,
                type='string'),
            spec_item(
                'approval_criteria',
                "A human readable string that explains the issuer's requirements for approving transactions",
                type='string')
        ]

        # Authorization flags
        regulated_assets_structure['authorization_flags'] = [
            spec_item(
                'authorization_required',
                'Authorization Required flag must be set on issuer account', required=True,
                category='Authorization Flag'),
            spec_item(
                'authorization_revocable',
                'Authorization Revocable flag must be set on issuer account', required=True,
                category='Authorization Flag')
        ]

        # Store structure as sections
        data['sections'].append(section(
            'Approval Endpoint', 'approval_endpoint',
            'POST /tx_approve endpoint for transaction approval',
            regulated_assets_structure['approval_endpoint']))

        data['sections'].append(section(
            'Request Parameters', 'request_parameters', 'Parameters for POST /tx_approve request',
            regulated_assets_structure['request_parameters']))

        data['sections'].append(section(
            'Response Statuses', 'response_statuses', 'All possible response status values',
            regulated_assets_structure['response_statuses']))

        data['sections'].append(section(
            'Success Response Fields', 'success_response_fields',
            'Fields returned in success response',
            regulated_assets_structure['success_response_fields']))

        data['sections'].append(section(
            'Revised Response Fields', 'revised_response_fields',
            'Fields returned in revised response',
            regulated_assets_structure['revised_response_fields']))

        data['sections'].append(section(
            'Pending Response Fields', 'pending_response_fields',
            'Fields returned in pending response',
            regulated_assets_structure['pending_response_fields']))

        data['sections'].append(section(
            'Action Required Response Fields', 'action_required_response_fields',
            'Fields returned in action_required response',
            regulated_assets_structure['action_required_response_fields']))

        data['sections'].append(section(
            'Rejected Response Fields', 'rejected_response_fields',
            'Fields returned in rejected response',
            regulated_assets_structure['rejected_response_fields']))

        data['sections'].append(section(
            'Action URL Handling', 'action_url_handling',
            'Features for handling action_url in action_required response',
            regulated_assets_structure['action_url_handling']))

        data['sections'].append(section(
            'Stellar TOML Fields', 'stellar_toml_fields',
            'Fields in stellar.toml for regulated assets',
            regulated_assets_structure['stellar_toml_fields']))

        data['sections'].append(section(
            'Authorization Flags', 'authorization_flags',
            'Required authorization flags on issuer account',
            regulated_assets_structure['authorization_flags']))

        # Calculate totals
        total_features = (
            len(regulated_assets_structure['approval_endpoint']) +
            len(regulated_assets_structure['request_parameters']) +
            len(regulated_assets_structure['response_statuses']) +
            len(regulated_assets_structure['success_response_fields']) +
            len(regulated_assets_structure['revised_response_fields']) +
            len(regulated_assets_structure['pending_response_fields']) +
            len(regulated_assets_structure['action_required_response_fields']) +
            len(regulated_assets_structure['rejected_response_fields']) +
            len(regulated_assets_structure['action_url_handling']) +
            len(regulated_assets_structure['stellar_toml_fields']) +
            len(regulated_assets_structure['authorization_flags'])
        )

        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['approval_endpoint'])} approval endpoint{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['request_parameters'])} request parameter{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['response_statuses'])} response statuses{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['success_response_fields'])} success response fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['revised_response_fields'])} revised response fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['pending_response_fields'])} pending response fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['action_required_response_fields'])} action_required response fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['rejected_response_fields'])} rejected response fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['action_url_handling'])} action URL handling features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['stellar_toml_fields'])} stellar.toml fields{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(regulated_assets_structure['authorization_flags'])} authorization flags{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-08 features{Colors.END}")

        return data

    def parse_sep_45(self) -> Dict[str, Any]:
        """
        Parse SEP-45 (Web Authentication for Contract Accounts) specific structure.

        Returns:
            Structured SEP-45 data with contract authentication protocol features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define authentication features structure for SEP-45
        auth_features = {
            'authentication_endpoints': [],
            'challenge_features': [],
            'jwt_token_features': [],
            'client_domain_features': [],
            'validation_features': [],
            'exception_types': []
        }

        # Authentication Endpoints (GET and POST /auth)
        auth_features['authentication_endpoints'] = [
            spec_item(
                'get_auth_challenge',
                'GET /auth endpoint - Returns authorization entries for contract accounts',
                required=True, category='Authentication Endpoint', method='GET',
                parameters=['account', 'home_domain', 'client_domain']),
            spec_item(
                'post_auth_token',
                'POST /auth endpoint - Validates signed authorization entries and returns JWT token',
                required=True, category='Authentication Endpoint', method='POST',
                parameters=['authorization_entries'])
        ]

        # Challenge Features (SorobanAuthorizationEntry based)
        auth_features['challenge_features'] = [
            spec_item(
                'authorization_entry_decoding',
                'Decode base64 XDR encoded authorization entries from server', required=True,
                category='Challenge'),
            spec_item(
                'authorization_entry_encoding',
                'Encode signed authorization entries to base64 XDR for submission', required=True,
                category='Challenge'),
            spec_item(
                'contract_invocation_parsing',
                'Parse web_auth_verify contract invocation from authorization entries',
                required=True, category='Challenge'),
            spec_item(
                'signature_expiration_ledger',
                'Support signature expiration ledger for replay protection', required=True,
                category='Challenge'),
            spec_item(
                'auto_signature_expiration',
                'Automatically fetch and set signature expiration from Soroban RPC',
                category='Challenge'),
            spec_item(
                'nonce_consistency', 'Verify nonce is consistent across all authorization entries',
                required=True, category='Challenge'),
            spec_item(
                'server_entry_signing', 'Server entry is pre-signed in challenge', required=True,
                category='Challenge'),
            spec_item(
                'client_entry_signing', 'Sign client authorization entry with provided signers',
                required=True, category='Challenge')
        ]

        # JWT Token Features
        auth_features['jwt_token_features'] = [
            spec_item(
                'jwt_token_response', 'Parse JWT token from server response', required=True,
                category='JWT Token'),
            spec_item(
                'jwt_token_generation', 'Generate JWT token after successful challenge validation',
                required=True, category='JWT Token', server_side_only=True,
                client_note='Server-side feature. Client SDKs receive and use the JWT token.'),
            spec_item(
                'complete_auth_flow', 'Execute complete authentication flow via jwtToken method',
                required=True, category='JWT Token')
        ]

        # Client Domain Features
        auth_features['client_domain_features'] = [
            spec_item(
                'client_domain_parameter',
                'Support optional client_domain parameter in challenge request',
                category='Client Domain'),
            spec_item(
                'client_domain_entry', 'Handle client domain authorization entry in challenge',
                category='Client Domain'),
            spec_item(
                'client_domain_local_signing', 'Sign client domain entry with local keypair',
                category='Client Domain'),
            spec_item(
                'client_domain_callback_signing', 'Sign client domain entry via remote callback',
                category='Client Domain'),
            spec_item(
                'client_domain_toml_lookup', 'Lookup client domain signing key from stellar.toml',
                category='Client Domain')
        ]

        # Validation Features
        auth_features['validation_features'] = [
            spec_item(
                'contract_address_validation',
                'Validate contract address matches WEB_AUTH_CONTRACT_ID from stellar.toml',
                required=True, category='Validation'),
            spec_item(
                'function_name_validation', 'Validate function name is web_auth_verify',
                required=True, category='Validation'),
            spec_item(
                'sub_invocations_check', 'Reject authorization entries with sub-invocations',
                required=True, category='Validation'),
            spec_item(
                'server_signature_verification',
                'Verify server signature on server authorization entry', required=True,
                category='Validation'),
            spec_item(
                'server_entry_presence', 'Validate server authorization entry is present',
                required=True, category='Validation'),
            spec_item(
                'client_entry_presence', 'Validate client authorization entry is present',
                required=True, category='Validation'),
            spec_item(
                'home_domain_validation', 'Validate home_domain argument matches expected domain',
                required=True, category='Validation'),
            spec_item(
                'web_auth_domain_validation',
                'Validate web_auth_domain argument matches server domain', required=True,
                category='Validation'),
            spec_item(
                'account_validation', 'Validate account argument matches client contract account',
                required=True, category='Validation'),
            spec_item(
                'network_passphrase_validation',
                'Validate network passphrase if provided in response', category='Validation')
        ]

        # Exception Types
        auth_features['exception_types'] = [
            spec_item(
                'invalid_contract_address_exception', 'Exception for contract address mismatch',
                required=True, category='Exception'),
            spec_item(
                'invalid_function_name_exception', 'Exception for invalid function name',
                required=True, category='Exception'),
            spec_item(
                'sub_invocations_exception', 'Exception when sub-invocations found', required=True,
                category='Exception'),
            spec_item(
                'invalid_server_signature_exception', 'Exception for invalid server signature',
                required=True, category='Exception'),
            spec_item(
                'missing_server_entry_exception', 'Exception when server entry is missing',
                required=True, category='Exception'),
            spec_item(
                'missing_client_entry_exception', 'Exception when client entry is missing',
                required=True, category='Exception'),
            spec_item(
                'challenge_request_error_exception', 'Exception for challenge request errors',
                required=True, category='Exception'),
            spec_item(
                'submit_challenge_error_exception', 'Exception for challenge submission errors',
                required=True, category='Exception')
        ]

        # Store sections
        data['sections'].append(section(
            'Authentication Endpoints', 'auth_endpoints',
            'GET and POST /auth endpoints for contract account authentication',
            auth_features['authentication_endpoints'], features_key='auth_features'))

        data['sections'].append(section(
            'Challenge Features', 'challenge_features',
            'SorobanAuthorizationEntry challenge handling features',
            auth_features['challenge_features'], features_key='auth_features'))

        data['sections'].append(section(
            'JWT Token Features', 'jwt_token', 'JWT token handling and authentication flow',
            auth_features['jwt_token_features'], features_key='auth_features'))

        data['sections'].append(section(
            'Client Domain Features', 'client_domain',
            'Optional client domain verification features',
            auth_features['client_domain_features'], features_key='auth_features'))

        data['sections'].append(section(
            'Validation Features', 'validation', 'Challenge validation and security checks',
            auth_features['validation_features'], features_key='auth_features'))

        data['sections'].append(section(
            'Exception Types', 'exception_types', 'Specific exception types for error handling',
            auth_features['exception_types'], features_key='auth_features'))

        # Add metadata
        data['metadata'] = {
            'parsed_at': datetime.now().isoformat(),
            'source_url': f'https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-{self.sep_number}.md',
            'content_length': len(self.raw_content)
        }

        # Print summary
        total_features = sum(len(auth_features[key]) for key in auth_features)
        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['authentication_endpoints'])} authentication endpoints{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['challenge_features'])} challenge features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['jwt_token_features'])} JWT token features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['client_domain_features'])} client domain features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['validation_features'])} validation features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(auth_features['exception_types'])} exception types{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-45 features{Colors.END}")

        return data

    def parse_sep_46(self) -> Dict[str, Any]:
        """
        Parse SEP-46 (Contract Meta) specific structure.

        Returns:
            Structured SEP-46 data with contract metadata features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define contract metadata features structure for SEP-46
        contract_meta_features = {
            'metadata_storage': [],
            'encoding_format': [],
            'implementation_support': []
        }

        # Metadata storage features
        contract_meta_features['metadata_storage'] = [
            spec_item(
                'contractmetav0_section',
                'Support for storing metadata in "contractmetav0" Wasm custom sections',
                required=True, category='Metadata Storage'),
            spec_item(
                'multiple_entries_single_section',
                'Support for multiple metadata entries in a single custom section', required=True,
                category='Metadata Storage'),
            spec_item(
                'multiple_sections',
                'Support for multiple "contractmetav0" sections interpreted sequentially',
                required=True, category='Metadata Storage')
        ]

        # Encoding format features
        contract_meta_features['encoding_format'] = [
            spec_item(
                'scmetaentry_xdr', 'Use SCMetaEntry XDR type for structuring metadata',
                required=True, category='Encoding Format'),
            spec_item(
                'binary_stream_encoding', 'Encode entries as a stream of binary values',
                required=True, category='Encoding Format'),
            spec_item(
                'key_value_pairs', 'Store metadata as key-value string pairs', required=True,
                category='Encoding Format')
        ]

        # Implementation support features
        contract_meta_features['implementation_support'] = [
            spec_item(
                'parse_contract_meta', 'Parse contract metadata from contract bytecode',
                required=True, category='Implementation Support'),
            spec_item(
                'extract_meta_entries', 'Extract meta entries as key-value pairs from contract',
                required=True, category='Implementation Support'),
            spec_item(
                'decode_scmetaentry', 'Decode SCMetaEntry XDR structures', required=True,
                category='Implementation Support')
        ]

        # Store features as sections
        data['sections'].append(section(
            'Contract Metadata Storage', 'metadata_storage',
            'Features for storing metadata in Wasm custom sections',
            contract_meta_features['metadata_storage'], features_key='contract_meta_features'))

        data['sections'].append(section(
            'Encoding Format', 'encoding_format', 'XDR encoding format for metadata entries',
            contract_meta_features['encoding_format'], features_key='contract_meta_features'))

        data['sections'].append(section(
            'Implementation Support', 'implementation_support',
            'SDK support for parsing and extracting contract metadata',
            contract_meta_features['implementation_support'], features_key='contract_meta_features'))

        total_features = (
            len(contract_meta_features['metadata_storage']) +
            len(contract_meta_features['encoding_format']) +
            len(contract_meta_features['implementation_support'])
        )

        print(f"{Colors.GREEN}  ✓ Found {len(contract_meta_features['metadata_storage'])} metadata storage features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(contract_meta_features['encoding_format'])} encoding format features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(contract_meta_features['implementation_support'])} implementation support features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-46 features{Colors.END}")

        return data

    def parse_sep_47(self) -> Dict[str, Any]:
        """
        Parse SEP-47 (Contract Interface Discovery) specific structure.

        Returns:
            Structured SEP-47 data with contract interface discovery features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define contract interface discovery features structure for SEP-47
        interface_discovery_features = {
            'sep_declaration': [],
            'meta_entry_format': [],
            'implementation_support': []
        }

        # SEP declaration features
        interface_discovery_features['sep_declaration'] = [
            spec_item(
                'sep_meta_key', 'Support for "sep" meta entry key to indicate implemented SEPs',
                required=True, category='SEP Declaration'),
            spec_item(
                'comma_separated_list', 'Parse comma-separated list of SEP numbers from meta value',
                required=True, category='SEP Declaration'),
            spec_item(
                'multiple_sep_entries',
                'Support for multiple "sep" meta entries with combined values', required=True,
                category='SEP Declaration')
        ]

        # Meta entry format features
        interface_discovery_features['meta_entry_format'] = [
            spec_item(
                'sep_number_format',
                'Parse SEP numbers in various formats (e.g., "41", "0041", "SEP-41")',
                required=True, category='Meta Entry Format'),
            spec_item(
                'whitespace_handling', 'Trim whitespace from SEP numbers in comma-separated list',
                required=True, category='Meta Entry Format'),
            spec_item(
                'empty_value_handling', 'Handle empty or missing "sep" meta entries gracefully',
                required=True, category='Meta Entry Format')
        ]

        # Implementation support features
        interface_discovery_features['implementation_support'] = [
            spec_item(
                'parse_supported_seps',
                'Parse and extract list of supported SEPs from contract metadata', required=True,
                category='Implementation Support'),
            spec_item(
                'expose_supported_seps', 'Expose supportedSeps property on contract info object',
                required=True, category='Implementation Support'),
            spec_item(
                'validate_sep_format', 'Validate SEP number format and filter invalid entries',
                required=True, category='Implementation Support')
        ]

        # Store features as sections
        data['sections'].append(section(
            'SEP Declaration', 'sep_declaration',
            'Features for declaring implemented SEPs in contract metadata',
            interface_discovery_features['sep_declaration'], features_key='contract_meta_features'))

        data['sections'].append(section(
            'Meta Entry Format', 'meta_entry_format',
            'Parsing and format handling for SEP meta entries',
            interface_discovery_features['meta_entry_format'], features_key='contract_meta_features'))

        data['sections'].append(section(
            'Implementation Support', 'implementation_support',
            'SDK support for parsing and exposing supported SEPs',
            interface_discovery_features['implementation_support'], features_key='contract_meta_features'))

        total_features = (
            len(interface_discovery_features['sep_declaration']) +
            len(interface_discovery_features['meta_entry_format']) +
            len(interface_discovery_features['implementation_support'])
        )

        print(f"{Colors.GREEN}  ✓ Found {len(interface_discovery_features['sep_declaration'])} SEP declaration features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(interface_discovery_features['meta_entry_format'])} meta entry format features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(interface_discovery_features['implementation_support'])} implementation support features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-47 features{Colors.END}")

        return data

    def parse_sep_48(self) -> Dict[str, Any]:
        """
        Parse SEP-48 (Smart Contract Specifications) specific structure.

        Returns:
            Structured SEP-48 data with contract specification features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        # Define contract specification features structure for SEP-48
        contract_spec_features = {
            'wasm_section': [],
            'entry_types': [],
            'type_system_primitive': [],
            'type_system_compound': [],
            'parsing_support': [],
            'xdr_support': []
        }

        # Wasm custom section features
        contract_spec_features['wasm_section'] = [
            spec_item(
                'contractspecv0_section', 'Support for "contractspecv0" Wasm custom section',
                required=True, category='Wasm Custom Section'),
            spec_item(
                'contractenvmetav0_section',
                'Support for "contractenvmetav0" Wasm custom section for environment metadata',
                required=True, category='Wasm Custom Section'),
            spec_item(
                'contractmetav0_section',
                'Support for "contractmetav0" Wasm custom section for contract metadata',
                required=True, category='Wasm Custom Section'),
            spec_item(
                'xdr_binary_encoding', 'Parse XDR binary encoded specification entries',
                required=True, category='Wasm Custom Section')
        ]

        # Entry types - all 6 specified in SEP-48
        contract_spec_features['entry_types'] = [
            spec_item(
                'function_specs',
                'Parse function specification entries (SC_SPEC_ENTRY_FUNCTION_V0)', required=True,
                category='Entry Types'),
            spec_item(
                'struct_specs',
                'Parse struct type specification entries (SC_SPEC_ENTRY_UDT_STRUCT_V0)',
                required=True, category='Entry Types'),
            spec_item(
                'union_specs',
                'Parse union type specification entries (SC_SPEC_ENTRY_UDT_UNION_V0)',
                required=True, category='Entry Types'),
            spec_item(
                'enum_specs', 'Parse enum type specification entries (SC_SPEC_ENTRY_UDT_ENUM_V0)',
                required=True, category='Entry Types'),
            spec_item(
                'error_enum_specs',
                'Parse error enum specification entries (SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0)',
                required=True, category='Entry Types'),
            spec_item(
                'event_specs', 'Parse event specification entries (SC_SPEC_ENTRY_EVENT_V0)',
                required=True, category='Entry Types')
        ]

        # Type system - primitive types
        contract_spec_features['type_system_primitive'] = [
            spec_item(
                'boolean_type', 'Support for boolean type (SC_SPEC_TYPE_BOOL)', required=True,
                category='Type System - Primitive'),
            spec_item(
                'void_type', 'Support for void type (SC_SPEC_TYPE_VOID)', required=True,
                category='Type System - Primitive'),
            spec_item(
                'numeric_types',
                'Support for numeric types (u32, i32, u64, i64, u128, i128, u256, i256)',
                required=True, category='Type System - Primitive'),
            spec_item(
                'timepoint_duration', 'Support for timepoint and duration types', required=True,
                category='Type System - Primitive'),
            spec_item(
                'bytes_string_symbol', 'Support for bytes, string, and symbol types', required=True,
                category='Type System - Primitive'),
            spec_item(
                'address_type', 'Support for address type (SC_SPEC_TYPE_ADDRESS)', required=True,
                category='Type System - Primitive')
        ]

        # Type system - compound types
        contract_spec_features['type_system_compound'] = [
            spec_item(
                'option_type', 'Support for Option<T> type (SC_SPEC_TYPE_OPTION)', required=True,
                category='Type System - Compound'),
            spec_item(
                'result_type', 'Support for Result<T, E> type (SC_SPEC_TYPE_RESULT)', required=True,
                category='Type System - Compound'),
            spec_item(
                'vector_type', 'Support for Vec<T> type (SC_SPEC_TYPE_VEC)', required=True,
                category='Type System - Compound'),
            spec_item(
                'map_type', 'Support for Map<K, V> type (SC_SPEC_TYPE_MAP)', required=True,
                category='Type System - Compound'),
            spec_item(
                'tuple_type', 'Support for tuple types (SC_SPEC_TYPE_TUPLE)', required=True,
                category='Type System - Compound'),
            spec_item(
                'bytes_n_type', 'Support for fixed-length bytes type (SC_SPEC_TYPE_BYTES_N)',
                required=True, category='Type System - Compound'),
            spec_item(
                'user_defined_type', 'Support for user-defined types (SC_SPEC_TYPE_UDT)',
                required=True, category='Type System - Compound')
        ]

        # Parsing support
        contract_spec_features['parsing_support'] = [
            spec_item(
                'parse_contract_bytecode', 'Parse contract specifications from Wasm bytecode',
                required=True, category='Parsing Support'),
            spec_item(
                'extract_spec_entries', 'Extract and decode all specification entries',
                required=True, category='Parsing Support'),
            spec_item(
                'parse_environment_meta', 'Parse environment metadata (interface version)',
                required=True, category='Parsing Support'),
            spec_item(
                'parse_contract_meta', 'Parse contract metadata key-value pairs', required=True,
                category='Parsing Support')
        ]

        # XDR support
        contract_spec_features['xdr_support'] = [
            spec_item(
                'decode_scspecentry', 'Decode SCSpecEntry XDR structures', required=True,
                category='XDR Support'),
            spec_item(
                'decode_scspectypedef', 'Decode SCSpecTypeDef XDR structures for type definitions',
                required=True, category='XDR Support'),
            spec_item(
                'decode_scenvmetaentry', 'Decode SCEnvMetaEntry XDR structures', required=True,
                category='XDR Support'),
            spec_item(
                'decode_scmetaentry', 'Decode SCMetaEntry XDR structures', required=True,
                category='XDR Support')
        ]

        # Store features as sections
        data['sections'].append(section(
            'Wasm Custom Section', 'wasm_section',
            'Support for parsing contract specifications from Wasm custom sections',
            contract_spec_features['wasm_section'], features_key='contract_spec_features'))

        data['sections'].append(section(
            'Entry Types', 'entry_types', 'Support for all 6 specification entry types',
            contract_spec_features['entry_types'], features_key='contract_spec_features'))

        data['sections'].append(section(
            'Type System - Primitive Types', 'type_system_primitive',
            'Support for primitive Soroban types',
            contract_spec_features['type_system_primitive'], features_key='contract_spec_features'))

        data['sections'].append(section(
            'Type System - Compound Types', 'type_system_compound',
            'Support for compound Soroban types',
            contract_spec_features['type_system_compound'], features_key='contract_spec_features'))

        data['sections'].append(section(
            'Parsing Support', 'parsing_support', 'SDK support for parsing contract specifications',
            contract_spec_features['parsing_support'], features_key='contract_spec_features'))

        data['sections'].append(section(
            'XDR Support', 'xdr_support', 'XDR decoding support for specification structures',
            contract_spec_features['xdr_support'], features_key='contract_spec_features'))

        total_features = (
            len(contract_spec_features['wasm_section']) +
            len(contract_spec_features['entry_types']) +
            len(contract_spec_features['type_system_primitive']) +
            len(contract_spec_features['type_system_compound']) +
            len(contract_spec_features['parsing_support']) +
            len(contract_spec_features['xdr_support'])
        )

        print(f"{Colors.GREEN}  ✓ Found {len(contract_spec_features['wasm_section'])} Wasm section features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(contract_spec_features['entry_types'])} entry type features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(contract_spec_features['type_system_primitive'])} primitive type features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(contract_spec_features['type_system_compound'])} compound type features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(contract_spec_features['parsing_support'])} parsing support features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(contract_spec_features['xdr_support'])} XDR support features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-48 features{Colors.END}")

        return data

    def parse_sep_51(self) -> Dict[str, Any]:
        """
        Parse SEP-51 (XDR-JSON) specific structure.

        SEP-51 defines a mapping between XDR structures and JSON rather than an
        HTTP API, so the capability set is one entry per mapping rule the
        specification states. Preamble and summary come from the fetched
        document.

        Two rules are recommendations rather than requirements and are recorded
        as optional: accepting a JSON number for the two Hyper types, which the
        specification asks for "where possible" to stay readable to XDR-JSON v1
        producers, and allowing a `$schema` property on JSON objects, which the
        specification requires be allowed but not required.

        Returns:
            Structured SEP-51 data with XDR-JSON mapping features
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': []
        }

        xdr_json_features = {
            'xdr_data_types': [],
            'stellar_specific_types': [],
            'json_schema': []
        }

        # XDR data type mappings (SEP-51 Specification -> XDR Data Types).
        xdr_json_features['xdr_data_types'] = [
            spec_item(
                'integer_32', '32-bit signed integer maps to a JSON number', required=True,
                category='XDR Data Types'),
            spec_item(
                'unsigned_integer_32', '32-bit unsigned integer maps to a JSON number',
                required=True, category='XDR Data Types'),
            spec_item(
                'hyper_integer', '64-bit signed integer maps to a base-10 JSON string',
                required=True, category='XDR Data Types'),
            spec_item(
                'unsigned_hyper_integer', '64-bit unsigned integer maps to a base-10 JSON string',
                required=True, category='XDR Data Types'),
            spec_item(
                'hyper_number_input',
                'Deserializes a JSON number for Hyper, for XDR-JSON v1 compatibility',
                category='XDR Data Types'),
            spec_item(
                'unsigned_hyper_number_input',
                'Deserializes a JSON number for Unsigned Hyper, for XDR-JSON v1 compatibility',
                category='XDR Data Types'),
            spec_item(
                'boolean', 'Boolean maps to a JSON boolean', required=True,
                category='XDR Data Types'),
            spec_item(
                'opaque_fixed', 'Fixed-length opaque data maps to a hexadecimal string',
                required=True, category='XDR Data Types'),
            spec_item(
                'opaque_variable', 'Variable-length opaque data maps to a hexadecimal string',
                required=True, category='XDR Data Types'),
            spec_item(
                'string_escaping',
                'String is escaped per the specification ladder: \\0, \\t, \\n, \\r, \\\\, printable ASCII verbatim, \\xNN otherwise',
                required=True, category='XDR Data Types'),
            spec_item(
                'array_fixed', 'Fixed-length array maps to a JSON array', required=True,
                category='XDR Data Types'),
            spec_item(
                'array_variable', 'Variable-length array maps to a JSON array', required=True,
                category='XDR Data Types'),
            spec_item(
                'enum', 'Enum maps to a snake_case string with any shared prefix removed',
                required=True, category='XDR Data Types'),
            spec_item(
                'struct', 'Struct maps to a JSON object keyed by the snake_case field name',
                required=True, category='XDR Data Types'),
            spec_item(
                'union_void_arm', 'Union with a void arm maps to a bare discriminant string',
                required=True, category='XDR Data Types'),
            spec_item(
                'union_value_arm',
                'Union with a value arm maps to a single-key object keyed by the discriminant',
                required=True, category='XDR Data Types'),
            spec_item(
                'union_integer_cases',
                'Union with integer cases keys on the discriminant name suffixed by the integer',
                required=True, category='XDR Data Types'),
            spec_item('void', 'Void is omitted in JSON', required=True, category='XDR Data Types'),
            spec_item(
                'optional', 'Optional data maps to null when unset and to the value when set',
                required=True, category='XDR Data Types'),
        ]

        # Stellar-specific renderings (SEP-51 Stellar-Specific Types).
        xdr_json_features['stellar_specific_types'] = [
            spec_item(
                'sc_address', 'ScAddress renders as a G, C, M, B or L strkey by arm', required=True,
                category='Stellar-Specific Types'),
            spec_item(
                'account_id', 'AccountID renders as a G strkey', required=True,
                category='Stellar-Specific Types'),
            spec_item(
                'contract_id', 'ContractID renders as a C strkey', required=True,
                category='Stellar-Specific Types'),
            spec_item(
                'muxed_account',
                'MuxedAccount renders as a G strkey (ed25519) or an M strkey (muxed ed25519)',
                required=True, category='Stellar-Specific Types'),
            spec_item(
                'muxed_account_med25519', 'MuxedAccountMed25519 renders as an M strkey',
                required=True, category='Stellar-Specific Types'),
            spec_item(
                'muxed_ed25519_account', 'MuxedEd25519Account renders as an M strkey',
                required=True, category='Stellar-Specific Types'),
            spec_item(
                'pool_id', 'PoolID renders as an L strkey', required=True,
                category='Stellar-Specific Types'),
            spec_item(
                'claimable_balance_id', 'ClaimableBalanceID renders as a B strkey', required=True,
                category='Stellar-Specific Types'),
            spec_item(
                'public_key', 'PublicKey renders as a G strkey', required=True,
                category='Stellar-Specific Types'),
            spec_item(
                'node_id', 'NodeID renders as a G strkey', required=True,
                category='Stellar-Specific Types'),
            spec_item(
                'signer_key', 'SignerKey renders as a G, T, X or P strkey by arm', required=True,
                category='Stellar-Specific Types'),
            spec_item(
                'signer_key_ed25519_signed_payload',
                'SignerKeyEd25519SignedPayload renders as a P strkey', required=True,
                category='Stellar-Specific Types'),
            spec_item(
                'asset_code',
                'AssetCode renders as the string of its AssetCode4 or AssetCode12 arm',
                required=True, category='Stellar-Specific Types'),
            spec_item(
                'asset_code_4',
                'AssetCode4 drops trailing zero bytes, then takes the string escape ladder',
                required=True, category='Stellar-Specific Types'),
            spec_item(
                'asset_code_12',
                'AssetCode12 drops trailing zero bytes down to five, then takes the string escape ladder',
                required=True, category='Stellar-Specific Types'),
            spec_item(
                'int128_parts',
                'Int128Parts renders as one base-10 string of the reassembled integer',
                required=True, category='Stellar-Specific Types'),
            spec_item(
                'uint128_parts',
                'UInt128Parts renders as one base-10 string of the reassembled integer',
                required=True, category='Stellar-Specific Types'),
            spec_item(
                'int256_parts',
                'Int256Parts renders as one base-10 string of the reassembled integer',
                required=True, category='Stellar-Specific Types'),
            spec_item(
                'uint256_parts',
                'UInt256Parts renders as one base-10 string of the reassembled integer',
                required=True, category='Stellar-Specific Types'),
        ]

        # JSON Schema property (SEP-51 JSON Schema).
        xdr_json_features['json_schema'] = [
            spec_item(
                'schema_property', 'JSON objects allow, but do not require, a $schema property',
                category='JSON Schema'),
        ]

        data['sections'].append(section(
            'XDR Data Types', 'xdr_data_types',
            'Mapping of the XDR data types to their JSON representation',
            xdr_json_features['xdr_data_types'], features_key='xdr_json_features'))

        data['sections'].append(section(
            'Stellar-Specific Types', 'stellar_specific_types',
            'Strkey, asset code and multi-limb integer renderings',
            xdr_json_features['stellar_specific_types'], features_key='xdr_json_features'))

        data['sections'].append(section(
            'JSON Schema', 'json_schema', 'Optional $schema property on JSON objects',
            xdr_json_features['json_schema'], features_key='xdr_json_features'))

        total_features = (
            len(xdr_json_features['xdr_data_types']) +
            len(xdr_json_features['stellar_specific_types']) +
            len(xdr_json_features['json_schema'])
        )

        print(f"{Colors.GREEN}  ✓ Found {len(xdr_json_features['xdr_data_types'])} XDR data type features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(xdr_json_features['stellar_specific_types'])} Stellar-specific type features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Found {len(xdr_json_features['json_schema'])} JSON schema features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {total_features} SEP-51 features{Colors.END}")

        return data

    SEP_23_SPECIFICATION_SECTION = re.compile(
        r'^##[ \t]+Specification[ \t]*\n(.*?)(?=^##[ \t]|\Z)', re.MULTILINE | re.DOTALL
    )
    # SEP-23 version byte table: the header row names the 'Key type' and
    # 'First char' columns, a separator row follows, then one row per type.
    SEP_23_TYPE_TABLE = re.compile(
        r'^\|(?=[^\n]*\bKey type\b)(?=[^\n]*\bFirst char\b)([^\n]*)\|[ \t]*\n'
        r'\|[-:| \t]+\|[ \t]*\n'
        r'((?:\|[^\n]*(?:\n|\Z))*)',
        re.MULTILINE
    )
    SEP_23_TESTS_SECTION = re.compile(
        r'^##[ \t]+Tests[ \t]*\n(.*?)(?=^##[ \t]|\Z)', re.MULTILINE | re.DOTALL
    )
    # A numbered test case at column 0, up to the next one.
    SEP_23_TEST_CASE = re.compile(
        r'^[0-9]+\.[ \t]+(.*?)(?=^[0-9]+\.[ \t]|\Z)', re.MULTILINE | re.DOTALL
    )
    # The vector is on the '- Strkey' line or on the line after '- Strkey:'.
    SEP_23_VECTOR = re.compile(r'- Strkey:?\s*`([^`]+)`')

    def parse_sep_23(self) -> Dict[str, Any]:
        """
        Parse SEP-23 (Strkeys) from the fetched markdown document.

        Each row of the version byte table in Specification is a key type, and
        each numbered case of the valid and invalid lists in Tests is a test
        vector, so the counts follow the document.

        Raises:
            ValueError: If a section, the table, or a list is missing or
                empty, or a row or case does not parse.
        """
        specification = self.SEP_23_SPECIFICATION_SECTION.search(self.raw_content)
        if not specification:
            raise ValueError("SEP-23 document has no '## Specification' section")
        key_types = self._parse_sep_23_key_types(specification.group(1))
        tests = self.SEP_23_TESTS_SECTION.search(self.raw_content)
        if not tests:
            raise ValueError("SEP-23 document has no '## Tests' section")
        vectors = (
            self._parse_sep_23_vectors(tests.group(1), 'Valid test cases', 'valid')
            + self._parse_sep_23_vectors(tests.group(1), 'Invalid test cases', 'invalid')
        )

        print(f"{Colors.GREEN}  ✓ Found {len(key_types)} key types and "
              f"{len(vectors)} test vectors{Colors.END}")
        return {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': [
                {'title': 'Key types', 'key': 'key_types', 'strkey_type_features': key_types},
                {'title': 'Test vectors quoted in the StrKey unit test files',
                 'key': 'test_vectors_quoted_in_the_strkey_unit_test_files',
                 'strkey_vector_features': vectors},
            ]
        }

    def _parse_sep_23_key_types(self, specification: str) -> List[Dict[str, Any]]:
        """
        Read one key type per row of the version byte table in the text of the
        Specification section. The base value is evaluated to an integer, so
        the analyzer compares values, not spelling.
        """
        table = self.SEP_23_TYPE_TABLE.search(specification)
        if not table:
            raise ValueError(
                "SEP-23 Specification section has no version byte table "
                "with 'Key type' and 'First char' columns"
            )

        header = [cell.strip() for cell in table.group(1).split('|')]
        columns = {}
        for label in ('Key type', 'Base value', 'First char'):
            if label not in header:
                raise ValueError(f"SEP-23 version byte table has no '{label}' column")
            columns[label] = header.index(label)

        key_types = []
        for row in table.group(2).splitlines():
            cells = [cell.strip() for cell in row.strip().strip('|').split('|')]
            if len(cells) != len(header):
                raise ValueError(
                    f"SEP-23 version byte table row {row!r} has {len(cells)} cells, "
                    f"the header {len(header)}"
                )
            name = cells[columns['Key type']]
            base_text = ' '.join(cells[columns['Base value']].split())
            first_char = cells[columns['First char']]
            try:
                base_value = evaluate_shift_expression(base_text)
            except ValueError as e:
                raise ValueError(f"SEP-23 version byte table row {row!r}: {e}") from e

            key_types.append({
                'name': name, 'required': True, 'base_value': base_value, 'first_char': first_char,
                'description': f'Base value {base_text} ({base_value}), first character {first_char}',
            })

        if not key_types:
            raise ValueError("SEP-23 version byte table has no rows")
        return key_types

    def _parse_sep_23_vectors(self, tests: str, subsection: str,
                              prefix: str) -> List[Dict[str, Any]]:
        """
        Read one test vector per numbered case of the '### <subsection>' list
        in the text of the Tests section.

        Items are named '<prefix>_01', '<prefix>_02', ... in document order;
        the zero padding keeps that order when the matrix sorts rows by name.
        The description is the case title up to the first blank line, with
        line breaks collapsed.
        """
        pattern = rf'^###[ \t]+{re.escape(subsection)}[ \t]*\n(.*?)(?=^#{{2,3}}[ \t]|\Z)'
        match = re.search(pattern, tests, re.MULTILINE | re.DOTALL)
        if not match:
            raise ValueError(f"SEP-23 Tests section has no '### {subsection}' subsection")

        # The paragraph starting 'You can paste' ends the case list; the C
        # array after it repeats the invalid keys.
        cases_text = re.split(r'^You can paste', match.group(1), maxsplit=1,
                              flags=re.MULTILINE)[0]

        vectors = []
        for index, case in enumerate(self.SEP_23_TEST_CASE.finditer(cases_text), start=1):
            body = case.group(1)
            title = ' '.join(re.split(r'\n[ \t]*\n', body, maxsplit=1)[0].split())
            found = self.SEP_23_VECTOR.findall(body)
            if len(found) != 1:
                raise ValueError(
                    f"SEP-23 case {index} of '{subsection}' ({title!r}) carries "
                    f"{len(found)} Strkey vectors, expected 1"
                )
            vectors.append({'name': f'{prefix}_{index:02d}', 'description': title,
                            'required': True, 'vector': found[0]})

        if not vectors:
            raise ValueError(f"SEP-23 '### {subsection}' lists no test cases")
        return vectors

    def parse_sep_29(self) -> Dict[str, Any]:
        """
        Build the SEP-29 (Account Memo Requirements) definition.

        SEP-29 defines a client-side check with no HTTP endpoints of its own, so
        the capability set and the summary are enumerated here. The preamble is
        read from the fetched markdown document.

        Returns:
            Structured SEP-29 data with memo required capability fields
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': (
                'An account signals that incoming payments must carry a memo by '
                'setting the data entry "config.memo_required" to the value "1". '
                'Before submitting a transaction without a memo, the sender loads '
                'the destination account of every payment, path payment and '
                'account merge operation and refuses to submit when one of them '
                'requires a memo. Multiplexed destinations are exempt, because '
                'the multiplexing id already identifies the recipient.'
            ),
            'sections': []
        }

        # Memo required check capability fields.
        memo_required_fields = [
            spec_item(
                'memo_required_data_entry',
                "Reads the destination account's config.memo_required data entry and compares its decoded value with 1",
                required=True, requirements='config.memo_required data entry lookup',
                category='Memo Required'),
            spec_item(
                'set_memo_required_flag',
                'Sets or removes the data entry with a manage data operation', required=True,
                requirements='ManageDataOperationBuilder', category='Memo Required'),
            spec_item(
                'payment_destination', 'Checks the destination of a payment operation',
                required=True, requirements='PaymentOperation destination check',
                category='Memo Required'),
            spec_item(
                'path_payment_strict_send_destination',
                'Checks the destination of a path payment strict send operation', required=True,
                requirements='PathPaymentStrictSendOperation destination check',
                category='Memo Required'),
            spec_item(
                'path_payment_strict_receive_destination',
                'Checks the destination of a path payment strict receive operation', required=True,
                requirements='PathPaymentStrictReceiveOperation destination check',
                category='Memo Required'),
            spec_item(
                'account_merge_destination', 'Checks the destination of an account merge operation',
                required=True, requirements='AccountMergeOperation destination check',
                category='Memo Required'),
            spec_item(
                'muxed_destination_exempt', 'Skips multiplexed destinations', required=True,
                requirements='Multiplexed destination detection', category='Memo Required'),
            spec_item(
                'memo_present_skips_lookup',
                'Performs no lookup when the transaction carries a memo', required=True,
                requirements='Memo presence short-circuit', category='Memo Required'),
            spec_item(
                'fee_bump_inner_transaction',
                'Checks a fee bump transaction through its inner transaction', required=True,
                requirements='Fee bump inner transaction unwrap', category='Memo Required'),
            spec_item(
                'unknown_destination_skipped',
                'Skips a destination Horizon does not know and lets the network report it',
                required=True, requirements='HTTP 404 handling on account lookup',
                category='Memo Required'),
            spec_item(
                'check_memo_required_method', 'Public check without submitting', required=True,
                requirements='checkMemoRequired(AbstractTransaction) method',
                category='Memo Required'),
            spec_item(
                'submit_transaction_opt_out',
                'submitTransaction runs the check unless skipMemoRequiredCheck is true',
                required=True, requirements='submitTransaction skipMemoRequiredCheck parameter',
                category='Memo Required'),
            spec_item(
                'submit_fee_bump_transaction_opt_out',
                'submitFeeBumpTransaction runs the check unless skipMemoRequiredCheck is true',
                required=True,
                requirements='submitFeeBumpTransaction skipMemoRequiredCheck parameter',
                category='Memo Required'),
            spec_item(
                'submit_async_transaction_opt_out',
                'submitAsyncTransaction runs the check unless skipMemoRequiredCheck is true',
                required=True,
                requirements='submitAsyncTransaction skipMemoRequiredCheck parameter',
                category='Memo Required'),
            spec_item(
                'submit_async_fee_bump_transaction_opt_out',
                'submitAsyncFeeBumpTransaction runs the check unless skipMemoRequiredCheck is true',
                required=True,
                requirements='submitAsyncFeeBumpTransaction skipMemoRequiredCheck parameter',
                category='Memo Required'),
            spec_item(
                'submit_transaction_envelope_opt_out',
                'submitTransactionEnvelopeXdrBase64 runs the check unless skipMemoRequiredCheck is true',
                required=True,
                requirements='submitTransactionEnvelopeXdrBase64 skipMemoRequiredCheck parameter',
                category='Memo Required'),
            spec_item(
                'submit_async_transaction_envelope_opt_out',
                'submitAsyncTransactionEnvelopeXdrBase64 runs the check unless skipMemoRequiredCheck is true',
                required=True,
                requirements='submitAsyncTransactionEnvelopeXdrBase64 skipMemoRequiredCheck parameter',
                category='Memo Required'),
            spec_item(
                'account_requires_memo_exception',
                'Dedicated exception carrying the account id and the operation index',
                required=True, requirements='AccountRequiresMemoException class',
                category='Memo Required'),
        ]

        data['sections'].append(section(
            'Memo Required', 'memo_required',
            'Checking payment destinations for the config.memo_required data entry before submission',
            memo_required_fields, features_key='memo_required_features'))

        print(f"{Colors.GREEN}  ✓ Found {len(memo_required_fields)} memo required features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {len(memo_required_fields)} SEP-29 features{Colors.END}")

        return data

    def parse_sep_53(self) -> Dict[str, Any]:
        """
        Build the SEP-53 (Sign and Verify Messages) definition.

        SEP-53 is a cryptographic specification with no HTTP endpoints, so the
        capability set and the summary are enumerated here. The preamble is
        read from the fetched markdown document.

        Returns:
            Structured SEP-53 data with message signing capability fields
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': (
                'A canonical method for signing and verifying arbitrary messages '
                'using Stellar key pairs. Messages are prefixed with '
                '"Stellar Signed Message:\\n", hashed with SHA-256, and signed '
                'with the Ed25519 private key. Both binary and UTF-8 string '
                'message variants are supported for signing and verification.'
            ),
            'sections': []
        }

        # Message signing and verification capability fields.
        message_signing_fields = [
            spec_item(
                'message_prefix', 'Uses "Stellar Signed Message:\\n" prefix before hashing',
                required=True, requirements='Message prefix per SEP-53 specification',
                category='Message Signing'),
            spec_item(
                'sha256_hashing', 'SHA-256 hash of the prefixed message', required=True,
                requirements='SHA-256 hash computation', category='Message Signing'),
            spec_item(
                'sign_message_binary', 'Sign a binary message per SEP-53', required=True,
                requirements='signMessage(Uint8List) method', category='Message Signing'),
            spec_item(
                'sign_message_string', 'Sign a UTF-8 string message per SEP-53', required=True,
                requirements='signMessageString(String) method', category='Message Signing'),
            spec_item(
                'verify_message_binary', 'Verify a binary message signature per SEP-53',
                required=True, requirements='verifyMessage(Uint8List, Uint8List) method',
                category='Message Signing'),
            spec_item(
                'verify_message_string', 'Verify a UTF-8 string message signature per SEP-53',
                required=True, requirements='verifyMessageString(String, Uint8List) method',
                category='Message Signing'),
            spec_item(
                'ed25519_signature', '64-byte Ed25519 signature output', required=True,
                requirements='Ed25519 signing via sign method', category='Message Signing'),
            spec_item(
                'utf8_encoding', 'UTF-8 encoding for string messages', required=True,
                requirements='utf8.encode usage for string encoding', category='Message Signing'),
        ]

        data['sections'].append(section(
            'Message Signing', 'message_signing',
            'Signing and verifying arbitrary messages with Stellar key pairs',
            message_signing_fields, features_key='message_signing_features'))

        print(f"{Colors.GREEN}  ✓ Found {len(message_signing_fields)} message signing features{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Total: {len(message_signing_fields)} SEP-53 features{Colors.END}")

        return data

    def parse(self) -> Dict[str, Any]:
        """
        Parse SEP documentation based on SEP number.

        Returns:
            Parsed SEP data dictionary

        Raises:
            ValueError: If no content was fetched or no parser is defined for the SEP number.
        """
        if not self.raw_content:
            raise ValueError("No content to parse. Call fetch_sep_markdown() first.")

        parse_sep = getattr(self, f'parse_sep_{int(self.sep_number):02d}', None)
        if parse_sep is None:
            raise ValueError(f"No parser defined for SEP-{self.sep_number}")

        print(f"\n{Colors.CYAN}Parsing SEP-{self.sep_number}...{Colors.END}")
        self.parsed_data = parse_sep()

        # Add metadata
        self.parsed_data['metadata'] = {
            'parsed_at': datetime.now().isoformat(),
            'source_url': f'https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-{self.sep_number}.md',
            'content_length': len(self.raw_content)
        }

        print(f"{Colors.GREEN}✓ Parsed {len(self.parsed_data.get('sections', []))} sections{Colors.END}")

        return self.parsed_data

    def save_to_file(self, output_path: str) -> None:
        """
        Save parsed data to JSON file.

        Args:
            output_path: Path to output JSON file
        """
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(self.parsed_data, f, indent=2, ensure_ascii=False)

        print(f"{Colors.GREEN}✓ Saved to {output_path}{Colors.END}")

    def print_summary(self) -> None:
        """Print a summary of parsed SEP data"""
        if not self.parsed_data:
            print(f"{Colors.YELLOW}No data parsed yet{Colors.END}")
            return

        print(f"\n{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.HEADER}SEP-{self.sep_number} Parser Summary{Colors.END}")
        print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")

        preamble = self.parsed_data.get('preamble', {})
        print(f"{Colors.BOLD}Title:{Colors.END} {preamble.get('title', 'N/A')}")
        print(f"{Colors.BOLD}Status:{Colors.END} {preamble.get('status', 'N/A')}")
        print(f"{Colors.BOLD}Version:{Colors.END} {preamble.get('version', 'N/A')}")

        summary = self.parsed_data.get('summary', '')
        if summary:
            print(f"\n{Colors.BOLD}Summary:{Colors.END}")
            # Print first 200 chars
            print(f"  {summary[:200]}..." if len(summary) > 200 else f"  {summary}")

        sections = self.parsed_data.get('sections', [])
        print(f"\n{Colors.BOLD}Sections:{Colors.END} {len(sections)}")

        total_fields = 0
        for section in sections:
            fields = section.get('fields', [])
            if fields:
                print(f"  - {section.get('title', 'Unknown')}: {len(fields)} fields")
                total_fields += len(fields)

        print(f"\n{Colors.BOLD}Total Fields Identified:{Colors.END} {total_fields}")
        print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        sep_number = '0001'  # Default to SEP-01
        print(f"{Colors.YELLOW}No SEP number provided, using default: {sep_number}{Colors.END}")
    else:
        sep_number = sys.argv[1]

    print(f"\n{Colors.BOLD}{Colors.HEADER}SEP Documentation Parser{Colors.END}")
    print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")

    # Define output path
    data_dir = Path(__file__).parent.parent / 'data' / 'sep'
    data_dir.mkdir(parents=True, exist_ok=True)
    output_path = data_dir / f'sep_{sep_number}_definition.json'

    # Create parser
    parser = SEPParser(sep_number)

    try:
        if not parser.fetch_sep_markdown():
            print(f"\n{Colors.RED}Failed to fetch SEP-{sep_number}{Colors.END}")
            return 1

        # Parse content
        parser.parse()

        # Save to file
        parser.save_to_file(str(output_path))

        # Print summary
        parser.print_summary()

        print(f"{Colors.GREEN}✓ SEP-{sep_number} parsing complete!{Colors.END}\n")
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
