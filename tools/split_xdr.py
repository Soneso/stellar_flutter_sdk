#!/usr/bin/env python3
"""
Split XDR files into one-file-per-type.

Reads the 20 multi-class XDR source files in lib/src/xdr/,
extracts each class into its own file with correct imports,
and generates a barrel file exporting everything.

Usage:
    python3 tools/split_xdr.py [--dry-run] [--only FILE]
"""

import re
import os
import sys
import argparse
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

ROOT = Path(__file__).resolve().parent.parent
XDR_DIR = ROOT / "lib" / "src" / "xdr"
EXCLUDE_FILES = {"xdr_data_io.dart"}

# Classes that need base+wrapper pairs (from the plan)
WRAPPER_CLASSES = {
    # Union types with decodeAs pattern
    "XdrPublicKey", "XdrSCVal", "XdrSCAddress", "XdrSCSpecTypeDef",
    "XdrHostFunction", "XdrContractExecutable", "XdrContractIDPreimage",
    "XdrSorobanCredentials", "XdrSorobanAuthorizedFunction",
    "XdrLedgerKey", "XdrClaimableBalanceID",
    "XdrTrustlineAsset", "XdrChangeTrustAsset",
    # Sequential types
    "XdrAccountID", "XdrMuxedAccountMed25519",
    "XdrInt128Parts", "XdrUInt128Parts",
    "XdrInt256Parts", "XdrUInt256Parts",
    "XdrLedgerKeyOffer", "XdrLedgerKeyData",
    # Base64/envelope-only
    "XdrTransactionMeta", "XdrTransactionEvent", "XdrDiagnosticEvent",
    "XdrSorobanTransactionData", "XdrContractEvent", "XdrTransactionResult",
    "XdrTransactionEnvelope", "XdrLedgerEntry", "XdrLedgerEntryData",
    "XdrLedgerEntryChanges", "XdrLedgerFootprint",
}

# External (non-XDR) imports that may appear in source files.
# Maps a regex pattern found in class bodies to the import statement needed.
EXTERNAL_IMPORT_PATTERNS = {
    r'\bUint8List\b': "import 'dart:typed_data';",
    r'\bByteData\b': "import 'dart:typed_data';",
    r'\butf8\b': "import 'dart:convert';",
    r'\bbase64Decode\b': "import 'dart:convert';",
    r'\bbase64Encode\b': "import 'dart:convert';",
    r'\bKeyPair\b': "import 'package:stellar_flutter_sdk/src/key_pair.dart';",
    r'\bStrKey\b': "import 'package:stellar_flutter_sdk/src/key_pair.dart';",
    r'\bAddress\b': "import 'package:stellar_flutter_sdk/src/soroban/soroban_auth.dart';",
    r'\bUtil\b': "import 'package:stellar_flutter_sdk/src/util.dart';",
    r'\bBitConstants\b': "import 'package:stellar_flutter_sdk/src/constants/bit_constants.dart';",
    r'\bpinenacl\b': "import 'package:pinenacl/api.dart';",
    r'\bSigningKey\b': "import 'package:pinenacl/api.dart';",
}

# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class DartClass:
    """Represents a single Dart class extracted from a source file."""
    name: str
    body: str  # Full text including 'class ...' line through closing brace
    source_file: str  # e.g. "xdr_error.dart"
    start_line: int
    end_line: int

    # Populated during analysis
    extends_class: str = ""
    xdr_refs: set = field(default_factory=set)      # Other XDR class names referenced
    external_imports: set = field(default_factory=set)  # Import statements needed
    needs_wrapper: bool = False

    # Union detection
    is_union: bool = False
    accessor_name: str = ""       # "discriminant" or "type"
    backing_field: str = ""       # "_type", "_kind", "_code", etc.
    backing_field_type: str = ""  # "int" or "XdrSomeType"
    is_version_union: bool = False
    has_switch_in_body: bool = False


# ---------------------------------------------------------------------------
# Phase 0.1: Parse classes from source files
# ---------------------------------------------------------------------------

def parse_classes(filepath: Path) -> list[DartClass]:
    """Extract all class definitions from a Dart file using brace-depth tracking."""
    text = filepath.read_text()
    lines = text.split('\n')
    classes = []

    i = 0
    while i < len(lines):
        line = lines[i]
        # Match class declaration (possibly with extends/implements/with)
        m = re.match(r'^class\s+(\w+)', line)
        if m:
            class_name = m.group(1)
            start_line = i

            # Check for extends
            extends_match = re.search(r'\bextends\s+(\w+)', line)
            extends_class = extends_match.group(1) if extends_match else ""

            # Track brace depth to find the end of the class
            depth = 0
            class_lines = []
            j = i
            while j < len(lines):
                class_lines.append(lines[j])
                depth += lines[j].count('{') - lines[j].count('}')
                if depth <= 0 and '{' in ''.join(class_lines):
                    break
                j += 1

            body = '\n'.join(class_lines)
            classes.append(DartClass(
                name=class_name,
                body=body,
                source_file=filepath.name,
                start_line=start_line + 1,  # 1-indexed
                end_line=j + 1,
                extends_class=extends_class,
            ))
            i = j + 1
        else:
            i += 1

    return classes


# ---------------------------------------------------------------------------
# Phase 0.2: Build dependency graph
# ---------------------------------------------------------------------------

def strip_comments(text: str) -> str:
    """Remove single-line (//) and multi-line (/* */) comments from Dart code."""
    # Remove multi-line comments first
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)
    # Remove single-line comments
    text = re.sub(r'//[^\n]*', '', text)
    return text


def find_xdr_refs(cls: DartClass, all_class_names: set[str]) -> set[str]:
    """Find all XDR class names referenced in a class body (ignoring comments)."""
    refs = set()
    code_only = strip_comments(cls.body)
    # Match word boundaries for class names
    for name in all_class_names:
        if name == cls.name:
            continue
        if re.search(r'\b' + re.escape(name) + r'\b', code_only):
            refs.add(name)
    return refs


def find_external_imports(cls: DartClass) -> set[str]:
    """Detect external (non-XDR) imports needed by a class body."""
    imports = set()
    for pattern, import_stmt in EXTERNAL_IMPORT_PATTERNS.items():
        if re.search(pattern, cls.body):
            imports.add(import_stmt)
    return imports


def analyze_dependencies(classes: dict[str, DartClass]):
    """Populate xdr_refs and external_imports for all classes."""
    all_names = set(classes.keys())
    for cls in classes.values():
        cls.xdr_refs = find_xdr_refs(cls, all_names)
        cls.external_imports = find_external_imports(cls)

        # Also check extends
        if cls.extends_class and cls.extends_class in all_names:
            cls.xdr_refs.add(cls.extends_class)


# ---------------------------------------------------------------------------
# Phase 0.3: Classify classes
# ---------------------------------------------------------------------------

def detect_union_info(cls: DartClass):
    """Detect if a class is a union type and its accessor style."""
    # Check for property-style accessor: get (discriminant|type) => this._field
    m = re.search(
        r'(?:get\s+(discriminant|type)\s*=>\s*this\.(_\w+))',
        cls.body
    )
    if m:
        cls.accessor_name = m.group(1)
        cls.backing_field = m.group(2)

        # Find the backing field's declared type
        field_pattern = re.escape(cls.backing_field)
        type_match = re.search(
            rf'^\s+(\w+\??)\s+{field_pattern}\s*;',
            cls.body, re.MULTILINE
        )
        if type_match:
            cls.backing_field_type = type_match.group(1).rstrip('?')

    # Check for method-style accessor (XdrPublicKey)
    if not m and re.search(r'getDiscriminant\(\)', cls.body):
        cls.accessor_name = "getDiscriminant()"
        # Find the backing field from the constructor
        ctor_match = re.search(rf'{re.escape(cls.name)}\(this\.(_\w+)\)', cls.body)
        if ctor_match:
            cls.backing_field = ctor_match.group(1)
            type_match = re.search(
                rf'^\s+(\w+\??)\s+{re.escape(cls.backing_field)}\s*;',
                cls.body, re.MULTILINE
            )
            if type_match:
                cls.backing_field_type = type_match.group(1).rstrip('?')

    # Check for switch statement in body (confirms union vs plain data class)
    cls.has_switch_in_body = bool(re.search(r'\bswitch\s*\(', cls.body))

    # A class is a union if it has a discriminant accessor AND a switch in encode/decode
    if cls.accessor_name and cls.has_switch_in_body:
        cls.is_union = True
        cls.is_version_union = (cls.backing_field_type == "int")


def classify_classes(classes: dict[str, DartClass]):
    """Classify each class as wrapper-needed, version-union, or plain."""
    for cls in classes.values():
        detect_union_info(cls)
        cls.needs_wrapper = cls.name in WRAPPER_CLASSES


# ---------------------------------------------------------------------------
# Phase 0.4: Generate files
# ---------------------------------------------------------------------------

def class_name_to_filename(name: str) -> str:
    """Convert a class name to a snake_case filename.

    XdrSCVal -> xdr_sc_val.dart
    TrustLineEntryExtensionV2 -> xdr_trust_line_entry_extension_v2.dart
    """
    # Strip Xdr prefix if present
    if name.startswith("Xdr"):
        stripped = name[3:]
    else:
        stripped = name

    # Convert CamelCase to snake_case
    # Insert underscore before uppercase letters that follow lowercase/digits
    s = re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', stripped)
    # Insert underscore between consecutive uppercase followed by lowercase
    s = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1_\2', s)
    snake = s.lower()

    return f"xdr_{snake}.dart"


def resolve_import_path(ref_class_name: str, classes: dict[str, DartClass]) -> str:
    """Get the import path for a referenced class.

    If the class needs a wrapper, import the wrapper file (not the base).
    """
    filename = class_name_to_filename(ref_class_name)
    # Wrapper classes: the wrapper file has the original name,
    # the base file has _base suffix. Other files import the wrapper.
    # (The wrapper re-exports/delegates to base internally)
    return filename


def generate_file_content(cls: DartClass, classes: dict[str, DartClass]) -> str:
    """Generate the content for a single-class file."""
    lines = []

    # Copyright header
    lines.append("// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.")
    lines.append("// Use of this source code is governed by a license that can be")
    lines.append("// found in the LICENSE file.")
    lines.append("")

    # Collect imports
    imports = set()

    # Always import xdr_data_io (unless this class doesn't use it)
    if re.search(r'\bXdrData(Input|Output)Stream\b', cls.body):
        imports.add("import 'xdr_data_io.dart';")

    # External imports
    imports.update(cls.external_imports)

    # XDR type imports (relative within xdr/ directory)
    for ref in sorted(cls.xdr_refs):
        if ref in classes:
            filename = resolve_import_path(ref, classes)
            imports.add(f"import '{filename}';")

    # Sort and add imports
    dart_imports = sorted([i for i in imports if i.startswith("import 'dart:")])
    pkg_imports = sorted([i for i in imports if i.startswith("import 'package:")])
    rel_imports = sorted([i for i in imports if not i.startswith("import 'dart:") and not i.startswith("import 'package:")])

    if dart_imports:
        lines.extend(dart_imports)
        lines.append("")
    if pkg_imports:
        lines.extend(pkg_imports)
        lines.append("")
    if rel_imports:
        lines.extend(rel_imports)
        lines.append("")

    # Class body
    lines.append(cls.body)
    lines.append("")  # trailing newline

    return '\n'.join(lines)


# ---------------------------------------------------------------------------
# Phase 0.5: Generate barrel file
# ---------------------------------------------------------------------------

def generate_barrel(classes: dict[str, DartClass]) -> str:
    """Generate xdr.dart barrel file exporting all types."""
    lines = []
    lines.append("// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.")
    lines.append("// Use of this source code is governed by a license that can be")
    lines.append("// found in the LICENSE file.")
    lines.append("")
    lines.append("// Auto-generated barrel file. Do not edit manually.")
    lines.append("")

    # Always export xdr_data_io
    lines.append("export 'xdr_data_io.dart';")

    # Export all type files
    filenames = set()
    for cls in classes.values():
        filename = class_name_to_filename(cls.name)
        filenames.add(filename)

    for filename in sorted(filenames):
        lines.append(f"export '{filename}';")

    lines.append("")
    return '\n'.join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Split XDR files into one-file-per-type")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print what would be done without writing files")
    parser.add_argument("--only", type=str,
                        help="Process only this source file (e.g., xdr_error.dart)")
    parser.add_argument("--output-dir", type=str, default=None,
                        help="Write output to a different directory (for testing)")
    args = parser.parse_args()

    output_dir = Path(args.output_dir) if args.output_dir else XDR_DIR

    # --- Phase 0.1: Parse ---
    print("Phase 0.1: Parsing classes...")
    all_classes: dict[str, DartClass] = {}
    source_files = sorted(XDR_DIR.glob("*.dart"))

    for filepath in source_files:
        if filepath.name in EXCLUDE_FILES:
            continue
        if args.only and filepath.name != args.only:
            continue

        parsed = parse_classes(filepath)
        for cls in parsed:
            if cls.name in all_classes:
                print(f"  WARNING: Duplicate class name {cls.name} in {filepath.name} "
                      f"(already in {all_classes[cls.name].source_file})")
            all_classes[cls.name] = cls

    print(f"  Found {len(all_classes)} classes across "
          f"{len(set(c.source_file for c in all_classes.values()))} files")

    # --- Phase 0.2: Dependencies ---
    print("Phase 0.2: Building dependency graph...")
    analyze_dependencies(all_classes)

    # --- Phase 0.3: Classify ---
    print("Phase 0.3: Classifying classes...")
    classify_classes(all_classes)

    # Print summary
    unions = [c for c in all_classes.values() if c.is_union and not c.is_version_union]
    version_unions = [c for c in all_classes.values() if c.is_version_union]
    wrappers = [c for c in all_classes.values() if c.needs_wrapper]
    plain = [c for c in all_classes.values() if not c.needs_wrapper]

    print(f"  Union types: {len(unions)}")
    print(f"  Version-union (int _v): {len(version_unions)}")
    print(f"  Wrapper-needed: {len(wrappers)}")
    print(f"  Plain: {len(plain)}")

    # --- Phase 0.4: Generate files ---
    print("Phase 0.4: Generating files...")
    generated = 0
    skipped = 0

    for cls in sorted(all_classes.values(), key=lambda c: c.name):
        filename = class_name_to_filename(cls.name)
        content = generate_file_content(cls, all_classes)
        filepath = output_dir / filename

        if args.dry_run:
            print(f"  [DRY RUN] Would write {filename} ({len(content)} bytes)")
            generated += 1
            continue

        # Don't overwrite if content is identical
        if filepath.exists() and filepath.read_text() == content:
            skipped += 1
            continue

        filepath.write_text(content)
        generated += 1

    print(f"  Generated: {generated}, Skipped (unchanged): {skipped}")

    # --- Phase 0.5: Barrel file ---
    if args.only:
        print("Phase 0.5: Skipping barrel generation (--only mode)")
    else:
        print("Phase 0.5: Generating barrel file...")
        barrel_content = generate_barrel(all_classes)
        barrel_path = output_dir / "xdr.dart"

        if args.dry_run:
            print(f"  [DRY RUN] Would write xdr.dart ({len(barrel_content)} bytes)")
        else:
            barrel_path.write_text(barrel_content)
            print(f"  Written: xdr.dart")

    # --- Summary ---
    print(f"\nDone! {generated} files generated.")
    print(f"Expected ~{len(all_classes)} type files + 1 barrel = ~{len(all_classes) + 1} total")

    # Print wrapper classes for verification
    if wrappers:
        print(f"\nWrapper-needed classes ({len(wrappers)}):")
        for cls in sorted(wrappers, key=lambda c: c.name):
            print(f"  {cls.name} (from {cls.source_file})"
                  f"{' [union]' if cls.is_union else ''}"
                  f"{' [version-union]' if cls.is_version_union else ''}")


if __name__ == "__main__":
    main()
