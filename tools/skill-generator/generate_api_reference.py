#!/usr/bin/env python3
"""
Stellar Flutter SDK API Reference Generator

Generates a compact markdown file listing the public API signatures for the
stellar_flutter_sdk package by parsing Dart source files. Handled declaration
kinds: class, mixin, mixin class, enum (including enhanced-enum fields,
constants, and constructors), extension, and typedef. Member extraction covers
fields (typed and inferred), const/factory constructors, getters, setters,
methods (including generic methods), and operators.

A declaration is treated as public when its declaring file is reachable from
the public barrel (lib/stellar_flutter_sdk.dart) via the transitive export
graph and the declared name is not underscore-prefixed.

Usage: python3 generate_api_reference.py
"""

from __future__ import annotations

import os
import re
import sys
import traceback
from pathlib import Path
from dataclasses import dataclass, field

# Configuration — paths derived from script location
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
SDK_PATH = REPO_ROOT / "lib" / "src"
LIB_PATH = REPO_ROOT / "lib"
BARREL_PATH = REPO_ROOT / "lib" / "stellar_flutter_sdk.dart"
OUTPUT_PATH = REPO_ROOT / "skills" / "stellar-flutter-sdk" / "references" / "api_reference.md"

# Package import prefix used by `package:...` export URIs.
PACKAGE_PREFIX = "package:stellar_flutter_sdk/"

# Directories to skip entirely
SKIP_DIRS = {"xdr"}

# Files to skip (stubs, internals)
SKIP_FILES = {"http_client_io.dart", "http_client_stub.dart",
              "soroban_http_io.dart", "soroban_http_stub.dart"}

# Object members and other inherited noise that we intentionally never emit.
OBJECT_GETTERS = frozenset({"hashCode", "runtimeType"})
SUPPRESSED_METHODS = frozenset({"toString", "hashCode", "noSuchMethod"})
# Object operators/overrides that are intentionally suppressed from output but
# must be excluded from the member-level coverage scan so it does not flag them.
SUPPRESSED_MEMBER_NAMES = frozenset({"toString", "hashCode", "noSuchMethod", "runtimeType"})

# Tokens that can appear where a field type would be but are not real types,
# so a "Type name" field match starting with one of these is not a field.
NON_TYPE_KEYWORDS = frozenset({
    "return", "if", "for", "while", "switch", "throw", "await",
    "class", "abstract", "import", "export", "new", "super", "this",
    "assert", "yield", "do", "else", "try", "catch", "finally", "rethrow",
})

# Enum-value scan noise: identifiers that are not enum value names.
ENUM_VALUE_NOISE = frozenset({"const", "final"})

# Field/declaration modifier keywords handled explicitly by the field branch.
FIELD_MODIFIERS = ("static", "late", "final", "var", "const")

# Operators supported by the operator branch (longest first so multi-char
# operators are matched before their single-char prefixes).
OPERATORS = [
    "[]=", "[]", "<<", ">>", "<=", ">=", "==",
    "~/", "+", "-", "*", "/", "%", "&", "|", "^", "~", "<", ">",
]
_OPERATOR_ALT = "|".join(re.escape(op) for op in OPERATORS)

# Render order for class/extension/enum member buckets. The single source of
# truth for which buckets exist and the order they are emitted in. Adding a
# bucket requires editing this tuple (and the ClassInfo dataclass).
MEMBER_FIELDS = ("constants", "fields", "constructors", "getters", "setters", "methods")

# Group titles (order matters for output)
GROUP_TITLES = {
    "core": "Core Classes",
    "requests": "Requests (Query Builders)",
    "responses": "Responses",
    "soroban": "Soroban",
    "sep": "SEP (Stellar Ecosystem Proposals)",
    # Note: the lib/src/eventsource directory is not reachable from the public
    # barrel (lib/stellar_flutter_sdk.dart), so no class is ever grouped under
    # it. No "eventsource" group title is defined here for that reason.
    "constants": "Constants",
}


@dataclass
class ClassInfo:
    """Parsed class/mixin/enum/extension/typedef information."""
    name: str
    kind: str = ""  # "abstract class", "final class", "mixin", "enum", "extension", "typedef", ...
    parent: str = ""
    interfaces: list[str] = field(default_factory=list)
    mixins: list[str] = field(default_factory=list)
    constants: list[str] = field(default_factory=list)
    fields: list[str] = field(default_factory=list)
    constructors: list[str] = field(default_factory=list)
    methods: list[str] = field(default_factory=list)
    getters: list[str] = field(default_factory=list)
    setters: list[str] = field(default_factory=list)
    on_type: str = ""    # for extensions: the `on Type` target
    signature: str = ""  # for typedefs: the aliased signature shown as content

    def member_lines(self) -> list[str]:
        """All emitted member signature lines in render order."""
        lines: list[str] = []
        for bucket in MEMBER_FIELDS:
            lines.extend(getattr(self, bucket))
        return lines

    def member_count(self) -> int:
        """Number of emitted members across all buckets."""
        return sum(len(getattr(self, bucket)) for bucket in MEMBER_FIELDS)


def determine_group(rel_path: str) -> str:
    """Determine which group a file belongs to based on its relative path."""
    parts = rel_path.split(os.sep)
    if len(parts) > 1:
        subdir = parts[0]
        if subdir in GROUP_TITLES:
            return subdir
    return "core"


def is_private(name: str) -> bool:
    """Check if a Dart identifier is private (starts with _)."""
    return name.startswith('_')


def skip_string_literal(text: str, i: int) -> int:
    """
    Given that text[i] opens a string literal ('"' or "'"), return the index of
    the character immediately after the closing quote (or after the run of
    literal content for an unterminated single-line string). Handles triple- and
    single-quoted strings and backslash escapes.
    """
    n = len(text)
    quote = text[i]
    # Triple-quoted string
    if text[i:i + 3] in ('"""', "'''"):
        triple = text[i:i + 3]
        i += 3
        while i < n:
            if text[i:i + 3] == triple:
                return i + 3
            if text[i] == '\\':
                i += 2
            else:
                i += 1
        return n
    # Single-quoted string (terminates at quote or newline)
    i += 1
    while i < n and text[i] != quote and text[i] != '\n':
        if text[i] == '\\':
            i += 2
        else:
            i += 1
    if i < n and text[i] == quote:
        return i + 1
    return i


def strip_all_comments(content: str) -> str:
    """Remove all comments from Dart source, preserving string literals."""
    result = []
    i = 0
    n = len(content)
    while i < n:
        ch = content[i]
        # String literals — copy them intact
        if ch in ('"', "'"):
            end = skip_string_literal(content, i)
            result.append(content[i:end])
            i = end
        # Multi-line comments
        elif content[i:i + 2] == '/*':
            i += 2
            while i < n and content[i:i + 2] != '*/':
                # Preserve newlines for line counting
                if content[i] == '\n':
                    result.append('\n')
                i += 1
            i += 2  # skip */
        # Single-line comments
        elif content[i:i + 2] == '//':
            while i < n and content[i] != '\n':
                i += 1
        else:
            result.append(ch)
            i += 1
    return ''.join(result)


def balance(text: str, start: int, open_ch: str, close_ch: str) -> int:
    """
    Find the index of the closing delimiter matching the opening delimiter at
    `start`. String literals are skipped so delimiters inside strings do not
    affect the depth count.
    """
    depth = 0
    i = start
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return i
        elif ch in ('"', "'"):
            i = skip_string_literal(text, i)
            continue
        i += 1
    return n - 1


def balance_braces(text: str, start: int) -> int:
    """Find the closing brace matching the opening brace at `start`."""
    return balance(text, start, '{', '}')


def balance_parens(text: str, start: int) -> int:
    """Find the closing paren matching the opening paren at `start`."""
    return balance(text, start, '(', ')')


def compact_whitespace(s: str) -> str:
    """Normalize whitespace in a string."""
    return re.sub(r'\s+', ' ', s).strip()


# --- Per-line member classifier patterns (precompiled) ----------------------
# Each matches a single normalized top-level declaration line within a type body.

_STATIC_CONST_RE = re.compile(
    r'static\s+(?:const|final)\s+(?:([\w<>,?.\s]+?)\s+)?(\w+)\s*=\s*(.*)'
)
_GETTER_RE = re.compile(
    r'(static\s+)?([\w<>,?.\s]*?)\s*get\s+(\w+)(?:\s*=>.*)?'
)
_SETTER_RE = re.compile(r'set\s+(\w+)\s*\((.*?)\)')
_OPERATOR_RE = re.compile(
    r'([\w<>,?\s]+?)\s+operator\s*(' + _OPERATOR_ALT + r')\s*\('
)
# Method (and void) declarations, including an optional generic clause.
# The return-type alternation already covers `void`, so a single branch
# handles both. The generic clause `<...>` is balanced separately.
_METHOD_RE = re.compile(
    r'(static\s+)?'
    r'([\w.]+\s*<[\w<>,?.\s]+?>[?]?|[\w<>,?.]+)\s+'
    r'(\w+)\s*(<|\()'
)
# No-return-type method declarations: `[static] name(params)` (implicit
# dynamic return). The general method pattern requires a return-type token, so
# these would otherwise be dropped. Matched only after the typed-method branch.
_BARE_METHOD_RE = re.compile(r'(static\s+)?(\w+)\s*(?:<[^(]*>)?\s*\(')
# Field declarations: explicit modifier(s) then optional type then name.
_FIELD_RE = re.compile(
    r'((?:(?:static|late|final|var|const)\s+)*)'
    r'(?:([\w<>,?.\s]+?)\s+)?'
    r'(\w+)\s*(?:=.*)?$'
)


def _classify_operator(line: str, info: ClassInfo) -> bool:
    """Append an operator signature if `line` declares one. Returns True if matched."""
    m = _OPERATOR_RE.match(line)
    if not m:
        return False
    return_type = m.group(1).strip()
    op = m.group(2)
    # Locate the opening paren after the operator token.
    paren_start = line.index('(', m.start(2))
    paren_end = balance_parens(line, paren_start)
    params = compact_whitespace(line[paren_start + 1:paren_end])
    sig = ""
    if return_type:
        sig += f"{return_type} "
    sig += f"operator {op}({params})"
    info.methods.append(sig)
    return True


def _classify_method(line: str, info: ClassInfo, class_name: str) -> bool:
    """Append a method signature if `line` declares one. Returns True if matched."""
    m = _METHOD_RE.match(line)
    if not m:
        return False
    is_static = bool(m.group(1))
    return_type = m.group(2).strip()
    method_name = m.group(3)

    if is_private(method_name):
        return True  # consumed (private), do not fall through
    if method_name == class_name:
        return False  # this is a constructor; let the field/other branches skip it
    if method_name in SUPPRESSED_METHODS:
        return True

    # Resolve an optional generic clause before the parameter list.
    delim_pos = m.start(4)
    if line[delim_pos] == '<':
        generic_end = balance(line, delim_pos, '<', '>')
        # If the `<...>` is not a method type-parameter clause immediately
        # followed by `(`, this line is not a method (e.g. a typed field like
        # `final List<String>? transports`). Defer to the field branch.
        rest = line[generic_end + 1:].lstrip()
        if not rest.startswith('('):
            return False
        generic = line[delim_pos:generic_end + 1]
        paren_search = generic_end + 1
    else:
        generic = ""
        paren_search = delim_pos
    paren_start = line.index('(', paren_search)
    paren_end = balance_parens(line, paren_start)
    params = compact_whitespace(line[paren_start + 1:paren_end])

    after = line[paren_end + 1:].strip()
    is_async = after.startswith('async')

    sig = ""
    if is_static:
        sig += "static "
    sig += f"{return_type} {method_name}{generic}({params})"
    if is_async:
        sig += " async"
    info.methods.append(sig)
    return True


def extract_top_level_members(body: str, class_name: str) -> ClassInfo:
    """
    Extract public members from a class body by tokenizing top-level
    declarations (depth 0 — not inside nested braces) and classifying each.
    """
    info = ClassInfo(name=class_name)
    for kind, line in _split_top_level_declarations(body):
        _classify_member(line, info, class_name)
    return info


def _split_top_level_declarations(body: str) -> list[tuple[str, str]]:
    """
    Tokenize a type body into top-level declaration units. Each unit is a
    ('block_start' | 'statement', text) tuple where `text` is the normalized
    declaration prefix up to its `{` (block_start) or `;` (statement). Nested
    braces and string literals are skipped.
    """
    decls: list[tuple[str, str]] = []
    current_line: list[str] = []
    depth = 0
    i = 0
    n = len(body)

    while i < n:
        ch = body[i]

        if ch in ('"', "'"):
            end = skip_string_literal(body, i)
            current_line.append(body[i:end])
            i = end
            continue

        if ch == '{':
            if depth == 0:
                # Start of a method/getter/setter/constructor body.
                line_text = ''.join(current_line).strip()
                if line_text:
                    decls.append(('block_start', line_text))
                current_line = []
                # Skip to matching }.
                i = balance_braces(body, i) + 1
                continue
            else:
                depth += 1
        elif ch == '}':
            depth -= 1
        elif ch == ';' and depth == 0:
            line_text = ''.join(current_line).strip()
            if line_text:
                decls.append(('statement', line_text))
            current_line = []
            i += 1
            continue
        elif ch == '\n' and depth == 0:
            # Don't split on newline — Dart declarations can span multiple lines.
            current_line.append(' ')
            i += 1
            continue

        current_line.append(ch)
        i += 1

    remaining = ''.join(current_line).strip()
    if remaining:
        decls.append(('statement', remaining))
    return decls


def _classify_member(line: str, info: ClassInfo, class_name: str) -> None:
    """Classify a single normalized declaration line into the appropriate bucket."""
    line = compact_whitespace(line)

    # Remove annotations like @override, @visibleForTesting, @Deprecated, etc.
    line = re.sub(r'@\w+(?:\([^)]*\))?\s*', '', line).strip()
    if not line:
        return

    # --- Static const / static final ---
    m = _STATIC_CONST_RE.match(line)
    if m:
        type_hint = (m.group(1) or "").strip()
        name = m.group(2)
        if not is_private(name):
            if type_hint:
                info.constants.append(f"static const {type_hint} {name}")
            else:
                info.constants.append(f"static const {name}")
        return

    # --- Getters ---
    # Pattern: [static] ReturnType get name
    m = _GETTER_RE.match(line)
    if m and m.group(3) and not is_private(m.group(3)):
        is_static = bool(m.group(1))
        return_type = (m.group(2) or "").strip()
        name = m.group(3)
        if name in OBJECT_GETTERS:
            return
        sig = ""
        if is_static:
            sig += "static "
        if return_type:
            sig += f"{return_type} "
        sig += f"get {name}"
        info.getters.append(sig)
        return

    # --- Setters ---
    m = _SETTER_RE.match(line)
    if m:
        name = m.group(1)
        params = compact_whitespace(m.group(2))
        if not is_private(name):
            info.setters.append(f"set {name}({params})")
        return

    # --- Operators ---
    if _classify_operator(line, info):
        return

    # --- Constructors (const / factory / const factory / plain, named or not) ---
    ctor_pattern = (
        r'(const\s+factory\s+|factory\s+|const\s+)?'
        rf'({re.escape(class_name)}(?:\.\w+)?)\s*\('
    )
    m = re.match(ctor_pattern, line)
    if m:
        modifier = (m.group(1) or "").strip()
        ctor_name = m.group(2)
        # Skip private named constructors (e.g. `ClassName._()`).
        if '.' in ctor_name and is_private(ctor_name.split('.', 1)[1]):
            return
        paren_start = line.index('(')
        paren_end = balance_parens(line, paren_start)
        params = compact_whitespace(line[paren_start + 1:paren_end])
        sig = ""
        if modifier:
            sig += f"{modifier} "
        sig += f"{ctor_name}({params})"
        info.constructors.append(sig)
        return

    # --- Methods (including generic methods and void) ---
    if _classify_method(line, info, class_name):
        return

    # --- No-return-type methods (implicit dynamic): `name(params)` ---
    m = _BARE_METHOD_RE.match(line)
    if m and m.group(2) != class_name:
        is_static = bool(m.group(1))
        method_name = m.group(2)
        if is_private(method_name):
            return
        if method_name in SUPPRESSED_METHODS or method_name in NON_TYPE_KEYWORDS:
            return
        paren_start = line.index('(', m.start(2))
        paren_end = balance_parens(line, paren_start)
        params = compact_whitespace(line[paren_start + 1:paren_end])
        after = line[paren_end + 1:].strip()
        is_async = after.startswith('async')
        sig = ""
        if is_static:
            sig += "static "
        sig += f"{method_name}({params})"
        if is_async:
            sig += " async"
        info.methods.append(sig)
        return

    # --- Fields (instance variables, typed or inferred) ---
    m = _FIELD_RE.match(line)
    if m:
        modifiers = compact_whitespace(m.group(1) or "")
        type_str = (m.group(2) or "").strip()
        name = m.group(3)
        if is_private(name):
            return
        # A leading non-type keyword without an explicit modifier means this is
        # not a field declaration (e.g. `return foo`).
        if not modifiers and type_str in NON_TYPE_KEYWORDS:
            return
        if type_str in NON_TYPE_KEYWORDS:
            return
        prefix = f"{modifiers} " if modifiers else ""
        if type_str:
            info.fields.append(f"{prefix}{type_str} {name}")
        else:
            # Inferred-type field (e.g. `final foo = X();` / `var n = 42;`).
            # Only meaningful with a modifier; bare `name` lines are not fields.
            if modifiers:
                info.fields.append(f"{prefix}{name}")
        return


# Broad secondary regex matching every top-level public declaration name across
# all kinds. Used only by the coverage sanity scan — diagnostic, never affects
# what is emitted.
_SANITY_DECL_RE = re.compile(
    r'^[ \t]*'
    r'(?:(?:abstract|final|sealed|base|interface)\s+)*'
    r'(?:'
    r'(?:mixin\s+class|class|mixin|enum)\s+(?P<cls>[A-Za-z]\w*)'
    r'|extension\s+(?P<ext>[A-Za-z]\w*)\s*(?:<[^{]*?>)?\s+on\b'
    r'|typedef\s+(?:[\w<>,?\s.]+?\s+)?(?P<td>[A-Za-z]\w*)\s*(?:<[^=;{(]*>)?\s*[=(]'
    r')',
    re.MULTILINE
)

_SANITY_OPERATOR_RE = re.compile(r'\boperator\s*(?:\[\]=|\[\]|<<|>>|<=|>=|==|~/|[+\-*/%&|^~<>])\s*\(')
_SANITY_GETTER_RE = re.compile(r'(?:[\w<>,?\s.]+?\s+)?get\s+(?P<name>[A-Za-z]\w*)\b')
_SANITY_SETTER_RE = re.compile(r'(?:static\s+)?set\s+(?P<name>[A-Za-z]\w*)\s*\(')
_SANITY_TRAILING_NAME_RE = re.compile(r'(?:^|[^\w$])(?P<name>[A-Za-z]\w*)\s*(?:<[^(<>]*>)?\s*$')
_SANITY_FIELD_RE = re.compile(
    r'(?:(?:static|late|final|var|const|covariant|external)\s+)*'
    r'(?:[\w<>,?\s.]+\s+)?(?P<name>[A-Za-z]\w*)\s*(?:=.*)?$'
)


def scan_public_member_count(body: str, type_name: str) -> int:
    """
    Broad member-level scan over a type body: count public, non-underscore
    member-like lines (methods, constructors, operators, getters, setters,
    fields, enum values). Only top-level (depth-0) declarations are considered —
    statements nested inside method bodies are skipped via the same tokenizer
    the emitter uses. Suppressed Object overrides (toString/hashCode/etc.) are
    excluded so the scan matches what the emitter intentionally drops.
    Diagnostic only; never influences emitted output.
    """
    count = 0
    for _kind, raw in _split_top_level_declarations(body):
        line = compact_whitespace(raw)
        line = re.sub(r'@\w+(?:\([^)]*\))?\s*', '', line).strip()
        if not line:
            continue

        if _SANITY_OPERATOR_RE.search(line):
            count += 1
            continue

        m = _SANITY_GETTER_RE.match(line)
        if m and re.match(r'(?:[\w<>,?\s.]+?\s+)?get\s', line):
            if _is_countable_member(m.group('name')):
                count += 1
            continue

        m = _SANITY_SETTER_RE.match(line)
        if m:
            if _is_countable_member(m.group('name')):
                count += 1
            continue

        # Callable (method / constructor / enum value): name is the identifier
        # (with optional generic clause) immediately preceding the first
        # top-level `(`. Find that paren by balance-aware scanning so a nested
        # `(` inside the parameter list cannot be mistaken for the signature.
        # A top-level `=` before the paren means the paren belongs to a field
        # initializer (e.g. `final x = Foo.bar(...)`), not a signature.
        paren = _first_top_level_paren(line)
        assign = _first_top_level_assign(line)
        if paren != -1 and (assign == -1 or assign > paren):
            name_m = _SANITY_TRAILING_NAME_RE.search(line[:paren])
            if name_m:
                if _is_countable_member(name_m.group('name')):
                    count += 1
                continue
            # No identifier before the paren — not a member-shaped declaration.
            continue

        # Field (no parameter list).
        m = _SANITY_FIELD_RE.match(line)
        if m and _is_countable_member(m.group('name')):
            count += 1

    return count


def _first_top_level_paren(line: str) -> int:
    """Return the index of the first `(` not inside a string literal, or -1."""
    i = 0
    n = len(line)
    while i < n:
        ch = line[i]
        if ch in ('"', "'"):
            i = skip_string_literal(line, i)
            continue
        if ch == '(':
            return i
        i += 1
    return -1


def _first_top_level_assign(line: str) -> int:
    """
    Return the index of the first `=` that is a plain assignment (not `==`,
    `<=`, `>=`, `!=`, `=>`) and not inside a string literal, or -1.
    """
    i = 0
    n = len(line)
    while i < n:
        ch = line[i]
        if ch in ('"', "'"):
            i = skip_string_literal(line, i)
            continue
        if ch == '=':
            prev = line[i - 1] if i > 0 else ''
            nxt = line[i + 1] if i + 1 < n else ''
            if nxt != '=' and prev not in ('=', '<', '>', '!'):
                return i
        i += 1
    return -1


def _is_countable_member(name: str | None) -> bool:
    """True if a scanned member name should be counted (public, not suppressed)."""
    if not name or is_private(name):
        return False
    if name in SUPPRESSED_MEMBER_NAMES or name in NON_TYPE_KEYWORDS:
        return False
    return True


def scan_enum_value_count(body: str) -> int:
    """Count public enum values in the pre-`;` section of an enum body."""
    semi = body.find(';')
    values_section = body if semi == -1 else body[:semi]
    count = 0
    for vm in re.finditer(r'(\w+)(?:\s*\([^)]*\))?', values_section):
        val_name = vm.group(1)
        if not is_private(val_name) and val_name not in ENUM_VALUE_NOISE:
            count += 1
    return count


def _extract_export_targets(export_clean: str) -> list[str]:
    """
    Extract the resolvable target URI(s) from a single `export '...';` clause
    (comments already stripped from the input).

    Plain export:        export 'a/b.dart';            -> ['a/b.dart']
    Conditional export:  export 'stub.dart'
                             if (dart.library.js_interop) 'impl.dart';

    For conditional exports we deliberately select ONLY the `if (...)` target
    (the platform implementation, e.g. the Flutter-web variant) and drop the
    default token (the stub). This guarantees a single allowlisted variant so
    the public class is emitted exactly once with its real signature.
    """
    uris = re.findall(r"'([^']+)'", export_clean)
    if not uris:
        return []
    start = 1 if ('if (' in export_clean and len(uris) >= 2) else 0
    return [u for u in uris[start:] if u.endswith('.dart')]


def _resolve_export_uri(uri: str, current_file: Path) -> Path | None:
    """
    Resolve an export URI to an absolute path under lib/.

    Handles relative-to-file URIs and `package:stellar_flutter_sdk/...` URIs.
    Returns None for non-package external URIs (e.g. dart:io).
    """
    if uri.startswith('dart:'):
        return None
    if uri.startswith(PACKAGE_PREFIX):
        rel = uri.removeprefix(PACKAGE_PREFIX)
        return (LIB_PATH / rel).resolve()
    if uri.startswith('package:'):
        return None
    # Relative to the directory of the exporting file
    return (current_file.parent / uri).resolve()


def _collect_exports(clean_text: str, source_file: Path) -> list[Path]:
    """Resolve all export target paths declared in already-cleaned `clean_text`."""
    resolved_paths: list[Path] = []
    for stmt in re.finditer(r'export\b([^;]*);', clean_text):
        for uri in _extract_export_targets(stmt.group(1)):
            resolved = _resolve_export_uri(uri, source_file)
            if resolved:
                resolved_paths.append(resolved)
    return resolved_paths


def build_export_allowlist() -> set[Path]:
    """
    Build the transitive set of source files reachable from the public barrel
    (lib/stellar_flutter_sdk.dart) via `export` statements.

    Only classes declared in files within this set are emitted, mirroring the
    public API surface authority of the barrel.
    """
    allow: set[Path] = set()
    worklist: list[Path] = [BARREL_PATH]

    while worklist:
        current = worklist.pop()
        if not current.exists():
            print(f"WARNING: export target does not exist, skipping: {current}",
                  file=sys.stderr)
            continue
        try:
            clean = strip_all_comments(current.read_text(encoding='utf-8'))
        except (OSError, UnicodeDecodeError) as e:
            print(f"WARNING: could not read export target {current}: {e}",
                  file=sys.stderr)
            continue
        for resolved in _collect_exports(clean, current):
            if resolved not in allow:
                allow.add(resolved)
                worklist.append(resolved)

    return allow


def scan_public_declaration_names(filepath: Path) -> set[str]:
    """
    Broad secondary scan: return the set of every top-level public declaration
    name in a file across all kinds (class incl. modifiers, mixin class, mixin,
    enum, extension, typedef). Public = does not start with underscore.

    Diagnostic only (coverage sanity scan); never influences emitted output.
    """
    try:
        clean = strip_all_comments(filepath.read_text(encoding='utf-8'))
    except (OSError, UnicodeDecodeError) as e:
        print(f"WARNING: could not read {filepath} for sanity scan: {e}",
              file=sys.stderr)
        return set()
    names: set[str] = set()
    for m in _SANITY_DECL_RE.finditer(clean):
        name = m.group('cls') or m.group('ext') or m.group('td')
        if name and not is_private(name):
            names.add(name)
    return names


# Top-level type-declaration patterns (precompiled).
_CLASS_RE = re.compile(
    r'^[ \t]*((?:(?:abstract|final|sealed|base|interface)\s+)*)'
    r'(mixin\s+class|class|mixin|enum)\s+'
    r'(\w+)\s*(?:<[^{]*?>)?'
    r'((?:\s+extends\s+[\w<>,?\s]+?)?)'
    r'((?:\s+with\s+[\w<>,\s]+?)?)'
    r'((?:\s+implements\s+[\w<>,\s]+?)?)'
    r'\s*\{',
    re.MULTILINE
)
_EXT_RE = re.compile(
    r'^[ \t]*extension\s+(?:(\w+)\s*(?:<[^{]*?>)?\s+)?on\s+([\w<>,?\s.]+?)\s*\{',
    re.MULTILINE
)
_TYPEDEF_RE = re.compile(r'^[ \t]*typedef\s+([^;{]+?)\s*;', re.MULTILINE)


def parse_dart_file(filepath: Path) -> list[ClassInfo]:
    """Parse a Dart file and extract all public classes with their members."""
    content = filepath.read_text(encoding='utf-8')
    clean = strip_all_comments(content)
    results: list[ClassInfo] = []

    # --- Classes / mixins / mixin classes / enums ---
    for m in _CLASS_RE.finditer(clean):
        modifiers_str = compact_whitespace(m.group(1) or "")
        kind_word = compact_whitespace(m.group(2))  # "mixin class", "class", "mixin", "enum"
        class_name = m.group(3)
        extends_str = (m.group(4) or "").strip()
        with_str = (m.group(5) or "").strip()
        implements_str = (m.group(6) or "").strip()

        if is_private(class_name):
            continue

        is_enum = (kind_word == "enum")
        if modifiers_str:
            display_kind = f"{modifiers_str} {kind_word}".strip()
        elif kind_word == "class":
            display_kind = ""
        else:
            display_kind = kind_word

        parent = ""
        if extends_str:
            parent = re.sub(r'^extends\s+', '', extends_str).strip()
        mixins = []
        if with_str:
            mixins_raw = re.sub(r'^with\s+', '', with_str).strip()
            mixins = [x.strip() for x in mixins_raw.split(',')]
        interfaces = []
        if implements_str:
            impl_raw = re.sub(r'^implements\s+', '', implements_str).strip()
            interfaces = [x.strip() for x in impl_raw.split(',')]

        brace_pos = m.end() - 1  # position of {
        body_end = balance_braces(clean, brace_pos)
        body = clean[brace_pos + 1:body_end]

        if is_enum:
            # Enum values precede the first semicolon; the trailing body (after
            # the semicolon) is parsed exactly like a normal class body so its
            # fields, constants, constructors, getters, setters, and methods are
            # all captured. Enum values are prepended to constants.
            semi_pos = body.find(';')
            values_section = body if semi_pos == -1 else body[:semi_pos]
            enum_values: list[str] = []
            for vm in re.finditer(r'(\w+)(?:\s*\([^)]*\))?', values_section):
                val_name = vm.group(1)
                if not is_private(val_name) and val_name not in ENUM_VALUE_NOISE:
                    enum_values.append(val_name)

            if semi_pos != -1:
                info = extract_top_level_members(body[semi_pos + 1:], class_name)
            else:
                info = ClassInfo(name=class_name)
            info.constants = enum_values + info.constants
            info.kind = "enum"
        else:
            info = extract_top_level_members(body, class_name)
            info.kind = display_kind

        info.parent = parent
        info.mixins = mixins
        info.interfaces = interfaces
        results.append(info)

    # --- Extensions ---
    for m in _EXT_RE.finditer(clean):
        ext_name = m.group(1)
        on_type = compact_whitespace(m.group(2) or "")
        if ext_name and is_private(ext_name):
            continue
        brace_pos = m.end() - 1
        body_end = balance_braces(clean, brace_pos)
        body = clean[brace_pos + 1:body_end]
        members = extract_top_level_members(body, ext_name or "")
        if not ext_name:
            if not on_type or members.member_count() == 0:
                continue
            members.name = f"extension on {on_type}"
        else:
            members.name = ext_name
        members.kind = "extension"
        members.on_type = on_type
        results.append(members)

    # --- Typedefs ---
    # Modern:  typedef Name<...> = <aliased>;
    # Legacy:  typedef ReturnType Name(args);
    for m in _TYPEDEF_RE.finditer(clean):
        decl = compact_whitespace(m.group(1))
        eq = decl.find('=')
        if eq != -1:
            lhs = decl[:eq].strip()
            name_m = re.match(r'(\w+)', lhs)
            if not name_m:
                continue
            td_name = name_m.group(1)
        else:
            paren = decl.find('(')
            if paren == -1:
                continue
            name_m = re.search(r'(\w+)\s*$', decl[:paren])
            if not name_m:
                continue
            td_name = name_m.group(1)
        if is_private(td_name):
            continue
        info = ClassInfo(name=td_name)
        info.kind = "typedef"
        info.signature = f"typedef {decl}"
        results.append(info)

    return results


def format_class_header(info: ClassInfo) -> str:
    """Format the class header line."""
    if info.kind == "typedef":
        return f"## typedef {info.name}"
    if info.kind == "extension":
        header = f"## extension {info.name}"
        if info.on_type and not info.name.startswith("extension on "):
            header += f" on {info.on_type}"
        return header
    header = "## "
    if info.kind:
        header += f"{info.kind} "
    header += info.name
    if info.parent:
        header += f" extends {info.parent}"
    if info.mixins:
        header += f" with {', '.join(info.mixins)}"
    if info.interfaces:
        header += f" implements {', '.join(info.interfaces)}"
    return header


def format_class_section(info: ClassInfo) -> str:
    """Format a complete class section for markdown output."""
    lines = [format_class_header(info)]

    if info.kind == "typedef" and info.signature:
        lines.append(info.signature)
        lines.append("")
        return "\n".join(lines)

    lines.extend(info.member_lines())
    lines.append("")  # blank line between classes
    return "\n".join(lines)


def collect_classes(
    allowlist: set[Path],
    stats: dict,
    scanned_by_file: dict[Path, set[str]],
    emitted_by_file: dict[Path, set[str]],
    member_gaps: list[tuple[str, str, int, int]],
) -> dict[str, list[ClassInfo]]:
    """
    Walk the SDK source, parse each barrel-allowlisted file, and group the
    parsed classes. Populates `stats` and the coverage-scan tracking dicts.
    """
    groups: dict[str, list[ClassInfo]] = {k: [] for k in GROUP_TITLES}

    for root, dirs, files in os.walk(SDK_PATH):
        # Skip excluded directories in place (preserving the skip count).
        kept = []
        for d in dirs:
            if d in SKIP_DIRS:
                stats["skipped_dirs"] += 1
            else:
                kept.append(d)
        dirs[:] = kept

        for fname in sorted(files):
            if not fname.endswith('.dart') or fname in SKIP_FILES:
                continue

            filepath = Path(root) / fname
            rel_path = os.path.relpath(filepath, SDK_PATH)
            group = determine_group(rel_path)

            # Honor the barrel: only emit classes from files in the export graph.
            if filepath.resolve() not in allowlist:
                stats["skipped_files_not_exported"] += 1
                continue

            try:
                content = filepath.read_text(encoding='utf-8')
                clean = strip_all_comments(content)
                classes = parse_dart_file(filepath)
                stats["files"] += 1

                resolved_fp = filepath.resolve()
                scanned_by_file[resolved_fp] = scan_public_declaration_names(filepath)
                emitted_by_file.setdefault(resolved_fp, set())

                # Member-level coverage: compare the broad member scan over each
                # type body against the member count actually emitted.
                for cls in classes:
                    member_count = cls.member_count()
                    stats["classes"] += 1
                    stats["members"] += member_count
                    groups[group].append(cls)
                    emitted_by_file[resolved_fp].add(cls.name)
                    print(f"  {rel_path}: {cls.name} ({member_count} members)",
                          file=sys.stderr)

                    if cls.kind in ("typedef",):
                        continue
                    body = _find_type_body(clean, cls)
                    if body is None:
                        continue
                    if cls.kind == "enum":
                        semi = body.find(';')
                        trailing = body if semi == -1 else body[semi + 1:]
                        scanned = scan_enum_value_count(body) + scan_public_member_count(trailing, cls.name)
                    else:
                        scanned = scan_public_member_count(body, cls.name)
                    if scanned > member_count:
                        member_gaps.append((cls.name, rel_path, scanned, member_count))

            except (OSError, UnicodeDecodeError, ValueError) as e:
                print(f"  ERROR parsing {rel_path}: {e}", file=sys.stderr)
                traceback.print_exc(file=sys.stderr)
                stats["errors"] += 1

    return groups


def _find_type_body(clean: str, cls: ClassInfo) -> str | None:
    """
    Locate the brace-delimited body of a parsed type within cleaned source, for
    the member-level coverage scan. Returns None for extensions/typedefs or when
    the declaration cannot be re-located.
    """
    if cls.kind == "extension":
        return None
    name = re.escape(cls.name)
    if cls.kind == "enum":
        decl_re = re.compile(rf'\benum\s+{name}\b[^{{]*\{{', re.MULTILINE)
    else:
        decl_re = re.compile(
            r'\b(?:mixin\s+class|class|mixin)\s+' + name + r'\b[^{]*\{',
            re.MULTILINE
        )
    m = decl_re.search(clean)
    if not m:
        return None
    brace_pos = m.end() - 1
    body_end = balance_braces(clean, brace_pos)
    return clean[brace_pos + 1:body_end]


def report_coverage(
    scanned_by_file: dict[Path, set[str]],
    emitted_by_file: dict[Path, set[str]],
    member_gaps: list[tuple[str, str, int, int]],
) -> int:
    """
    Run both coverage sanity scans (name-level and member-level) and report on
    stderr. Returns the total number of unemitted public symbols found.
    """
    # Name-level coverage scan.
    missing: list[tuple[str, str]] = []
    for resolved_fp, scanned_names in scanned_by_file.items():
        emitted_names = emitted_by_file.get(resolved_fp, set())
        for name in sorted(scanned_names - emitted_names):
            try:
                rel = os.path.relpath(resolved_fp, SDK_PATH)
            except ValueError:
                rel = str(resolved_fp)
            missing.append((name, rel))

    if missing:
        print(f"\nWARNING: {len(missing)} public declaration(s) in allowlisted "
              f"files were not emitted:", file=sys.stderr)
        for name, rel in missing:
            print(f"  - {name}  ({rel})", file=sys.stderr)
    else:
        print("\nCoverage sanity scan (name-level): 0 unemitted public declarations.",
              file=sys.stderr)

    # Member-level coverage scan.
    if member_gaps:
        print(f"\nWARNING: {len(member_gaps)} type(s) have unemitted public "
              f"members (source count exceeds emitted count):", file=sys.stderr)
        for name, rel, scanned, emitted in member_gaps:
            print(f"  - {name}  ({rel}): scanned {scanned}, emitted {emitted} "
                  f"(gap {scanned - emitted})", file=sys.stderr)
    else:
        print("Coverage sanity scan (member-level): 0 types with unemitted members.",
              file=sys.stderr)

    return len(missing) + len(member_gaps)


def render_markdown(groups: dict[str, list[ClassInfo]], stats: dict) -> str:
    """Render the full markdown document from grouped classes."""
    parts: list[str] = []
    parts.append("# Flutter SDK API Reference (Signatures)\n\n")
    parts.append("Compact method signature reference for `stellar_flutter_sdk`.\n")
    parts.append("Generated by `generate_api_reference.py`. Do not edit manually.\n\n")
    parts.append(f"**Stats:** {stats['classes']} classes, {stats['members']} members\n\n")

    for group_key, title in GROUP_TITLES.items():
        class_list = groups[group_key]
        if not class_list:
            continue
        parts.append("---\n")
        parts.append(f"## {title}\n")
        parts.append("---\n\n")
        for cls in class_list:
            parts.append(format_class_section(cls))

    return "".join(parts)


def main() -> None:
    """Generate the API reference markdown and exit nonzero on any regression."""
    if not SDK_PATH.exists():
        print(f"ERROR: SDK source not found at {SDK_PATH}", file=sys.stderr)
        print(f"Clone it first: git clone https://github.com/Soneso/stellar_flutter_sdk.git {SDK_PATH.parent}", file=sys.stderr)
        sys.exit(1)
    if not BARREL_PATH.exists():
        print(f"ERROR: public barrel not found at {BARREL_PATH}", file=sys.stderr)
        print(f"Clone it first: git clone https://github.com/Soneso/stellar_flutter_sdk.git {BARREL_PATH.parent.parent}", file=sys.stderr)
        sys.exit(1)

    print(f"Scanning Dart files in {SDK_PATH}...", file=sys.stderr)

    # Build the public-API allowlist from the barrel's transitive export graph.
    allowlist = build_export_allowlist()
    print(f"Barrel export allowlist: {len(allowlist)} reachable files", file=sys.stderr)

    stats = {"files": 0, "classes": 0, "members": 0, "skipped_dirs": 0,
             "errors": 0, "skipped_files_not_exported": 0}

    # Coverage sanity scan tracking.
    emitted_by_file: dict[Path, set[str]] = {}
    scanned_by_file: dict[Path, set[str]] = {}
    member_gaps: list[tuple[str, str, int, int]] = []

    groups = collect_classes(allowlist, stats, scanned_by_file,
                             emitted_by_file, member_gaps)

    unemitted = report_coverage(scanned_by_file, emitted_by_file, member_gaps)

    # Sort classes within each group alphabetically.
    for group in groups.values():
        group.sort(key=lambda c: c.name)

    md = render_markdown(groups, stats)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(md, encoding='utf-8')

    print("\n=== Generation Complete ===", file=sys.stderr)
    print(f"Files processed: {stats['files']}", file=sys.stderr)
    print(f"Classes extracted: {stats['classes']}", file=sys.stderr)
    print(f"Total members: {stats['members']}", file=sys.stderr)
    print(f"Directories skipped: {stats['skipped_dirs']}", file=sys.stderr)
    print(f"Files skipped (not barrel-exported): {stats['skipped_files_not_exported']}", file=sys.stderr)
    print(f"Errors: {stats['errors']}", file=sys.stderr)
    print(f"Output written to: {OUTPUT_PATH}", file=sys.stderr)
    print(f"File size: {OUTPUT_PATH.stat().st_size:,} bytes", file=sys.stderr)

    if stats["errors"] > 0 or unemitted > 0:
        print("FAILURE: errors or unemitted public symbols detected; "
              "see warnings above.", file=sys.stderr)
        sys.exit(1)

    print("API reference generated successfully!")


if __name__ == "__main__":
    main()
