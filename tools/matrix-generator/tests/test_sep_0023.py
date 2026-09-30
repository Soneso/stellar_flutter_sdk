"""Tests for the SEP-23 (Strkeys) parser, analyzer, and compatibility matrix.

The fixture tests/fixtures/sep-0023.md is a copy of ecosystem/sep-0023.md from
stellar/stellar-protocol master. The analyzer runs against a temporary SDK root
holding the Dart sources each test writes, except the end-to-end test, which
reads this SDK and its tracked matrix.
"""

import io
import json
import re
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import List, Optional
from unittest import mock

TESTS_DIR = Path(__file__).resolve().parent
TOOLS_DIR = TESTS_DIR.parent
SDK_ROOT = TOOLS_DIR.parent.parent
for path in (TOOLS_DIR, TOOLS_DIR / 'sep', TESTS_DIR):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

import generate_sep_comparison  # noqa: E402
import run_analysis  # noqa: E402
import sep_analyzer  # noqa: E402
from sep_analyzer import SEPAnalyzer  # noqa: E402
from test_sep_parser import load_fixture, parse_markdown, replace_once  # noqa: E402

KEY_TYPES_TITLE = 'Key types'
VECTORS_TITLE = 'Test vectors quoted in the StrKey unit test files'
KEY_PAIR_FILE = 'lib/src/key_pair.dart'
CONSTANTS_FILE = 'lib/src/constants/stellar_protocol_constants.dart'
TEST_FILE = 'test/unit/strkey_test.dart'

KEY_TYPES = [
    ('STRKEY_PUBKEY', 48, 'G'), ('STRKEY_MUXED', 96, 'M'), ('STRKEY_PRIVKEY', 144, 'S'),
    ('STRKEY_PRE_AUTH_TX', 152, 'T'), ('STRKEY_HASH_X', 184, 'X'),
    ('STRKEY_SIGNED_PAYLOAD', 120, 'P'), ('STRKEY_CONTRACT', 16, 'C'),
    ('STRKEY_LIQUIDITY_POOL', 88, 'L'), ('STRKEY_CLAIMABLE_BALANCE', 8, 'B'),
]

G = 'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJ'
M = 'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJ'
P = 'PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAA'
B = 'DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RG'
VALID_CASES = [
    ('Valid non-multiplexed account', G + 'VSGZ'),
    ('Valid multiplexed account', M + 'UAAAAAAAAAAAACJUQ'),
    ('Valid multiplexed account in which unsigned id exceeds maximum signed 64-bit integer',
     M + 'VAAAAAAAAAAAAAJLK'),
    ('Valid signed payload with an ed25519 public key and a 32-byte payload.',
     P + 'QACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM'),
    ('Valid signed payload with an ed25519 public key and a 29-byte payload which becomes '
     'zero padded.', P + 'OQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUAAAAFGBU'),
    ('Valid contract', 'CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA'),
    ('Valid liquidity pool address', 'LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN'),
    ('Valid claimable balance address', 'BAAD6' + B + 'R4TU'),
]
INVALID_CASES = [
    ('Invalid length (Ed25519 should be 32 bytes, not 5)', 'GAAAAAAAACGC6'),
    ('The unused trailing bit must be zero in the encoding of the last three bytes (24 bits) '
     'as five base-32 symbols (25 bits)', M + 'UAAAAAAAAAAAACJUR'),
    ('Invalid length (congruent to 1 mod 8)', G + 'VSGZA'),
    ('Invalid length (base-32 decoding should yield 35 bytes, not 36)', G + 'UACUSI'),
    ('Invalid algorithm (low 3 bits of version byte are 7)',
     'G47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVP2I'),
    ('Invalid length (congruent to 6 mod 8)', M + 'VAAAAAAAAAAAAAJLKA'),
    ('Invalid length (base-32 decoding should yield 43 bytes, not 44)', M + 'VAAAAAAAAAAAAAAV75I'),
    ('Invalid algorithm (low 3 bits of version byte are 7)',
     'M47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ'),
    ('Padding bytes are not allowed', M + 'UAAAAAAAAAAAACJUK==='),
    ('Invalid checksum', M + 'UAAAAAAAAAAAACJUO'),
    ('Length prefix specifies length that is shorter than payload in signed payload',
     P + 'QACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IAAAAAAAAPM'),
    ('Length prefix specifies length that is longer than payload in signed payload',
     P + 'OQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4Z2PQ'),
    ('No zero padding in signed payload', P + 'OQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DXFH6'),
    ('The unused trailing 2-bits must be zero in the encoding of the last symbol.',
     'BAAD6' + B + 'R4TV'),
    ('Invalid claimable balance type (first byte of binary key is not 0)', 'BAAT6' + B + 'XACA'),
]
VECTORS = (
    [(f'valid_{i:02d}', title, vector) for i, (title, vector) in enumerate(VALID_CASES, 1)]
    + [(f'invalid_{i:02d}', title, vector) for i, (title, vector) in enumerate(INVALID_CASES, 1)]
)
VECTOR_BY_NAME = {name: vector for name, _, vector in VECTORS}

SDK_METHODS = {
    'STRKEY_PUBKEY': 'StrKey.encodeStellarAccountId / decodeStellarAccountId',
    'STRKEY_MUXED': 'StrKey.encodeStellarMuxedAccountId / decodeStellarMuxedAccountId',
    'STRKEY_PRIVKEY': 'StrKey.encodeStellarSecretSeed / decodeStellarSecretSeed',
    'STRKEY_PRE_AUTH_TX': 'StrKey.encodePreAuthTx / decodePreAuthTx',
    'STRKEY_HASH_X': 'StrKey.encodeSha256Hash / decodeSha256Hash',
    'STRKEY_SIGNED_PAYLOAD': 'StrKey.encodeSignedPayload / decodeSignedPayload',
    'STRKEY_CONTRACT': 'StrKey.encodeContractId / decodeContractId',
    'STRKEY_LIQUIDITY_POOL': 'StrKey.encodeLiquidityPoolId / decodeLiquidityPoolId',
    'STRKEY_CLAIMABLE_BALANCE': 'StrKey.encodeClaimableBalanceId / decodeClaimableBalanceId',
}

VERSION_BYTES = [
    ('ACCOUNT_ID', 'ACCOUNT_ID', '6 << 3'), ('MUXED_ACCOUNT_ID', 'MUXED_ACCOUNT', '12 << 3'),
    ('SEED', 'SEED', '18 << 3'), ('PRE_AUTH_TX', 'PRE_AUTH_TX', '19 << 3'),
    ('SHA256_HASH', 'SHA256_HASH', '23 << 3'), ('SIGNED_PAYLOAD', 'SIGNED_PAYLOAD', '15 << 3'),
    ('CONTRACT_ID', 'CONTRACT_ID', '2 << 3'), ('LIQUIDITY_POOL', 'LIQUIDITY_POOL', '11 << 3'),
    ('CLAIMABLE_BALANCE', 'CLAIMABLE_BALANCE', '1 << 3'),
]
CONSTANTS_DART = 'class StellarProtocolConstants {\n' + ''.join(
    f'  static const int VERSION_BYTE_{constant} = {value};\n'
    for _, constant, value in VERSION_BYTES
) + '}\n'
KEY_PAIR_DART = (
    "import 'dart:typed_data';\n\nclass VersionByte {\n  const VersionByte._internal(this._value);\n"
    '  int doubled() {\n    if (_value > 0) {\n      return _value * 2;\n    }\n    return 0;\n  }\n'
    + ''.join(
        f'  static const {member} = const VersionByte._internal('
        f'StellarProtocolConstants.VERSION_BYTE_{constant});\n'
        for member, constant, _ in VERSION_BYTES)
    + '}\n\nclass StrKey {\n'
    + ''.join(
        f'  static String {encode}(Uint8List data) => encodeCheck(VersionByte.X, data);\n'
        f'  static Uint8List {decode}(String key) => decodeCheck(VersionByte.X, key);\n'
        for encode, decode in (method[7:].split(' / ') for method in SDK_METHODS.values()))
    + '}\n\nclass KeyPair {\n}\n'
)


def dart_test_source(literals: List[str]) -> str:
    return 'void main() {\n' + ''.join(f'  final v = {literal};\n' for literal in literals) + '}\n'


# Every vector, alternating single and double quotes.
EXACT_TEST_SOURCE = dart_test_source([
    f"'{vector}'" if i % 2 == 0 else f'"{vector}"' for i, (_, _, vector) in enumerate(VECTORS)
])
# invalid_03 and invalid_06 extend valid_01 and valid_03 by one character;
# invalid_10 and invalid_14 appear only padded with '==='.
COLLISION_TEST_SOURCE = dart_test_source([
    f"'{VECTOR_BY_NAME['invalid_03']}'", f'"{VECTOR_BY_NAME["invalid_06"]}"',
    f"'{VECTOR_BY_NAME['invalid_10']}==='", f'"{VECTOR_BY_NAME["invalid_14"]}==="',
    f"'X{VECTOR_BY_NAME['valid_02']}'",
])


def parse_fixture(markdown: Optional[str] = None) -> dict:
    return parse_markdown('0023', load_fixture('0023') if markdown is None else markdown)


def section(definition: dict, title: str) -> dict:
    return next(s for s in definition['sections'] if s['title'] == title)


def write_sdk_tree(root: Path, test_source: Optional[str] = EXACT_TEST_SOURCE,
                   key_pair: Optional[str] = KEY_PAIR_DART,
                   constants: Optional[str] = CONSTANTS_DART,
                   definition: Optional[dict] = None) -> None:
    """Write the three sources under root/sdk (None leaves one out) and the definition."""
    for relative, content in ((KEY_PAIR_FILE, key_pair), (CONSTANTS_FILE, constants),
                              (TEST_FILE, test_source)):
        if content is not None:
            (root / 'sdk' / relative).parent.mkdir(parents=True, exist_ok=True)
            (root / 'sdk' / relative).write_text(content, encoding='utf-8')
    (root / 'data').mkdir(exist_ok=True)
    (root / 'data' / 'sep_0023_definition.json').write_text(
        json.dumps(parse_fixture() if definition is None else definition), encoding='utf-8')


def analyzer_for(root: Path) -> SEPAnalyzer:
    analyzer = SEPAnalyzer(str(root / 'sdk'), '0023')
    analyzer.data_dir = root / 'data'
    return analyzer


def analyze_sdk(root: Path, **sources) -> dict:
    write_sdk_tree(root, **sources)
    with redirect_stdout(io.StringIO()):
        return analyzer_for(root).analyze()


def render(root: Path, analysis: dict) -> List[str]:
    """Render the matrix from the fixture definition and the analysis."""
    (root / 'definition.json').write_text(json.dumps(parse_fixture()), encoding='utf-8')
    (root / 'analysis.json').write_text(json.dumps(analysis), encoding='utf-8')
    with redirect_stdout(io.StringIO()):
        comparator = generate_sep_comparison.SEPComparator(
            str(root / 'definition.json'), str(root / 'analysis.json'), '0023')
        comparator.load_data()
        comparator.compare_fields()
        comparator.generate_markdown_report(str(root / 'matrix.md'))
    return (root / 'matrix.md').read_text(encoding='utf-8').splitlines()


class Sep0023DefinitionTest(unittest.TestCase):
    """parse_sep_23 reads the key types and test vectors from the document."""

    def test_preamble_sections_and_key_types(self):
        definition = parse_fixture()
        types = section(definition, KEY_TYPES_TITLE)['strkey_type_features']

        self.assertEqual(
            [definition['preamble'][key] for key in ('title', 'version', 'status')],
            ['Strkeys', '1.3.0', 'Active'])
        self.assertEqual(
            [(s['title'], s['key']) for s in definition['sections']],
            [(KEY_TYPES_TITLE, 'key_types'),
             (VECTORS_TITLE, 'test_vectors_quoted_in_the_strkey_unit_test_files')])
        self.assertEqual([(t['name'], t['base_value'], t['first_char']) for t in types], KEY_TYPES)
        self.assertEqual(types[0]['description'], 'Base value 6 << 3 (48), first character G')

    def test_vectors_in_document_order(self):
        vectors = section(parse_fixture(), VECTORS_TITLE)['strkey_vector_features']

        self.assertEqual([(v['name'], v['description'], v['vector']) for v in vectors], VECTORS)
        self.assertTrue(VECTOR_BY_NAME['invalid_09'].endswith('ACJUK==='))

    def test_items_and_counts_follow_an_edited_document(self):
        row = '| STRKEY_CLAIMABLE_BALANCE | 1 << 3     | B          | no    | Hash |\n'
        markdown = replace_once(load_fixture('0023'), '| 6 << 3     |', '| 7 << 3     |')
        markdown = replace_once(markdown, row, row + '| STRKEY_EXTRA | 31 << 3 | 7 | no | PK |\n')
        markdown = replace_once(markdown, 'UWDA`', 'UWDB`')
        markdown = replace_once(markdown, '\n\nYou can paste',
                                '\n\n1. Extra case\n\n   - Strkey: `EXTRA`\n\nYou can paste')
        definition = parse_fixture(markdown)
        types = section(definition, KEY_TYPES_TITLE)['strkey_type_features']
        vectors = section(definition, VECTORS_TITLE)['strkey_vector_features']

        self.assertEqual([(t['name'], t['base_value']) for t in types][0], ('STRKEY_PUBKEY', 56))
        self.assertEqual((types[9]['name'], types[9]['base_value']), ('STRKEY_EXTRA', 248))
        self.assertEqual(vectors[5]['vector'], VALID_CASES[5][1][:-1] + 'B')
        self.assertEqual((len(vectors), vectors[-1]['name'], vectors[-1]['vector']),
                         (24, 'invalid_16', 'EXTRA'))

    def test_text_after_the_invalid_cases_is_not_read(self):
        markdown = replace_once(load_fixture('0023'), 'the following array:\n',
                                'the following array:\n\n- Strkey: `GAAAAAAAACGC6`\n')
        vectors = section(parse_fixture(markdown), VECTORS_TITLE)['strkey_vector_features']
        self.assertEqual([(v['name'], v['description'], v['vector']) for v in vectors], VECTORS)

    def test_table_outside_specification(self):
        fixture = load_fixture('0023')
        table = re.search(r'^\| Key type .*?\n(?:\|.*\n)+', fixture, re.MULTILINE).group()
        before = replace_once(fixture, '## Specification\n',
                              table.splitlines()[0] + '\n' + table.splitlines()[1]
                              + '\n| STRKEY_PUBKEY | 7 << 3 | G | no | PK |\n\n## Specification\n')
        inside = replace_once(fixture, '## Specification\n',
                              '## Specification\n\n| Key type | Meaning |\n| --- | --- |\n| G | Account |\n')
        for markdown in (before, inside):
            types = section(parse_fixture(markdown), KEY_TYPES_TITLE)['strkey_type_features']
            self.assertEqual([(t['name'], t['base_value'], t['first_char']) for t in types], KEY_TYPES)

        later = replace_once(replace_once(fixture, table, ''), '## Security Concerns\n',
                             '## Security Concerns\n\n' + table)
        with self.assertRaisesRegex(ValueError, '^SEP-23 Specification section has no version'):
            parse_fixture(later)

    def test_missing_or_empty_parts_raise(self):
        fixture = load_fixture('0023')
        valid_body = r'(### Valid test cases\n).*?(?=### Invalid test cases)'
        invalid_body = r'(### Invalid test cases\n).*?(?=You can paste)'
        contract = '   - Strkey `CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA`\n'
        cases = {
            "^SEP-23 document has no '## Specification' section$":
                replace_once(fixture, '## Specification\n', '## Details\n'),
            '^SEP-23 Specification section has no version byte table':
                replace_once(fixture, '| Key type ', '| Key kind '),
            "^SEP-23 version byte table has no 'Base value' column$":
                replace_once(fixture, '| Base value |', '| Base       |'),
            '^SEP-23 version byte table has no rows$':
                re.sub(r'^\| STRKEY_\w+ +\| \d+ << 3 .*\n', '', fixture, flags=re.MULTILINE),
            r'^SEP-23 version byte table row .* has 4 cells, the header 5$':
                replace_once(fixture, '| G          | no    | PK   |', '| G          | no    |'),
            "^SEP-23 version byte table row .*: Not an integer or shift expression: 'six << 3'$":
                replace_once(fixture, '| 6 << 3     |', '| six << 3   |'),
            "^SEP-23 document has no '## Tests' section$":
                replace_once(fixture, '## Tests\n', '## Test data\n'),
            "^SEP-23 Tests section has no '### Valid test cases' subsection$":
                replace_once(fixture, '### Valid test cases\n', '### Other\n'),
            "^SEP-23 Tests section has no '### Invalid test cases' subsection$":
                replace_once(fixture, '### Invalid test cases\n', '### Other\n'),
            "^SEP-23 '### Valid test cases' lists no test cases$":
                re.sub(valid_body, r'\1\nNone.\n\n', fixture, flags=re.DOTALL),
            "^SEP-23 '### Invalid test cases' lists no test cases$":
                re.sub(invalid_body, r'\1\nNone.\n\n', fixture, flags=re.DOTALL),
            r"^SEP-23 case 6 of 'Valid test cases' \('Valid contract'\) carries 0 Strkey":
                replace_once(fixture, contract, ''),
            r"^SEP-23 case 6 of 'Valid test cases' \('Valid contract'\) carries 2 Strkey":
                replace_once(fixture, contract, contract * 2),
        }
        for message, markdown in cases.items():
            with self.subTest(message), self.assertRaisesRegex(ValueError, message):
                parse_fixture(markdown)


class Sep0023AnalyzerTest(unittest.TestCase):
    """analyze_sep_23 reads the Dart sources and the StrKey unit test file."""

    def setUp(self):
        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        self.root = Path(temp_dir.name)

    def sdk_methods(self, **sources) -> dict:
        types = analyze_sdk(self.root, **sources)['implemented_features']['strkey_type_features']
        return {name: item['sdk_method'] for name, item in types.items()}

    def test_every_key_type_and_vector_is_implemented(self):
        analysis = analyze_sdk(self.root)
        features = analysis['implemented_features']
        vectors = features['strkey_vector_features']

        self.assertEqual({name: item['sdk_method'] for name, item in
                          features['strkey_type_features'].items()}, SDK_METHODS)
        self.assertEqual({name: item['sdk_method'] for name, item in vectors.items()},
                         {name: TEST_FILE for name, _, _ in VECTORS})
        self.assertEqual(analysis['files'], [KEY_PAIR_FILE, CONSTANTS_FILE, TEST_FILE])
        self.assertEqual([c['name'] for c in analysis['classes']], ['VersionByte', 'StrKey'])
        self.assertEqual(vectors['valid_04']['description'],
                         'Valid signed payload with an ed25519 public key and a 32-byte payload, '
                         f'quoted in `{TEST_FILE}`')

    def test_value_forms_the_reader_accepts(self):
        constants = CONSTANTS_DART
        for old, new in (('= 6 << 3', '= 48'), ('= 12 << 3', '= 0x60'), ('= 18 << 3', '= 1__4_4'),
                         ('int VERSION_BYTE_PRE_AUTH_TX = 19 << 3', 'VERSION_BYTE_PRE_AUTH_TX = 0X98')):
            constants = replace_once(constants, old, new)
        key_pair = replace_once(KEY_PAIR_DART, 'StellarProtocolConstants.VERSION_BYTE_CONTRACT_ID',
                                '2 << 3')
        self.assertEqual(self.sdk_methods(constants=constants, key_pair=key_pair), SDK_METHODS)

    def test_typed_member_and_trailing_comma_are_read(self):
        key_pair = replace_once(KEY_PAIR_DART, '  static const ACCOUNT_ID = ',
                                '  static const VersionByte ACCOUNT_ID = ')
        key_pair = replace_once(key_pair, '(StellarProtocolConstants.VERSION_BYTE_SEED)',
                                '(\n    StellarProtocolConstants.VERSION_BYTE_SEED,\n  )')
        self.assertEqual(self.sdk_methods(key_pair=key_pair), SDK_METHODS)

    def test_value_that_differs_renders_not_implemented(self):
        cases = {
            'constant': {'constants': replace_once(CONSTANTS_DART, '= 6 << 3', '= 7 << 3')},
            'specification': {'definition': parse_fixture(
                replace_once(load_fixture('0023'), '| 6 << 3     |', '| 7 << 3     |'))},
            'member built from another constant': {'key_pair': replace_once(
                KEY_PAIR_DART, 'VERSION_BYTE_ACCOUNT_ID)', 'VERSION_BYTE_SEED)')},
        }
        for label, sources in cases.items():
            with self.subTest(label):
                self.assertEqual(self.sdk_methods(**sources), {**SDK_METHODS, 'STRKEY_PUBKEY': None})

    def test_key_type_the_sdk_does_not_implement_renders_not_implemented(self):
        with mock.patch.dict(sep_analyzer.SEP_23_KEY_TYPE_NAMES, {'STRKEY_HASH_X': None}):
            self.assertEqual(self.sdk_methods(), {**SDK_METHODS, 'STRKEY_HASH_X': None})

    def test_drift_raises_naming_what_is_missing(self):
        seed = '  static const SEED = const VersionByte._internal('
        extra_row = '| STRKEY_EXTRA | 31 << 3 | 7 | no | PK |\n'
        cases = {
            f'^SEP-23 class VersionByte not found in {KEY_PAIR_FILE}$':
                {'key_pair': replace_once(KEY_PAIR_DART, 'class VersionByte {', 'class VersionBytes {')},
            f'^SEP-23 class StellarProtocolConstants not found in {CONSTANTS_FILE}$':
                {'constants': replace_once(CONSTANTS_DART, 'class StellarProtocolConstants',
                                           'class ProtocolConstants')},
            f'^SEP-23 VersionByte.SEED not found in {KEY_PAIR_FILE}$':
                {'key_pair': replace_once(KEY_PAIR_DART, seed, '  static const OTHER = VersionByte._internal(')},
            f'^SEP-23 VersionByte.CONTRACT_ID not found in {KEY_PAIR_FILE}$':
                {'key_pair': replace_once(KEY_PAIR_DART, '  static const CONTRACT_ID = ', '  static const OTHER_ID = ')
                 + 'class LegacyBytes {\n  static const CONTRACT_ID = const VersionByte._internal('
                   'StellarProtocolConstants.VERSION_BYTE_CONTRACT_ID);\n}\n'},
            f'^SEP-23 StellarProtocolConstants.VERSION_BYTE_LIQUIDITY_POOL not found in {CONSTANTS_FILE}$':
                {'constants': replace_once(CONSTANTS_DART, 'VERSION_BYTE_LIQUIDITY_POOL =', 'VERSION_BYTE_POOL =')
                 + 'class LegacyConstants {\n  static const int VERSION_BYTE_LIQUIDITY_POOL = 11 << 3;\n}\n'},
            f'^SEP-23 StellarProtocolConstants.VERSION_BYTE_SEED not found in {CONSTANTS_FILE}$':
                {'constants': replace_once(CONSTANTS_DART, 'VERSION_BYTE_SEED =', 'VERSION_BYTE_SEEDS =')},
            f'^SEP-23 StrKey.encodeSha256Hash not found in {KEY_PAIR_FILE}$':
                {'key_pair': replace_once(KEY_PAIR_DART, 'String encodeSha256Hash(', 'String encodeSha(')},
            f'^SEP-23 StrKey.decodeStellarMuxedAccountId not found in {KEY_PAIR_FILE}$':
                {'key_pair': replace_once(KEY_PAIR_DART, 'decodeStellarMuxedAccountId(', 'decodeMuxed(')},
            '^SEP-23 key type STRKEY_EXTRA has no entry in SEP_23_KEY_TYPE_NAMES$':
                {'definition': parse_fixture(replace_once(
                    load_fixture('0023'), '| Hash |\n\nThe low', '| Hash |\n' + extra_row + '\nThe low'))},
            f"^SEP-23 StellarProtocolConstants.VERSION_BYTE_SEED in {CONSTANTS_FILE} has a value "
            "this reader cannot evaluate: 'SEED_BASE << 3'$":
                {'constants': replace_once(CONSTANTS_DART, '= 18 << 3', '= SEED_BASE << 3')},
            f"^SEP-23 VersionByte.SEED in {KEY_PAIR_FILE} has a value this reader cannot "
            r"evaluate: 'StellarProtocolConstants.VERSION_BYTE_SEED \+ 0'$":
                {'key_pair': replace_once(KEY_PAIR_DART, 'VERSION_BYTE_SEED)', 'VERSION_BYTE_SEED + 0)')},
            '^SEP-23 definition lists no strkey_vector_features$':
                {'definition': {**parse_fixture(), 'sections': [
                    section(parse_fixture(), KEY_TYPES_TITLE)]}},
            '^SEP-23 definition lists no strkey_type_features$':
                {'definition': {**parse_fixture(), 'sections': [
                    section(parse_fixture(), VECTORS_TITLE)]}},
        }
        for message, sources in cases.items():
            with self.subTest(message), tempfile.TemporaryDirectory() as root:
                with self.assertRaisesRegex(ValueError, message):
                    analyze_sdk(Path(root), **sources)

    def test_unreadable_input_raises_naming_the_path(self):
        cases = {
            f'^SEP-23 cannot read {TEST_FILE}: No such file or directory$': {'test_source': None},
            f'^SEP-23 cannot read {KEY_PAIR_FILE}: No such file or directory$': {'key_pair': None},
            f'^SEP-23 cannot read {CONSTANTS_FILE}: No such file or directory$': {'constants': None},
        }
        for message, sources in cases.items():
            with self.subTest(message), tempfile.TemporaryDirectory() as root:
                with self.assertRaisesRegex(RuntimeError, message):
                    analyze_sdk(Path(root), **sources)
        write_sdk_tree(self.root)
        (self.root / 'sdk' / TEST_FILE).write_bytes(b"final v = '\xff';\n")
        with redirect_stdout(io.StringIO()), self.assertRaisesRegex(
                RuntimeError, f'^SEP-23 cannot read {TEST_FILE}: .*utf-8'):
            analyzer_for(self.root).analyze()
        (self.root / 'data' / 'sep_0023_definition.json').unlink()
        with redirect_stdout(io.StringIO()), self.assertRaisesRegex(
                RuntimeError, '^SEP-23 cannot read .*sep_0023_definition.json: No such file'):
            analyzer_for(self.root).analyze()

    def test_vector_counts_only_as_a_complete_quoted_literal(self):
        vectors = analyze_sdk(self.root, test_source=COLLISION_TEST_SOURCE)[
            'implemented_features']['strkey_vector_features']
        self.assertEqual([name for name, item in vectors.items() if item['implemented']],
                         ['invalid_03', 'invalid_06'])

    def test_analyzer_main_writes_nothing_when_the_run_fails(self):
        original_init = SEPAnalyzer.__init__

        def run_main(root: Path) -> tuple:
            def init_on_root(analyzer, sdk_path, sep_number):
                original_init(analyzer, str(root / 'sdk'), sep_number)
                analyzer.data_dir = root / 'data'
            with mock.patch.object(SEPAnalyzer, '__init__', init_on_root), \
                    mock.patch.object(SEPAnalyzer, 'save_to_file', autospec=True) as save, \
                    mock.patch.object(sys, 'argv', ['sep_analyzer.py', '0023']), \
                    redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                return sep_analyzer.main(), save

        write_sdk_tree(self.root)
        exit_code, save = run_main(self.root)
        self.assertEqual(exit_code, 0)
        save.assert_called_once()
        for label, sources in {'missing test file': {'test_source': None},
                               'renamed class': {'key_pair': replace_once(
                                   KEY_PAIR_DART, 'class VersionByte {', 'class Bytes {')}}.items():
            with self.subTest(label), tempfile.TemporaryDirectory() as root:
                write_sdk_tree(Path(root), **sources)
                exit_code, save = run_main(Path(root))
                self.assertEqual(exit_code, 1)
                save.assert_not_called()


class Sep0023MatrixTest(unittest.TestCase):
    """The matrix renders from the definition and the analysis."""

    def setUp(self):
        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        self.root = Path(temp_dir.name)

    def test_render_of_this_sdk_matches_the_tracked_matrix(self):
        (self.root / 'data').mkdir()
        (self.root / 'data' / 'sep_0023_definition.json').write_text(
            json.dumps(parse_fixture()), encoding='utf-8')
        analyzer = SEPAnalyzer(str(SDK_ROOT), '0023')
        analyzer.data_dir = self.root / 'data'
        with redirect_stdout(io.StringIO()):
            lines = render(self.root, analyzer.analyze())
        tracked = (SDK_ROOT / 'compatibility' / 'sep' / 'SEP-0023_COMPATIBILITY_MATRIX.md'
                   ).read_text(encoding='utf-8').splitlines()

        # The Generated and SDK Version lines change with every run and release.
        def normalized(matrix: List[str]) -> List[str]:
            return [re.sub(r'^(\*\*(?:Generated|SDK Version):\*\*) .*', r'\1 ...', line)
                    for line in matrix]

        self.assertEqual(normalized(lines), normalized(tracked))
        self.assertIn('**Total Coverage:** 100.0% (32/32 fields)', lines)

    def test_run_analysis_runs_sep_0023_after_sep_0012(self):
        steps = [script for script, _, _ in run_analysis.AnalysisOrchestrator().scripts]
        start = steps.index('sep/sep_parser.py 0023')
        self.assertEqual(steps[start - 1:start + 4], [
            'sep/generate_sep_comparison.py 0012', 'sep/sep_parser.py 0023',
            'sep/sep_analyzer.py 0023', 'sep/generate_sep_comparison.py 0023',
            'sep/sep_parser.py 0024',
        ])


if __name__ == '__main__':
    unittest.main()
