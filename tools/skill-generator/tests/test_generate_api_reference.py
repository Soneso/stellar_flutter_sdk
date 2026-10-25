"""Offline tests for the agent-skill API reference generator.

Small Dart sources in temporary directories pin how class and extension
headers carry their type parameters and which annotations keep a member or a
whole declaration out of the reference. One test class runs the generator over
a temporary copy of the SDK's `lib/` directory and derives its expectations
from an independent scan of that source, so the shapes of the real source are
covered without touching or comparing the committed reference. Another runs
the generator over a small library whose skipped and private types hold
internal members.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from dataclasses import dataclass, field
from pathlib import Path

GENERATOR_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = GENERATOR_DIR.parent.parent
if str(GENERATOR_DIR) not in sys.path:
    sys.path.insert(0, str(GENERATOR_DIR))

import generate_api_reference as gen  # noqa: E402


class DartSourceTestCase(unittest.TestCase):
    """Writes a Dart source into a temporary directory and parses it."""

    def write_source(self, source: str) -> Path:
        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        path = Path(temp_dir.name) / 'sample.dart'
        path.write_text(source, encoding='utf-8')
        return path

    def parse(self, source: str) -> dict:
        return {info.name: info for info in gen.parse_dart_file(self.write_source(source))}


class TypeParameterHeaderTest(DartSourceTestCase):
    """Class and named-extension headers keep their type parameters as declared."""

    def test_one_parameter_class_with_extends_and_implements(self):
        infos = self.parse(
            'class Page<T> extends Response implements TypedResponse<Page<T>> {\n'
            '  List<T> records = [];\n'
            '}\n'
        )
        self.assertEqual(
            gen.format_class_header(infos['Page']),
            '## Page<T> extends Response implements TypedResponse<Page<T>>',
        )

    def test_bounded_recursive_parameter(self):
        infos = self.parse(
            'abstract class OperationBuilder<B extends OperationBuilder<B>> {\n'
            '  B setSourceAccount(String sourceAccountId) {\n'
            '    return this as B;\n'
            '  }\n'
            '}\n'
        )
        self.assertEqual(
            gen.format_class_header(infos['OperationBuilder']),
            '## abstract class OperationBuilder<B extends OperationBuilder<B>>',
        )

    def test_generic_named_extension(self):
        infos = self.parse(
            'extension Chunks<T> on List<T> {\n'
            '  List<List<T>> chunked(int size) => [];\n'
            '}\n'
        )
        self.assertEqual(
            gen.format_class_header(infos['Chunks']),
            '## extension Chunks<T> on List<T>',
        )

    def test_non_generic_class_header_unchanged(self):
        infos = self.parse(
            'class KeyPair extends Signer implements Comparable<KeyPair> {\n'
            '  String get accountId => "";\n'
            '}\n'
            '\n'
            'class Network {\n'
            '  final String networkPassphrase = "";\n'
            '}\n'
        )
        self.assertEqual(infos['KeyPair'].type_params, '')
        self.assertEqual(
            gen.format_class_header(infos['KeyPair']),
            '## KeyPair extends Signer implements Comparable<KeyPair>',
        )
        self.assertEqual(gen.format_class_header(infos['Network']), '## Network')


class InternalAnnotationTest(DartSourceTestCase):
    """`@internal` keeps members and declarations out, public members stay."""

    MANAGER_SOURCE = (
        'class Manager {\n'
        '  @internal\n'
        '  Manager(this._kit);\n'
        '\n'
        '  @internal\n'
        '  final String networkPassphrase;\n'
        '\n'
        '  @internal\n'
        '  @override\n'
        '  Future<void> clearInMemorySigners() async {}\n'
        '\n'
        '  /// Lists the rules.\n'
        '  Future<List<String>> listRules() async => <String>[];\n'
        '\n'
        '  final Object _kit;\n'
        '}\n'
    )

    def test_internal_constructor_field_and_method_are_left_out(self):
        infos = self.parse(self.MANAGER_SOURCE)
        self.assertEqual(
            infos['Manager'].member_lines(),
            ['Future<List<String>> listRules() async'],
        )

    def test_member_scan_agrees_with_emitted_members(self):
        path = self.write_source(self.MANAGER_SOURCE)
        info = {i.name: i for i in gen.parse_dart_file(path)}['Manager']
        clean = gen.strip_all_comments(path.read_text(encoding='utf-8'))
        body = gen._find_type_body(clean, info)
        self.assertEqual(gen.scan_public_member_count(body, 'Manager'), 1)
        self.assertEqual(info.member_count(), 1)

    def test_internal_and_deprecated_declarations_are_left_out(self):
        path = self.write_source(
            '@internal\n'
            'class Hidden {\n'
            '  void run() {}\n'
            '}\n'
            '\n'
            '@Deprecated(\n'
            "    'Use Shown')\n"
            'class Old {\n'
            '  void run() {}\n'
            '}\n'
            '\n'
            'class Shown {\n'
            '  void run() {}\n'
            '}\n'
        )
        self.assertEqual([i.name for i in gen.parse_dart_file(path)], ['Shown'])
        self.assertEqual(gen.scan_public_declaration_names(path), {'Shown'})


class AnnotationReadingTest(DartSourceTestCase):
    """Annotations are read as code: `@` in a string is text, arguments are balanced."""

    def member_counts(self, path: Path, name: str) -> tuple:
        info = {i.name: i for i in gen.parse_dart_file(path)}[name]
        clean = gen.strip_all_comments(path.read_text(encoding='utf-8'))
        body = gen._find_type_body(clean, info)
        return info.member_count(), gen.scan_public_member_count(body, name)

    def test_at_sign_in_a_string_keeps_field_and_default_argument(self):
        path = self.write_source(
            'class Contact {\n'
            "  final String address = 'user@internal.example';\n"
            "  void notify({String to = 'user@internal.example'}) {}\n"
            '}\n'
        )
        infos = {i.name: i for i in gen.parse_dart_file(path)}
        self.assertEqual(
            infos['Contact'].member_lines(),
            ['final String address', "void notify({String to = 'user@internal.example'})"],
        )
        self.assertEqual(self.member_counts(path, 'Contact'), (2, 2))

    def test_at_sign_in_another_annotation_keeps_the_class(self):
        path = self.write_source(
            "@Contact('user@internal.example')\n"
            'class Shown {\n'
            '  void run() {}\n'
            '}\n'
        )
        self.assertEqual([i.name for i in gen.parse_dart_file(path)], ['Shown'])
        self.assertEqual(gen.scan_public_declaration_names(path), {'Shown'})

    def test_internal_before_a_multi_line_collection_annotation(self):
        path = self.write_source(
            '@internal\n'
            '@Tags({\n'
            "  'slow',\n"
            "  'network',\n"
            '})\n'
            'class Hidden {\n'
            '  void run() {}\n'
            '}\n'
            '\n'
            'class Holder {\n'
            '  @internal\n'
            '  @Tags({\n'
            "    'slow',\n"
            '  })\n'
            '  void hidden() {}\n'
            '\n'
            '  @meta.internal\n'
            '  int get secret => 1;\n'
            '\n'
            '  void shown() {}\n'
            '}\n'
        )
        infos = {i.name: i for i in gen.parse_dart_file(path)}
        self.assertEqual(list(infos), ['Holder'])
        self.assertEqual(gen.scan_public_declaration_names(path), {'Holder'})
        self.assertEqual(infos['Holder'].member_lines(), ['void shown()'])
        self.assertEqual(self.member_counts(path, 'Holder'), (1, 1))


# Independent scan of the barrel-exported sources. It reads the layout that
# `dart format` gives the SDK (enforced by the Tests workflow): top-level
# declarations start in column 0, members of a type in column 2, and the body
# of a top-level type closes with `}` in column 0. It shares only file
# selection and comment stripping with the generator, so the expectations it
# derives do not depend on the generator's own declaration and member parsing.
# It reads metadata itself: string literals are masked first, and an
# annotation's argument list is balanced across lines.

_TOP_LEVEL_TYPE_RE = re.compile(
    r'^(?:(?:abstract|sealed|base|final|interface)\s+)*'
    r'(?:mixin\s+class|class|mixin|enum)\s+(?P<name>\w+)'
    r'|^extension\s+(?P<ext>\w+)?'
)
_SKIPPING_NAMES = frozenset({'Deprecated', 'deprecated', 'internal'})
_ANNOTATION_NAME_AT = re.compile(r'@((?:[A-Za-z_$][\w$]*\.)*[A-Za-z_$][\w$]*)')
_HEADER_KEYWORDS = frozenset(
    {'abstract', 'sealed', 'base', 'final', 'interface', 'mixin', 'class', 'enum', 'extension', 'typedef'}
)


@dataclass
class SourceScan:
    """What the independent scan expects of the reference."""

    # (name, type parameters as declared) of public generic classes, mixins,
    # enums and named extensions that carry no skipping annotation.
    generic_types: list = field(default_factory=list)
    # Names of public top-level types annotated @Deprecated or @internal.
    skipped_types: set = field(default_factory=set)
    # Names of public named top-level types without a skipping annotation.
    public_types: set = field(default_factory=set)
    # (type name, member identifier) of members annotated @internal.
    internal_members: list = field(default_factory=list)
    # `@internal` occurrences the scan could not place.
    unplaced: list = field(default_factory=list)


def _balanced_angle(text: str, start: int) -> str:
    """Return the `<...>` group that opens at `text[start]`."""
    depth = 0
    for i in range(start, len(text)):
        if text[i] == '<':
            depth += 1
        elif text[i] == '>':
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    raise ValueError(f'unbalanced type parameters at offset {start}')


def mask_strings(text: str) -> str:
    """
    `text` with the contents of every string literal replaced by spaces
    (line breaks kept, so offsets and columns stay valid). Handles single,
    double and triple quotes, raw strings, escapes, and `${...}`
    interpolation, whose code stays visible.
    """
    out = list(text)
    n = len(text)

    def blank(a: int, b: int) -> None:
        for k in range(a, min(b, n)):
            if out[k] != '\n':
                out[k] = ' '

    def code(i: int, nested: bool) -> int:
        depth = 0
        while i < n:
            c = text[i]
            if c in '\'"':
                i = literal(i, raw=False)
            elif c == 'r' and i + 1 < n and text[i + 1] in '\'"' and (
                    i == 0 or not (text[i - 1].isalnum() or text[i - 1] in '_$')):
                i = literal(i + 1, raw=True)
            elif nested and c == '{':
                depth += 1
                i += 1
            elif nested and c == '}':
                if depth == 0:
                    return i
                depth -= 1
                i += 1
            else:
                i += 1
        return i

    def literal(i: int, raw: bool) -> int:
        quote = text[i]
        delimiter = quote * 3 if text.startswith(quote * 3, i) else quote
        j = i + len(delimiter)
        while j < n:
            if text.startswith(delimiter, j):
                return j + len(delimiter)
            if not raw and text[j] == '\\':
                blank(j, j + 2)
                j += 2
                continue
            if not raw and text.startswith('${', j):
                blank(j, j + 2)
                close = code(j + 2, nested=True)
                blank(close, close + 1)
                j = close + 1
                continue
            if len(delimiter) == 1 and text[j] == '\n':
                return j
            blank(j, j + 1)
            j += 1
        return j

    code(0, nested=False)
    return ''.join(out)


def _skip_annotation(masked: str, at: int) -> int:
    """End of the annotation that starts with `@` at `at`, its argument list included."""
    name = _ANNOTATION_NAME_AT.match(masked, at)
    end = name.end()
    k = end
    while k < len(masked) and masked[k] in ' \t':
        k += 1
    if k < len(masked) and masked[k] == '(':
        depth = 0
        for q in range(k, len(masked)):
            if masked[q] == '(':
                depth += 1
            elif masked[q] == ')':
                depth -= 1
                if depth == 0:
                    return q + 1
        raise ValueError(f'unbalanced annotation arguments at offset {at}')
    return end


def annotation_names_before(masked: str, start: int) -> list:
    """Names of the annotations directly in front of the declaration at `start`."""
    names = []
    i = start
    while True:
        j = i - 1
        while j >= 0 and masked[j].isspace():
            j -= 1
        if j < 0:
            break
        if masked[j] == ')':
            depth = 0
            k = j
            while k >= 0:
                if masked[k] == ')':
                    depth += 1
                elif masked[k] == '(':
                    depth -= 1
                    if depth == 0:
                        break
                k -= 1
            head = re.search(r'@((?:[A-Za-z_$][\w$]*\.)*[A-Za-z_$][\w$]*)[ \t]*$', masked[:max(k, 0)])
        else:
            head = re.search(r'@((?:[A-Za-z_$][\w$]*\.)*[A-Za-z_$][\w$]*)$', masked[:j + 1])
        if not head:
            break
        names.append(head.group(1))
        i = head.start()
    return names


def _skips(names: list) -> bool:
    return any(name.split('.')[-1] in _SKIPPING_NAMES for name in names)


def member_identifier(declaration: str) -> str:
    """
    Identifier a member declaration (source or reference line) declares:
    the name of a field, method or getter, `name=` for a setter, `Type` or
    `Type.name` for a constructor, `operator==` style for an operator.
    """
    flat = ' '.join(declaration.split())
    operator = re.search(r'\boperator\s*([^\s(]+)\s*\(', flat)
    if operator:
        return 'operator' + operator.group(1)
    flat = re.sub(r'Function\s*\((?:[^()]|\([^()]*\))*\)\??', 'Function', flat)
    head = re.split(r'[(=;{]', flat, maxsplit=1)[0].strip()
    if head.endswith('>'):
        head = head[:len(head) - len(_trailing_angle_group(head))].strip()
    tokens = head.split(' ')
    if len(tokens) > 1 and tokens[-2] == 'set':
        return tokens[-1] + '='
    return tokens[-1]


def _trailing_angle_group(text: str) -> str:
    """The trailing `<...>` group of `text` (a generic method's parameters)."""
    depth = 0
    for i in range(len(text) - 1, -1, -1):
        if text[i] == '>':
            depth += 1
        elif text[i] == '<':
            depth -= 1
            if depth == 0:
                return text[i:]
    raise ValueError(f'unbalanced type parameters in {text!r}')


def scan_source(clean: str) -> SourceScan:
    """Scan one comment-stripped, dart-formatted source file."""
    scan = SourceScan()
    masked = mask_strings(clean)
    lines = masked.split('\n')
    line_starts = [0]
    for line in lines[:-1]:
        line_starts.append(line_starts[-1] + len(line) + 1)
    # The type whose body each line belongs to (None at the top level).
    owner = []
    current_type = None
    for index, line in enumerate(lines):
        if line and not line[0].isspace():
            declaration = _TOP_LEVEL_TYPE_RE.match(line)
            if declaration:
                current_type = declaration.group('name') or declaration.group('ext')
                name = current_type
                if name and not name.startswith('_'):
                    if _skips(annotation_names_before(masked, line_starts[index])):
                        scan.skipped_types.add(name)
                    else:
                        scan.public_types.add(name)
                        offset = line_starts[index] + declaration.end()
                        rest = masked[offset:]
                        stripped = rest.lstrip()
                        if stripped.startswith('<'):
                            begin = offset + len(rest) - len(stripped)
                            group = _balanced_angle(masked, begin)
                            scan.generic_types.append((name, clean[begin:begin + len(group)]))
            elif line.startswith('}'):
                owner.append(current_type)
                current_type = None
                continue
        owner.append(current_type)
    for found in _ANNOTATION_NAME_AT.finditer(masked):
        if found.group(1).split('.')[-1] != 'internal':
            continue
        index = masked.count('\n', 0, found.start())
        column = found.start() - line_starts[index]
        if column == 0:
            continue  # a top-level declaration, recorded through skipped_types
        if column != 2 or owner[index] is None:
            scan.unplaced.append(clean.split('\n')[index])
            continue
        member = _skip_annotation(masked, found.start())
        while True:
            while member < len(masked) and masked[member].isspace():
                member += 1
            if member < len(masked) and masked[member] == '@':
                member = _skip_annotation(masked, member)
                continue
            break
        text = ''
        for follow in masked[member:].split('\n'):
            text += ' ' + follow
            if re.search(r'[(=;{]', follow):
                break
        scan.internal_members.append((owner[index], member_identifier(text)))
    return scan


_EXPORT_RE = re.compile(r'^export\s+([^;]*);', re.MULTILINE)
_PACKAGE_PREFIX = 'package:stellar_flutter_sdk/'


def exported_files(lib: Path) -> set:
    """
    Files reachable from the barrel `lib/stellar_flutter_sdk.dart` through
    `export` directives, read independently of the generator. A conditional
    export (`export 'stub.dart' if (dart.library.x) 'impl.dart';`) reaches its
    platform targets, not the default stub.
    """
    reached: set = set()
    pending = [lib / 'stellar_flutter_sdk.dart']
    while pending:
        source = pending.pop()
        text = source.read_text(encoding='utf-8')
        text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)
        text = re.sub(r'//[^\n]*', '', text)
        for directive in _EXPORT_RE.finditer(text):
            uris = re.findall(r"'([^']+)'", directive.group(1))
            if 'if (' in directive.group(1):
                uris = uris[1:]
            for uri in uris:
                if uri.startswith(_PACKAGE_PREFIX):
                    target = lib / uri[len(_PACKAGE_PREFIX):]
                elif ':' in uri:
                    continue
                else:
                    target = source.parent / uri
                target = target.resolve()
                if target not in reached and target.exists():
                    reached.add(target)
                    pending.append(target)
    return reached


def source_files(lib: Path) -> list:
    """The exported files under lib/src that the generator documents (its skip lists applied)."""
    exported = exported_files(lib)
    files = []
    for root, dirs, names in os.walk(lib / 'src'):
        dirs[:] = sorted(d for d in dirs if d not in gen.SKIP_DIRS)
        for name in sorted(names):
            path = Path(root) / name
            if name.endswith('.dart') and name not in gen.SKIP_FILES and path.resolve() in exported:
                files.append(path)
    return files


def scan_exported_sources(lib: Path) -> SourceScan:
    """Scan every source file the reference documents."""
    total = SourceScan()
    for path in source_files(lib):
        scan = scan_source(gen.strip_all_comments(path.read_text(encoding='utf-8')))
        total.public_types |= scan.public_types
        total.generic_types += scan.generic_types
        total.skipped_types |= scan.skipped_types
        total.internal_members += scan.internal_members
        total.unplaced += [f'{path}: {line.strip()}' for line in scan.unplaced]
    return total


def header_name(header: str) -> str:
    """Declared name in a section header such as `## abstract class Page<T> ...`."""
    for word in header[3:].split():
        if word not in _HEADER_KEYWORDS:
            return re.match(r'\w+', word).group(0)
    raise ValueError(f'no name in header {header!r}')


def read_sections(output: Path) -> dict:
    """Sections of a generated reference: the declared name of each `## ` header
    mapped to its header lines and member identifiers."""
    sections: dict = {}
    if output.exists():
        current = None
        for line in output.read_text(encoding='utf-8').splitlines():
            if line.startswith('## '):
                current = header_name(line)
                sections.setdefault(current, {'headers': [], 'members': set()})
                sections[current]['headers'].append(line)
            elif line.startswith('# ') or line.startswith('---'):
                current = None
            elif current is not None and line.strip():
                sections[current]['members'].add(member_identifier(line))
    return sections


def internal_member_problems(scan: SourceScan, sections: dict) -> list:
    """An `@internal` member never appears: a type the generator skips, by its
    annotation or because it is private, has no section at all, and a public
    type keeps its section without the member."""
    problems = []
    for type_name, member in scan.internal_members:
        if type_name in scan.skipped_types or type_name.startswith('_'):
            if type_name in sections:
                problems.append(f'{type_name} is skipped but has a section')
        elif type_name not in sections:
            problems.append(f'{type_name} has no section')
        elif member in sections[type_name]['members']:
            problems.append(f'{type_name}.{member} is listed')
    return problems


class SourceScanTest(unittest.TestCase):
    """The independent scan reads dart-formatted declarations correctly."""

    SOURCE = (
        "@Deprecated(\n"
        "  'Use Page; it pages',\n"
        ")\n"
        "class OldPage<T> {\n"
        "  void run() {}\n"
        "}\n"
        "\n"
        "abstract class Builder<B extends Builder<B>> {\n"
        "  @internal\n"
        "  Builder(this._kit);\n"
        "\n"
        "  @internal\n"
        "  @override\n"
        "  final void Function(int value)? onValue;\n"
        "\n"
        "  @internal\n"
        "  Future<List<T>> load<T>(\n"
        "    String id,\n"
        "  ) async => <T>[];\n"
        "\n"
        "  @internal\n"
        "  set limit(int value) {}\n"
        "\n"
        "  int get limit => 0;\n"
        "  final Object _kit;\n"
        "}\n"
        "\n"
        "extension Chunks<T> on List<T> {\n"
        "  @internal\n"
        "  static const int size = 2;\n"
        "}\n"
    )

    def test_scan_finds_generic_skipped_and_internal_declarations(self):
        scan = scan_source(self.SOURCE)
        self.assertEqual(scan.generic_types, [('Builder', '<B extends Builder<B>>'), ('Chunks', '<T>')])
        self.assertEqual(scan.skipped_types, {'OldPage'})
        self.assertEqual(scan.public_types, {'Builder', 'Chunks'})
        self.assertEqual(scan.internal_members, [
            ('Builder', 'Builder'),
            ('Builder', 'onValue'),
            ('Builder', 'load'),
            ('Builder', 'limit='),
            ('Chunks', 'size'),
        ])
        self.assertEqual(scan.unplaced, [])

    def test_at_sign_in_a_string_is_no_annotation(self):
        scan = scan_source(
            "class Mailer {\n"
            "  final String address = 'user@internal.example';\n"
            "  final String marker = '@internal';\n"
            "  void send({String to = \"user@internal.example\"}) {}\n"
            "}\n"
        )
        self.assertEqual(scan.public_types, {'Mailer'})
        self.assertEqual(scan.internal_members, [])
        self.assertEqual(scan.unplaced, [])

    def test_at_sign_in_an_annotation_argument_keeps_the_type(self):
        scan = scan_source(
            "@Contact('user@internal.example', note: '@internal')\n"
            "class Mailer {\n"
            "  void send() {}\n"
            "}\n"
        )
        self.assertEqual(scan.public_types, {'Mailer'})
        self.assertEqual(scan.skipped_types, set())
        self.assertEqual(scan.unplaced, [])

    def test_multi_line_metadata_keeps_internal_in_view(self):
        scan = scan_source(
            "@internal\n"
            "@Tags({\n"
            "  'a',\n"
            "})\n"
            "class Hidden {}\n"
            "\n"
            "@Tags({\n"
            "  'b',\n"
            "})\n"
            "@internal\n"
            "class AlsoHidden {}\n"
            "\n"
            "class Holder {\n"
            "  @internal\n"
            "  @Tags({\n"
            "    'c',\n"
            "  })\n"
            "  void hidden() {}\n"
            "\n"
            "  void shown() {}\n"
            "}\n"
        )
        self.assertEqual(scan.skipped_types, {'Hidden', 'AlsoHidden'})
        self.assertEqual(scan.public_types, {'Holder'})
        self.assertEqual(scan.internal_members, [('Holder', 'hidden')])
        self.assertEqual(scan.unplaced, [])

    def test_member_identifier_reads_reference_lines(self):
        cases = {
            'OZContextRuleManager(this._kit)': 'OZContextRuleManager',
            'factory Page.fromJson(Map<String, dynamic> json)': 'Page.fromJson',
            'final OZExternalWalletAdapter? walletAdapter': 'walletAdapter',
            'Future<void> setPrimary(String credentialId) async': 'setPrimary',
            'String get uniqueKey': 'uniqueKey',
            'bool operator ==(Object other)': 'operator==',
            'static const String MAX_LIMIT = "922337203685.4775807"': 'MAX_LIMIT',
        }
        for line, expected in cases.items():
            with self.subTest(line=line):
                self.assertEqual(member_identifier(line), expected)


class RealLibraryRunTest(unittest.TestCase):
    """
    The generator, run over a temporary copy of lib/, applies both rules to
    whatever the barrel exports today: expectations come from the independent
    scan of lib/, not from a list of names.
    """

    @classmethod
    def setUpClass(cls):
        cls._temp_dir = tempfile.TemporaryDirectory()
        root = Path(cls._temp_dir.name)
        shutil.copytree(REPO_ROOT / 'lib', root / 'lib')
        script = root / 'tools' / 'skill-generator' / 'generate_api_reference.py'
        script.parent.mkdir(parents=True)
        shutil.copy2(GENERATOR_DIR / 'generate_api_reference.py', script)
        cls.result = subprocess.run(
            [sys.executable, str(script)],
            capture_output=True, text=True, check=False,
        )
        output = root / 'skills' / 'stellar-flutter-sdk' / 'references' / 'api_reference.md'
        cls.sections = read_sections(output)
        cls.lib = REPO_ROOT / 'lib'
        cls.scan = scan_exported_sources(cls.lib)

    @classmethod
    def tearDownClass(cls):
        cls._temp_dir.cleanup()

    def test_generator_exits_cleanly(self):
        self.assertEqual(self.result.returncode, 0, self.result.stderr[-2000:])
        self.assertIn('(name-level): 0 unemitted public declarations', self.result.stderr)
        self.assertIn('(member-level): 0 types with unemitted members', self.result.stderr)

    def test_generator_selects_the_exported_files(self):
        exported = exported_files(self.lib)
        self.assertGreater(len(exported), 0)
        self.assertEqual(gen.build_export_allowlist(), exported)
        self.assertGreater(len(source_files(self.lib)), 0)

    def test_inventories_and_sections_are_not_empty(self):
        # Deprecated API may be removed in a major release, so the skipped
        # inventory is not required to hold entries.
        self.assertGreater(len(self.sections), 0)
        self.assertGreater(len(self.scan.public_types), 0)
        self.assertGreater(len(self.scan.generic_types), 0)
        self.assertGreater(len(self.scan.internal_members), 0)

    def test_every_public_type_has_a_section(self):
        for name in sorted(self.scan.public_types):
            with self.subTest(name=name):
                self.assertIn(name, self.sections)

    def test_scan_places_every_internal_annotation(self):
        self.assertEqual(self.scan.unplaced, [])

    def test_generic_headers_carry_type_parameters(self):
        for name, type_params in self.scan.generic_types:
            with self.subTest(name=name):
                self.assertIn(name, self.sections)
                expected = ''.join((name + type_params).split())
                carried = [
                    ''.join(header.split())
                    for header in self.sections[name]['headers']
                ]
                self.assertTrue(
                    any(expected in header for header in carried),
                    f'{name}{type_params} missing from {self.sections[name]["headers"]}',
                )

    def test_skipped_declarations_have_no_section(self):
        for name in sorted(self.scan.skipped_types):
            with self.subTest(name=name):
                self.assertNotIn(name, self.sections)

    def test_internal_members_are_absent(self):
        self.assertEqual(internal_member_problems(self.scan, self.sections), [])


class SkippedTypeRunTest(unittest.TestCase):
    """
    A skipped or private type may hold `@internal` members. The generator, run
    over a small library, leaves the whole type out, and the check accepts that;
    a public type whose section is missing still counts as a problem.
    """

    BARREL = "library stellar_flutter_sdk;\n\nexport 'src/sample.dart';\n"
    SAMPLE = (
        "import 'package:meta/meta.dart';\n"
        '\n'
        "@Deprecated('Use Current')\n"
        'class Old {\n'
        '  @internal\n'
        '  void hidden() {}\n'
        '\n'
        '  void visible() {}\n'
        '}\n'
        '\n'
        'class Current {\n'
        '  @internal\n'
        '  void hidden() {}\n'
        '\n'
        '  void visible() {}\n'
        '}\n'
        '\n'
        'class _Cache {\n'
        '  @internal\n'
        '  void clearCache() {}\n'
        '}\n'
    )

    @classmethod
    def setUpClass(cls):
        cls._temp_dir = tempfile.TemporaryDirectory()
        root = Path(cls._temp_dir.name)
        (root / 'lib' / 'src').mkdir(parents=True)
        (root / 'lib' / 'stellar_flutter_sdk.dart').write_text(cls.BARREL, encoding='utf-8')
        (root / 'lib' / 'src' / 'sample.dart').write_text(cls.SAMPLE, encoding='utf-8')
        script = root / 'tools' / 'skill-generator' / 'generate_api_reference.py'
        script.parent.mkdir(parents=True)
        shutil.copy2(GENERATOR_DIR / 'generate_api_reference.py', script)
        cls.result = subprocess.run(
            [sys.executable, str(script)],
            capture_output=True, text=True, check=False,
        )
        cls.sections = read_sections(
            root / 'skills' / 'stellar-flutter-sdk' / 'references' / 'api_reference.md')
        cls.scan = scan_exported_sources(root / 'lib')

    @classmethod
    def tearDownClass(cls):
        cls._temp_dir.cleanup()

    def test_both_cases_are_present(self):
        self.assertEqual(self.result.returncode, 0, self.result.stderr[-2000:])
        self.assertEqual(self.scan.skipped_types, {'Old'})
        self.assertEqual(sorted(self.scan.internal_members),
                         [('Current', 'hidden'), ('Old', 'hidden'), ('_Cache', 'clearCache')])
        self.assertEqual(self.sections['Current']['members'], {'visible'})

    def test_skipped_type_with_internal_members_passes(self):
        self.assertNotIn('Old', self.sections)
        self.assertEqual(internal_member_problems(self.scan, self.sections), [])

    def test_private_type_with_internal_member_passes(self):
        self.assertNotIn('_Cache', self.sections)
        self.assertNotIn('_Cache has no section', internal_member_problems(self.scan, self.sections))

    def test_missing_public_section_still_fails(self):
        sections = {name: section for name, section in self.sections.items() if name != 'Current'}
        self.assertEqual(internal_member_problems(self.scan, sections), ['Current has no section'])


if __name__ == '__main__':
    unittest.main()
