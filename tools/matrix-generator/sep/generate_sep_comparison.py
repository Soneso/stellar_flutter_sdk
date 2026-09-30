#!/usr/bin/env python3
"""
SEP Specification vs Flutter SDK Compatibility Comparison Generator

This script compares SEP specifications with Flutter SDK implementations
and generates detailed compatibility reports, statistics, and markdown documentation.

Author: Stellar Flutter SDK Team
License: Apache-2.0
"""

import json
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from enum import Enum


class FieldPriority(Enum):
    """Priority levels for missing fields"""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


# Add parent dir to path for shared modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from common import Colors, get_sdk_version


@dataclass
class FieldComparison:
    """Represents a comparison between a SEP field and SDK implementation"""
    section: str
    field_name: str
    required: bool
    implemented: Optional[bool]  # None for N/A (e.g., server-side-only)
    sdk_property: Optional[str]
    description: str
    priority: Optional[str] = None
    server_side_only: bool = False
    client_note: Optional[str] = None


# Title of each analysis category per SEP, in report order. SEP-09 reads its
# categories from implemented_fields, the others from implemented_features;
# SEP-01 takes its sections from the analysis.
SECTION_TITLES: Dict[str, Dict[str, str]] = {
    '0002': {
        'request_types': 'Request Types',
        'request_parameters': 'Request Parameters',
        'response_fields': 'Response Fields',
    },
    '0005': {
        'bip39_features': 'BIP-39 Mnemonic Features',
        'bip32_features': 'BIP-32 Key Derivation',
        'bip44_features': 'BIP-44 Multi-Account Support',
        'key_derivation_methods': 'Key Derivation Methods',
        'language_support': 'Language Support',
    },
    '0006': {
        'info_endpoint': 'Info Endpoint',
        'deposit_endpoints': 'Deposit Endpoints',
        'withdraw_endpoints': 'Withdraw Endpoints',
        'fee_endpoint': 'Fee Endpoint',
        'transaction_endpoints': 'Transaction Endpoints',
        'deposit_request_parameters': 'Deposit Request Parameters',
        'withdraw_request_parameters': 'Withdraw Request Parameters',
        'deposit_response_fields': 'Deposit Response Fields',
        'withdraw_response_fields': 'Withdraw Response Fields',
        'transaction_fields': 'Transaction Fields',
        'transaction_status_values': 'Transaction Status Values',
        'info_response_fields': 'Info Response Fields',
    },
    '0007': {
        'operations': 'URI Operations',
        'tx_parameters': 'TX Operation Parameters',
        'pay_parameters': 'PAY Operation Parameters',
        'common_parameters': 'Common Parameters',
        'validation_features': 'Validation Features',
        'signature_features': 'Signature Features',
    },
    '0008': {
        'approval_endpoint': 'Approval Endpoint',
        'request_parameters': 'Request Parameters',
        'response_statuses': 'Response Statuses',
        'success_response_fields': 'Success Response Fields',
        'revised_response_fields': 'Revised Response Fields',
        'pending_response_fields': 'Pending Response Fields',
        'action_required_response_fields': 'Action Required Response Fields',
        'rejected_response_fields': 'Rejected Response Fields',
        'action_url_handling': 'Action URL Handling',
        'stellar_toml_fields': 'Stellar TOML Fields',
        'authorization_flags': 'Authorization Flags',
    },
    '0009': {
        'natural_person_fields': 'Natural Person Fields',
        'organization_fields': 'Organization Fields',
        'financial_account_fields': 'Financial Account Fields',
        'card_fields': 'Card Fields',
    },
    '0010': {
        'authentication_endpoints': 'Authentication Endpoints',
        'challenge_transaction_features': 'Challenge Transaction Features',
        'jwt_token_features': 'JWT Token Features',
        'client_domain_features': 'Client Domain Features',
        'verification_features': 'Verification Features',
    },
    '0011': {
        'encoding_features': 'Encoding Features',
        'decoding_features': 'Decoding Features',
        'asset_encoding': 'Asset Encoding',
        'operation_types': 'Operation Types',
        'format_features': 'Format Features',
    },
    '0012': {
        'endpoints': 'API Endpoints',
        'request_parameters': 'Request Parameters',
        'response_fields': 'Response Fields',
        'field_types': 'Field Type Specifications',
    },
    '0023': {
        'strkey_type_features': 'Key types',
        'strkey_vector_features': 'Test vectors quoted in the StrKey unit test files',
    },
    '0024': {
        'info_endpoint': 'Info Endpoint',
        'interactive_deposit_endpoint': 'Interactive Deposit Endpoint',
        'interactive_withdraw_endpoint': 'Interactive Withdraw Endpoint',
        'transaction_endpoints': 'Transaction Endpoints',
        'fee_endpoint': 'Fee Endpoint',
        'deposit_request_parameters': 'Deposit Request Parameters',
        'withdraw_request_parameters': 'Withdraw Request Parameters',
        'interactive_response_fields': 'Interactive Response Fields',
        'transaction_status_values': 'Transaction Status Values',
        'transaction_fields': 'Transaction Fields',
        'info_response_fields': 'Info Response Fields',
        'deposit_asset_fields': 'Deposit Asset Fields',
        'withdraw_asset_fields': 'Withdraw Asset Fields',
        'feature_flags_fields': 'Feature Flags Fields',
        'fee_endpoint_fields': 'Fee Endpoint Info Fields',
    },
    '0029': {
        'memo_required': 'Memo Required',
    },
    '0030': {
        'api_endpoints': 'API Endpoints',
        'request_fields': 'Request Fields',
        'response_fields': 'Response Fields',
        'error_codes': 'Error Codes',
        'recovery_features': 'Recovery Features',
        'authentication': 'Authentication',
    },
    '0038': {
        'info_endpoint': 'Info Endpoint',
        'prices_endpoint': 'Prices Endpoint',
        'price_endpoint': 'Price Endpoint',
        'post_quote_endpoint': 'Post Quote Endpoint',
        'get_quote_endpoint': 'Get Quote Endpoint',
        'info_response_fields': 'Info Response Fields',
        'asset_fields': 'Asset Fields',
        'delivery_method_fields': 'Delivery Method Fields',
        'prices_request_parameters': 'Prices Request Parameters',
        'prices_response_fields': 'Prices Response Fields',
        'buy_asset_fields': 'Buy Asset Fields',
        'price_request_parameters': 'Price Request Parameters',
        'price_response_fields': 'Price Response Fields',
        'post_quote_request_fields': 'Post Quote Request Fields',
        'quote_response_fields': 'Quote Response Fields',
        'fee_fields': 'Fee Fields',
        'fee_details_fields': 'Fee Details Fields',
    },
    '0045': {
        'authentication_endpoints': 'Authentication Endpoints',
        'challenge_features': 'Challenge Features',
        'jwt_token_features': 'JWT Token Features',
        'client_domain_features': 'Client Domain Features',
        'validation_features': 'Validation Features',
        'exception_types': 'Exception Types',
    },
    '0046': {
        'metadata_storage': 'Metadata Storage',
        'encoding_format': 'Encoding Format',
        'implementation_support': 'Implementation Support',
    },
    '0047': {
        'sep_declaration': 'SEP Declaration',
        'meta_entry_format': 'Meta Entry Format',
        'implementation_support': 'Implementation Support',
    },
    '0048': {
        'wasm_section': 'Wasm Custom Section',
        'entry_types': 'Entry Types',
        'type_system_primitive': 'Type System - Primitive Types',
        'type_system_compound': 'Type System - Compound Types',
        'parsing_support': 'Parsing Support',
        'xdr_support': 'XDR Support',
    },
    '0051': {
        'xdr_data_types': 'XDR Data Types',
        'stellar_specific_types': 'Stellar-Specific Types',
        'json_schema': 'JSON Schema',
    },
    '0053': {
        'message_signing': 'Message Signing',
    },
}

# Keys under which an analysis entry names its SDK counterpart; an entry
# carries at most one of them.
REFERENCE_KEYS = ('sdk_method', 'sdk_property', 'sdk_constant', 'sdk_class',
                  'sdk_method_or_class', 'sdk_exception')

# Descriptions of known classes, printed in place of their doc comments.
CLASS_DESCRIPTIONS = {
    # SEP-01 classes
    'StellarToml': 'Main class for fetching and parsing stellar.toml files from Stellar domains',
    'GeneralInformation': 'Represents the general information section (VERSION, NETWORK_PASSPHRASE, etc.)',
    'Documentation': 'Represents organization documentation (ORG_NAME, ORG_URL, ORG_LOGO, etc.)',
    'PointOfContact': 'Represents point of contact information (name, email, keybase, etc.)',
    'Currency': 'Represents currency/asset documentation (code, issuer, status, etc.)',
    'Validator': 'Represents validator node information (ALIAS, DISPLAY_NAME, PUBLIC_KEY, etc.)',
    # SEP-02 classes
    'Federation': 'Resolves federation addresses to Stellar account IDs',
    'FederationResponse': 'Response from federation server lookups',
    # SEP-05 classes
    'Wallet': 'HD wallet implementation with BIP-39 mnemonic support',
    # SEP-06 classes
    'TransferServerService': 'Main service class for SEP-6 deposit and withdrawal operations',
    'DepositRequest': 'Request parameters for initiating a deposit',
    'DepositResponse': 'Response containing deposit instructions from anchor',
    'DepositInstruction': 'Instructions for completing a deposit (account, memo, etc.)',
    'DepositExchangeRequest': 'Request for deposit with on-chain asset exchange',
    'WithdrawRequest': 'Request parameters for initiating a withdrawal',
    'WithdrawResponse': 'Response containing withdrawal details from anchor',
    'WithdrawExchangeRequest': 'Request for withdrawal with on-chain asset exchange',
    'InfoResponse': 'Response from /info endpoint with supported assets and features',
    'DepositAsset': 'Asset configuration for deposits (min/max amounts, fees, etc.)',
    'DepositExchangeAsset': 'Asset configuration for deposit-exchange operations',
    'WithdrawAsset': 'Asset configuration for withdrawals (min/max amounts, fees, etc.)',
    'WithdrawExchangeAsset': 'Asset configuration for withdraw-exchange operations',
    'AnchorField': 'Custom field definition required by anchor for KYC/compliance',
    'FeeRequest': 'Request parameters for fee calculation',
    'FeeResponse': 'Response containing calculated fee for operation',
    'FeeDetails': 'Detailed fee breakdown information',
    'FeeDetailsDetails': 'Individual fee component details',
    'AnchorFeeInfo': 'Fee information from anchor /info endpoint',
    'AnchorFeatureFlags': 'Feature flags indicating anchor capabilities',
    'AnchorTransaction': 'Represents a single anchor transaction with full details',
    'AnchorTransactionInfo': 'Transaction information from /transaction endpoint',
    'AnchorTransactionsInfo': 'Transaction list from /transactions endpoint',
    'AnchorTransactionRequest': 'Request for single transaction status',
    'AnchorTransactionResponse': 'Response containing single transaction details',
    'AnchorTransactionsRequest': 'Request for transaction history',
    'AnchorTransactionsResponse': 'Response containing transaction list',
    'PatchTransactionRequest': 'Request to update transaction with additional info',
    'TransactionRefunds': 'Refund information for a transaction',
    'TransactionRefundPayment': 'Individual refund payment details',
    'ExtraInfo': 'Additional information provided by anchor',
    'CustomerInformationNeededResponse': 'Response when additional KYC info is required',
    'CustomerInformationNeededException': 'Exception thrown when KYC info is needed',
    'CustomerInformationStatusResponse': 'Response with KYC verification status',
    'CustomerInformationStatusException': 'Exception for KYC status issues',
    'AuthenticationRequiredException': 'Exception when SEP-10 authentication is required',
    # SEP-07 classes
    'URIScheme': 'Parses and generates Stellar URIs for delegated signing',
    'SubmitUriSchemeTransactionResponse': 'Response from submitting a signed transaction via callback URL',
    'URISchemeError': 'Error information when URI scheme validation or processing fails',
    'IsValidSep7UrlResult': 'Result of validating a SEP-7 URL with validity status and error details',
    'ParsedSep7UrlResult': 'Parsed components of a SEP-7 URL (operation type, parameters, etc.)',
    'UriSchemeReplacement': 'Field replacement specification for transaction template substitution',
    # SEP-08 classes
    'RegulatedAssetsService': 'Main service for SEP-8 regulated asset approval operations',
    # SEP-09 classes
    'StandardKYCFields': 'Container for all standard KYC field types',
    'NaturalPersonKYCFields': 'KYC fields for individuals (name, address, ID documents, etc.)',
    'OrganizationKYCFields': 'KYC fields for organizations (legal name, registration, address, etc.)',
    'FinancialAccountKYCFields': 'KYC fields for financial accounts (bank name, account number, etc.)',
    'CardKYCFields': 'KYC fields for payment cards (card number, expiration, CVV, etc.)',
    'RegulatedAsset': 'Represents a regulated asset with approval server configuration',
    'PostTransactionResponse': 'Base response from posting transaction to approval server',
    'PostTransactionSuccess': 'Response when transaction is approved without modifications',
    'PostTransactionRevised': 'Response when transaction is approved with modifications',
    'PostTransactionPending': 'Response when transaction approval is pending review',
    'PostTransactionActionRequired': 'Response when additional user action is required',
    'PostTransactionRejected': 'Response when transaction is rejected by approval server',
    'PostActionResponse': 'Base response from action URL endpoint',
    'PostActionDone': 'Response when action is completed successfully',
    'PostActionNextUrl': 'Response with next URL for continued action flow',
    'IssuerAccountNotFound': 'Exception when regulated asset issuer account is not found',
    'IncompleteInitData': 'Exception when initialization data is incomplete',
    'UnknownPostTransactionResponseStatus': 'Exception for unrecognized transaction response status',
    'UnknownPostTransactionResponse': 'Exception for unrecognized transaction response format',
    'UnknownPostActionResponse': 'Exception for unrecognized action response format',
    'UnknownPostActionResponseResult': 'Exception for unrecognized action response result',
    # SEP-10 classes
    'WebAuth': 'Client-side SEP-10 web authentication implementation',
    # SEP-12 classes
    'KYCService': 'Main service for SEP-12 KYC API operations',
    'GetCustomerInfoRequest': 'Request parameters for retrieving customer KYC info',
    'GetCustomerInfoResponse': 'Response containing customer KYC status and fields',
    'GetCustomerInfoField': 'Field definition for required KYC information',
    'GetCustomerInfoProvidedField': 'Field containing already provided KYC information',
    'PutCustomerInfoRequest': 'Request for submitting customer KYC information',
    'PutCustomerInfoResponse': 'Response after submitting customer KYC info',
    'GetCustomerFilesResponse': 'Response containing list of customer uploaded files',
    'CustomerFileResponse': 'Individual file information in customer files response',
    'PutCustomerVerificationRequest': 'Request for submitting verification codes',
    'PutCustomerCallbackRequest': 'Request for registering KYC status callback URL',
    # SEP-24 classes
    'TransferServerSEP24Service': 'Main service for SEP-24 hosted deposit and withdrawal',
    'SEP24InfoResponse': 'Response from /info endpoint with supported assets and features',
    'SEP24DepositAsset': 'Asset configuration for interactive deposits',
    'SEP24WithdrawAsset': 'Asset configuration for interactive withdrawals',
    'FeeEndpointInfo': 'Fee endpoint configuration from /info response',
    'FeatureFlags': 'Feature flags indicating anchor capabilities',
    'SEP24FeeRequest': 'Request parameters for fee calculation',
    'SEP24FeeResponse': 'Response containing calculated fee',
    'SEP24DepositRequest': 'Request for initiating interactive deposit',
    'SEP24WithdrawRequest': 'Request for initiating interactive withdrawal',
    'SEP24InteractiveResponse': 'Response with interactive URL for deposit/withdrawal',
    'SEP24Transaction': 'Represents a single SEP-24 transaction with full details',
    'SEP24TransactionsRequest': 'Request for transaction history',
    'SEP24TransactionsResponse': 'Response containing transaction list',
    'SEP24TransactionRequest': 'Request for single transaction status',
    'SEP24TransactionResponse': 'Response containing single transaction details',
    'Refund': 'Refund information for a transaction',
    'RefundPayment': 'Individual refund payment details',
    'RequestErrorException': 'Exception for general request errors',
    'SEP24AuthenticationRequiredException': 'Exception when SEP-10 authentication is required',
    'SEP24TransactionNotFoundException': 'Exception when requested transaction is not found',
    # SEP-30 classes
    'SEP30RecoveryService': 'Main service for SEP-30 account recovery operations',
    'SEP30Request': 'Request for registering an account for recovery',
    'SEP30RequestIdentity': 'Identity information for recovery registration',
    'SEP30AuthMethod': 'Authentication method for identity verification',
    'SEP30AccountResponse': 'Response containing single account recovery details',
    'SEP30AccountsResponse': 'Response containing list of recoverable accounts',
    'SEP30ResponseSigner': 'Signer information in account recovery response',
    'SEP30ResponseIdentity': 'Identity information in account recovery response',
    'SEP30SignatureResponse': 'Response containing recovery signature',
    'SEP30ResponseException': 'Base exception for SEP-30 errors',
    'SEP30BadRequestResponseException': 'Exception for invalid request parameters',
    'SEP30UnauthorizedResponseException': 'Exception when authentication fails',
    'SEP30NotFoundResponseException': 'Exception when account is not found',
    'SEP30ConflictResponseException': 'Exception when account already registered',
    'SEP30UnknownResponseException': 'Exception for unrecognized response format',
    # SEP-38 classes
    'SEP38QuoteService': 'Main service for SEP-38 quote/RFQ operations',
    'SEP38InfoResponse': 'Response from /info endpoint with supported assets',
    'SEP38Asset': 'Asset information with delivery methods and exchange info',
    'SEP38BuyAsset': 'Buy asset configuration with delivery methods',
    'Sep38SellDeliveryMethod': 'Delivery method for selling assets',
    'Sep38BuyDeliveryMethod': 'Delivery method for buying assets',
    'SEP38PricesResponse': 'Response containing indicative prices',
    'SEP38PriceResponse': 'Response containing single price quote',
    'SEP38PostQuoteRequest': 'Request for creating a firm quote',
    'SEP38QuoteResponse': 'Response containing firm quote details',
    'SEP38Fee': 'Fee information for a quote',
    'SEP38FeeDetails': 'Detailed fee breakdown',
    'SEP38ResponseException': 'Base exception for SEP-38 errors',
    'SEP38BadRequest': 'Exception for invalid request parameters',
    'SEP38PermissionDenied': 'Exception when access is denied',
    'SEP38NotFound': 'Exception when quote is not found',
    'SEP38UnknownResponse': 'Exception for unrecognized response format',
    # SEP-45 classes
    'WebAuthForContracts': 'Client-side SEP-45 web authentication for contract accounts',
    'ContractChallengeResponse': 'Response containing contract authentication challenge',
    'SubmitContractChallengeResponse': 'Response after submitting signed contract challenge',
    'ContractChallengeValidationException': 'Base exception for contract challenge validation errors',
    'ContractChallengeValidationErrorInvalidContractAddress': 'Error when contract address is invalid',
    'ContractChallengeValidationErrorInvalidFunctionName': 'Error when function name is not __check_auth',
    'ContractChallengeValidationErrorSubInvocationsFound': 'Error when sub-invocations are present',
    'ContractChallengeValidationErrorInvalidHomeDomain': 'Error when home domain is invalid',
    'ContractChallengeValidationErrorInvalidWebAuthDomain': 'Error when web auth domain is invalid',
    'ContractChallengeValidationErrorInvalidAccount': 'Error when account address is invalid',
    'ContractChallengeValidationErrorInvalidNonce': 'Error when nonce is invalid or expired',
    'ContractChallengeValidationErrorInvalidServerSignature': 'Error when server signature is invalid',
    'ContractChallengeValidationErrorMissingServerEntry': 'Error when server entry is missing',
    'ContractChallengeValidationErrorMissingClientEntry': 'Error when client entry is missing',
    'ContractChallengeValidationErrorInvalidArgs': 'Error when challenge arguments are invalid',
    'ContractChallengeValidationErrorInvalidNetworkPassphrase': 'Error when network passphrase is invalid',
    'ContractChallengeRequestErrorResponse': 'Error response from contract challenge request',
    'SubmitContractChallengeErrorResponseException': 'Exception when challenge submission returns error',
    'SubmitContractChallengeTimeoutResponseException': 'Exception when challenge submission times out',
    'SubmitContractChallengeUnknownResponseException': 'Exception for unknown challenge response',
    'NoWebAuthForContractsEndpointFoundException': 'Exception when contract auth endpoint not found',
    'NoWebAuthContractIdFoundException': 'Exception when contract ID not found in stellar.toml',
    'MissingClientDomainForContractAuthException': 'Exception when client domain is required but missing',
    # SEP-46/47/48 classes
    'SorobanContractParser': 'Parser for extracting metadata from Soroban contract WASM',
    'SorobanContractInfo': 'Container for parsed contract metadata and supported SEPs',
    'SorobanContractParserFailed': 'Exception when contract parsing fails',
    'ContractSpec': 'Utility for converting Dart values to XDR based on contract spec',
    'ContractSpecException': 'Exception for contract spec conversion errors',
    'NativeUnionVal': 'Represents a native union value for contract spec conversion',
    # SEP-48 XDR classes
    'XdrSCEnvMetaEntry': 'XDR structure for environment metadata entries',
    'XdrSCMetaEntry': 'XDR structure for contract metadata entries',
    'XdrSCSpecTypeOption': 'XDR structure for Option<T> type in contract spec',
    'XdrSCSpecTypeResult': 'XDR structure for Result<T, E> type in contract spec',
    'XdrSCSpecTypeVec': 'XDR structure for Vec<T> type in contract spec',
    'XdrSCSpecTypeMap': 'XDR structure for Map<K, V> type in contract spec',
    'XdrSCSpecTypeTuple': 'XDR structure for tuple types in contract spec',
    'XdrSCSpecTypeBytesN': 'XDR structure for fixed-size byte arrays in contract spec',
    'XdrSCSpecTypeUDT': 'XDR structure for user-defined types in contract spec',
    'XdrSCSpecTypeDef': 'XDR structure for type definitions in contract spec',
    'XdrSCSpecEntry': 'XDR structure for contract spec entries',
    # SEP-10 validation errors and exceptions
    'ChallengeRequestErrorResponse': 'Error response from challenge request endpoint',
    'ChallengeValidationError': 'Base class for challenge validation errors',
    'ChallengeValidationErrorInvalidSeqNr': 'Error when challenge has invalid sequence number',
    'ChallengeValidationErrorInvalidSourceAccount': 'Error when challenge has invalid source account',
    'ChallengeValidationErrorInvalidTimeBounds': 'Error when challenge timebounds are invalid or expired',
    'ChallengeValidationErrorInvalidOperationType': 'Error when challenge contains invalid operation type',
    'ChallengeValidationErrorInvalidHomeDomain': 'Error when home domain in challenge is invalid',
    'ChallengeValidationErrorInvalidWebAuthDomain': 'Error when web auth domain is invalid',
    'ChallengeValidationErrorInvalidSignature': 'Error when challenge signature verification fails',
    'ChallengeValidationErrorMemoAndMuxedAccount': 'Error when both memo and muxed account are present',
    'ChallengeValidationErrorInvalidMemoType': 'Error when memo type is not supported',
    'ChallengeValidationErrorInvalidMemoValue': 'Error when memo value is invalid',
    'SubmitCompletedChallengeTimeoutResponseException': 'Exception when challenge submission times out',
    'SubmitCompletedChallengeUnknownResponseException': 'Exception for unknown response from challenge submission',
    'SubmitCompletedChallengeErrorResponseException': 'Exception when challenge submission returns error',
    'NoWebAuthEndpointFoundException': 'Exception when web auth endpoint not found in stellar.toml',
    'NoWebAuthServerSigningKeyFoundException': 'Exception when server signing key not found',
    'NoClientDomainSigningKeyFoundException': 'Exception when client domain signing key not found',
    'MissingClientDomainException': 'Exception when client domain is required but not provided',
    'MissingTransactionInChallengeResponseException': 'Exception when challenge response lacks transaction',
    'NoMemoForMuxedAccountsException': 'Exception when memo is used with muxed accounts',
}


class SEPComparator:
    """Main class for comparing SEP specifications with Flutter SDK implementation"""

    def __init__(self, sep_def_path: str, sdk_impl_path: str, sep_number: str):
        """
        Initialize the comparator with data file paths.

        Args:
            sep_def_path: Path to SEP definition JSON
            sdk_impl_path: Path to SDK implementation JSON
            sep_number: SEP number (e.g., '0001')
        """
        self.sep_def_path = Path(sep_def_path)
        self.sdk_impl_path = Path(sdk_impl_path)
        self.sep_number = sep_number
        self.sep_data: Dict[str, Any] = {}
        self.sdk_data: Dict[str, Any] = {}
        self.comparisons: List[FieldComparison] = []
        self.sdk_version = get_sdk_version()

    def load_data(self) -> None:
        """Load JSON data from both files"""
        print(f"{Colors.CYAN}Loading SEP-{self.sep_number} definition...{Colors.END}")
        with open(self.sep_def_path, 'r', encoding='utf-8') as f:
            self.sep_data = json.load(f)

        print(f"{Colors.CYAN}Loading Flutter SDK implementation...{Colors.END}")
        with open(self.sdk_impl_path, 'r', encoding='utf-8') as f:
            self.sdk_data = json.load(f)

        sections = len(self.sep_data.get('sections', []))
        classes = self.sdk_data.get('total_classes', 0)

        print(f"{Colors.GREEN}✓ Loaded {sections} SEP sections{Colors.END}")
        print(f"{Colors.GREEN}✓ Loaded {classes} SDK classes{Colors.END}")

    def determine_field_priority(self, required: bool, section: str) -> str:
        """
        Determine priority for a missing field.

        Args:
            required: Whether the field is required
            section: Section containing the field

        Returns:
            Priority level string
        """
        # Critical: Required fields in core sections
        if required:
            if section in ['global', 'general', 'general information']:
                return FieldPriority.CRITICAL.value
            else:
                return FieldPriority.HIGH.value

        # Medium: Optional fields in core sections
        if section in ['global', 'general', 'general information']:
            return FieldPriority.MEDIUM.value

        # Low: Optional fields in other sections
        return FieldPriority.LOW.value

    def compare_fields(self) -> None:
        """Compare SEP fields with SDK implementation"""
        if self.sep_number != '0001' and self.sep_number not in SECTION_TITLES:
            raise ValueError(f"No comparison defined for SEP-{self.sep_number}")

        print(f"\n{Colors.CYAN}Comparing SEP-{self.sep_number} fields with SDK implementation...{Colors.END}")

        if not self.sdk_data.get('implemented'):
            print(f"{Colors.YELLOW}⚠ SEP not implemented in SDK{Colors.END}")
            return

        if self.sep_number == '0001':
            self._compare_sep_01_fields()
            return

        source = 'implemented_fields' if self.sep_number == '0009' else 'implemented_features'
        for category, title in SECTION_TITLES[self.sep_number].items():
            self._compare_category(source, category, title)
        if self.sep_number == '0012':
            self._add_sep_12_capabilities()

        print(f"{Colors.GREEN}✓ Compared {len(self.comparisons)} features{Colors.END}")

    def _compare_sep_01_fields(self) -> None:
        """Compare SEP-01 style fields"""
        implemented_fields = self.sdk_data.get('implemented_fields', {})

        # Compare each section
        for section_key, section_data in implemented_fields.items():
            section_title = section_data.get('title', section_key)

            for field_name, field_info in section_data.get('fields', {}).items():
                comparison = FieldComparison(
                    section=section_title,
                    field_name=field_name,
                    required=field_info.get('required', False),
                    implemented=field_info.get('implemented', False),
                    sdk_property=field_info.get('sdk_property'),
                    description=field_info.get('description', ''),
                    priority=self.determine_field_priority(
                        field_info.get('required', False),
                        section_key
                    ) if not field_info.get('implemented') else None
                )

                self.comparisons.append(comparison)

        print(f"{Colors.GREEN}✓ Compared {len(self.comparisons)} fields{Colors.END}")

    def _compare_category(self, source: str, category: str, title: str) -> None:
        """
        Add one comparison per entry of an analysis category.

        A server-side-only entry gets no priority. An entry that carries an
        HTTP method and path shows them before its description.
        """
        for name, info in self.sdk_data.get(source, {}).get(category, {}).items():
            required = info.get('required', False)
            implemented = info.get('implemented')
            server_side_only = info.get('server_side_only', False)
            description = info.get('description', '')
            if info.get('method') and info.get('path'):
                description = f"{info['method']} {info['path']} - {description}"
            self.comparisons.append(FieldComparison(
                section=title,
                field_name=name,
                required=required,
                implemented=implemented,
                sdk_property=next((info[key] for key in REFERENCE_KEYS if info.get(key)), None),
                description=description,
                priority=None if server_side_only or implemented
                else self.determine_field_priority(required, category),
                server_side_only=server_side_only,
                client_note=info.get('client_note'),
            ))

    def _add_sep_12_capabilities(self) -> None:
        """Add SEP-12's authentication, file upload and SEP-9 rows."""
        implemented_features = self.sdk_data.get('implemented_features', {})
        auth = implemented_features.get('authentication', {})
        comparison = FieldComparison(
            section='Authentication',
            field_name='jwt_authentication',
            required=True,
            implemented=auth.get('implemented', False),
            sdk_property='JWT Token',
            description=f"{auth.get('method', 'JWT Token')} via {auth.get('type', 'SEP-10')} - {auth.get('description', '')}",
            priority=FieldPriority.CRITICAL.value if not auth.get('implemented') else None
        )
        self.comparisons.append(comparison)

        file_upload = implemented_features.get('file_upload', {})
        comparison = FieldComparison(
            section='File Upload',
            field_name='multipart_file_upload',
            required=True,
            implemented=file_upload.get('implemented', False),
            sdk_property='multipart/form-data',
            description=file_upload.get('description', ''),
            priority=FieldPriority.HIGH.value if not file_upload.get('implemented') else None
        )
        self.comparisons.append(comparison)

        sep9 = implemented_features.get('sep9_integration', {})
        comparison = FieldComparison(
            section='SEP-9 Integration',
            field_name='standard_kyc_fields',
            required=True,
            implemented=sep9.get('implemented', False),
            sdk_property='StandardKYCFields',
            description=sep9.get('description', ''),
            priority=FieldPriority.HIGH.value if not sep9.get('implemented') else None
        )
        self.comparisons.append(comparison)

    def calculate_statistics(self) -> Dict[str, Any]:
        """Calculate coverage statistics from comparisons (excluding server-side-only features)"""
        print(f"\n{Colors.CYAN}Calculating statistics...{Colors.END}")

        # Filter out server-side-only features for statistics
        client_comparisons = [c for c in self.comparisons if not c.server_side_only]
        server_side_count = len([c for c in self.comparisons if c.server_side_only])

        total = len(client_comparisons)
        implemented = sum(1 for c in client_comparisons if c.implemented)
        not_implemented = total - implemented

        required_total = sum(1 for c in client_comparisons if c.required)
        required_implemented = sum(1 for c in client_comparisons if c.required and c.implemented)

        optional_total = sum(1 for c in client_comparisons if not c.required)
        optional_implemented = sum(1 for c in client_comparisons if not c.required and c.implemented)

        # Section statistics (excluding server-side-only)
        section_stats = {}
        for comp in client_comparisons:
            if comp.section not in section_stats:
                section_stats[comp.section] = {
                    'total': 0,
                    'implemented': 0,
                    'required': 0,
                    'required_implemented': 0
                }

            section_stats[comp.section]['total'] += 1
            if comp.implemented:
                section_stats[comp.section]['implemented'] += 1
            if comp.required:
                section_stats[comp.section]['required'] += 1
                if comp.implemented:
                    section_stats[comp.section]['required_implemented'] += 1

        # Calculate percentages
        for section, stats in section_stats.items():
            stats['percentage'] = round(
                (stats['implemented'] / stats['total'] * 100) if stats['total'] > 0 else 0, 2
            )
            stats['required_percentage'] = round(
                (stats['required_implemented'] / stats['required'] * 100) if stats['required'] > 0 else 100, 2
            )

        # Gap analysis by priority
        gaps_by_priority = {
            FieldPriority.CRITICAL.value: [],
            FieldPriority.HIGH.value: [],
            FieldPriority.MEDIUM.value: [],
            FieldPriority.LOW.value: []
        }

        for comp in self.comparisons:
            if not comp.implemented and comp.priority:
                gaps_by_priority[comp.priority].append({
                    'field': comp.field_name,
                    'section': comp.section,
                    'required': comp.required,
                    'description': comp.description
                })

        return {
            'overall': {
                'total_fields': total,
                'implemented': implemented,
                'not_implemented': not_implemented,
                'coverage_percentage': round((implemented / total * 100) if total > 0 else 0, 2),
                'required_total': required_total,
                'required_implemented': required_implemented,
                'required_percentage': round((required_implemented / required_total * 100) if required_total > 0 else 0, 2),
                'optional_total': optional_total,
                'optional_implemented': optional_implemented,
                'optional_percentage': round((optional_implemented / optional_total * 100) if optional_total > 0 else 0, 2),
                'server_side_only_count': server_side_count,
                'server_side_note': f'Excludes {server_side_count} server-side-only feature(s) not applicable to client SDKs' if server_side_count > 0 else None
            },
            'by_section': section_stats,
            'gaps_by_priority': gaps_by_priority
        }

    def generate_markdown_report(self, output_path: str) -> None:
        """Generate detailed markdown compatibility matrix"""
        print(f"\n{Colors.CYAN}Generating markdown report: {output_path}{Colors.END}")

        stats = self.calculate_statistics()
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        preamble = self.sep_data.get('preamble', {})
        sep_title = preamble.get('title', f'SEP-{self.sep_number}')
        sep_version = preamble.get('version', 'N/A')
        sep_status = preamble.get('status', 'Unknown')

        with open(output_file, 'w', encoding='utf-8') as f:
            # Header
            f.write(f"# SEP-{self.sep_number} ({sep_title}) Compatibility Matrix\n\n")
            f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  \n")
            f.write(f"**SDK Version:** {self.sdk_version}  \n")
            f.write(f"**SEP Version:** {sep_version}  \n")
            f.write(f"**SEP Status:** {sep_status}  \n")
            f.write(f"**SEP URL:** {self.sep_data.get('metadata', {}).get('source_url', 'N/A')}\n\n")

            # Summary
            summary = self.sep_data.get('summary', '')
            if summary:
                f.write("## SEP Summary\n\n")
                f.write(f"{summary}\n\n")

            # Overall Statistics
            overall = stats['overall']
            f.write("## Overall Coverage\n\n")
            f.write(f"**Total Coverage:** {overall['coverage_percentage']}% ({overall['implemented']}/{overall['total_fields']} fields)\n\n")
            f.write(f"- ✅ **Implemented:** {overall['implemented']}/{overall['total_fields']}\n")
            f.write(f"- ❌ **Not Implemented:** {overall['not_implemented']}/{overall['total_fields']}\n\n")

            # Add note about server-side exclusions if applicable
            if overall.get('server_side_only_count', 0) > 0:
                f.write(f"_Note: {overall['server_side_note']}_\n\n")

            f.write(f"**Required Fields:** {overall['required_percentage']}% ({overall['required_implemented']}/{overall['required_total']})\n\n")
            f.write(f"**Optional Fields:** {overall['optional_percentage']}% ({overall['optional_implemented']}/{overall['optional_total']})\n\n")

            # Implementation Status
            if not self.sdk_data.get('implemented'):
                f.write("## Implementation Status\n\n")
                f.write("❌ **Not Implemented**\n\n")
                f.write(f"Reason: {self.sdk_data.get('reason', 'Unknown')}\n\n")
            else:
                f.write("## Implementation Status\n\n")
                f.write("✅ **Implemented**\n\n")

                # List implementation files
                f.write("### Implementation Files\n\n")
                for file in self.sdk_data.get('files', []):
                    f.write(f"- `{file}`\n")
                f.write("\n")

                classes = self.sdk_data.get('classes', [])
                # Filter out private classes (those starting with _)
                public_classes = [cls for cls in classes if not cls['name'].startswith('_')]
                if public_classes:
                    f.write("### Key Classes\n\n")
                    for cls in public_classes:
                        class_name = cls['name']
                        f.write(f"- **`{class_name}`**")

                        # Use specific description if available, otherwise try SDK docs
                        if class_name in CLASS_DESCRIPTIONS:
                            f.write(f": {CLASS_DESCRIPTIONS[class_name]}")
                        elif cls.get('documentation'):
                            doc = cls['documentation']
                            lines = [line.strip() for line in doc.split('\n') if line.strip() and not line.strip().startswith('///')]
                            if lines:
                                first_line = lines[0]
                                # Skip generic descriptions
                                if 'Parses and provides access to stellar.toml' not in first_line:
                                    if len(first_line) > 200 and 'http' not in first_line:
                                        first_line = first_line[:200] + '...'
                                    f.write(f": {first_line}")
                        f.write("\n")
                    f.write("\n")

            # SEP-48 adds an implementation details and an integration section
            self._generate_sep_48_enhanced_sections(f)

            # Section Coverage
            f.write("## Coverage by Section\n\n")
            f.write("| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |\n")
            f.write("|---------|----------|-------------------|-------------|-----------------|-------|\n")

            for section in sorted(stats['by_section'].keys()):
                sec_stats = stats['by_section'][section]
                not_implemented = sec_stats['total'] - sec_stats['implemented']
                f.write(f"| {section} | {sec_stats['percentage']}% | "
                       f"{sec_stats['required_percentage']}% | "
                       f"{sec_stats['implemented']} | {not_implemented} | {sec_stats['total']} |\n")
            f.write("\n")

            # Detailed Field Comparison
            f.write("## Detailed Field Comparison\n\n")

            # Group by section
            by_section = {}
            for comp in self.comparisons:
                if comp.section not in by_section:
                    by_section[comp.section] = []
                by_section[comp.section].append(comp)

            for section in sorted(by_section.keys()):
                f.write(f"### {section}\n\n")
                f.write("| Field | Required | Status | SDK Property | Description |\n")
                f.write("|-------|----------|--------|--------------|-------------|\n")

                for comp in sorted(by_section[section], key=lambda x: x.field_name):
                    # Handle server-side-only features
                    if comp.server_side_only:
                        status = "⚙️ Server"
                        required_mark = ""
                        sdk_prop = "N/A"
                        desc = f"{comp.description} **Note:** {comp.client_note}" if comp.client_note else comp.description
                    else:
                        status = "✅" if comp.implemented else "❌"
                        required_mark = "✓" if comp.required else ""
                        sdk_prop = f"`{comp.sdk_property}`" if comp.sdk_property else "-"
                        desc = comp.description

                    # Keep description concise but don't truncate URLs
                    desc = desc.replace('\n', ' ').strip()
                    if len(desc) > 200 and 'http' not in desc:
                        desc = desc[:200] + '...'

                    f.write(f"| `{comp.field_name}` | {required_mark} | {status} | "
                           f"{sdk_prop} | {desc} |\n")

                f.write("\n")

            # Implementation Gaps
            f.write("## Implementation Gaps\n\n")

            gaps = stats['gaps_by_priority']
            total_gaps = sum(len(gaps[p]) for p in gaps)

            if total_gaps == 0:
                f.write("🎉 **No gaps found!** All fields are implemented.\n\n")
            else:
                for priority in [FieldPriority.CRITICAL.value, FieldPriority.HIGH.value,
                               FieldPriority.MEDIUM.value, FieldPriority.LOW.value]:
                    priority_gaps = gaps[priority]
                    if priority_gaps:
                        icon = {"critical": "🔴", "high": "🟠", "medium": "🟡", "low": "🟢"}
                        f.write(f"### {icon[priority]} {priority.title()} Priority ({len(priority_gaps)} gaps)\n\n")

                        for gap in priority_gaps:
                            required_mark = " (Required)" if gap['required'] else " (Optional)"
                            f.write(f"- **`{gap['field']}`**{required_mark}\n")
                            f.write(f"  - Section: {gap['section']}\n")
                            if gap['description']:
                                # Keep description reasonable but don't truncate URLs
                                desc = gap['description'].replace('\n', ' ').strip()
                                if len(desc) > 200 and 'http' not in desc:
                                    desc = desc[:200] + '...'
                                f.write(f"  - {desc}\n")

                        f.write("\n")

            # Recommendations
            f.write("## Recommendations\n\n")

            if total_gaps > 0:
                critical_gaps = len(gaps[FieldPriority.CRITICAL.value])
                high_gaps = len(gaps[FieldPriority.HIGH.value])

                if critical_gaps > 0:
                    f.write(f"1. **Immediate Action Required**: Implement {critical_gaps} critical field(s)\n")
                if high_gaps > 0:
                    f.write(f"2. **High Priority**: Implement {high_gaps} high-priority field(s)\n")

                if overall['required_percentage'] < 100:
                    missing_required = overall['required_total'] - overall['required_implemented']
                    f.write(f"3. **Required Fields**: Complete implementation of {missing_required} required field(s)\n")
            else:
                f.write(f"✅ The SDK has full compatibility with SEP-{self.sep_number}!\n")

            f.write("\n")

            # Legend
            f.write("## Legend\n\n")
            f.write("- ✅ **Implemented**: Field is implemented in SDK\n")
            f.write("- ❌ **Not Implemented**: Field is missing from SDK\n")
            f.write("- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)\n")
            f.write("- ✓ **Required**: Field is required by SEP specification\n")
            f.write("- (blank) **Optional**: Field is optional\n")

            # Add note about server-side features if any exist
            server_side_count = stats['overall'].get('server_side_only_count', 0)
            if server_side_count > 0:
                f.write(f"\n**Note:** {stats['overall']['server_side_note']}\n")

        print(f"{Colors.GREEN}✓ Markdown report written to {output_path}{Colors.END}")

    def generate_statistics_report(self, output_path: str) -> None:
        """Generate statistics JSON report"""
        print(f"\n{Colors.CYAN}Generating statistics report: {output_path}{Colors.END}")

        stats = self.calculate_statistics()
        preamble = self.sep_data.get('preamble', {})

        report = {
            'generated_at': datetime.now().isoformat(),
            'sep_number': self.sep_number,
            'sep_title': preamble.get('title', f'SEP-{self.sep_number}'),
            'sep_version': preamble.get('version', 'N/A'),
            'sep_status': preamble.get('status', 'Unknown'),
            'overall': stats['overall'],
            'by_section': stats['by_section'],
            'gaps_by_priority': stats['gaps_by_priority']
        }

        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

        print(f"{Colors.GREEN}✓ Statistics report written to {output_path}{Colors.END}")

    def print_summary(self) -> None:
        """Print a summary of the comparison results to console"""
        stats = self.calculate_statistics()
        preamble = self.sep_data.get('preamble', {})

        print(f"\n{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.HEADER}SEP-{self.sep_number} COMPATIBILITY SUMMARY{Colors.END}")
        print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")

        print(f"{Colors.BOLD}SEP Title:{Colors.END} {preamble.get('title', 'N/A')}")
        print(f"{Colors.BOLD}SEP Version:{Colors.END} {preamble.get('version', 'N/A')}")
        print(f"{Colors.BOLD}SEP Status:{Colors.END} {preamble.get('status', 'N/A')}\n")

        overall = stats['overall']
        print(f"{Colors.BOLD}Overall Coverage:{Colors.END} {overall['coverage_percentage']}%")
        print(f"  ✅ Implemented:     {overall['implemented']}/{overall['total_fields']}")
        print(f"  ❌ Not Implemented: {overall['not_implemented']}/{overall['total_fields']}\n")

        print(f"{Colors.BOLD}Required Fields:{Colors.END} {overall['required_percentage']}% "
              f"({overall['required_implemented']}/{overall['required_total']})")
        print(f"{Colors.BOLD}Optional Fields:{Colors.END} {overall['optional_percentage']}% "
              f"({overall['optional_implemented']}/{overall['optional_total']})\n")

        print(f"{Colors.BOLD}Section Coverage:{Colors.END}")
        for section, sec_stats in sorted(stats['by_section'].items()):
            color = Colors.GREEN if sec_stats['percentage'] >= 80 else Colors.YELLOW if sec_stats['percentage'] >= 50 else Colors.RED
            print(f"  {color}{section:30s}: {sec_stats['percentage']:5.1f}% "
                  f"({sec_stats['implemented']}/{sec_stats['total']}){Colors.END}")

        print(f"\n{Colors.BOLD}Implementation Gaps:{Colors.END}")
        gaps = stats['gaps_by_priority']
        for priority in [FieldPriority.CRITICAL.value, FieldPriority.HIGH.value,
                        FieldPriority.MEDIUM.value, FieldPriority.LOW.value]:
            count = len(gaps[priority])
            if count > 0:
                icon = {"critical": "🔴", "high": "🟠", "medium": "🟡", "low": "🟢"}
                print(f"  {icon[priority]} {priority.upper():10s}: {count} gaps")

        print(f"\n{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")


    def _generate_sep_48_enhanced_sections(self, f) -> None:
        """
        Generate enhanced sections for SEP-48 compatibility matrix.
        These sections provide detailed implementation information and integration details.

        Args:
            f: File handle for writing markdown content
        """
        if self.sep_number != '0048':
            return  # Only generate for SEP-48

        # Implementation Details section
        self._generate_sep_48_implementation_details(f)

        # Integration with Other SEPs section
        self._generate_sep_48_integration_with_seps(f)

    def _generate_sep_48_implementation_details(self, f) -> None:
        """Generate Implementation Details section for SEP-48"""
        f.write("## Implementation Details\n\n")

        f.write("### Parsing Contract Bytecode\n\n")
        f.write("The Flutter SDK provides comprehensive bytecode parsing through the `SorobanContractParser` class:\n\n")
        f.write("```dart\n")
        f.write("import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';\n\n")
        f.write("// Parse contract bytecode\n")
        f.write("final contractBytes = await Util.readFile('path/to/contract.wasm');\n")
        f.write("final contractInfo = SorobanContractParser.parseContractByteCode(contractBytes);\n\n")
        f.write("// Access parsed data\n")
        f.write("final envVersion = contractInfo.envInterfaceVersion;\n")
        f.write("final specEntries = contractInfo.specEntries;  // List of XdrSCSpecEntry\n")
        f.write("final metaEntries = contractInfo.metaEntries;  // Map<String, String>\n")
        f.write("final supportedSeps = contractInfo.supportedSeps;  // SEP-47 integration\n\n")
        f.write("// Convenient categorized access (automatically populated)\n")
        f.write("final functions = contractInfo.funcs;  // List of XdrSCSpecFunctionV0\n")
        f.write("final structs = contractInfo.udtStructs;  // List of XdrSCSpecUDTStructV0\n")
        f.write("final unions = contractInfo.udtUnions;  // List of XdrSCSpecUDTUnionV0\n")
        f.write("final enums = contractInfo.udtEnums;  // List of XdrSCSpecUDTEnumV0\n")
        f.write("final errorEnums = contractInfo.udtErrorEnums;  // List of XdrSCSpecUDTErrorEnumV0\n")
        f.write("final events = contractInfo.events;  // List of XdrSCSpecEventV0\n")
        f.write("```\n\n")

        f.write("### Working with Contract Specifications\n\n")
        f.write("The `ContractSpec` class provides utilities for working with parsed specifications:\n\n")
        f.write("```dart\n")
        f.write("import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';\n\n")
        f.write("// Create ContractSpec from parsed entries\n")
        f.write("final spec = ContractSpec(contractInfo.specEntries);\n\n")
        f.write("// Get all functions\n")
        f.write("final functions = spec.funcs();\n\n")
        f.write("// Get all UDT structs\n")
        f.write("final structs = spec.udtStructs();\n\n")
        f.write("// Get all UDT unions\n")
        f.write("final unions = spec.udtUnions();\n\n")
        f.write("// Get all UDT enums\n")
        f.write("final enums = spec.udtEnums();\n\n")
        f.write("// Get all UDT error enums\n")
        f.write("final errorEnums = spec.udtErrorEnums();\n\n")
        f.write("// Get all events\n")
        f.write("final events = spec.events();\n\n")
        f.write("// Get specific function\n")
        f.write("final func = spec.getFunc('transfer');\n\n")
        f.write("// Find any entry by name (function, struct, union, enum, error enum, or event)\n")
        f.write("final entry = spec.findEntry('DataKey');\n\n")
        f.write("// Convert native Dart arguments to XDR SCVal\n")
        f.write("final args = {\n")
        f.write("  'from': 'GABC...',\n")
        f.write("  'to': 'GDEF...',\n")
        f.write("  'amount': 1000\n")
        f.write("};\n")
        f.write("final xdrArgs = spec.funcArgsToXdrSCValues('transfer', args);\n")
        f.write("```\n\n")

        f.write("### Type System Support\n\n")
        f.write("The SDK provides complete XDR type system support with 70+ XDR classes covering:\n\n")
        f.write("- **Primitive types**: bool, u32, i32, u64, i64, u128, i128, u256, i256, address, bytes, string, symbol, void, timepoint, duration\n")
        f.write("- **Compound types**: vec, map, tuple, option, result, bytesN\n")
        f.write("- **User-defined types**: struct, union, enum, error enum\n")
        f.write("- **Special types**: function inputs, event parameters\n\n")

        f.write("### Native to XDR Conversion\n\n")
        f.write("The `ContractSpec` class includes production-ready type conversion:\n\n")
        f.write("```dart\n")
        f.write("// Supports all primitive types\n")
        f.write("spec.nativeToXdrSCVal(true, boolType);\n")
        f.write("spec.nativeToXdrSCVal(42, u32Type);\n")
        f.write("spec.nativeToXdrSCVal('Hello', stringType);\n\n")
        f.write("// Supports compound types\n")
        f.write("spec.nativeToXdrSCVal([1, 2, 3], vecType);\n")
        f.write("spec.nativeToXdrSCVal({'key': 'value'}, mapType);\n\n")
        f.write("// Supports BigInt values for u128, i128, u256, i256\n")
        f.write("spec.nativeToXdrSCVal(BigInt.parse('123456789'), u128Type);\n")
        f.write("spec.nativeToXdrSCVal('999999999999999999', u256Type);\n\n")
        f.write("// Supports user-defined types\n")
        f.write("spec.nativeToXdrSCVal({'name': 'Alice'}, structType);\n")
        f.write("```\n\n")

    def _generate_sep_48_integration_with_seps(self, f) -> None:
        """Generate Integration with Other SEPs section for SEP-48"""
        f.write("## Integration with Other SEPs\n\n")

        f.write("### SEP-46 (Contract Meta)\n\n")
        f.write("SEP-48 builds on SEP-46 by parsing metadata from the `contractmetav0` custom section:\n\n")
        f.write("```dart\n")
        f.write("// Meta entries are automatically parsed\n")
        f.write("final metaEntries = contractInfo.metaEntries;\n\n")
        f.write("// Example: Get contract version\n")
        f.write("final version = metaEntries['version'];\n")
        f.write("```\n\n")

        f.write("### SEP-47 (Contract Interface Discovery)\n\n")
        f.write("SEP-48 implementation includes full SEP-47 support for discovering which SEPs a contract implements:\n\n")
        f.write("```dart\n")
        f.write("// Supported SEPs are automatically extracted from meta entries\n")
        f.write("final supportedSeps = contractInfo.supportedSeps;\n\n")
        f.write("// Example: Check if contract supports SEP-41\n")
        f.write("if (supportedSeps.contains('41')) {\n")
        f.write("  // Contract implements SEP-41 (Token Interface)\n")
        f.write("}\n")
        f.write("```\n\n")


def main():
    """Main entry point for the script"""
    if len(sys.argv) < 2:
        sep_number = '0001'  # Default to SEP-01
        print(f"{Colors.YELLOW}No SEP number provided, using default: {sep_number}{Colors.END}")
    else:
        sep_number = sys.argv[1]

    print(f"\n{Colors.BOLD}{Colors.HEADER}SEP Compatibility Analysis{Colors.END}")
    print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")

    # Define paths
    compatibility_dir = Path(__file__).parent.parent.parent.parent / 'compatibility'
    data_dir = Path(__file__).parent.parent / 'data' / 'sep'

    sep_def_path = data_dir / f'sep_{sep_number}_definition.json'
    sdk_impl_path = data_dir / f'flutter_sep_{sep_number}_implementation.json'
    statistics_output_path = data_dir / f'sep_{sep_number}_coverage_stats.json'
    markdown_output_path = compatibility_dir / 'sep' / f'SEP-{sep_number}_COMPATIBILITY_MATRIX.md'

    # Verify input files exist
    if not sep_def_path.exists():
        print(f"{Colors.RED}ERROR: SEP definition file not found: {sep_def_path}{Colors.END}")
        print(f"Please run: {Colors.CYAN}sep_parser.py {sep_number}{Colors.END}")
        return 1

    if not sdk_impl_path.exists():
        print(f"{Colors.RED}ERROR: SDK implementation file not found: {sdk_impl_path}{Colors.END}")
        print(f"Please run: {Colors.CYAN}sep_analyzer.py {sep_number}{Colors.END}")
        return 1

    # Create comparator
    comparator = SEPComparator(
        str(sep_def_path),
        str(sdk_impl_path),
        sep_number
    )

    try:
        # Load data
        comparator.load_data()

        # Compare fields
        comparator.compare_fields()

        # Generate reports
        comparator.generate_statistics_report(str(statistics_output_path))
        comparator.generate_markdown_report(str(markdown_output_path))

        # Print summary
        comparator.print_summary()

        print(f"{Colors.GREEN}✓ Comparison complete!{Colors.END}\n")
        print(f"{Colors.BOLD}Output files:{Colors.END}")
        print(f"  - Statistics: {statistics_output_path}")
        print(f"  - Markdown:   {markdown_output_path}\n")

        return 0

    except Exception as e:
        print(f"\n{Colors.RED}❌ ERROR: {str(e)}{Colors.END}")
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    # Check if we're in a TTY (for colors)
    if not sys.stdout.isatty():
        Colors.disable()

    sys.exit(main())
