#!/usr/bin/env python3
"""
Split 32 XDR classes into base+wrapper pairs.

For each target class, creates a base file (standard encode/decode only)
and modifies the wrapper file to extend the base with custom methods.

Usage:
    python3 tools/split_xdr_wrappers.py [--dry-run] [--only CLASS_NAME]
"""

import re
import sys
import argparse
from pathlib import Path
from dataclasses import dataclass, field

ROOT = Path(__file__).resolve().parent.parent
XDR_DIR = ROOT / "lib" / "src" / "xdr"

COPYRIGHT = """\
// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.
"""

# ---------------------------------------------------------------------------
# Target classes grouped by category
# ---------------------------------------------------------------------------

# Union types with custom factories
UNION_CLASSES = {
    "XdrSCVal", "XdrSCSpecTypeDef", "XdrLedgerKey", "XdrHostFunction",
    "XdrSCAddress", "XdrSorobanAuthorizedFunction", "XdrSorobanCredentials",
    "XdrContractIDPreimage", "XdrContractExecutable", "XdrClaimableBalanceID",
    "XdrPublicKey",
}

# Sequential types with helpers
SEQUENTIAL_CLASSES = {
    "XdrAccountID", "XdrMuxedAccountMed25519",
    "XdrInt128Parts", "XdrUInt128Parts",
    "XdrInt256Parts", "XdrUInt256Parts",
    "XdrLedgerKeyOffer", "XdrLedgerKeyData",
}

# Base64/envelope-only — mix of union and sequential
BASE64_UNION_CLASSES = {
    "XdrTransactionMeta", "XdrTransactionEnvelope", "XdrLedgerEntryData",
}
BASE64_SEQUENTIAL_CLASSES = {
    "XdrTransactionResult", "XdrLedgerEntry", "XdrLedgerEntryChanges",
    "XdrSorobanTransactionData", "XdrContractEvent", "XdrDiagnosticEvent",
    "XdrTransactionEvent", "XdrLedgerFootprint",
}

# Existing inheritance (extends XdrAsset)
EXTENDS_ASSET_CLASSES = {
    "XdrChangeTrustAsset", "XdrTrustlineAsset",
}

ALL_TARGETS = (UNION_CLASSES | SEQUENTIAL_CLASSES |
               BASE64_UNION_CLASSES | BASE64_SEQUENTIAL_CLASSES |
               EXTENDS_ASSET_CLASSES)

# SDK-specific imports that should stay in wrapper only
SDK_IMPORT_PATTERNS = {
    "key_pair.dart", "soroban_auth.dart", "util.dart", "bit_constants.dart",
}

# ---------------------------------------------------------------------------
# Filename utilities
# ---------------------------------------------------------------------------

def class_name_to_filename(name: str) -> str:
    """Convert class name to snake_case filename."""
    if name.startswith("Xdr"):
        stripped = name[3:]
    else:
        stripped = name
    s = re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', stripped)
    s = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1_\2', s)
    return f"xdr_{s.lower()}.dart"

def base_filename(wrapper_filename: str) -> str:
    """xdr_foo.dart -> xdr_foo_base.dart"""
    return wrapper_filename.replace('.dart', '_base.dart')

def base_class_name(class_name: str) -> str:
    """XdrFoo -> XdrFooBase"""
    return class_name + "Base"


# ---------------------------------------------------------------------------
# Class body parsing
# ---------------------------------------------------------------------------

@dataclass
class ParsedClass:
    """Parsed structure of an XDR class file."""
    class_name: str
    extends_class: str  # "" or "XdrAsset"
    file_imports: list  # All import lines from the file
    class_line: str     # The 'class Foo ...' line
    pre_encode: str     # Constructor + fields + getters/setters (before encode)
    encode_body: str    # The encode static method
    mid_section: str    # Custom methods between encode and decode
    decode_body: str    # The decode static method
    post_decode: str    # Custom methods (after decode)

    # Detected properties
    is_union: bool = False
    is_version_union: bool = False  # int discriminant
    disc_accessor: str = ""   # "discriminant", "type", or "getDiscriminant()"
    disc_field: str = ""      # "_type", "_v", "_kind", etc.
    disc_type: str = ""       # "XdrFooType", "int", etc.
    constructor_args: str = ""  # "this._type" or "this._field1, this._field2"


def find_method_bounds(lines: list[str], signature_pattern: str) -> tuple[int, int]:
    """Find start and end line indices of a method matching the signature pattern."""
    start = -1
    for i, line in enumerate(lines):
        if re.search(signature_pattern, line):
            start = i
            break

    if start == -1:
        return -1, -1

    # Track brace depth to find end
    depth = 0
    for j in range(start, len(lines)):
        depth += lines[j].count('{') - lines[j].count('}')
        if depth <= 0 and j > start:
            return start, j
        # Handle one-liner methods (arrow syntax on same line)
        if j == start and '=>' in lines[j] and lines[j].rstrip().endswith(';'):
            return start, j

    return start, len(lines) - 1


def parse_class_file(filepath: Path) -> ParsedClass:
    """Parse a single-class XDR file into structured components."""
    text = filepath.read_text()
    lines = text.split('\n')

    # Extract imports (before class)
    imports = []
    class_line_idx = -1
    for i, line in enumerate(lines):
        if line.startswith('import '):
            imports.append(line)
        if re.match(r'^class\s+\w+', line):
            class_line_idx = i
            break

    class_line = lines[class_line_idx]

    # Detect extends
    extends_match = re.search(r'\bextends\s+(\w+)', class_line)
    extends_class = extends_match.group(1) if extends_match else ""

    # Extract class name
    class_name = re.match(r'class\s+(\w+)', class_line).group(1)

    # Find class body end
    depth = 0
    class_end = class_line_idx
    for j in range(class_line_idx, len(lines)):
        depth += lines[j].count('{') - lines[j].count('}')
        if depth <= 0 and j > class_line_idx:
            class_end = j
            break

    # Work with lines inside the class body (after opening brace, before closing brace)
    body_lines = lines[class_line_idx + 1 : class_end]

    # Find encode method
    encode_start, encode_end = find_method_bounds(body_lines, r'^\s+static\s+void\s+encode\s*\(')

    # Find decode method
    decode_start, decode_end = find_method_bounds(body_lines, rf'^\s+static\s+{re.escape(class_name)}\s+decode\s*\(')

    if encode_start == -1 or decode_start == -1:
        raise ValueError(f"Could not find encode/decode in {filepath.name}")

    pre_encode = '\n'.join(body_lines[:encode_start])
    encode_body = '\n'.join(body_lines[encode_start:encode_end + 1])
    mid_section = '\n'.join(body_lines[encode_end + 1:decode_start])
    decode_body = '\n'.join(body_lines[decode_start:decode_end + 1])
    post_decode = '\n'.join(body_lines[decode_end + 1:])

    # Detect union pattern
    is_union = bool(re.search(r'\bswitch\s*\(', encode_body))

    # Detect discriminant
    disc_accessor = ""
    disc_field = ""
    disc_type = ""

    # Property-style: get (discriminant|type) => this._field
    m = re.search(r'get\s+(discriminant|type)\s*=>\s*this\.(_\w+)', pre_encode)
    if m:
        disc_accessor = m.group(1)
        disc_field = m.group(2)
        # Find field type
        tm = re.search(rf'^\s+(\w+\??)\s+{re.escape(disc_field)}\s*;', pre_encode, re.MULTILINE)
        if tm:
            disc_type = tm.group(1).rstrip('?')

    # Method-style: getDiscriminant()
    if not disc_accessor and re.search(r'getDiscriminant\(\)', pre_encode):
        disc_accessor = "getDiscriminant()"
        ctor_m = re.search(rf'{re.escape(class_name)}\(this\.(_\w+)\)', pre_encode)
        if ctor_m:
            disc_field = ctor_m.group(1)
            tm = re.search(rf'^\s+(\w+\??)\s+{re.escape(disc_field)}\s*;', pre_encode, re.MULTILINE)
            if tm:
                disc_type = tm.group(1).rstrip('?')

    # Fallback: if union but no disc_type, try constructor parameter (extends classes)
    if is_union and not disc_type:
        ctor_param_m = re.search(rf'{re.escape(class_name)}\((\w+)\s+\w+\)', pre_encode)
        if ctor_param_m:
            disc_type = ctor_param_m.group(1)

    is_version_union = is_union and disc_type == "int"

    # Extract constructor args
    ctor_m = re.search(rf'{re.escape(class_name)}\((.*?)\)\s*[;{{:]', pre_encode, re.DOTALL)
    constructor_args = ctor_m.group(1).strip() if ctor_m else ""

    return ParsedClass(
        class_name=class_name,
        extends_class=extends_class,
        file_imports=imports,
        class_line=class_line,
        pre_encode=pre_encode,
        encode_body=encode_body,
        mid_section=mid_section,
        decode_body=decode_body,
        post_decode=post_decode,
        is_union=is_union,
        is_version_union=is_version_union,
        disc_accessor=disc_accessor,
        disc_field=disc_field,
        disc_type=disc_type,
        constructor_args=constructor_args,
    )


# ---------------------------------------------------------------------------
# Import classification
# ---------------------------------------------------------------------------

def is_sdk_import(imp: str) -> bool:
    """Check if an import is an SDK-specific import (not needed by base)."""
    for pattern in SDK_IMPORT_PATTERNS:
        if pattern in imp:
            return True
    return False


def classify_imports(all_imports: list[str], base_code: str, wrapper_code: str) -> tuple[list[str], list[str]]:
    """Split imports into base imports and wrapper-only imports."""
    base_imports = []
    wrapper_imports = []

    for imp in all_imports:
        if is_sdk_import(imp):
            wrapper_imports.append(imp)
        else:
            base_imports.append(imp)

    return base_imports, wrapper_imports


# ---------------------------------------------------------------------------
# Code generation
# ---------------------------------------------------------------------------

def generate_decode_as(parsed: ParsedClass) -> str:
    """Transform the decode method into a decodeAs<T> method for union types."""
    cn = parsed.class_name
    bcn = base_class_name(cn)
    decode = parsed.decode_body

    # Replace constructor call: = ClassName(...) -> = constructor(...)
    # Handles both inline decode and local-variable patterns
    if parsed.is_version_union:
        ctor_type = "int"
    else:
        ctor_type = parsed.disc_type
    decode_as = re.sub(
        rf'=\s*{re.escape(cn)}\(',
        '= constructor(',
        decode,
        count=1)

    # Replace class name with bcn in variable declarations
    # e.g., "XdrContractExecutable decoded =" -> "T decoded ="
    decode_as = re.sub(
        rf'{re.escape(cn)}\s+(decoded\w*|decodedTransactionMeta|decodedTransactionResult|'
        rf'decodedTransactionEnvelope|decodedLedgerEntryData)\s*=',
        r'T \1 =',
        decode_as
    )

    # Also handle other variable naming patterns
    # e.g., "XdrFoo decodedFoo =" -> "T decodedFoo ="
    decode_as = re.sub(
        rf'{re.escape(cn)}\s+(decoded\w*)\s*=',
        r'T \1 =',
        decode_as
    )

    # Change method signature
    old_sig_pattern = rf'static\s+{re.escape(cn)}\s+decode\s*\(\s*XdrDataInputStream\s+stream\s*\)'
    new_sig = f'static T decodeAs<T extends {bcn}>(XdrDataInputStream stream, T Function({ctor_type}) constructor)'
    decode_as = re.sub(old_sig_pattern, new_sig, decode_as)

    return decode_as


def generate_base_file(parsed: ParsedClass) -> str:
    """Generate the base file content."""
    cn = parsed.class_name
    bcn = base_class_name(cn)
    is_union = parsed.is_union or cn in UNION_CLASSES or cn in BASE64_UNION_CLASSES
    extends = parsed.extends_class

    lines = [COPYRIGHT.rstrip()]
    lines.append("")

    # Compute base code for import filtering
    base_code = parsed.pre_encode + "\n" + parsed.encode_body + "\n" + parsed.decode_body

    # Base imports: only imports actually used in base code
    # Extract all Xdr* refs from base code to determine needed imports
    base_xdr_refs = set(re.findall(r'\bXdr\w+\b', base_code))
    base_xdr_refs.discard(bcn)
    base_needed_files = {class_name_to_filename(ref) for ref in base_xdr_refs}
    base_needed_files.add('xdr_data_io.dart')  # Always needed
    if extends:
        base_needed_files.add(class_name_to_filename(extends))  # Parent class

    base_imports = []
    for imp in parsed.file_imports:
        if is_sdk_import(imp):
            continue
        if "dart:convert" in imp:
            if re.search(r'\bbase64|json|utf8\b', base_code):
                base_imports.append(imp)
            continue
        if "dart:typed_data" in imp:
            if re.search(r'\bUint8List|ByteData|Float64List\b', base_code):
                base_imports.append(imp)
            continue
        # Check if this XDR import is used in base code
        m = re.search(r"import\s+'.*?(\w+\.dart)'", imp)
        if m and m.group(1) in base_needed_files:
            base_imports.append(imp)
        elif not m:
            base_imports.append(imp)  # Keep non-file imports

    # Sort imports
    dart_imports = sorted([i for i in base_imports if i.startswith("import 'dart:")])
    rel_imports = sorted([i for i in base_imports if not i.startswith("import 'dart:")])

    if dart_imports:
        lines.extend(dart_imports)
        lines.append("")
    if rel_imports:
        lines.extend(rel_imports)
        lines.append("")

    # Class declaration
    if extends and extends != "":
        # Three-level inheritance: XdrFooBase extends XdrAsset
        lines.append(f"class {bcn} extends {extends} {{")
    else:
        lines.append(f"class {bcn} {{")

    # Pre-encode (constructor, fields, getters, setters)
    # Replace class name in constructor
    pre = parsed.pre_encode
    pre = pre.replace(f'{cn}(', f'{bcn}(')
    # For extends XdrAsset classes, constructor calls super
    if extends and f': super(' not in pre:
        # Need to add super call if constructor has this._field syntax
        pass  # The existing code already has : super(type) for extends classes

    lines.append(pre)
    lines.append("")

    # Encode method - widen parameter type from XdrFoo to XdrFooBase
    encode = parsed.encode_body
    # Replace parameter type in signature
    encode = re.sub(
        rf'(static\s+void\s+encode\s*\(\s*\n?\s*XdrDataOutputStream\s+stream\s*,\s*){re.escape(cn)}(\??\s+\w+)',
        rf'\1{bcn}\2',
        encode
    )
    lines.append(encode)
    lines.append("")

    if is_union:
        # Generate decode that calls decodeAs
        if parsed.is_version_union:
            ctor_type = "int"
        else:
            ctor_type = parsed.disc_type

        lines.append(f"  static {bcn} decode(XdrDataInputStream stream) {{")
        lines.append(f"    return decodeAs(stream, {bcn}.new);")
        lines.append(f"  }}")
        lines.append("")

        # Generate decodeAs
        decode_as = generate_decode_as(parsed)
        lines.append(decode_as)
    else:
        # Sequential: keep decode as-is but with base class name
        decode = parsed.decode_body
        decode = decode.replace(f'static {cn} decode(', f'static {bcn} decode(')
        decode = re.sub(
            rf'return\s+{re.escape(cn)}\(',
            f'return {bcn}(',
            decode
        )
        # Also replace variable type declarations
        decode = re.sub(
            rf'{re.escape(cn)}\s+(\w+)\s*=\s*{re.escape(cn)}\(',
            rf'{bcn} \1 = {bcn}(',
            decode
        )
        lines.append(decode)

    lines.append("}")
    lines.append("")

    return '\n'.join(lines)


def generate_wrapper_file(parsed: ParsedClass) -> str:
    """Generate the modified wrapper file content."""
    cn = parsed.class_name
    bcn = base_class_name(cn)
    is_union = parsed.is_union or cn in UNION_CLASSES or cn in BASE64_UNION_CLASSES
    base_file = base_filename(class_name_to_filename(cn))

    lines = [COPYRIGHT.rstrip()]
    lines.append("")

    custom_code = parsed.mid_section + "\n" + parsed.post_decode

    # --- Compute wrapper imports ---
    wrapper_imports = set()

    # Always need base file and xdr_data_io (for encode/decode signatures)
    wrapper_imports.add(f"import '{base_file}';")
    wrapper_imports.add("import 'xdr_data_io.dart';")

    # dart: imports for custom code
    if re.search(r'\bbase64(Decode|Encode)\b', custom_code):
        wrapper_imports.add("import 'dart:convert';")
    if re.search(r'\bUint8List\b|\bByteData\b', custom_code):
        wrapper_imports.add("import 'dart:typed_data';")

    # SDK imports for custom code
    for imp in parsed.file_imports:
        if is_sdk_import(imp):
            wrapper_imports.add(imp)

    # pinenacl import for custom code
    for imp in parsed.file_imports:
        if "pinenacl" in imp and re.search(r'\bSigningKey\b|\bpinenacl\b', custom_code):
            wrapper_imports.add(imp)

    # XDR imports referenced in custom code (for types used in custom methods)
    # Extract all Xdr* identifiers from custom code, excluding self and base
    xdr_refs = set(re.findall(r'\bXdr\w+\b', custom_code))
    xdr_refs.discard(cn)
    xdr_refs.discard(bcn)
    xdr_refs.discard('XdrDataInputStream')
    xdr_refs.discard('XdrDataOutputStream')
    needed_files = {class_name_to_filename(ref) for ref in xdr_refs}
    for imp in parsed.file_imports:
        if is_sdk_import(imp) or imp.startswith("import 'dart:") or "xdr_data_io" in imp:
            continue
        m = re.search(r"import\s+'.*?(\w+\.dart)'", imp)
        if m and m.group(1) in needed_files:
            wrapper_imports.add(imp)

    # Sort imports
    dart_imports = sorted(i for i in wrapper_imports if i.startswith("import 'dart:"))
    pkg_imports = sorted(i for i in wrapper_imports if i.startswith("import 'package:"))
    rel_imports = sorted(i for i in wrapper_imports if not i.startswith("import 'dart:") and not i.startswith("import 'package:"))

    if dart_imports:
        lines.extend(dart_imports)
        lines.append("")
    if pkg_imports:
        lines.extend(pkg_imports)
        lines.append("")
    if rel_imports:
        lines.extend(rel_imports)
        lines.append("")

    # --- Class declaration ---
    lines.append(f"class {cn} extends {bcn} {{")

    # Detect if encode parameter is nullable (e.g., XdrAccountID?)
    encode_nullable = '?' if re.search(rf'{re.escape(cn)}\?', parsed.encode_body) else ''

    if is_union:
        # Union constructor with super param (type inferred from base)
        disc_name = parsed.disc_field.lstrip('_') if parsed.disc_field else "type"
        lines.append(f"  {cn}(super.{disc_name});")
        lines.append("")

        # Delegating encode
        lines.append(f"  static void encode(XdrDataOutputStream stream, {cn}{encode_nullable} val) {{")
        lines.append(f"    {bcn}.encode(stream, val);")
        lines.append(f"  }}")
        lines.append("")

        # Delegating decode via decodeAs
        lines.append(f"  static {cn} decode(XdrDataInputStream stream) {{")
        lines.append(f"    return {bcn}.decodeAs(stream, {cn}.new);")
        lines.append(f"  }}")
    else:
        # Sequential constructor with super params (types inferred from base)
        field_names = re.findall(r'this\.(_\w+)', parsed.constructor_args)
        public_names = [f.lstrip('_') for f in field_names]

        super_params = ", ".join(f"super.{n}" for n in public_names)
        lines.append(f"  {cn}({super_params});")
        lines.append("")

        # Delegating encode
        lines.append(f"  static void encode(XdrDataOutputStream stream, {cn}{encode_nullable} val) {{")
        lines.append(f"    {bcn}.encode(stream, val);")
        lines.append(f"  }}")
        lines.append("")

        # Decode: read via base, reconstruct wrapper
        getter_args = ", ".join(f"b.{n}" for n in public_names)
        lines.append(f"  static {cn} decode(XdrDataInputStream stream) {{")
        lines.append(f"    var b = {bcn}.decode(stream);")
        lines.append(f"    return {cn}({getter_args});")
        lines.append(f"  }}")

    # Custom methods (mid_section + post_decode)
    mid = parsed.mid_section.rstrip()
    custom = parsed.post_decode.rstrip()
    all_custom = (mid + "\n" + custom).strip()
    if all_custom:
        # Replace private field access with public getters/setters
        # (private fields are in the base file, not accessible from wrapper)
        private_fields = set(re.findall(r'\b(_\w+)\s*;', parsed.pre_encode))
        for field in sorted(private_fields, key=len, reverse=True):  # longest first
            public = field.lstrip('_')
            all_custom = re.sub(rf'\b{re.escape(field)}\b', public, all_custom)
        lines.append("")
        lines.append(all_custom)

    lines.append("}")
    lines.append("")

    return '\n'.join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Split XDR classes into base+wrapper pairs")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--only", type=str, help="Process only this class name")
    parser.add_argument("--batch", type=int, help="Process only this batch number (1-5)")
    args = parser.parse_args()

    # Batch definitions
    batches = {
        1: BASE64_SEQUENTIAL_CLASSES | BASE64_UNION_CLASSES,
        2: {"XdrAccountID", "XdrInt128Parts", "XdrUInt128Parts",
            "XdrInt256Parts", "XdrUInt256Parts", "XdrLedgerKeyOffer", "XdrLedgerKeyData"},
        3: {"XdrContractExecutable", "XdrContractIDPreimage",
            "XdrSorobanCredentials", "XdrSorobanAuthorizedFunction",
            "XdrSCSpecTypeDef", "XdrClaimableBalanceID",
            "XdrHostFunction", "XdrPublicKey"},
        4: {"XdrSCAddress", "XdrLedgerKey"},
        5: {"XdrMuxedAccountMed25519", "XdrChangeTrustAsset",
            "XdrTrustlineAsset", "XdrSCVal"},
    }

    targets = ALL_TARGETS
    if args.only:
        targets = {args.only}
    elif args.batch:
        targets = batches.get(args.batch, set())

    print(f"Processing {len(targets)} classes...")

    generated_bases = 0
    modified_wrappers = 0
    errors = []

    for class_name in sorted(targets):
        wrapper_file = class_name_to_filename(class_name)
        filepath = XDR_DIR / wrapper_file

        if not filepath.exists():
            errors.append(f"  ERROR: {wrapper_file} not found")
            continue

        print(f"\n--- {class_name} ({wrapper_file}) ---")

        try:
            parsed = parse_class_file(filepath)
        except Exception as e:
            errors.append(f"  ERROR parsing {wrapper_file}: {e}")
            continue

        print(f"  Union: {parsed.is_union}, Version-union: {parsed.is_version_union}")
        print(f"  Discriminant: {parsed.disc_accessor} ({parsed.disc_type})")
        print(f"  Constructor: {parsed.constructor_args}")
        print(f"  Custom code: {len(parsed.post_decode.strip())} chars")

        # Generate base file
        try:
            base_content = generate_base_file(parsed)
        except Exception as e:
            errors.append(f"  ERROR generating base for {class_name}: {e}")
            continue

        base_file_path = XDR_DIR / base_filename(wrapper_file)

        if args.dry_run:
            print(f"  [DRY RUN] Would write {base_filename(wrapper_file)} ({len(base_content)} bytes)")
        else:
            base_file_path.write_text(base_content)
            print(f"  Written: {base_filename(wrapper_file)}")
            generated_bases += 1

        # Generate wrapper file
        try:
            wrapper_content = generate_wrapper_file(parsed)
        except Exception as e:
            errors.append(f"  ERROR generating wrapper for {class_name}: {e}")
            continue

        if args.dry_run:
            print(f"  [DRY RUN] Would modify {wrapper_file} ({len(wrapper_content)} bytes)")
        else:
            filepath.write_text(wrapper_content)
            print(f"  Modified: {wrapper_file}")
            modified_wrappers += 1

    # Summary
    print(f"\n{'='*60}")
    print(f"Generated {generated_bases} base files, modified {modified_wrappers} wrappers")
    if errors:
        print(f"\nErrors ({len(errors)}):")
        for e in errors:
            print(e)

    if not args.dry_run and generated_bases > 0:
        print(f"\nNext: run 'dart analyze lib/src/xdr/' to verify")


if __name__ == "__main__":
    main()
