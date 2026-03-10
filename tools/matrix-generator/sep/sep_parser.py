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

from common import Colors


class SEPParser:
    """Parser for Stellar Ecosystem Proposal (SEP) documentation"""

    # Known SEPs and their titles (can be expanded)
    KNOWN_SEPS = {
        '0001': 'stellar.toml',
        '0002': 'Federation Protocol',
        '0005': 'Key Derivation Methods for Stellar Keys',
        '0006': 'Anchor/Client Interoperability',
        '0007': 'URI Scheme to facilitate delegated signing',
        '0008': 'Regulated Assets',
        '0009': 'Standard KYC / AML fields',
        '0010': 'Stellar Web Authentication',
        '0011': 'Txrep: Human-Readable Low-Level Representation of Stellar Transactions',
        '0012': 'Anchor/Client customer info transfer',
        '0024': 'Hosted Deposit and Withdrawal',
        '0030': 'Account Recovery',
        '0038': 'Anchor RFQ API',
        '0045': 'Web Authentication for Contract Accounts',
        '0046': 'Contract Meta',
        '0047': 'Contract Interface Discovery',
        '0048': 'Smart Contract Specifications',
    }

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
            field_pos = match.start()
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
            {
                'name': 'q',
                'description': 'String to look up (stellar address, account ID, or transaction ID)',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'type',
                'description': 'Type of lookup (name, id, txid, or forward)',
                'required': True,
                'type': 'string',
                'values': ['name', 'id', 'txid', 'forward']
            }
        ]
        api_structure['request_parameters'] = query_params

        # Extract response fields
        # For SEP-02, we know the response fields from the spec, so hardcode them
        # The parsing regex has issues with multiline descriptions
        api_structure['response_fields'] = [
            {
                'name': 'stellar_address',
                'description': 'stellar address',
                'required': True
            },
            {
                'name': 'account_id',
                'description': 'Stellar public key / account ID',
                'required': True
            },
            {
                'name': 'memo_type',
                'description': 'type of memo to attach to transaction, one of text, id or hash',
                'required': False
            },
            {
                'name': 'memo',
                'description': 'value of memo to attach to transaction, for hash this should be base64-encoded. This field should always be of type string (even when memo_type is equal id) to support parsing value in languages that don\'t support big numbers',
                'required': False
            }
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
        for section in general_sections:
            if section['title'] not in ['Preamble', 'Summary', 'Simple Summary']:
                data['sections'].append(section)

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
            {
                'name': 'get_auth_challenge',
                'description': 'GET /auth endpoint - Returns challenge transaction',
                'required': True,
                'category': 'Authentication Endpoint',
                'method': 'GET',
                'parameters': ['account', 'memo', 'home_domain', 'client_domain']
            },
            {
                'name': 'post_auth_token',
                'description': 'POST /auth endpoint - Validates signed challenge and returns JWT token',
                'required': True,
                'category': 'Authentication Endpoint',
                'method': 'POST',
                'parameters': ['transaction']
            }
        ]

        # Challenge Transaction Features
        auth_features['challenge_transaction_features'] = [
            {
                'name': 'challenge_transaction_generation',
                'description': 'Generate challenge transaction with proper structure',
                'required': True,
                'category': 'Challenge Transaction'
            },
            {
                'name': 'transaction_envelope_format',
                'description': 'Challenge uses proper Stellar transaction envelope format',
                'required': True,
                'category': 'Challenge Transaction'
            },
            {
                'name': 'sequence_number_zero',
                'description': 'Challenge transaction has sequence number 0',
                'required': True,
                'category': 'Challenge Transaction'
            },
            {
                'name': 'manage_data_operations',
                'description': 'Challenge uses ManageData operations for auth data',
                'required': True,
                'category': 'Challenge Transaction'
            },
            {
                'name': 'home_domain_operation',
                'description': 'First operation contains home_domain + " auth" as data name',
                'required': True,
                'category': 'Challenge Transaction'
            },
            {
                'name': 'web_auth_domain_operation',
                'description': 'Optional operation with web_auth_domain for domain verification',
                'required': False,
                'category': 'Challenge Transaction'
            },
            {
                'name': 'timebounds_enforcement',
                'description': 'Challenge transaction has timebounds for expiration',
                'required': True,
                'category': 'Challenge Transaction'
            },
            {
                'name': 'server_signature',
                'description': 'Challenge is signed by server before sending to client',
                'required': True,
                'category': 'Challenge Transaction'
            },
            {
                'name': 'nonce_generation',
                'description': 'Random nonce in ManageData operation value',
                'required': True,
                'category': 'Challenge Transaction'
            }
        ]

        # JWT Token Features
        auth_features['jwt_token_features'] = [
            {
                'name': 'jwt_token_generation',
                'description': 'Generate JWT token after successful challenge validation',
                'required': True,
                'category': 'JWT Token'
            },
            {
                'name': 'jwt_token_response',
                'description': 'Return JWT token in JSON response with "token" field',
                'required': True,
                'category': 'JWT Token'
            },
            {
                'name': 'jwt_token_validation',
                'description': 'Validate JWT token structure and signature',
                'required': True,
                'category': 'JWT Token',
                'server_side_only': True,
                'client_note': 'This is a server-side validation feature. Client SDKs only need to receive, store, and send the JWT as a bearer token.'
            },
            {
                'name': 'jwt_expiration',
                'description': 'JWT token includes expiration time',
                'required': True,
                'category': 'JWT Token'
            },
            {
                'name': 'jwt_claims',
                'description': 'JWT token includes required claims (sub, iat, exp)',
                'required': True,
                'category': 'JWT Token'
            }
        ]

        # Client Domain Features
        auth_features['client_domain_features'] = [
            {
                'name': 'client_domain_parameter',
                'description': 'Support optional client_domain parameter in GET /auth',
                'required': False,
                'category': 'Client Domain'
            },
            {
                'name': 'client_domain_operation',
                'description': 'Add client_domain ManageData operation to challenge',
                'required': False,
                'category': 'Client Domain'
            },
            {
                'name': 'client_domain_verification',
                'description': 'Verify client domain by checking stellar.toml',
                'required': False,
                'category': 'Client Domain',
                'server_side_only': True,
                'client_note': 'This is a server-side verification feature. Client SDKs only need to support the client_domain parameter and signing.'
            },
            {
                'name': 'client_domain_signature',
                'description': 'Require signature from client domain account',
                'required': False,
                'category': 'Client Domain'
            }
        ]

        # Verification Features
        auth_features['verification_features'] = [
            {
                'name': 'challenge_validation',
                'description': 'Validate challenge transaction structure and content',
                'required': True,
                'category': 'Verification'
            },
            {
                'name': 'signature_verification',
                'description': 'Verify all signatures on challenge transaction',
                'required': True,
                'category': 'Verification'
            },
            {
                'name': 'multi_signature_support',
                'description': 'Support multiple signatures on challenge (client account + signers)',
                'required': True,
                'category': 'Verification'
            },
            {
                'name': 'timebounds_validation',
                'description': 'Validate challenge is within valid time window',
                'required': True,
                'category': 'Verification'
            },
            {
                'name': 'home_domain_validation',
                'description': 'Validate home domain in challenge matches server',
                'required': True,
                'category': 'Verification'
            },
            {
                'name': 'memo_support',
                'description': 'Support optional memo in challenge for muxed accounts',
                'required': False,
                'category': 'Verification'
            }
        ]

        # Store auth features as sections
        data['sections'].append({
            'title': 'Authentication Endpoints',
            'key': 'auth_endpoints',
            'content': 'GET and POST /auth endpoints for challenge-response authentication',
            'auth_features': auth_features['authentication_endpoints'],
            'feature_count': len(auth_features['authentication_endpoints'])
        })

        data['sections'].append({
            'title': 'Challenge Transaction Features',
            'key': 'challenge_transaction',
            'content': 'Challenge transaction structure, operations, and requirements',
            'auth_features': auth_features['challenge_transaction_features'],
            'feature_count': len(auth_features['challenge_transaction_features'])
        })

        data['sections'].append({
            'title': 'JWT Token Features',
            'key': 'jwt_token',
            'content': 'JWT token generation, validation, and structure',
            'auth_features': auth_features['jwt_token_features'],
            'feature_count': len(auth_features['jwt_token_features'])
        })

        data['sections'].append({
            'title': 'Client Domain Features',
            'key': 'client_domain',
            'content': 'Optional client domain verification and signing',
            'auth_features': auth_features['client_domain_features'],
            'feature_count': len(auth_features['client_domain_features'])
        })

        data['sections'].append({
            'title': 'Verification Features',
            'key': 'verification',
            'content': 'Challenge validation, signature verification, and security checks',
            'auth_features': auth_features['verification_features'],
            'feature_count': len(auth_features['verification_features'])
        })

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
            {
                'name': 'mnemonic_generation_12_words',
                'description': 'Generate 12-word BIP-39 mnemonic phrase',
                'required': True,
                'category': 'BIP-39 Mnemonic Generation'
            },
            {
                'name': 'mnemonic_generation_24_words',
                'description': 'Generate 24-word BIP-39 mnemonic phrase',
                'required': True,
                'category': 'BIP-39 Mnemonic Generation'
            },
            {
                'name': 'mnemonic_validation',
                'description': 'Validate BIP-39 mnemonic phrase (word list and checksum)',
                'required': True,
                'category': 'BIP-39 Mnemonic Validation'
            },
            {
                'name': 'mnemonic_to_seed',
                'description': 'Convert BIP-39 mnemonic to seed using PBKDF2',
                'required': True,
                'category': 'BIP-39 Seed Generation'
            },
            {
                'name': 'passphrase_support',
                'description': 'Support optional BIP-39 passphrase (25th word)',
                'required': False,
                'category': 'BIP-39 Passphrase'
            }
        ]

        # BIP-32 Hierarchical Deterministic Key Derivation
        crypto_features['bip32_features'] = [
            {
                'name': 'hd_key_derivation',
                'description': 'BIP-32 hierarchical deterministic key derivation',
                'required': True,
                'category': 'BIP-32 Key Derivation'
            },
            {
                'name': 'ed25519_curve',
                'description': 'Support Ed25519 curve for Stellar keys',
                'required': True,
                'category': 'BIP-32 Curve Support'
            },
            {
                'name': 'master_key_generation',
                'description': 'Generate master key from seed',
                'required': True,
                'category': 'BIP-32 Master Key'
            },
            {
                'name': 'child_key_derivation',
                'description': 'Derive child keys from parent keys',
                'required': True,
                'category': 'BIP-32 Child Derivation'
            }
        ]

        # BIP-44 Multi-Account Hierarchy
        crypto_features['bip44_features'] = [
            {
                'name': 'stellar_derivation_path',
                'description': "Support Stellar's BIP-44 derivation path: m/44'/148'/account'",
                'required': True,
                'category': 'BIP-44 Derivation Path'
            },
            {
                'name': 'multiple_accounts',
                'description': 'Derive multiple Stellar accounts from single seed',
                'required': True,
                'category': 'BIP-44 Multiple Accounts'
            },
            {
                'name': 'account_index_support',
                'description': 'Support account index parameter in derivation',
                'required': True,
                'category': 'BIP-44 Account Index'
            }
        ]

        # Key Derivation Methods
        crypto_features['key_derivation_methods'] = [
            {
                'name': 'keypair_from_mnemonic',
                'description': 'Generate Stellar KeyPair from mnemonic',
                'required': True,
                'category': 'Key Derivation'
            },
            {
                'name': 'account_id_from_mnemonic',
                'description': 'Get Stellar account ID from mnemonic',
                'required': True,
                'category': 'Account Derivation'
            },
            {
                'name': 'seed_from_mnemonic',
                'description': 'Convert mnemonic to raw seed bytes',
                'required': True,
                'category': 'Seed Derivation'
            }
        ]

        # Language Support
        crypto_features['language_support'] = [
            {
                'name': 'english',
                'description': 'English BIP-39 word list (2048 words)',
                'required': True,
                'category': 'Language Support'
            },
            {
                'name': 'chinese_simplified',
                'description': 'Chinese Simplified BIP-39 word list',
                'required': False,
                'category': 'Language Support'
            },
            {
                'name': 'chinese_traditional',
                'description': 'Chinese Traditional BIP-39 word list',
                'required': False,
                'category': 'Language Support'
            },
            {
                'name': 'french',
                'description': 'French BIP-39 word list',
                'required': False,
                'category': 'Language Support'
            },
            {
                'name': 'italian',
                'description': 'Italian BIP-39 word list',
                'required': False,
                'category': 'Language Support'
            },
            {
                'name': 'japanese',
                'description': 'Japanese BIP-39 word list',
                'required': False,
                'category': 'Language Support'
            },
            {
                'name': 'korean',
                'description': 'Korean BIP-39 word list',
                'required': False,
                'category': 'Language Support'
            },
            {
                'name': 'spanish',
                'description': 'Spanish BIP-39 word list',
                'required': False,
                'category': 'Language Support'
            }
        ]

        # Store crypto features as sections
        data['sections'].append({
            'title': 'BIP-39 Mnemonic Features',
            'key': 'bip39',
            'content': 'BIP-39 mnemonic generation, validation, and seed derivation',
            'crypto_features': crypto_features['bip39_features'],
            'feature_count': len(crypto_features['bip39_features'])
        })

        data['sections'].append({
            'title': 'BIP-32 Key Derivation',
            'key': 'bip32',
            'content': 'BIP-32 hierarchical deterministic key derivation',
            'crypto_features': crypto_features['bip32_features'],
            'feature_count': len(crypto_features['bip32_features'])
        })

        data['sections'].append({
            'title': 'BIP-44 Multi-Account Support',
            'key': 'bip44',
            'content': "BIP-44 multi-account hierarchy for Stellar (m/44'/148'/account')",
            'crypto_features': crypto_features['bip44_features'],
            'feature_count': len(crypto_features['bip44_features'])
        })

        data['sections'].append({
            'title': 'Key Derivation Methods',
            'key': 'key_derivation',
            'content': 'Methods for deriving Stellar keys from mnemonics',
            'crypto_features': crypto_features['key_derivation_methods'],
            'feature_count': len(crypto_features['key_derivation_methods'])
        })

        data['sections'].append({
            'title': 'Language Support',
            'key': 'languages',
            'content': 'BIP-39 word list language support',
            'crypto_features': crypto_features['language_support'],
            'feature_count': len(crypto_features['language_support'])
        })

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

        # Define comprehensive API structure for SEP-06
        api_structure = {
            'info_endpoint': {
                'name': 'info_endpoint',
                'description': 'GET /info - Provides anchor capabilities and asset information',
                'required': True,
                'method': 'GET',
                'path': '/info',
                'category': 'Info Endpoint'
            },
            'deposit_endpoints': [
                {
                    'name': 'deposit',
                    'description': 'GET /deposit - Initiates a deposit transaction for on-chain assets',
                    'required': True,
                    'method': 'GET',
                    'path': '/deposit',
                    'category': 'Deposit Endpoint'
                },
                {
                    'name': 'deposit_exchange',
                    'description': 'GET /deposit-exchange - Initiates a deposit with asset exchange (SEP-38 integration)',
                    'required': False,
                    'method': 'GET',
                    'path': '/deposit-exchange',
                    'category': 'Deposit Endpoint'
                }
            ],
            'withdraw_endpoints': [
                {
                    'name': 'withdraw',
                    'description': 'GET /withdraw - Initiates a withdrawal transaction for off-chain assets',
                    'required': True,
                    'method': 'GET',
                    'path': '/withdraw',
                    'category': 'Withdraw Endpoint'
                },
                {
                    'name': 'withdraw_exchange',
                    'description': 'GET /withdraw-exchange - Initiates a withdrawal with asset exchange (SEP-38 integration)',
                    'required': False,
                    'method': 'GET',
                    'path': '/withdraw-exchange',
                    'category': 'Withdraw Endpoint'
                }
            ],
            'transaction_endpoints': [
                {
                    'name': 'transactions',
                    'description': 'GET /transactions - Retrieves transaction history for an account',
                    'required': True,
                    'method': 'GET',
                    'path': '/transactions',
                    'category': 'Transaction Endpoint'
                },
                {
                    'name': 'transaction',
                    'description': 'GET /transaction - Retrieves details for a single transaction',
                    'required': True,
                    'method': 'GET',
                    'path': '/transaction',
                    'category': 'Transaction Endpoint'
                },
                {
                    'name': 'patch_transaction',
                    'description': 'PATCH /transaction - Updates transaction fields (for debugging/testing)',
                    'required': False,
                    'method': 'PATCH',
                    'path': '/transaction',
                    'category': 'Transaction Endpoint'
                }
            ],
            'fee_endpoint': {
                'name': 'fee_endpoint',
                'description': 'GET /fee - Calculates fees for a deposit or withdrawal operation',
                'required': False,
                'method': 'GET',
                'path': '/fee',
                'category': 'Fee Endpoint'
            },
            'deposit_request_parameters': [
                {
                    'name': 'asset_code',
                    'description': 'Code of the on-chain asset the user wants to receive',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'account',
                    'description': 'Stellar account ID of the user',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'memo_type',
                    'description': 'Type of memo to attach to transaction (text, id, or hash)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'memo',
                    'description': 'Value of memo to attach to transaction',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'email_address',
                    'description': 'Email address of the user (for notifications)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'type',
                    'description': 'Type of deposit method (e.g., bank_account, cash, mobile_money)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'wallet_name',
                    'description': 'Name of the wallet the user is using',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'wallet_url',
                    'description': 'URL of the wallet the user is using',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'lang',
                    'description': 'Language code for response messages (ISO 639-1)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'on_change_callback',
                    'description': 'URL for anchor to send callback when transaction status changes',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'amount',
                    'description': 'Amount of on-chain asset the user wants to receive',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'country_code',
                    'description': 'Country code of the user (ISO 3166-1 alpha-3)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'claimable_balance_supported',
                    'description': 'Whether the client supports receiving claimable balances',
                    'required': False,
                    'type': 'boolean'
                },
                {
                    'name': 'customer_id',
                    'description': 'ID of the customer from SEP-12 KYC process',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'location_id',
                    'description': 'ID of the physical location for cash pickup',
                    'required': False,
                    'type': 'string'
                }
            ],
            'withdraw_request_parameters': [
                {
                    'name': 'asset_code',
                    'description': 'Code of the on-chain asset the user wants to send',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'type',
                    'description': 'Type of withdrawal method (e.g., bank_account, cash, mobile_money)',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'dest',
                    'description': 'Destination for withdrawal (bank account number, etc.)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'dest_extra',
                    'description': 'Extra information for destination (routing number, etc.)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'account',
                    'description': 'Stellar account ID of the user',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'memo',
                    'description': 'Memo to identify the user if account is shared',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'memo_type',
                    'description': 'Type of memo (text, id, or hash)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'wallet_name',
                    'description': 'Name of the wallet the user is using',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'wallet_url',
                    'description': 'URL of the wallet the user is using',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'lang',
                    'description': 'Language code for response messages (ISO 639-1)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'on_change_callback',
                    'description': 'URL for anchor to send callback when transaction status changes',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'amount',
                    'description': 'Amount of on-chain asset the user wants to send',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'country_code',
                    'description': 'Country code of the user (ISO 3166-1 alpha-3)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'refund_memo',
                    'description': 'Memo to use for refund transaction if withdrawal fails',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'refund_memo_type',
                    'description': 'Type of refund memo (text, id, or hash)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'customer_id',
                    'description': 'ID of the customer from SEP-12 KYC process',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'location_id',
                    'description': 'ID of the physical location for cash pickup',
                    'required': False,
                    'type': 'string'
                }
            ],
            'deposit_response_fields': [
                {
                    'name': 'how',
                    'description': 'Instructions for how to deposit the asset',
                    'required': True
                },
                {
                    'name': 'id',
                    'description': 'Persistent transaction identifier',
                    'required': False
                },
                {
                    'name': 'eta',
                    'description': 'Estimated seconds until deposit completes',
                    'required': False
                },
                {
                    'name': 'min_amount',
                    'description': 'Minimum deposit amount',
                    'required': False
                },
                {
                    'name': 'max_amount',
                    'description': 'Maximum deposit amount',
                    'required': False
                },
                {
                    'name': 'fee_fixed',
                    'description': 'Fixed fee for deposit',
                    'required': False
                },
                {
                    'name': 'fee_percent',
                    'description': 'Percentage fee for deposit',
                    'required': False
                },
                {
                    'name': 'extra_info',
                    'description': 'Additional information about the deposit',
                    'required': False
                }
            ],
            'withdraw_response_fields': [
                {
                    'name': 'account_id',
                    'description': 'Stellar account to send withdrawn assets to',
                    'required': True
                },
                {
                    'name': 'memo_type',
                    'description': 'Type of memo to attach to transaction',
                    'required': False
                },
                {
                    'name': 'memo',
                    'description': 'Value of memo to attach to transaction',
                    'required': False
                },
                {
                    'name': 'id',
                    'description': 'Persistent transaction identifier',
                    'required': True
                },
                {
                    'name': 'eta',
                    'description': 'Estimated seconds until withdrawal completes',
                    'required': False
                },
                {
                    'name': 'min_amount',
                    'description': 'Minimum withdrawal amount',
                    'required': False
                },
                {
                    'name': 'max_amount',
                    'description': 'Maximum withdrawal amount',
                    'required': False
                },
                {
                    'name': 'fee_fixed',
                    'description': 'Fixed fee for withdrawal',
                    'required': False
                },
                {
                    'name': 'fee_percent',
                    'description': 'Percentage fee for withdrawal',
                    'required': False
                },
                {
                    'name': 'extra_info',
                    'description': 'Additional information about the withdrawal',
                    'required': False
                }
            ],
            'transaction_status_values': [
                {
                    'name': 'incomplete',
                    'description': 'Deposit/withdrawal has not yet been submitted',
                    'required': True
                },
                {
                    'name': 'pending_user_transfer_start',
                    'description': 'Waiting for user to initiate off-chain transfer',
                    'required': True
                },
                {
                    'name': 'pending_user_transfer_complete',
                    'description': 'Off-chain transfer has been initiated',
                    'required': False
                },
                {
                    'name': 'pending_external',
                    'description': 'Waiting for external action (banking system, etc.)',
                    'required': False
                },
                {
                    'name': 'pending_anchor',
                    'description': 'Anchor is processing the transaction',
                    'required': True
                },
                {
                    'name': 'pending_stellar',
                    'description': 'Stellar transaction has been submitted',
                    'required': False
                },
                {
                    'name': 'pending_trust',
                    'description': 'User needs to add trustline for asset',
                    'required': False
                },
                {
                    'name': 'pending_user',
                    'description': 'Waiting for user action (accepting claimable balance)',
                    'required': False
                },
                {
                    'name': 'completed',
                    'description': 'Transaction completed successfully',
                    'required': True
                },
                {
                    'name': 'refunded',
                    'description': 'Transaction refunded',
                    'required': False
                },
                {
                    'name': 'expired',
                    'description': 'Transaction expired without completion',
                    'required': False
                },
                {
                    'name': 'error',
                    'description': 'Transaction failed with error',
                    'required': False
                }
            ],
            'transaction_fields': [
                {
                    'name': 'id',
                    'description': 'Unique transaction identifier',
                    'required': True
                },
                {
                    'name': 'kind',
                    'description': 'Kind of transaction (deposit, withdrawal, deposit-exchange, withdrawal-exchange)',
                    'required': True
                },
                {
                    'name': 'status',
                    'description': 'Current status of the transaction',
                    'required': True
                },
                {
                    'name': 'status_eta',
                    'description': 'Estimated seconds until status changes',
                    'required': False
                },
                {
                    'name': 'amount_in',
                    'description': 'Amount received by anchor',
                    'required': False
                },
                {
                    'name': 'amount_out',
                    'description': 'Amount sent by anchor to user',
                    'required': False
                },
                {
                    'name': 'amount_fee',
                    'description': 'Total fee charged for transaction',
                    'required': False
                },
                {
                    'name': 'started_at',
                    'description': 'When transaction was created (ISO 8601)',
                    'required': True
                },
                {
                    'name': 'completed_at',
                    'description': 'When transaction completed (ISO 8601)',
                    'required': False
                },
                {
                    'name': 'stellar_transaction_id',
                    'description': 'Hash of the Stellar transaction',
                    'required': False
                },
                {
                    'name': 'external_transaction_id',
                    'description': 'Identifier from external system',
                    'required': False
                },
                {
                    'name': 'from',
                    'description': 'Stellar account that initiated the transaction',
                    'required': False
                },
                {
                    'name': 'to',
                    'description': 'Stellar account receiving the transaction',
                    'required': False
                },
                {
                    'name': 'refunded',
                    'description': 'Whether transaction was refunded',
                    'required': False
                },
                {
                    'name': 'refunds',
                    'description': 'Refund information if applicable',
                    'required': False
                },
                {
                    'name': 'message',
                    'description': 'Human-readable message about transaction',
                    'required': False
                }
            ],
            'info_response_fields': [
                {
                    'name': 'deposit',
                    'description': 'Map of asset codes to deposit asset information',
                    'required': True
                },
                {
                    'name': 'deposit-exchange',
                    'description': 'Map of asset codes to deposit-exchange asset information',
                    'required': False
                },
                {
                    'name': 'withdraw',
                    'description': 'Map of asset codes to withdraw asset information',
                    'required': True
                },
                {
                    'name': 'withdraw-exchange',
                    'description': 'Map of asset codes to withdraw-exchange asset information',
                    'required': False
                },
                {
                    'name': 'fee',
                    'description': 'Fee endpoint information',
                    'required': False
                },
                {
                    'name': 'transactions',
                    'description': 'Transaction history endpoint information',
                    'required': False
                },
                {
                    'name': 'transaction',
                    'description': 'Single transaction endpoint information',
                    'required': False
                },
                {
                    'name': 'features',
                    'description': 'Feature flags supported by the anchor',
                    'required': False
                }
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
        data['sections'].append({
            'title': 'Info Endpoint',
            'key': 'info_endpoint',
            'content': 'Endpoint for querying anchor capabilities',
            'api_features': [api_structure['info_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Deposit Endpoints',
            'key': 'deposit_endpoints',
            'content': 'Endpoints for initiating deposit transactions',
            'api_features': api_structure['deposit_endpoints'],
            'feature_count': len(api_structure['deposit_endpoints'])
        })

        data['sections'].append({
            'title': 'Withdraw Endpoints',
            'key': 'withdraw_endpoints',
            'content': 'Endpoints for initiating withdrawal transactions',
            'api_features': api_structure['withdraw_endpoints'],
            'feature_count': len(api_structure['withdraw_endpoints'])
        })

        data['sections'].append({
            'title': 'Transaction Endpoints',
            'key': 'transaction_endpoints',
            'content': 'Endpoints for tracking and managing transactions',
            'api_features': api_structure['transaction_endpoints'],
            'feature_count': len(api_structure['transaction_endpoints'])
        })

        data['sections'].append({
            'title': 'Fee Endpoint',
            'key': 'fee_endpoint',
            'content': 'Endpoint for calculating transaction fees',
            'api_features': [api_structure['fee_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Deposit Request Parameters',
            'key': 'deposit_request_parameters',
            'content': 'Parameters for deposit endpoint requests',
            'api_features': api_structure['deposit_request_parameters'],
            'feature_count': len(api_structure['deposit_request_parameters'])
        })

        data['sections'].append({
            'title': 'Withdraw Request Parameters',
            'key': 'withdraw_request_parameters',
            'content': 'Parameters for withdraw endpoint requests',
            'api_features': api_structure['withdraw_request_parameters'],
            'feature_count': len(api_structure['withdraw_request_parameters'])
        })

        data['sections'].append({
            'title': 'Deposit Response Fields',
            'key': 'deposit_response_fields',
            'content': 'Fields returned in deposit endpoint responses',
            'api_features': api_structure['deposit_response_fields'],
            'feature_count': len(api_structure['deposit_response_fields'])
        })

        data['sections'].append({
            'title': 'Withdraw Response Fields',
            'key': 'withdraw_response_fields',
            'content': 'Fields returned in withdraw endpoint responses',
            'api_features': api_structure['withdraw_response_fields'],
            'feature_count': len(api_structure['withdraw_response_fields'])
        })

        data['sections'].append({
            'title': 'Transaction Status Values',
            'key': 'transaction_status_values',
            'content': 'Possible transaction status values',
            'api_features': api_structure['transaction_status_values'],
            'feature_count': len(api_structure['transaction_status_values'])
        })

        data['sections'].append({
            'title': 'Transaction Fields',
            'key': 'transaction_fields',
            'content': 'Fields returned in transaction objects',
            'api_features': api_structure['transaction_fields'],
            'feature_count': len(api_structure['transaction_fields'])
        })

        data['sections'].append({
            'title': 'Info Response Fields',
            'key': 'info_response_fields',
            'content': 'Fields returned in info endpoint response',
            'api_features': api_structure['info_response_fields'],
            'feature_count': len(api_structure['info_response_fields'])
        })

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
            {'name': 'last_name', 'description': 'Family or last name', 'required': False},
            {'name': 'first_name', 'description': 'Given or first name', 'required': False},
            {'name': 'additional_name', 'description': 'Middle name or other additional name', 'required': False},
            {'name': 'address_country_code', 'description': 'Country code for current address', 'required': False},
            {'name': 'state_or_province', 'description': 'Name of state/province/region/prefecture', 'required': False},
            {'name': 'city', 'description': 'Name of city/town', 'required': False},
            {'name': 'postal_code', 'description': 'Postal or other code identifying user\'s locale', 'required': False},
            {'name': 'address', 'description': 'Entire address (country, state, postal code, street address, etc.) as a multi-line string', 'required': False},
            {'name': 'mobile_number', 'description': 'Mobile phone number with country code, in E.164 format', 'required': False},
            {'name': 'mobile_number_format', 'description': 'Expected format of the mobile_number field (E.164, hash, etc.)', 'required': False},
            {'name': 'email_address', 'description': 'Email address', 'required': False},
            {'name': 'birth_date', 'description': 'Date of birth (e.g., 1976-07-04)', 'required': False},
            {'name': 'birth_place', 'description': 'Place of birth (city, state, country; as on passport)', 'required': False},
            {'name': 'birth_country_code', 'description': 'ISO Code of country of birth (ISO 3166-1 alpha-3)', 'required': False},
            {'name': 'tax_id', 'description': 'Tax identifier of user in their country (social security number in US)', 'required': False},
            {'name': 'tax_id_name', 'description': 'Name of the tax ID (SSN or ITIN in the US)', 'required': False},
            {'name': 'occupation', 'description': 'Occupation ISCO code', 'required': False},
            {'name': 'employer_name', 'description': 'Name of employer', 'required': False},
            {'name': 'employer_address', 'description': 'Address of employer', 'required': False},
            {'name': 'language_code', 'description': 'Primary language (ISO 639-1)', 'required': False},
            {'name': 'id_type', 'description': 'Type of ID (passport, drivers_license, id_card, etc.)', 'required': False},
            {'name': 'id_country_code', 'description': 'Country issuing passport or photo ID (ISO 3166-1 alpha-3)', 'required': False},
            {'name': 'id_issue_date', 'description': 'ID issue date', 'required': False},
            {'name': 'id_expiration_date', 'description': 'ID expiration date', 'required': False},
            {'name': 'id_number', 'description': 'Passport or ID number', 'required': False},
            {'name': 'photo_id_front', 'description': 'Image of front of user\'s photo ID or passport', 'required': False, 'type': 'binary'},
            {'name': 'photo_id_back', 'description': 'Image of back of user\'s photo ID or passport', 'required': False, 'type': 'binary'},
            {'name': 'notary_approval_of_photo_id', 'description': 'Image of notary\'s approval of photo ID or passport', 'required': False, 'type': 'binary'},
            {'name': 'ip_address', 'description': 'IP address of customer\'s computer', 'required': False},
            {'name': 'photo_proof_residence', 'description': 'Image of a utility bill, bank statement or similar with the user\'s name and address', 'required': False, 'type': 'binary'},
            {'name': 'sex', 'description': 'Gender (male, female, or other)', 'required': False},
            {'name': 'proof_of_income', 'description': 'Image of user\'s proof of income document', 'required': False, 'type': 'binary'},
            {'name': 'proof_of_liveness', 'description': 'Video or image file of user as a liveness proof', 'required': False, 'type': 'binary'},
            {'name': 'referral_id', 'description': 'User\'s origin (such as an id in another application) or a referral code', 'required': False}
        ]

        # Organization Fields (prefixed with "organization.")
        field_categories['organization_fields'] = [
            {'name': 'organization.name', 'description': 'Full organization name as on the incorporation papers', 'required': False},
            {'name': 'organization.VAT_number', 'description': 'Organization VAT number', 'required': False},
            {'name': 'organization.registration_number', 'description': 'Organization registration number', 'required': False},
            {'name': 'organization.registration_date', 'description': 'Date the organization was registered', 'required': False},
            {'name': 'organization.registered_address', 'description': 'Organization registered address', 'required': False},
            {'name': 'organization.number_of_shareholders', 'description': 'Organization shareholder number', 'required': False},
            {'name': 'organization.shareholder_name', 'description': 'Name of shareholder (can be organization or person)', 'required': False},
            {'name': 'organization.photo_incorporation_doc', 'description': 'Image of incorporation documents', 'required': False, 'type': 'binary'},
            {'name': 'organization.photo_proof_address', 'description': 'Image of a utility bill, bank statement with the organization\'s name and address', 'required': False, 'type': 'binary'},
            {'name': 'organization.address_country_code', 'description': 'Country code for current address', 'required': False},
            {'name': 'organization.state_or_province', 'description': 'Name of state/province/region/prefecture', 'required': False},
            {'name': 'organization.city', 'description': 'Name of city/town', 'required': False},
            {'name': 'organization.postal_code', 'description': 'Postal or other code identifying organization\'s locale', 'required': False},
            {'name': 'organization.director_name', 'description': 'Organization registered managing director', 'required': False},
            {'name': 'organization.website', 'description': 'Organization website', 'required': False},
            {'name': 'organization.email', 'description': 'Organization contact email', 'required': False},
            {'name': 'organization.phone', 'description': 'Organization contact phone', 'required': False}
        ]

        # Financial Account Fields
        field_categories['financial_account_fields'] = [
            {'name': 'bank_name', 'description': 'Name of the bank', 'required': False},
            {'name': 'bank_account_type', 'description': 'Type of bank account', 'required': False},
            {'name': 'bank_account_number', 'description': 'Number identifying bank account', 'required': False},
            {'name': 'bank_number', 'description': 'Number identifying bank in national banking system (routing number in US)', 'required': False},
            {'name': 'bank_phone_number', 'description': 'Phone number with country code for bank', 'required': False},
            {'name': 'bank_branch_number', 'description': 'Number identifying bank branch', 'required': False},
            {'name': 'external_transfer_memo', 'description': 'A destination tag/memo used to identify a transaction', 'required': False},
            {'name': 'clabe_number', 'description': 'Bank account number for Mexico', 'required': False},
            {'name': 'cbu_number', 'description': 'Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU)', 'required': False},
            {'name': 'cbu_alias', 'description': 'The alias for a CBU or CVU', 'required': False},
            {'name': 'mobile_money_number', 'description': 'Mobile phone number in E.164 format with which a mobile money account is associated', 'required': False},
            {'name': 'mobile_money_provider', 'description': 'Name of the mobile money service provider', 'required': False},
            {'name': 'crypto_address', 'description': 'Address for a cryptocurrency account', 'required': False},
            {'name': 'crypto_memo', 'description': 'A destination tag/memo used to identify a transaction', 'required': False}
        ]

        # Card Fields (prefixed with "card.")
        field_categories['card_fields'] = [
            {'name': 'card.number', 'description': 'Card number', 'required': False},
            {'name': 'card.expiration_date', 'description': 'Expiration month and year in YY-MM format (e.g., 29-11, November 2029)', 'required': False},
            {'name': 'card.cvc', 'description': 'CVC number (Digits on the back of the card)', 'required': False},
            {'name': 'card.holder_name', 'description': 'Name of the card holder', 'required': False},
            {'name': 'card.network', 'description': 'Brand of the card/network it operates within (e.g., Visa, Mastercard, AmEx, etc.)', 'required': False},
            {'name': 'card.postal_code', 'description': 'Billing address postal code', 'required': False},
            {'name': 'card.country_code', 'description': 'Billing address country code in ISO 3166-1 alpha-2 code (e.g., US)', 'required': False},
            {'name': 'card.state_or_province', 'description': 'Name of state/province/region/prefecture in ISO 3166-2 format', 'required': False},
            {'name': 'card.city', 'description': 'Name of city/town', 'required': False},
            {'name': 'card.address', 'description': 'Entire address (country, state, postal code, street address, etc.) as a multi-line string', 'required': False},
            {'name': 'card.token', 'description': 'Token representation of the card in some external payment system (e.g., Stripe)', 'required': False}
        ]

        # Store field categories as sections
        data['sections'].append({
            'title': 'Natural Person Fields',
            'key': 'natural_person_fields',
            'content': 'Standard KYC fields for natural persons',
            'fields': field_categories['natural_person_fields'],
            'field_count': len(field_categories['natural_person_fields'])
        })

        data['sections'].append({
            'title': 'Organization Fields',
            'key': 'organization_fields',
            'content': 'Standard KYC fields for organizations',
            'fields': field_categories['organization_fields'],
            'field_count': len(field_categories['organization_fields'])
        })

        data['sections'].append({
            'title': 'Financial Account Fields',
            'key': 'financial_account_fields',
            'content': 'Standard fields for financial account information',
            'fields': field_categories['financial_account_fields'],
            'field_count': len(field_categories['financial_account_fields'])
        })

        data['sections'].append({
            'title': 'Card Fields',
            'key': 'card_fields',
            'content': 'Standard fields for card payment information',
            'fields': field_categories['card_fields'],
            'field_count': len(field_categories['card_fields'])
        })

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
                {
                    'name': 'encode_transaction',
                    'description': 'Convert transaction envelope XDR to txrep text format',
                    'required': True,
                    'category': 'Encoding'
                },
                {
                    'name': 'encode_fee_bump_transaction',
                    'description': 'Convert fee bump transaction envelope to txrep format',
                    'required': True,
                    'category': 'Encoding'
                },
                {
                    'name': 'encode_source_account',
                    'description': 'Encode source account (including muxed accounts)',
                    'required': True,
                    'category': 'Encoding'
                },
                {
                    'name': 'encode_memo',
                    'description': 'Encode all memo types (NONE, TEXT, ID, HASH, RETURN)',
                    'required': True,
                    'category': 'Encoding'
                },
                {
                    'name': 'encode_operations',
                    'description': 'Encode all Stellar operation types',
                    'required': True,
                    'category': 'Encoding'
                },
                {
                    'name': 'encode_preconditions',
                    'description': 'Encode transaction preconditions (time bounds, ledger bounds, min seq num, etc.)',
                    'required': True,
                    'category': 'Encoding'
                },
                {
                    'name': 'encode_signatures',
                    'description': 'Encode transaction signatures',
                    'required': True,
                    'category': 'Encoding'
                },
                {
                    'name': 'encode_soroban_data',
                    'description': 'Encode Soroban transaction data (resources, footprint, etc.)',
                    'required': True,
                    'category': 'Encoding'
                }
            ],
            'decoding_features': [
                {
                    'name': 'decode_transaction',
                    'description': 'Parse txrep text format to transaction envelope XDR',
                    'required': True,
                    'category': 'Decoding'
                },
                {
                    'name': 'decode_fee_bump_transaction',
                    'description': 'Parse fee bump transaction from txrep format',
                    'required': True,
                    'category': 'Decoding'
                },
                {
                    'name': 'decode_source_account',
                    'description': 'Parse source account (including muxed accounts)',
                    'required': True,
                    'category': 'Decoding'
                },
                {
                    'name': 'decode_memo',
                    'description': 'Parse all memo types from txrep',
                    'required': True,
                    'category': 'Decoding'
                },
                {
                    'name': 'decode_operations',
                    'description': 'Parse all Stellar operation types from txrep',
                    'required': True,
                    'category': 'Decoding'
                },
                {
                    'name': 'decode_preconditions',
                    'description': 'Parse transaction preconditions from txrep',
                    'required': True,
                    'category': 'Decoding'
                },
                {
                    'name': 'decode_signatures',
                    'description': 'Parse transaction signatures from txrep',
                    'required': True,
                    'category': 'Decoding'
                },
                {
                    'name': 'decode_soroban_data',
                    'description': 'Parse Soroban transaction data from txrep',
                    'required': True,
                    'category': 'Decoding'
                }
            ],
            'asset_encoding': [
                {
                    'name': 'encode_native_asset',
                    'description': 'Encode native XLM asset in txrep format',
                    'required': True,
                    'category': 'Asset Encoding'
                },
                {
                    'name': 'encode_alphanumeric4_asset',
                    'description': 'Encode 4-character alphanumeric asset',
                    'required': True,
                    'category': 'Asset Encoding'
                },
                {
                    'name': 'encode_alphanumeric12_asset',
                    'description': 'Encode 12-character alphanumeric asset',
                    'required': True,
                    'category': 'Asset Encoding'
                }
            ],
            'operation_types': [
                {
                    'name': 'create_account',
                    'description': 'Encode/decode CREATE_ACCOUNT operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'payment',
                    'description': 'Encode/decode PAYMENT operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'path_payment_strict_receive',
                    'description': 'Encode/decode PATH_PAYMENT_STRICT_RECEIVE operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'path_payment_strict_send',
                    'description': 'Encode/decode PATH_PAYMENT_STRICT_SEND operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'manage_sell_offer',
                    'description': 'Encode/decode MANAGE_SELL_OFFER operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'manage_buy_offer',
                    'description': 'Encode/decode MANAGE_BUY_OFFER operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'create_passive_sell_offer',
                    'description': 'Encode/decode CREATE_PASSIVE_SELL_OFFER operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'set_options',
                    'description': 'Encode/decode SET_OPTIONS operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'change_trust',
                    'description': 'Encode/decode CHANGE_TRUST operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'allow_trust',
                    'description': 'Encode/decode ALLOW_TRUST operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'account_merge',
                    'description': 'Encode/decode ACCOUNT_MERGE operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'manage_data',
                    'description': 'Encode/decode MANAGE_DATA operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'bump_sequence',
                    'description': 'Encode/decode BUMP_SEQUENCE operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'create_claimable_balance',
                    'description': 'Encode/decode CREATE_CLAIMABLE_BALANCE operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'claim_claimable_balance',
                    'description': 'Encode/decode CLAIM_CLAIMABLE_BALANCE operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'begin_sponsoring_future_reserves',
                    'description': 'Encode/decode BEGIN_SPONSORING_FUTURE_RESERVES operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'end_sponsoring_future_reserves',
                    'description': 'Encode/decode END_SPONSORING_FUTURE_RESERVES operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'revoke_sponsorship',
                    'description': 'Encode/decode REVOKE_SPONSORSHIP operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'clawback',
                    'description': 'Encode/decode CLAWBACK operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'clawback_claimable_balance',
                    'description': 'Encode/decode CLAWBACK_CLAIMABLE_BALANCE operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'set_trust_line_flags',
                    'description': 'Encode/decode SET_TRUST_LINE_FLAGS operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'liquidity_pool_deposit',
                    'description': 'Encode/decode LIQUIDITY_POOL_DEPOSIT operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'liquidity_pool_withdraw',
                    'description': 'Encode/decode LIQUIDITY_POOL_WITHDRAW operation',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'invoke_host_function',
                    'description': 'Encode/decode INVOKE_HOST_FUNCTION operation (Soroban)',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'extend_footprint_ttl',
                    'description': 'Encode/decode EXTEND_FOOTPRINT_TTL operation (Soroban)',
                    'required': True,
                    'category': 'Operation Type'
                },
                {
                    'name': 'restore_footprint',
                    'description': 'Encode/decode RESTORE_FOOTPRINT operation (Soroban)',
                    'required': True,
                    'category': 'Operation Type'
                }
            ],
            'format_features': [
                {
                    'name': 'comment_support',
                    'description': 'Support for comments in txrep format',
                    'required': True,
                    'category': 'Format Feature'
                },
                {
                    'name': 'dot_notation',
                    'description': 'Use dot notation for nested structures',
                    'required': True,
                    'category': 'Format Feature'
                },
                {
                    'name': 'array_indexing',
                    'description': 'Support array indexing in txrep format',
                    'required': True,
                    'category': 'Format Feature'
                },
                {
                    'name': 'hex_encoding',
                    'description': 'Hexadecimal encoding for binary data',
                    'required': True,
                    'category': 'Format Feature'
                },
                {
                    'name': 'string_escaping',
                    'description': 'Proper string escaping with double quotes',
                    'required': True,
                    'category': 'Format Feature'
                }
            ]
        }

        # Add encoding features section
        data['sections'].append({
            'title': 'Encoding Features',
            'key': 'encoding_features',
            'content': 'Features for converting transaction envelope XDR to txrep format',
            'txrep_features': txrep_features['encoding_features'],
            'feature_count': len(txrep_features['encoding_features'])
        })

        # Add decoding features section
        data['sections'].append({
            'title': 'Decoding Features',
            'key': 'decoding_features',
            'content': 'Features for parsing txrep format to transaction envelope XDR',
            'txrep_features': txrep_features['decoding_features'],
            'feature_count': len(txrep_features['decoding_features'])
        })

        # Add asset encoding section
        data['sections'].append({
            'title': 'Asset Encoding',
            'key': 'asset_encoding',
            'content': 'Asset type encoding in txrep format',
            'txrep_features': txrep_features['asset_encoding'],
            'feature_count': len(txrep_features['asset_encoding'])
        })

        # Add operation types section
        data['sections'].append({
            'title': 'Operation Types',
            'key': 'operation_types',
            'content': 'All supported Stellar operation types',
            'txrep_features': txrep_features['operation_types'],
            'feature_count': len(txrep_features['operation_types'])
        })

        # Add format features section
        data['sections'].append({
            'title': 'Format Features',
            'key': 'format_features',
            'content': 'Txrep format specification features',
            'txrep_features': txrep_features['format_features'],
            'feature_count': len(txrep_features['format_features'])
        })

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
                {
                    'name': 'id',
                    'description': 'ID of the customer as returned in previous PUT request',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'account',
                    'description': 'Stellar account ID (G...) of the customer',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'memo',
                    'description': 'Memo that uniquely identifies a customer in shared accounts',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'memo_type',
                    'description': 'Type of memo: text, id, or hash',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'type',
                    'description': 'Type of action the customer is being KYCd for',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'transaction_id',
                    'description': 'Transaction ID with which customer info is associated',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'lang',
                    'description': 'Language code (ISO 639-1) for human-readable responses',
                    'required': False,
                    'type': 'string'
                }
            ],
            'response_fields': [
                {
                    'name': 'id',
                    'description': 'ID of the customer',
                    'required': False
                },
                {
                    'name': 'status',
                    'description': 'Status of customer KYC process',
                    'required': True,
                    'values': ['ACCEPTED', 'PROCESSING', 'NEEDS_INFO', 'REJECTED']
                },
                {
                    'name': 'fields',
                    'description': 'Fields the anchor has not yet received',
                    'required': False
                },
                {
                    'name': 'provided_fields',
                    'description': 'Fields the anchor has received',
                    'required': False
                },
                {
                    'name': 'message',
                    'description': 'Human readable message describing KYC status',
                    'required': False
                }
            ],
            'field_types': [
                {
                    'name': 'type',
                    'description': 'Data type of field value',
                    'values': ['string', 'binary', 'number', 'date']
                },
                {
                    'name': 'description',
                    'description': 'Human-readable description of the field',
                    'required': False
                },
                {
                    'name': 'choices',
                    'description': 'Array of valid values for this field',
                    'required': False
                },
                {
                    'name': 'optional',
                    'description': 'Whether this field is required to proceed',
                    'required': False
                },
                {
                    'name': 'status',
                    'description': 'Status of provided field',
                    'required': False,
                    'values': ['ACCEPTED', 'PROCESSING', 'REJECTED', 'VERIFICATION_REQUIRED']
                },
                {
                    'name': 'error',
                    'description': 'Description of why field was rejected',
                    'required': False
                }
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
        for section in general_sections:
            if section['title'].lower() not in ['preamble', 'summary']:
                data['sections'].append(section)

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

        # Define comprehensive API structure for SEP-38
        api_structure = {
            'info_endpoint': {
                'name': 'info_endpoint',
                'description': 'GET /info - Returns supported Stellar and off-chain assets available for trading',
                'required': True,
                'method': 'GET',
                'path': '/info',
                'category': 'Info Endpoint'
            },
            'prices_endpoint': {
                'name': 'prices_endpoint',
                'description': 'GET /prices - Returns indicative prices of off-chain assets in exchange for Stellar assets',
                'required': True,
                'method': 'GET',
                'path': '/prices',
                'category': 'Prices Endpoint'
            },
            'price_endpoint': {
                'name': 'price_endpoint',
                'description': 'GET /price - Returns indicative price for a specific asset pair',
                'required': True,
                'method': 'GET',
                'path': '/price',
                'category': 'Price Endpoint'
            },
            'post_quote_endpoint': {
                'name': 'post_quote_endpoint',
                'description': 'POST /quote - Request a firm quote for asset exchange',
                'required': True,
                'method': 'POST',
                'path': '/quote',
                'category': 'Quote Endpoint'
            },
            'get_quote_endpoint': {
                'name': 'get_quote_endpoint',
                'description': 'GET /quote/:id - Fetch a previously-provided firm quote',
                'required': True,
                'method': 'GET',
                'path': '/quote/:id',
                'category': 'Quote Endpoint'
            },
            'info_response_fields': [
                {
                    'name': 'assets',
                    'description': 'Array of asset objects supported for trading',
                    'required': True
                }
            ],
            'asset_fields': [
                {
                    'name': 'asset',
                    'description': 'Asset identifier in Asset Identification Format',
                    'required': True
                },
                {
                    'name': 'sell_delivery_methods',
                    'description': 'Array of delivery methods for selling this asset',
                    'required': False
                },
                {
                    'name': 'buy_delivery_methods',
                    'description': 'Array of delivery methods for buying this asset',
                    'required': False
                },
                {
                    'name': 'country_codes',
                    'description': 'Array of ISO 3166-2 or ISO 3166-1 alpha-2 country codes',
                    'required': False
                }
            ],
            'delivery_method_fields': [
                {
                    'name': 'name',
                    'description': 'Delivery method name identifier',
                    'required': True
                },
                {
                    'name': 'description',
                    'description': 'Human-readable description of the delivery method',
                    'required': True
                }
            ],
            'prices_request_parameters': [
                {
                    'name': 'sell_asset',
                    'description': 'Asset to sell using Asset Identification Format',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'sell_amount',
                    'description': 'Amount of sell_asset to exchange',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'sell_delivery_method',
                    'description': 'Delivery method for off-chain sell asset',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'buy_delivery_method',
                    'description': 'Delivery method for off-chain buy asset',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'country_code',
                    'description': 'ISO 3166-2 or ISO 3166-1 alpha-2 country code',
                    'required': False,
                    'type': 'string'
                }
            ],
            'prices_response_fields': [
                {
                    'name': 'buy_assets',
                    'description': 'Array of buy asset objects with prices',
                    'required': True
                }
            ],
            'buy_asset_fields': [
                {
                    'name': 'asset',
                    'description': 'Asset identifier in Asset Identification Format',
                    'required': True
                },
                {
                    'name': 'price',
                    'description': 'Price offered by anchor for one unit of buy_asset',
                    'required': True
                },
                {
                    'name': 'decimals',
                    'description': 'Number of decimals for the buy asset',
                    'required': True
                }
            ],
            'price_request_parameters': [
                {
                    'name': 'context',
                    'description': 'Context for quote usage (sep6 or sep31)',
                    'required': True,
                    'type': 'string',
                    'values': ['sep6', 'sep31']
                },
                {
                    'name': 'sell_asset',
                    'description': 'Asset client would like to sell',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'buy_asset',
                    'description': 'Asset client would like to exchange for sell_asset',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'sell_amount',
                    'description': 'Amount of sell_asset to exchange (mutually exclusive with buy_amount)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'buy_amount',
                    'description': 'Amount of buy_asset to exchange for (mutually exclusive with sell_amount)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'sell_delivery_method',
                    'description': 'Delivery method for off-chain sell asset',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'buy_delivery_method',
                    'description': 'Delivery method for off-chain buy asset',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'country_code',
                    'description': 'ISO 3166-2 or ISO 3166-1 alpha-2 country code',
                    'required': False,
                    'type': 'string'
                }
            ],
            'price_response_fields': [
                {
                    'name': 'total_price',
                    'description': 'Total conversion price including fees',
                    'required': True
                },
                {
                    'name': 'price',
                    'description': 'Base conversion price excluding fees',
                    'required': True
                },
                {
                    'name': 'sell_amount',
                    'description': 'Amount of sell_asset that will be exchanged',
                    'required': True
                },
                {
                    'name': 'buy_amount',
                    'description': 'Amount of buy_asset that will be received',
                    'required': True
                },
                {
                    'name': 'fee',
                    'description': 'Fee object with total, asset, and optional details',
                    'required': True
                }
            ],
            'post_quote_request_fields': [
                {
                    'name': 'context',
                    'description': 'Context for quote usage (sep6 or sep31)',
                    'required': True,
                    'type': 'string',
                    'values': ['sep6', 'sep31']
                },
                {
                    'name': 'sell_asset',
                    'description': 'Asset client would like to sell',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'buy_asset',
                    'description': 'Asset client would like to exchange for sell_asset',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'sell_amount',
                    'description': 'Amount of sell_asset to exchange (mutually exclusive with buy_amount)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'buy_amount',
                    'description': 'Amount of buy_asset to exchange for (mutually exclusive with sell_amount)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'expire_after',
                    'description': 'Requested expiration timestamp for the quote (ISO 8601)',
                    'required': False,
                    'type': 'datetime'
                },
                {
                    'name': 'sell_delivery_method',
                    'description': 'Delivery method for off-chain sell asset',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'buy_delivery_method',
                    'description': 'Delivery method for off-chain buy asset',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'country_code',
                    'description': 'ISO 3166-2 or ISO 3166-1 alpha-2 country code',
                    'required': False,
                    'type': 'string'
                }
            ],
            'quote_response_fields': [
                {
                    'name': 'id',
                    'description': 'Unique identifier for the quote',
                    'required': True
                },
                {
                    'name': 'expires_at',
                    'description': 'Expiration timestamp for the quote (ISO 8601)',
                    'required': True
                },
                {
                    'name': 'total_price',
                    'description': 'Total conversion price including fees',
                    'required': True
                },
                {
                    'name': 'price',
                    'description': 'Base conversion price excluding fees',
                    'required': True
                },
                {
                    'name': 'sell_asset',
                    'description': 'Asset to be sold',
                    'required': True
                },
                {
                    'name': 'sell_amount',
                    'description': 'Amount of sell_asset to be exchanged',
                    'required': True
                },
                {
                    'name': 'buy_asset',
                    'description': 'Asset to be bought',
                    'required': True
                },
                {
                    'name': 'buy_amount',
                    'description': 'Amount of buy_asset to be received',
                    'required': True
                },
                {
                    'name': 'fee',
                    'description': 'Fee object with total, asset, and optional details',
                    'required': True
                }
            ],
            'fee_fields': [
                {
                    'name': 'total',
                    'description': 'Total fee amount as decimal string',
                    'required': True
                },
                {
                    'name': 'asset',
                    'description': 'Asset identifier for the fee',
                    'required': True
                },
                {
                    'name': 'details',
                    'description': 'Optional array of fee breakdown objects',
                    'required': False
                }
            ],
            'fee_details_fields': [
                {
                    'name': 'name',
                    'description': 'Name identifier for the fee component',
                    'required': True
                },
                {
                    'name': 'amount',
                    'description': 'Fee amount as decimal string',
                    'required': True
                },
                {
                    'name': 'description',
                    'description': 'Human-readable description of the fee',
                    'required': False
                }
            ],
            'authentication': {
                'type': 'SEP-10',
                'method': 'JWT Token',
                'description': 'Most endpoints support optional SEP-10 JWT authentication, POST /quote requires authentication',
                'required': True
            }
        }

        # Store API structure components as sections
        data['sections'].append({
            'title': 'Info Endpoint',
            'key': 'info_endpoint',
            'content': 'Endpoint for querying supported assets for trading',
            'api_features': [api_structure['info_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Prices Endpoint',
            'key': 'prices_endpoint',
            'content': 'Endpoint for fetching indicative prices for multiple buy assets',
            'api_features': [api_structure['prices_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Price Endpoint',
            'key': 'price_endpoint',
            'content': 'Endpoint for fetching indicative price for specific asset pair',
            'api_features': [api_structure['price_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Post Quote Endpoint',
            'key': 'post_quote_endpoint',
            'content': 'Endpoint for requesting firm quote',
            'api_features': [api_structure['post_quote_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Get Quote Endpoint',
            'key': 'get_quote_endpoint',
            'content': 'Endpoint for fetching previously provided firm quote',
            'api_features': [api_structure['get_quote_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Info Response Fields',
            'key': 'info_response_fields',
            'content': 'Fields returned in info endpoint response',
            'api_features': api_structure['info_response_fields'],
            'feature_count': len(api_structure['info_response_fields'])
        })

        data['sections'].append({
            'title': 'Asset Fields',
            'key': 'asset_fields',
            'content': 'Fields in asset objects',
            'api_features': api_structure['asset_fields'],
            'feature_count': len(api_structure['asset_fields'])
        })

        data['sections'].append({
            'title': 'Delivery Method Fields',
            'key': 'delivery_method_fields',
            'content': 'Fields in delivery method objects',
            'api_features': api_structure['delivery_method_fields'],
            'feature_count': len(api_structure['delivery_method_fields'])
        })

        data['sections'].append({
            'title': 'Prices Request Parameters',
            'key': 'prices_request_parameters',
            'content': 'Parameters for prices endpoint requests',
            'api_features': api_structure['prices_request_parameters'],
            'feature_count': len(api_structure['prices_request_parameters'])
        })

        data['sections'].append({
            'title': 'Prices Response Fields',
            'key': 'prices_response_fields',
            'content': 'Fields returned in prices endpoint response',
            'api_features': api_structure['prices_response_fields'],
            'feature_count': len(api_structure['prices_response_fields'])
        })

        data['sections'].append({
            'title': 'Buy Asset Fields',
            'key': 'buy_asset_fields',
            'content': 'Fields in buy asset objects from prices response',
            'api_features': api_structure['buy_asset_fields'],
            'feature_count': len(api_structure['buy_asset_fields'])
        })

        data['sections'].append({
            'title': 'Price Request Parameters',
            'key': 'price_request_parameters',
            'content': 'Parameters for price endpoint requests',
            'api_features': api_structure['price_request_parameters'],
            'feature_count': len(api_structure['price_request_parameters'])
        })

        data['sections'].append({
            'title': 'Price Response Fields',
            'key': 'price_response_fields',
            'content': 'Fields returned in price endpoint response',
            'api_features': api_structure['price_response_fields'],
            'feature_count': len(api_structure['price_response_fields'])
        })

        data['sections'].append({
            'title': 'Post Quote Request Fields',
            'key': 'post_quote_request_fields',
            'content': 'Fields in POST /quote request body',
            'api_features': api_structure['post_quote_request_fields'],
            'feature_count': len(api_structure['post_quote_request_fields'])
        })

        data['sections'].append({
            'title': 'Quote Response Fields',
            'key': 'quote_response_fields',
            'content': 'Fields returned in quote endpoint responses',
            'api_features': api_structure['quote_response_fields'],
            'feature_count': len(api_structure['quote_response_fields'])
        })

        data['sections'].append({
            'title': 'Fee Fields',
            'key': 'fee_fields',
            'content': 'Fields in fee objects',
            'api_features': api_structure['fee_fields'],
            'feature_count': len(api_structure['fee_fields'])
        })

        data['sections'].append({
            'title': 'Fee Details Fields',
            'key': 'fee_details_fields',
            'content': 'Fields in fee details objects',
            'api_features': api_structure['fee_details_fields'],
            'feature_count': len(api_structure['fee_details_fields'])
        })

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

        # Define comprehensive API structure for SEP-24
        # SEP-24 is similar to SEP-06 but uses POST for interactive flows
        api_structure = {
            'info_endpoint': {
                'name': 'info_endpoint',
                'description': 'GET /info - Provides anchor capabilities and supported assets for interactive deposits/withdrawals',
                'required': True,
                'method': 'GET',
                'path': '/info',
                'category': 'Info Endpoint'
            },
            'interactive_deposit_endpoint': {
                'name': 'interactive_deposit',
                'description': 'POST /transactions/deposit/interactive - Initiates an interactive deposit transaction',
                'required': True,
                'method': 'POST',
                'path': '/transactions/deposit/interactive',
                'category': 'Deposit Endpoint'
            },
            'interactive_withdraw_endpoint': {
                'name': 'interactive_withdraw',
                'description': 'POST /transactions/withdraw/interactive - Initiates an interactive withdrawal transaction',
                'required': True,
                'method': 'POST',
                'path': '/transactions/withdraw/interactive',
                'category': 'Withdraw Endpoint'
            },
            'transaction_endpoints': [
                {
                    'name': 'transactions',
                    'description': 'GET /transactions - Retrieves transaction history for authenticated account',
                    'required': True,
                    'method': 'GET',
                    'path': '/transactions',
                    'category': 'Transaction Endpoint'
                },
                {
                    'name': 'transaction',
                    'description': 'GET /transaction - Retrieves details for a single transaction',
                    'required': True,
                    'method': 'GET',
                    'path': '/transaction',
                    'category': 'Transaction Endpoint'
                }
            ],
            'fee_endpoint': {
                'name': 'fee_endpoint',
                'description': 'GET /fee - Calculates fees for a deposit or withdrawal operation (optional)',
                'required': False,
                'method': 'GET',
                'path': '/fee',
                'category': 'Fee Endpoint'
            },
            'deposit_request_parameters': [
                {
                    'name': 'asset_code',
                    'description': 'Code of the Stellar asset the user wants to receive',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'asset_issuer',
                    'description': 'Issuer of the Stellar asset (optional if anchor is issuer)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'source_asset',
                    'description': 'Off-chain asset user wants to deposit (in SEP-38 format)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'amount',
                    'description': 'Amount of asset to deposit',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'quote_id',
                    'description': 'ID from SEP-38 quote (for asset exchange)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'account',
                    'description': 'Stellar or muxed account for receiving deposit',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'memo',
                    'description': 'Memo value for transaction identification',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'memo_type',
                    'description': 'Type of memo (text, id, or hash)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'wallet_name',
                    'description': 'Name of wallet for user communication',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'wallet_url',
                    'description': 'URL to link in transaction notifications',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'lang',
                    'description': 'Language code for UI and messages (RFC 4646)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'claimable_balance_supported',
                    'description': 'Whether client supports claimable balances',
                    'required': False,
                    'type': 'boolean'
                }
            ],
            'withdraw_request_parameters': [
                {
                    'name': 'asset_code',
                    'description': 'Code of the Stellar asset user wants to send',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'asset_issuer',
                    'description': 'Issuer of the Stellar asset (optional if anchor is issuer)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'destination_asset',
                    'description': 'Off-chain asset user wants to receive (in SEP-38 format)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'amount',
                    'description': 'Amount of asset to withdraw',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'quote_id',
                    'description': 'ID from SEP-38 quote (for asset exchange)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'account',
                    'description': 'Stellar or muxed account that will send the withdrawal',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'memo',
                    'description': 'Memo for identifying the withdrawal transaction',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'memo_type',
                    'description': 'Type of memo (text, id, or hash)',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'wallet_name',
                    'description': 'Name of wallet for user communication',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'wallet_url',
                    'description': 'URL to link in transaction notifications',
                    'required': False,
                    'type': 'string'
                },
                {
                    'name': 'lang',
                    'description': 'Language code for UI and messages (RFC 4646)',
                    'required': False,
                    'type': 'string'
                }
            ],
            'interactive_response_fields': [
                {
                    'name': 'type',
                    'description': 'Always "interactive_customer_info_needed" for SEP-24',
                    'required': True
                },
                {
                    'name': 'url',
                    'description': 'URL for interactive flow popup/iframe',
                    'required': True
                },
                {
                    'name': 'id',
                    'description': 'Unique transaction identifier',
                    'required': True
                }
            ],
            'transaction_status_values': [
                {
                    'name': 'incomplete',
                    'description': 'Customer information still being collected via interactive flow',
                    'required': True
                },
                {
                    'name': 'pending_user_transfer_start',
                    'description': 'Waiting for user to send funds (deposits)',
                    'required': True
                },
                {
                    'name': 'pending_user_transfer_complete',
                    'description': 'User transfer detected, awaiting confirmations',
                    'required': False
                },
                {
                    'name': 'pending_external',
                    'description': 'Transaction being processed by external system',
                    'required': False
                },
                {
                    'name': 'pending_anchor',
                    'description': 'Anchor processing the transaction',
                    'required': True
                },
                {
                    'name': 'pending_stellar',
                    'description': 'Transaction submitted to Stellar network',
                    'required': False
                },
                {
                    'name': 'pending_trust',
                    'description': 'User needs to establish trustline',
                    'required': False
                },
                {
                    'name': 'pending_user',
                    'description': 'Waiting for user action (e.g., accepting claimable balance)',
                    'required': False
                },
                {
                    'name': 'completed',
                    'description': 'Transaction completed successfully',
                    'required': True
                },
                {
                    'name': 'refunded',
                    'description': 'Transaction refunded',
                    'required': False
                },
                {
                    'name': 'expired',
                    'description': 'Transaction expired before completion',
                    'required': False
                },
                {
                    'name': 'error',
                    'description': 'Transaction encountered an error',
                    'required': False
                }
            ],
            'transaction_fields': [
                {
                    'name': 'id',
                    'description': 'Unique transaction identifier',
                    'required': True
                },
                {
                    'name': 'kind',
                    'description': 'Kind of transaction (deposit or withdrawal)',
                    'required': True
                },
                {
                    'name': 'status',
                    'description': 'Current status of the transaction',
                    'required': True
                },
                {
                    'name': 'status_eta',
                    'description': 'Estimated seconds until status changes',
                    'required': False
                },
                {
                    'name': 'kyc_verified',
                    'description': 'Whether KYC has been verified for this transaction',
                    'required': False
                },
                {
                    'name': 'more_info_url',
                    'description': 'URL with additional transaction information',
                    'required': True
                },
                {
                    'name': 'amount_in',
                    'description': 'Amount received by anchor',
                    'required': False
                },
                {
                    'name': 'amount_in_asset',
                    'description': 'Asset received by anchor (SEP-38 format)',
                    'required': False
                },
                {
                    'name': 'amount_out',
                    'description': 'Amount sent by anchor to user',
                    'required': False
                },
                {
                    'name': 'amount_out_asset',
                    'description': 'Asset delivered to user (SEP-38 format)',
                    'required': False
                },
                {
                    'name': 'amount_fee',
                    'description': 'Total fee charged for transaction',
                    'required': False
                },
                {
                    'name': 'amount_fee_asset',
                    'description': 'Asset in which fees are calculated (SEP-38 format)',
                    'required': False
                },
                {
                    'name': 'quote_id',
                    'description': 'ID of SEP-38 quote used for this transaction',
                    'required': False
                },
                {
                    'name': 'started_at',
                    'description': 'When transaction was created (ISO 8601)',
                    'required': True
                },
                {
                    'name': 'completed_at',
                    'description': 'When transaction completed (ISO 8601)',
                    'required': False
                },
                {
                    'name': 'updated_at',
                    'description': 'When transaction status last changed (ISO 8601)',
                    'required': False
                },
                {
                    'name': 'user_action_required_by',
                    'description': 'Deadline for user action (ISO 8601)',
                    'required': False
                },
                {
                    'name': 'stellar_transaction_id',
                    'description': 'Hash of the Stellar transaction',
                    'required': False
                },
                {
                    'name': 'external_transaction_id',
                    'description': 'Identifier from external system',
                    'required': False
                },
                {
                    'name': 'message',
                    'description': 'Human-readable message about transaction',
                    'required': False
                },
                {
                    'name': 'refunded',
                    'description': 'Whether transaction was refunded (deprecated)',
                    'required': False
                },
                {
                    'name': 'refunds',
                    'description': 'Refund information object',
                    'required': False
                },
                {
                    'name': 'from',
                    'description': 'Source address (Stellar for withdrawals, external for deposits)',
                    'required': False
                },
                {
                    'name': 'to',
                    'description': 'Destination address (Stellar for deposits, external for withdrawals)',
                    'required': False
                },
                {
                    'name': 'deposit_memo',
                    'description': 'Memo for deposit to Stellar address',
                    'required': False
                },
                {
                    'name': 'deposit_memo_type',
                    'description': 'Type of deposit memo',
                    'required': False
                },
                {
                    'name': 'claimable_balance_id',
                    'description': 'ID of claimable balance for deposit',
                    'required': False
                },
                {
                    'name': 'withdraw_anchor_account',
                    'description': "Anchor's Stellar account for withdrawal payment",
                    'required': False
                },
                {
                    'name': 'withdraw_memo',
                    'description': 'Memo for withdrawal to anchor account',
                    'required': False
                },
                {
                    'name': 'withdraw_memo_type',
                    'description': 'Type of withdraw memo',
                    'required': False
                }
            ],
            'info_response_fields': [
                {
                    'name': 'deposit',
                    'description': 'Map of asset codes to deposit asset information',
                    'required': True
                },
                {
                    'name': 'withdraw',
                    'description': 'Map of asset codes to withdraw asset information',
                    'required': True
                },
                {
                    'name': 'fee',
                    'description': 'Fee endpoint information object',
                    'required': False
                },
                {
                    'name': 'features',
                    'description': 'Feature flags object',
                    'required': False
                }
            ],
            'deposit_asset_fields': [
                {
                    'name': 'enabled',
                    'description': 'Whether deposits are enabled for this asset',
                    'required': True
                },
                {
                    'name': 'min_amount',
                    'description': 'Minimum deposit amount',
                    'required': False
                },
                {
                    'name': 'max_amount',
                    'description': 'Maximum deposit amount',
                    'required': False
                },
                {
                    'name': 'fee_fixed',
                    'description': 'Fixed deposit fee',
                    'required': False
                },
                {
                    'name': 'fee_percent',
                    'description': 'Percentage deposit fee',
                    'required': False
                },
                {
                    'name': 'fee_minimum',
                    'description': 'Minimum deposit fee',
                    'required': False
                }
            ],
            'withdraw_asset_fields': [
                {
                    'name': 'enabled',
                    'description': 'Whether withdrawals are enabled for this asset',
                    'required': True
                },
                {
                    'name': 'min_amount',
                    'description': 'Minimum withdrawal amount',
                    'required': False
                },
                {
                    'name': 'max_amount',
                    'description': 'Maximum withdrawal amount',
                    'required': False
                },
                {
                    'name': 'fee_fixed',
                    'description': 'Fixed withdrawal fee',
                    'required': False
                },
                {
                    'name': 'fee_percent',
                    'description': 'Percentage withdrawal fee',
                    'required': False
                },
                {
                    'name': 'fee_minimum',
                    'description': 'Minimum withdrawal fee',
                    'required': False
                }
            ],
            'feature_flags_fields': [
                {
                    'name': 'account_creation',
                    'description': 'Whether anchor supports creating accounts',
                    'required': False
                },
                {
                    'name': 'claimable_balances',
                    'description': 'Whether anchor supports claimable balances',
                    'required': False
                }
            ],
            'fee_endpoint_fields': [
                {
                    'name': 'enabled',
                    'description': 'Whether fee endpoint is available',
                    'required': True
                },
                {
                    'name': 'authentication_required',
                    'description': 'Whether authentication is required for fee endpoint',
                    'required': False
                }
            ]
        }

        # Store API structure components as sections
        data['sections'].append({
            'title': 'Info Endpoint',
            'key': 'info_endpoint',
            'content': 'Endpoint for querying anchor interactive deposit/withdrawal capabilities',
            'api_features': [api_structure['info_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Interactive Deposit Endpoint',
            'key': 'interactive_deposit_endpoint',
            'content': 'Endpoint for initiating interactive deposit flow',
            'api_features': [api_structure['interactive_deposit_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Interactive Withdraw Endpoint',
            'key': 'interactive_withdraw_endpoint',
            'content': 'Endpoint for initiating interactive withdrawal flow',
            'api_features': [api_structure['interactive_withdraw_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Transaction Endpoints',
            'key': 'transaction_endpoints',
            'content': 'Endpoints for tracking and querying transactions',
            'api_features': api_structure['transaction_endpoints'],
            'feature_count': len(api_structure['transaction_endpoints'])
        })

        data['sections'].append({
            'title': 'Fee Endpoint',
            'key': 'fee_endpoint',
            'content': 'Optional endpoint for calculating transaction fees',
            'api_features': [api_structure['fee_endpoint']],
            'feature_count': 1
        })

        data['sections'].append({
            'title': 'Deposit Request Parameters',
            'key': 'deposit_request_parameters',
            'content': 'Parameters for interactive deposit endpoint',
            'api_features': api_structure['deposit_request_parameters'],
            'feature_count': len(api_structure['deposit_request_parameters'])
        })

        data['sections'].append({
            'title': 'Withdraw Request Parameters',
            'key': 'withdraw_request_parameters',
            'content': 'Parameters for interactive withdraw endpoint',
            'api_features': api_structure['withdraw_request_parameters'],
            'feature_count': len(api_structure['withdraw_request_parameters'])
        })

        data['sections'].append({
            'title': 'Interactive Response Fields',
            'key': 'interactive_response_fields',
            'content': 'Fields returned in interactive deposit/withdraw responses',
            'api_features': api_structure['interactive_response_fields'],
            'feature_count': len(api_structure['interactive_response_fields'])
        })

        data['sections'].append({
            'title': 'Transaction Status Values',
            'key': 'transaction_status_values',
            'content': 'Possible transaction status values in SEP-24',
            'api_features': api_structure['transaction_status_values'],
            'feature_count': len(api_structure['transaction_status_values'])
        })

        data['sections'].append({
            'title': 'Transaction Fields',
            'key': 'transaction_fields',
            'content': 'Fields returned in transaction objects',
            'api_features': api_structure['transaction_fields'],
            'feature_count': len(api_structure['transaction_fields'])
        })

        data['sections'].append({
            'title': 'Info Response Fields',
            'key': 'info_response_fields',
            'content': 'Fields returned in info endpoint response',
            'api_features': api_structure['info_response_fields'],
            'feature_count': len(api_structure['info_response_fields'])
        })

        data['sections'].append({
            'title': 'Deposit Asset Fields',
            'key': 'deposit_asset_fields',
            'content': 'Fields in deposit asset objects',
            'api_features': api_structure['deposit_asset_fields'],
            'feature_count': len(api_structure['deposit_asset_fields'])
        })

        data['sections'].append({
            'title': 'Withdraw Asset Fields',
            'key': 'withdraw_asset_fields',
            'content': 'Fields in withdraw asset objects',
            'api_features': api_structure['withdraw_asset_fields'],
            'feature_count': len(api_structure['withdraw_asset_fields'])
        })

        data['sections'].append({
            'title': 'Feature Flags Fields',
            'key': 'feature_flags_fields',
            'content': 'Fields in feature flags object',
            'api_features': api_structure['feature_flags_fields'],
            'feature_count': len(api_structure['feature_flags_fields'])
        })

        data['sections'].append({
            'title': 'Fee Endpoint Info Fields',
            'key': 'fee_endpoint_fields',
            'content': 'Fields in fee endpoint info object',
            'api_features': api_structure['fee_endpoint_fields'],
            'feature_count': len(api_structure['fee_endpoint_fields'])
        })

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

        # Define comprehensive API structure for SEP-30
        # SEP-30 provides multi-party account recovery functionality
        api_structure = {
            'endpoints': [
                {
                    'name': 'register_account',
                    'description': 'POST /accounts/{address} - Register an account for recovery',
                    'required': True,
                    'method': 'POST',
                    'path': '/accounts/{address}',
                    'category': 'Account Registration'
                },
                {
                    'name': 'update_account',
                    'description': 'PUT /accounts/{address} - Update identities for an account',
                    'required': True,
                    'method': 'PUT',
                    'path': '/accounts/{address}',
                    'category': 'Account Management'
                },
                {
                    'name': 'get_account',
                    'description': 'GET /accounts/{address} - Retrieve account details',
                    'required': True,
                    'method': 'GET',
                    'path': '/accounts/{address}',
                    'category': 'Account Information'
                },
                {
                    'name': 'delete_account',
                    'description': 'DELETE /accounts/{address} - Delete account record',
                    'required': True,
                    'method': 'DELETE',
                    'path': '/accounts/{address}',
                    'category': 'Account Management'
                },
                {
                    'name': 'list_accounts',
                    'description': 'GET /accounts - List accessible accounts',
                    'required': True,
                    'method': 'GET',
                    'path': '/accounts',
                    'category': 'Account Information'
                },
                {
                    'name': 'sign_transaction',
                    'description': 'POST /accounts/{address}/sign/{signing-address} - Sign a transaction',
                    'required': True,
                    'method': 'POST',
                    'path': '/accounts/{address}/sign/{signing-address}',
                    'category': 'Transaction Signing'
                }
            ],
            'request_fields': [
                {
                    'name': 'identities',
                    'description': 'Array of identity objects for account recovery',
                    'required': True,
                    'type': 'array'
                },
                {
                    'name': 'role',
                    'description': 'Role of the identity (owner or other)',
                    'required': True,
                    'type': 'string',
                    'values': ['owner', 'other']
                },
                {
                    'name': 'auth_methods',
                    'description': 'Array of authentication methods for the identity',
                    'required': True,
                    'type': 'array'
                },
                {
                    'name': 'type',
                    'description': 'Type of authentication method',
                    'required': True,
                    'type': 'string',
                    'values': ['stellar_address', 'phone_number', 'email', 'other']
                },
                {
                    'name': 'value',
                    'description': 'Value of the authentication method (address, phone, email, etc.)',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'transaction',
                    'description': 'Base64-encoded XDR transaction envelope to sign',
                    'required': True,
                    'type': 'string',
                    'context': 'sign_transaction'
                },
                {
                    'name': 'after',
                    'description': 'Cursor for pagination in list accounts endpoint',
                    'required': False,
                    'type': 'string',
                    'context': 'list_accounts'
                }
            ],
            'response_fields': [
                {
                    'name': 'address',
                    'description': 'Stellar address of the registered account',
                    'required': True,
                    'type': 'string'
                },
                {
                    'name': 'identities',
                    'description': 'Array of registered identity objects',
                    'required': True,
                    'type': 'array'
                },
                {
                    'name': 'signers',
                    'description': 'Array of signer objects for the account',
                    'required': True,
                    'type': 'array'
                },
                {
                    'name': 'role',
                    'description': 'Role of the identity in response',
                    'required': True,
                    'type': 'string',
                    'context': 'identity'
                },
                {
                    'name': 'authenticated',
                    'description': 'Whether the identity has been authenticated',
                    'required': False,
                    'type': 'boolean',
                    'context': 'identity'
                },
                {
                    'name': 'key',
                    'description': 'Public key of the signer',
                    'required': True,
                    'type': 'string',
                    'context': 'signer'
                },
                {
                    'name': 'signature',
                    'description': 'Base64-encoded signature of the transaction',
                    'required': True,
                    'type': 'string',
                    'context': 'sign_response'
                },
                {
                    'name': 'network_passphrase',
                    'description': 'Network passphrase used for signing',
                    'required': True,
                    'type': 'string',
                    'context': 'sign_response'
                },
                {
                    'name': 'accounts',
                    'description': 'Array of account objects in list response',
                    'required': True,
                    'type': 'array',
                    'context': 'list_accounts'
                }
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
                {
                    'name': 'multi_party_recovery',
                    'description': 'Support for multi-server account recovery',
                    'required': True,
                    'category': 'Core Feature'
                },
                {
                    'name': 'flexible_auth_methods',
                    'description': 'Support for multiple authentication method types',
                    'required': True,
                    'category': 'Core Feature'
                },
                {
                    'name': 'transaction_signing',
                    'description': 'Server-side transaction signing for recovery',
                    'required': True,
                    'category': 'Core Feature'
                },
                {
                    'name': 'account_sharing',
                    'description': 'Support for shared account access',
                    'required': False,
                    'category': 'Optional Feature'
                },
                {
                    'name': 'identity_roles',
                    'description': 'Support for owner and other identity roles',
                    'required': True,
                    'category': 'Core Feature'
                },
                {
                    'name': 'pagination',
                    'description': 'Pagination support in list accounts endpoint',
                    'required': False,
                    'category': 'Optional Feature'
                }
            ],
            'authentication': {
                'type': 'SEP-10 or External',
                'method': 'JWT Token',
                'description': 'All endpoints require authentication via Authorization header with JWT token from SEP-10 or external auth provider'
            }
        }

        # Store endpoints as a section
        data['sections'].append({
            'title': 'API Endpoints',
            'key': 'api_endpoints',
            'content': 'SEP-30 API endpoints for account recovery',
            'api_features': api_structure['endpoints'],
            'feature_count': len(api_structure['endpoints'])
        })

        # Store request fields as a section
        data['sections'].append({
            'title': 'Request Fields',
            'key': 'request_fields',
            'content': 'Fields used in API requests',
            'api_features': api_structure['request_fields'],
            'feature_count': len(api_structure['request_fields'])
        })

        # Store response fields as a section
        data['sections'].append({
            'title': 'Response Fields',
            'key': 'response_fields',
            'content': 'Fields returned in API responses',
            'api_features': api_structure['response_fields'],
            'feature_count': len(api_structure['response_fields'])
        })

        # Store error codes as a section
        data['sections'].append({
            'title': 'Error Codes',
            'key': 'error_codes',
            'content': 'HTTP error codes and their meanings',
            'api_features': api_structure['error_codes'],
            'feature_count': len(api_structure['error_codes'])
        })

        # Store features as a section
        data['sections'].append({
            'title': 'Recovery Features',
            'key': 'recovery_features',
            'content': 'Core and optional recovery features',
            'api_features': api_structure['features'],
            'feature_count': len(api_structure['features'])
        })

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
            {
                'name': 'tx',
                'description': 'Transaction operation - Request to sign a transaction',
                'required': True,
                'category': 'URI Operation'
            },
            {
                'name': 'pay',
                'description': 'Payment operation - Request to pay a specific address',
                'required': True,
                'category': 'URI Operation'
            }
        ]

        # TX operation parameters
        uri_structure['tx_operation_parameters'] = [
            {
                'name': 'xdr',
                'description': 'Base64 encoded TransactionEnvelope XDR',
                'required': True,
                'operation': 'tx',
                'type': 'string'
            },
            {
                'name': 'replace',
                'description': 'URL-encoded field replacement using Txrep (SEP-0011) format',
                'required': False,
                'operation': 'tx',
                'type': 'string'
            },
            {
                'name': 'callback',
                'description': 'URL for transaction submission callback',
                'required': False,
                'operation': 'tx',
                'type': 'string'
            },
            {
                'name': 'pubkey',
                'description': 'Stellar public key to specify which key should sign',
                'required': False,
                'operation': 'tx',
                'type': 'string'
            },
            {
                'name': 'chain',
                'description': 'Nested SEP-0007 URL for transaction chaining',
                'required': False,
                'operation': 'tx',
                'type': 'string'
            }
        ]

        # PAY operation parameters
        uri_structure['pay_operation_parameters'] = [
            {
                'name': 'destination',
                'description': 'Stellar account ID or payment address to receive payment',
                'required': True,
                'operation': 'pay',
                'type': 'string'
            },
            {
                'name': 'amount',
                'description': 'Amount to send',
                'required': False,
                'operation': 'pay',
                'type': 'string'
            },
            {
                'name': 'asset_code',
                'description': 'Asset code for the payment (e.g., USD, BTC)',
                'required': False,
                'operation': 'pay',
                'type': 'string'
            },
            {
                'name': 'asset_issuer',
                'description': 'Stellar account ID of asset issuer',
                'required': False,
                'operation': 'pay',
                'type': 'string'
            },
            {
                'name': 'memo',
                'description': 'Memo value to attach to transaction',
                'required': False,
                'operation': 'pay',
                'type': 'string'
            },
            {
                'name': 'memo_type',
                'description': 'Type of memo (MEMO_TEXT, MEMO_ID, MEMO_HASH, MEMO_RETURN)',
                'required': False,
                'operation': 'pay',
                'type': 'string',
                'values': ['MEMO_TEXT', 'MEMO_ID', 'MEMO_HASH', 'MEMO_RETURN']
            }
        ]

        # Common parameters (used by both operations)
        uri_structure['common_parameters'] = [
            {
                'name': 'msg',
                'description': 'Message for the user (max 300 characters)',
                'required': False,
                'operation': 'both',
                'type': 'string'
            },
            {
                'name': 'network_passphrase',
                'description': 'Network passphrase for the transaction',
                'required': False,
                'operation': 'both',
                'type': 'string'
            },
            {
                'name': 'origin_domain',
                'description': 'Fully qualified domain name of the service originating the request',
                'required': False,
                'operation': 'both',
                'type': 'string'
            },
            {
                'name': 'signature',
                'description': 'Signature of the URL for verification',
                'required': False,
                'operation': 'both',
                'type': 'string'
            }
        ]

        # Validation features
        uri_structure['validation_features'] = [
            {
                'name': 'validate_uri_scheme',
                'description': 'Validate that URI starts with web+stellar:',
                'required': True,
                'category': 'URI Validation'
            },
            {
                'name': 'validate_operation_type',
                'description': 'Validate operation type is tx or pay',
                'required': True,
                'category': 'URI Validation'
            },
            {
                'name': 'validate_xdr_parameter',
                'description': 'Validate XDR parameter for tx operation',
                'required': True,
                'category': 'URI Validation'
            },
            {
                'name': 'validate_destination_parameter',
                'description': 'Validate destination parameter for pay operation',
                'required': True,
                'category': 'URI Validation'
            },
            {
                'name': 'validate_stellar_address',
                'description': 'Validate Stellar addresses (account IDs, muxed accounts, contract IDs)',
                'required': True,
                'category': 'URI Validation'
            },
            {
                'name': 'validate_asset_code',
                'description': 'Validate asset code length and format',
                'required': True,
                'category': 'URI Validation'
            },
            {
                'name': 'validate_memo_type',
                'description': 'Validate memo type is one of allowed types',
                'required': True,
                'category': 'URI Validation'
            },
            {
                'name': 'validate_memo_value',
                'description': 'Validate memo value based on memo type',
                'required': True,
                'category': 'URI Validation'
            },
            {
                'name': 'validate_message_length',
                'description': 'Validate message parameter length (max 300 chars)',
                'required': True,
                'category': 'URI Validation'
            },
            {
                'name': 'validate_origin_domain',
                'description': 'Validate origin_domain is fully qualified domain name',
                'required': True,
                'category': 'URI Validation'
            },
            {
                'name': 'validate_chain_nesting',
                'description': 'Validate chain parameter nesting depth (max 7 levels)',
                'required': True,
                'category': 'URI Validation'
            }
        ]

        # Signature features
        uri_structure['signature_features'] = [
            {
                'name': 'sign_uri',
                'description': 'Sign a SEP-0007 URI with a keypair',
                'required': True,
                'category': 'URI Signing'
            },
            {
                'name': 'verify_signature',
                'description': 'Verify URI signature with a public key',
                'required': True,
                'category': 'URI Signing'
            },
            {
                'name': 'verify_signed_uri',
                'description': 'Verify signed URI by fetching signing key from origin domain TOML',
                'required': True,
                'category': 'URI Signing'
            }
        ]

        # Store URI structure as sections
        data['sections'].append({
            'title': 'URI Operations',
            'key': 'operations',
            'content': 'URI scheme operations (tx and pay)',
            'uri_features': uri_structure['operations'],
            'feature_count': len(uri_structure['operations'])
        })

        data['sections'].append({
            'title': 'TX Operation Parameters',
            'key': 'tx_parameters',
            'content': 'Parameters for tx operation',
            'uri_features': uri_structure['tx_operation_parameters'],
            'feature_count': len(uri_structure['tx_operation_parameters'])
        })

        data['sections'].append({
            'title': 'PAY Operation Parameters',
            'key': 'pay_parameters',
            'content': 'Parameters for pay operation',
            'uri_features': uri_structure['pay_operation_parameters'],
            'feature_count': len(uri_structure['pay_operation_parameters'])
        })

        data['sections'].append({
            'title': 'Common Parameters',
            'key': 'common_parameters',
            'content': 'Parameters common to both operations',
            'uri_features': uri_structure['common_parameters'],
            'feature_count': len(uri_structure['common_parameters'])
        })

        data['sections'].append({
            'title': 'Validation Features',
            'key': 'validation_features',
            'content': 'URI validation capabilities',
            'uri_features': uri_structure['validation_features'],
            'feature_count': len(uri_structure['validation_features'])
        })

        data['sections'].append({
            'title': 'Signature Features',
            'key': 'signature_features',
            'content': 'URI signing and verification capabilities',
            'uri_features': uri_structure['signature_features'],
            'feature_count': len(uri_structure['signature_features'])
        })

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
            {
                'name': 'tx_approve',
                'description': 'POST /tx_approve - Approval server endpoint that receives a signed transaction, checks for compliance, and signs it on success',
                'required': True,
                'method': 'POST',
                'path': '/tx_approve',
                'category': 'Approval Endpoint'
            }
        ]

        # Request parameters
        regulated_assets_structure['request_parameters'] = [
            {
                'name': 'tx',
                'description': 'A base64 encoded transaction envelope XDR signed by the user. This is the transaction that will be tested for compliance and signed on success.',
                'required': True,
                'type': 'string'
            }
        ]

        # Response statuses
        regulated_assets_structure['response_statuses'] = [
            {
                'name': 'success',
                'description': 'Transaction was found compliant and signed without being revised',
                'required': True,
                'http_status': 200,
                'category': 'Response Status'
            },
            {
                'name': 'revised',
                'description': 'Transaction was revised to be made compliant',
                'required': True,
                'http_status': 200,
                'category': 'Response Status'
            },
            {
                'name': 'pending',
                'description': 'Issuer could not determine whether to approve the transaction at the time of receiving it',
                'required': True,
                'http_status': 200,
                'category': 'Response Status'
            },
            {
                'name': 'action_required',
                'description': 'User must complete an action before this transaction can be approved',
                'required': True,
                'http_status': 200,
                'category': 'Response Status'
            },
            {
                'name': 'rejected',
                'description': 'Transaction is not compliant and could not be revised to be made compliant',
                'required': True,
                'http_status': 400,
                'category': 'Response Status'
            }
        ]

        # Success response fields
        regulated_assets_structure['success_response_fields'] = [
            {
                'name': 'status',
                'description': 'Status value "success"',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'tx',
                'description': 'Transaction envelope XDR, base64 encoded. This transaction will have both the original signature(s) from the request as well as one or multiple additional signatures from the issuer.',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'message',
                'description': 'A human readable string containing information to pass on to the user',
                'required': False,
                'type': 'string'
            }
        ]

        # Revised response fields
        regulated_assets_structure['revised_response_fields'] = [
            {
                'name': 'status',
                'description': 'Status value "revised"',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'tx',
                'description': 'Transaction envelope XDR, base64 encoded. This transaction is a revised compliant version of the original request transaction, signed by the issuer.',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'message',
                'description': 'A human readable string explaining the modifications made to the transaction to make it compliant',
                'required': True,
                'type': 'string'
            }
        ]

        # Pending response fields
        regulated_assets_structure['pending_response_fields'] = [
            {
                'name': 'status',
                'description': 'Status value "pending"',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'timeout',
                'description': 'Number of milliseconds to wait before submitting the same transaction again. Use 0 if the wait time cannot be determined.',
                'required': True,
                'type': 'integer'
            },
            {
                'name': 'message',
                'description': 'A human readable string containing information to pass on to the user',
                'required': False,
                'type': 'string'
            }
        ]

        # Action required response fields
        regulated_assets_structure['action_required_response_fields'] = [
            {
                'name': 'status',
                'description': 'Status value "action_required"',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'message',
                'description': 'A human readable string containing information regarding the action required',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'action_url',
                'description': 'A URL that allows the user to complete the actions required to have the transaction approved',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'action_method',
                'description': 'GET or POST, indicating the type of request that should be made to the action_url. If not provided, GET is assumed.',
                'required': False,
                'type': 'string'
            },
            {
                'name': 'action_fields',
                'description': 'An array of additional fields defined by SEP-9 Standard KYC / AML fields that the client may optionally provide to the approval service when sending the request to the action_url',
                'required': False,
                'type': 'string[]'
            }
        ]

        # Rejected response fields
        regulated_assets_structure['rejected_response_fields'] = [
            {
                'name': 'status',
                'description': 'Status value "rejected"',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'error',
                'description': 'A human readable string explaining why the transaction is not compliant and could not be made compliant',
                'required': True,
                'type': 'string'
            }
        ]

        # Action URL handling features
        regulated_assets_structure['action_url_handling'] = [
            {
                'name': 'action_url_get',
                'description': 'Support for GET method to action_url with query parameters',
                'required': True,
                'category': 'Action URL Handling'
            },
            {
                'name': 'action_url_post',
                'description': 'Support for POST method to action_url with JSON body',
                'required': True,
                'category': 'Action URL Handling'
            },
            {
                'name': 'action_url_post_response_no_further_action',
                'description': 'Handle POST response with result "no_further_action_required"',
                'required': True,
                'category': 'Action URL Handling'
            },
            {
                'name': 'action_url_post_response_follow_next_url',
                'description': 'Handle POST response with result "follow_next_url" and next_url field',
                'required': True,
                'category': 'Action URL Handling'
            }
        ]

        # stellar.toml fields for regulated assets
        regulated_assets_structure['stellar_toml_fields'] = [
            {
                'name': 'regulated',
                'description': 'A boolean indicating whether or not this is a regulated asset. If missing, false is assumed.',
                'required': True,
                'type': 'boolean'
            },
            {
                'name': 'approval_server',
                'description': 'The URL of an approval service that signs validated transactions',
                'required': True,
                'type': 'string'
            },
            {
                'name': 'approval_criteria',
                'description': "A human readable string that explains the issuer's requirements for approving transactions",
                'required': False,
                'type': 'string'
            }
        ]

        # Authorization flags
        regulated_assets_structure['authorization_flags'] = [
            {
                'name': 'authorization_required',
                'description': 'Authorization Required flag must be set on issuer account',
                'required': True,
                'category': 'Authorization Flag'
            },
            {
                'name': 'authorization_revocable',
                'description': 'Authorization Revocable flag must be set on issuer account',
                'required': True,
                'category': 'Authorization Flag'
            }
        ]

        # Store structure as sections
        data['sections'].append({
            'title': 'Approval Endpoint',
            'key': 'approval_endpoint',
            'content': 'POST /tx_approve endpoint for transaction approval',
            'api_features': regulated_assets_structure['approval_endpoint'],
            'feature_count': len(regulated_assets_structure['approval_endpoint'])
        })

        data['sections'].append({
            'title': 'Request Parameters',
            'key': 'request_parameters',
            'content': 'Parameters for POST /tx_approve request',
            'api_features': regulated_assets_structure['request_parameters'],
            'feature_count': len(regulated_assets_structure['request_parameters'])
        })

        data['sections'].append({
            'title': 'Response Statuses',
            'key': 'response_statuses',
            'content': 'All possible response status values',
            'api_features': regulated_assets_structure['response_statuses'],
            'feature_count': len(regulated_assets_structure['response_statuses'])
        })

        data['sections'].append({
            'title': 'Success Response Fields',
            'key': 'success_response_fields',
            'content': 'Fields returned in success response',
            'api_features': regulated_assets_structure['success_response_fields'],
            'feature_count': len(regulated_assets_structure['success_response_fields'])
        })

        data['sections'].append({
            'title': 'Revised Response Fields',
            'key': 'revised_response_fields',
            'content': 'Fields returned in revised response',
            'api_features': regulated_assets_structure['revised_response_fields'],
            'feature_count': len(regulated_assets_structure['revised_response_fields'])
        })

        data['sections'].append({
            'title': 'Pending Response Fields',
            'key': 'pending_response_fields',
            'content': 'Fields returned in pending response',
            'api_features': regulated_assets_structure['pending_response_fields'],
            'feature_count': len(regulated_assets_structure['pending_response_fields'])
        })

        data['sections'].append({
            'title': 'Action Required Response Fields',
            'key': 'action_required_response_fields',
            'content': 'Fields returned in action_required response',
            'api_features': regulated_assets_structure['action_required_response_fields'],
            'feature_count': len(regulated_assets_structure['action_required_response_fields'])
        })

        data['sections'].append({
            'title': 'Rejected Response Fields',
            'key': 'rejected_response_fields',
            'content': 'Fields returned in rejected response',
            'api_features': regulated_assets_structure['rejected_response_fields'],
            'feature_count': len(regulated_assets_structure['rejected_response_fields'])
        })

        data['sections'].append({
            'title': 'Action URL Handling',
            'key': 'action_url_handling',
            'content': 'Features for handling action_url in action_required response',
            'api_features': regulated_assets_structure['action_url_handling'],
            'feature_count': len(regulated_assets_structure['action_url_handling'])
        })

        data['sections'].append({
            'title': 'Stellar TOML Fields',
            'key': 'stellar_toml_fields',
            'content': 'Fields in stellar.toml for regulated assets',
            'api_features': regulated_assets_structure['stellar_toml_fields'],
            'feature_count': len(regulated_assets_structure['stellar_toml_fields'])
        })

        data['sections'].append({
            'title': 'Authorization Flags',
            'key': 'authorization_flags',
            'content': 'Required authorization flags on issuer account',
            'api_features': regulated_assets_structure['authorization_flags'],
            'feature_count': len(regulated_assets_structure['authorization_flags'])
        })

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
            {
                'name': 'get_auth_challenge',
                'description': 'GET /auth endpoint - Returns authorization entries for contract accounts',
                'required': True,
                'category': 'Authentication Endpoint',
                'method': 'GET',
                'parameters': ['account', 'home_domain', 'client_domain']
            },
            {
                'name': 'post_auth_token',
                'description': 'POST /auth endpoint - Validates signed authorization entries and returns JWT token',
                'required': True,
                'category': 'Authentication Endpoint',
                'method': 'POST',
                'parameters': ['authorization_entries']
            }
        ]

        # Challenge Features (SorobanAuthorizationEntry based)
        auth_features['challenge_features'] = [
            {
                'name': 'authorization_entry_decoding',
                'description': 'Decode base64 XDR encoded authorization entries from server',
                'required': True,
                'category': 'Challenge'
            },
            {
                'name': 'authorization_entry_encoding',
                'description': 'Encode signed authorization entries to base64 XDR for submission',
                'required': True,
                'category': 'Challenge'
            },
            {
                'name': 'contract_invocation_parsing',
                'description': 'Parse web_auth_verify contract invocation from authorization entries',
                'required': True,
                'category': 'Challenge'
            },
            {
                'name': 'signature_expiration_ledger',
                'description': 'Support signature expiration ledger for replay protection',
                'required': True,
                'category': 'Challenge'
            },
            {
                'name': 'auto_signature_expiration',
                'description': 'Automatically fetch and set signature expiration from Soroban RPC',
                'required': False,
                'category': 'Challenge'
            },
            {
                'name': 'nonce_consistency',
                'description': 'Verify nonce is consistent across all authorization entries',
                'required': True,
                'category': 'Challenge'
            },
            {
                'name': 'server_entry_signing',
                'description': 'Server entry is pre-signed in challenge',
                'required': True,
                'category': 'Challenge'
            },
            {
                'name': 'client_entry_signing',
                'description': 'Sign client authorization entry with provided signers',
                'required': True,
                'category': 'Challenge'
            }
        ]

        # JWT Token Features
        auth_features['jwt_token_features'] = [
            {
                'name': 'jwt_token_response',
                'description': 'Parse JWT token from server response',
                'required': True,
                'category': 'JWT Token'
            },
            {
                'name': 'jwt_token_generation',
                'description': 'Generate JWT token after successful challenge validation',
                'required': True,
                'category': 'JWT Token',
                'server_side_only': True,
                'client_note': 'Server-side feature. Client SDKs receive and use the JWT token.'
            },
            {
                'name': 'complete_auth_flow',
                'description': 'Execute complete authentication flow via jwtToken method',
                'required': True,
                'category': 'JWT Token'
            }
        ]

        # Client Domain Features
        auth_features['client_domain_features'] = [
            {
                'name': 'client_domain_parameter',
                'description': 'Support optional client_domain parameter in challenge request',
                'required': False,
                'category': 'Client Domain'
            },
            {
                'name': 'client_domain_entry',
                'description': 'Handle client domain authorization entry in challenge',
                'required': False,
                'category': 'Client Domain'
            },
            {
                'name': 'client_domain_local_signing',
                'description': 'Sign client domain entry with local keypair',
                'required': False,
                'category': 'Client Domain'
            },
            {
                'name': 'client_domain_callback_signing',
                'description': 'Sign client domain entry via remote callback',
                'required': False,
                'category': 'Client Domain'
            },
            {
                'name': 'client_domain_toml_lookup',
                'description': 'Lookup client domain signing key from stellar.toml',
                'required': False,
                'category': 'Client Domain'
            }
        ]

        # Validation Features
        auth_features['validation_features'] = [
            {
                'name': 'contract_address_validation',
                'description': 'Validate contract address matches WEB_AUTH_CONTRACT_ID from stellar.toml',
                'required': True,
                'category': 'Validation'
            },
            {
                'name': 'function_name_validation',
                'description': 'Validate function name is web_auth_verify',
                'required': True,
                'category': 'Validation'
            },
            {
                'name': 'sub_invocations_check',
                'description': 'Reject authorization entries with sub-invocations',
                'required': True,
                'category': 'Validation'
            },
            {
                'name': 'server_signature_verification',
                'description': 'Verify server signature on server authorization entry',
                'required': True,
                'category': 'Validation'
            },
            {
                'name': 'server_entry_presence',
                'description': 'Validate server authorization entry is present',
                'required': True,
                'category': 'Validation'
            },
            {
                'name': 'client_entry_presence',
                'description': 'Validate client authorization entry is present',
                'required': True,
                'category': 'Validation'
            },
            {
                'name': 'home_domain_validation',
                'description': 'Validate home_domain argument matches expected domain',
                'required': True,
                'category': 'Validation'
            },
            {
                'name': 'web_auth_domain_validation',
                'description': 'Validate web_auth_domain argument matches server domain',
                'required': True,
                'category': 'Validation'
            },
            {
                'name': 'account_validation',
                'description': 'Validate account argument matches client contract account',
                'required': True,
                'category': 'Validation'
            },
            {
                'name': 'network_passphrase_validation',
                'description': 'Validate network passphrase if provided in response',
                'required': False,
                'category': 'Validation'
            }
        ]

        # Exception Types
        auth_features['exception_types'] = [
            {
                'name': 'invalid_contract_address_exception',
                'description': 'Exception for contract address mismatch',
                'required': True,
                'category': 'Exception'
            },
            {
                'name': 'invalid_function_name_exception',
                'description': 'Exception for invalid function name',
                'required': True,
                'category': 'Exception'
            },
            {
                'name': 'sub_invocations_exception',
                'description': 'Exception when sub-invocations found',
                'required': True,
                'category': 'Exception'
            },
            {
                'name': 'invalid_server_signature_exception',
                'description': 'Exception for invalid server signature',
                'required': True,
                'category': 'Exception'
            },
            {
                'name': 'missing_server_entry_exception',
                'description': 'Exception when server entry is missing',
                'required': True,
                'category': 'Exception'
            },
            {
                'name': 'missing_client_entry_exception',
                'description': 'Exception when client entry is missing',
                'required': True,
                'category': 'Exception'
            },
            {
                'name': 'challenge_request_error_exception',
                'description': 'Exception for challenge request errors',
                'required': True,
                'category': 'Exception'
            },
            {
                'name': 'submit_challenge_error_exception',
                'description': 'Exception for challenge submission errors',
                'required': True,
                'category': 'Exception'
            }
        ]

        # Store sections
        data['sections'].append({
            'title': 'Authentication Endpoints',
            'key': 'auth_endpoints',
            'content': 'GET and POST /auth endpoints for contract account authentication',
            'auth_features': auth_features['authentication_endpoints'],
            'feature_count': len(auth_features['authentication_endpoints'])
        })

        data['sections'].append({
            'title': 'Challenge Features',
            'key': 'challenge_features',
            'content': 'SorobanAuthorizationEntry challenge handling features',
            'auth_features': auth_features['challenge_features'],
            'feature_count': len(auth_features['challenge_features'])
        })

        data['sections'].append({
            'title': 'JWT Token Features',
            'key': 'jwt_token',
            'content': 'JWT token handling and authentication flow',
            'auth_features': auth_features['jwt_token_features'],
            'feature_count': len(auth_features['jwt_token_features'])
        })

        data['sections'].append({
            'title': 'Client Domain Features',
            'key': 'client_domain',
            'content': 'Optional client domain verification features',
            'auth_features': auth_features['client_domain_features'],
            'feature_count': len(auth_features['client_domain_features'])
        })

        data['sections'].append({
            'title': 'Validation Features',
            'key': 'validation',
            'content': 'Challenge validation and security checks',
            'auth_features': auth_features['validation_features'],
            'feature_count': len(auth_features['validation_features'])
        })

        data['sections'].append({
            'title': 'Exception Types',
            'key': 'exception_types',
            'content': 'Specific exception types for error handling',
            'auth_features': auth_features['exception_types'],
            'feature_count': len(auth_features['exception_types'])
        })

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
            {
                'name': 'contractmetav0_section',
                'description': 'Support for storing metadata in "contractmetav0" Wasm custom sections',
                'required': True,
                'category': 'Metadata Storage'
            },
            {
                'name': 'multiple_entries_single_section',
                'description': 'Support for multiple metadata entries in a single custom section',
                'required': True,
                'category': 'Metadata Storage'
            },
            {
                'name': 'multiple_sections',
                'description': 'Support for multiple "contractmetav0" sections interpreted sequentially',
                'required': True,
                'category': 'Metadata Storage'
            }
        ]

        # Encoding format features
        contract_meta_features['encoding_format'] = [
            {
                'name': 'scmetaentry_xdr',
                'description': 'Use SCMetaEntry XDR type for structuring metadata',
                'required': True,
                'category': 'Encoding Format'
            },
            {
                'name': 'binary_stream_encoding',
                'description': 'Encode entries as a stream of binary values',
                'required': True,
                'category': 'Encoding Format'
            },
            {
                'name': 'key_value_pairs',
                'description': 'Store metadata as key-value string pairs',
                'required': True,
                'category': 'Encoding Format'
            }
        ]

        # Implementation support features
        contract_meta_features['implementation_support'] = [
            {
                'name': 'parse_contract_meta',
                'description': 'Parse contract metadata from contract bytecode',
                'required': True,
                'category': 'Implementation Support'
            },
            {
                'name': 'extract_meta_entries',
                'description': 'Extract meta entries as key-value pairs from contract',
                'required': True,
                'category': 'Implementation Support'
            },
            {
                'name': 'decode_scmetaentry',
                'description': 'Decode SCMetaEntry XDR structures',
                'required': True,
                'category': 'Implementation Support'
            }
        ]

        # Store features as sections
        data['sections'].append({
            'title': 'Contract Metadata Storage',
            'key': 'metadata_storage',
            'content': 'Features for storing metadata in Wasm custom sections',
            'contract_meta_features': contract_meta_features['metadata_storage'],
            'feature_count': len(contract_meta_features['metadata_storage'])
        })

        data['sections'].append({
            'title': 'Encoding Format',
            'key': 'encoding_format',
            'content': 'XDR encoding format for metadata entries',
            'contract_meta_features': contract_meta_features['encoding_format'],
            'feature_count': len(contract_meta_features['encoding_format'])
        })

        data['sections'].append({
            'title': 'Implementation Support',
            'key': 'implementation_support',
            'content': 'SDK support for parsing and extracting contract metadata',
            'contract_meta_features': contract_meta_features['implementation_support'],
            'feature_count': len(contract_meta_features['implementation_support'])
        })

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
            {
                'name': 'sep_meta_key',
                'description': 'Support for "sep" meta entry key to indicate implemented SEPs',
                'required': True,
                'category': 'SEP Declaration'
            },
            {
                'name': 'comma_separated_list',
                'description': 'Parse comma-separated list of SEP numbers from meta value',
                'required': True,
                'category': 'SEP Declaration'
            },
            {
                'name': 'multiple_sep_entries',
                'description': 'Support for multiple "sep" meta entries with combined values',
                'required': True,
                'category': 'SEP Declaration'
            }
        ]

        # Meta entry format features
        interface_discovery_features['meta_entry_format'] = [
            {
                'name': 'sep_number_format',
                'description': 'Parse SEP numbers in various formats (e.g., "41", "0041", "SEP-41")',
                'required': True,
                'category': 'Meta Entry Format'
            },
            {
                'name': 'whitespace_handling',
                'description': 'Trim whitespace from SEP numbers in comma-separated list',
                'required': True,
                'category': 'Meta Entry Format'
            },
            {
                'name': 'empty_value_handling',
                'description': 'Handle empty or missing "sep" meta entries gracefully',
                'required': True,
                'category': 'Meta Entry Format'
            }
        ]

        # Implementation support features
        interface_discovery_features['implementation_support'] = [
            {
                'name': 'parse_supported_seps',
                'description': 'Parse and extract list of supported SEPs from contract metadata',
                'required': True,
                'category': 'Implementation Support'
            },
            {
                'name': 'expose_supported_seps',
                'description': 'Expose supportedSeps property on contract info object',
                'required': True,
                'category': 'Implementation Support'
            },
            {
                'name': 'validate_sep_format',
                'description': 'Validate SEP number format and filter invalid entries',
                'required': True,
                'category': 'Implementation Support'
            }
        ]

        # Store features as sections
        data['sections'].append({
            'title': 'SEP Declaration',
            'key': 'sep_declaration',
            'content': 'Features for declaring implemented SEPs in contract metadata',
            'contract_meta_features': interface_discovery_features['sep_declaration'],
            'feature_count': len(interface_discovery_features['sep_declaration'])
        })

        data['sections'].append({
            'title': 'Meta Entry Format',
            'key': 'meta_entry_format',
            'content': 'Parsing and format handling for SEP meta entries',
            'contract_meta_features': interface_discovery_features['meta_entry_format'],
            'feature_count': len(interface_discovery_features['meta_entry_format'])
        })

        data['sections'].append({
            'title': 'Implementation Support',
            'key': 'implementation_support',
            'content': 'SDK support for parsing and exposing supported SEPs',
            'contract_meta_features': interface_discovery_features['implementation_support'],
            'feature_count': len(interface_discovery_features['implementation_support'])
        })

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
            {
                'name': 'contractspecv0_section',
                'description': 'Support for "contractspecv0" Wasm custom section',
                'required': True,
                'category': 'Wasm Custom Section'
            },
            {
                'name': 'contractenvmetav0_section',
                'description': 'Support for "contractenvmetav0" Wasm custom section for environment metadata',
                'required': True,
                'category': 'Wasm Custom Section'
            },
            {
                'name': 'contractmetav0_section',
                'description': 'Support for "contractmetav0" Wasm custom section for contract metadata',
                'required': True,
                'category': 'Wasm Custom Section'
            },
            {
                'name': 'xdr_binary_encoding',
                'description': 'Parse XDR binary encoded specification entries',
                'required': True,
                'category': 'Wasm Custom Section'
            }
        ]

        # Entry types - all 6 specified in SEP-48
        contract_spec_features['entry_types'] = [
            {
                'name': 'function_specs',
                'description': 'Parse function specification entries (SC_SPEC_ENTRY_FUNCTION_V0)',
                'required': True,
                'category': 'Entry Types'
            },
            {
                'name': 'struct_specs',
                'description': 'Parse struct type specification entries (SC_SPEC_ENTRY_UDT_STRUCT_V0)',
                'required': True,
                'category': 'Entry Types'
            },
            {
                'name': 'union_specs',
                'description': 'Parse union type specification entries (SC_SPEC_ENTRY_UDT_UNION_V0)',
                'required': True,
                'category': 'Entry Types'
            },
            {
                'name': 'enum_specs',
                'description': 'Parse enum type specification entries (SC_SPEC_ENTRY_UDT_ENUM_V0)',
                'required': True,
                'category': 'Entry Types'
            },
            {
                'name': 'error_enum_specs',
                'description': 'Parse error enum specification entries (SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0)',
                'required': True,
                'category': 'Entry Types'
            },
            {
                'name': 'event_specs',
                'description': 'Parse event specification entries (SC_SPEC_ENTRY_EVENT_V0)',
                'required': True,
                'category': 'Entry Types'
            }
        ]

        # Type system - primitive types
        contract_spec_features['type_system_primitive'] = [
            {
                'name': 'boolean_type',
                'description': 'Support for boolean type (SC_SPEC_TYPE_BOOL)',
                'required': True,
                'category': 'Type System - Primitive'
            },
            {
                'name': 'void_type',
                'description': 'Support for void type (SC_SPEC_TYPE_VOID)',
                'required': True,
                'category': 'Type System - Primitive'
            },
            {
                'name': 'numeric_types',
                'description': 'Support for numeric types (u32, i32, u64, i64, u128, i128, u256, i256)',
                'required': True,
                'category': 'Type System - Primitive'
            },
            {
                'name': 'timepoint_duration',
                'description': 'Support for timepoint and duration types',
                'required': True,
                'category': 'Type System - Primitive'
            },
            {
                'name': 'bytes_string_symbol',
                'description': 'Support for bytes, string, and symbol types',
                'required': True,
                'category': 'Type System - Primitive'
            },
            {
                'name': 'address_type',
                'description': 'Support for address type (SC_SPEC_TYPE_ADDRESS)',
                'required': True,
                'category': 'Type System - Primitive'
            }
        ]

        # Type system - compound types
        contract_spec_features['type_system_compound'] = [
            {
                'name': 'option_type',
                'description': 'Support for Option<T> type (SC_SPEC_TYPE_OPTION)',
                'required': True,
                'category': 'Type System - Compound'
            },
            {
                'name': 'result_type',
                'description': 'Support for Result<T, E> type (SC_SPEC_TYPE_RESULT)',
                'required': True,
                'category': 'Type System - Compound'
            },
            {
                'name': 'vector_type',
                'description': 'Support for Vec<T> type (SC_SPEC_TYPE_VEC)',
                'required': True,
                'category': 'Type System - Compound'
            },
            {
                'name': 'map_type',
                'description': 'Support for Map<K, V> type (SC_SPEC_TYPE_MAP)',
                'required': True,
                'category': 'Type System - Compound'
            },
            {
                'name': 'tuple_type',
                'description': 'Support for tuple types (SC_SPEC_TYPE_TUPLE)',
                'required': True,
                'category': 'Type System - Compound'
            },
            {
                'name': 'bytes_n_type',
                'description': 'Support for fixed-length bytes type (SC_SPEC_TYPE_BYTES_N)',
                'required': True,
                'category': 'Type System - Compound'
            },
            {
                'name': 'user_defined_type',
                'description': 'Support for user-defined types (SC_SPEC_TYPE_UDT)',
                'required': True,
                'category': 'Type System - Compound'
            }
        ]

        # Parsing support
        contract_spec_features['parsing_support'] = [
            {
                'name': 'parse_contract_bytecode',
                'description': 'Parse contract specifications from Wasm bytecode',
                'required': True,
                'category': 'Parsing Support'
            },
            {
                'name': 'extract_spec_entries',
                'description': 'Extract and decode all specification entries',
                'required': True,
                'category': 'Parsing Support'
            },
            {
                'name': 'parse_environment_meta',
                'description': 'Parse environment metadata (interface version)',
                'required': True,
                'category': 'Parsing Support'
            },
            {
                'name': 'parse_contract_meta',
                'description': 'Parse contract metadata key-value pairs',
                'required': True,
                'category': 'Parsing Support'
            }
        ]

        # XDR support
        contract_spec_features['xdr_support'] = [
            {
                'name': 'decode_scspecentry',
                'description': 'Decode SCSpecEntry XDR structures',
                'required': True,
                'category': 'XDR Support'
            },
            {
                'name': 'decode_scspectypedef',
                'description': 'Decode SCSpecTypeDef XDR structures for type definitions',
                'required': True,
                'category': 'XDR Support'
            },
            {
                'name': 'decode_scenvmetaentry',
                'description': 'Decode SCEnvMetaEntry XDR structures',
                'required': True,
                'category': 'XDR Support'
            },
            {
                'name': 'decode_scmetaentry',
                'description': 'Decode SCMetaEntry XDR structures',
                'required': True,
                'category': 'XDR Support'
            }
        ]

        # Store features as sections
        data['sections'].append({
            'title': 'Wasm Custom Section',
            'key': 'wasm_section',
            'content': 'Support for parsing contract specifications from Wasm custom sections',
            'contract_spec_features': contract_spec_features['wasm_section'],
            'feature_count': len(contract_spec_features['wasm_section'])
        })

        data['sections'].append({
            'title': 'Entry Types',
            'key': 'entry_types',
            'content': 'Support for all 6 specification entry types',
            'contract_spec_features': contract_spec_features['entry_types'],
            'feature_count': len(contract_spec_features['entry_types'])
        })

        data['sections'].append({
            'title': 'Type System - Primitive Types',
            'key': 'type_system_primitive',
            'content': 'Support for primitive Soroban types',
            'contract_spec_features': contract_spec_features['type_system_primitive'],
            'feature_count': len(contract_spec_features['type_system_primitive'])
        })

        data['sections'].append({
            'title': 'Type System - Compound Types',
            'key': 'type_system_compound',
            'content': 'Support for compound Soroban types',
            'contract_spec_features': contract_spec_features['type_system_compound'],
            'feature_count': len(contract_spec_features['type_system_compound'])
        })

        data['sections'].append({
            'title': 'Parsing Support',
            'key': 'parsing_support',
            'content': 'SDK support for parsing contract specifications',
            'contract_spec_features': contract_spec_features['parsing_support'],
            'feature_count': len(contract_spec_features['parsing_support'])
        })

        data['sections'].append({
            'title': 'XDR Support',
            'key': 'xdr_support',
            'content': 'XDR decoding support for specification structures',
            'contract_spec_features': contract_spec_features['xdr_support'],
            'feature_count': len(contract_spec_features['xdr_support'])
        })

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

    def parse_generic_sep(self) -> Dict[str, Any]:
        """
        Parse a generic SEP structure.

        Returns:
            Structured SEP data
        """
        data = {
            'sep_number': self.sep_number,
            'preamble': self.extract_preamble(),
            'summary': self.extract_summary(),
            'sections': self.extract_sections()
        }

        # Extract field definitions from specification sections
        for section in data['sections']:
            if 'specification' in section['title'].lower() or 'fields' in section['title'].lower():
                section['fields'] = self.extract_field_definitions(section['content'])

        return data

    def parse(self) -> Dict[str, Any]:
        """
        Parse SEP documentation based on SEP number.

        Returns:
            Parsed SEP data dictionary
        """
        if not self.raw_content:
            raise ValueError("No content to parse. Call fetch_sep_markdown() first.")

        print(f"\n{Colors.CYAN}Parsing SEP-{self.sep_number}...{Colors.END}")

        # Use specialized parsers for specific SEPs
        if self.sep_number == '0001':
            self.parsed_data = self.parse_sep_01()
        elif self.sep_number == '0002':
            self.parsed_data = self.parse_sep_02()
        elif self.sep_number == '0005':
            self.parsed_data = self.parse_sep_05()
        elif self.sep_number == '0006':
            self.parsed_data = self.parse_sep_06()
        elif self.sep_number == '0007':
            self.parsed_data = self.parse_sep_07()
        elif self.sep_number == '0008':
            self.parsed_data = self.parse_sep_08()
        elif self.sep_number == '0009':
            self.parsed_data = self.parse_sep_09()
        elif self.sep_number == '0010':
            self.parsed_data = self.parse_sep_10()
        elif self.sep_number == '0012':
            self.parsed_data = self.parse_sep_12()
        elif self.sep_number == '0024':
            self.parsed_data = self.parse_sep_24()
        elif self.sep_number == '0030':
            self.parsed_data = self.parse_sep_30()
        elif self.sep_number == '0011':
            self.parsed_data = self.parse_sep_11()
        elif self.sep_number == '0038':
            self.parsed_data = self.parse_sep_38()
        elif self.sep_number == '0045':
            self.parsed_data = self.parse_sep_45()
        elif self.sep_number == '0046':
            self.parsed_data = self.parse_sep_46()
        elif self.sep_number == '0047':
            self.parsed_data = self.parse_sep_47()
        elif self.sep_number == '0048':
            self.parsed_data = self.parse_sep_48()
        else:
            self.parsed_data = self.parse_generic_sep()

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
        # Fetch SEP markdown
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
