#!/usr/bin/env python3
"""Builds the SEP-0051 (XDR-JSON) conformance corpus from the hand-authored seeds.

Each seed is encoded to XDR with the pinned reference CLI and decoded straight
back, so every entry is checked by the reference before it is written. The
decoded document is what the SDK must emit, except for the seeds marked
incomparable, where the reference and SEP-0051 disagree. Such a seed either
names the transformation that derives the specified form from the reference's
output, or, where the divergence is not a transformation of one document into
another, records the reason in its place.

Output is byte-deterministic: fixed entry order, fixed key order and one
serialisation configuration. It carries no timestamp, so a re-run on an
unchanged input produces an unchanged file and any diff is real drift.

Usage:
    python3 generate_corpus.py [--output PATH]
    python3 generate_corpus.py --check-prerequisites
    python3 generate_corpus.py --advisory --output PATH

Exit codes:
    0  corpus written
    1  a seed failed, or a declared divergence has disappeared
    2  the reference CLI is missing or does not match the pin, or a committed
       artefact this generator reads is absent or malformed
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
ORACLE_DIR = os.path.join(REPO_ROOT, "tools", "sep-51-oracle")
PIN_FILE = os.path.join(ORACLE_DIR, "oracle-pin.json")
TYPE_MAP_FILE = os.path.join(ORACLE_DIR, "type_map.json")
NAME_MAP_FILE = os.path.join(ORACLE_DIR, "name-map.json")
GENERATOR_DIR = os.path.join(REPO_ROOT, "tools", "xdr-generator", "generator")
NAME_OVERRIDES_FILE = os.path.join(GENERATOR_DIR, "name_overrides.rb")
TYPE_OVERRIDES_FILE = os.path.join(GENERATOR_DIR, "type_overrides.rb")
MAKEFILE = os.path.join(REPO_ROOT, "Makefile")
XDR_DIR = os.path.join(REPO_ROOT, "xdr")
LIB_XDR_DIR = os.path.join(REPO_ROOT, "lib", "src", "xdr")
DEFAULT_OUTPUT = os.path.join(SCRIPT_DIR, "corpus.json")

sys.path.insert(0, SCRIPT_DIR)
from seeds import SEEDS  # noqa: E402

# One serialisation configuration for every string written into the corpus.
DUMP = dict(ensure_ascii=False, separators=(",", ":"))


class GenerationError(Exception):
    """A seed is wrong, or a declared divergence no longer holds."""


class PrerequisiteError(Exception):
    """The reference CLI is absent or does not match the pin, or an artefact is missing."""


# --- Reference CLI ------------------------------------------------------------


def resolve_cli(pin):
    cli = os.environ.get("STELLAR_XDR", "stellar-xdr")
    resolved = shutil.which(cli)
    if resolved is None and os.path.isfile(cli) and os.access(cli, os.X_OK):
        resolved = cli
    if resolved is None:
        raise PrerequisiteError(
            "reference CLI '%s' not found. Install it with:\n    %s\n"
            "then ensure it is on PATH, or set STELLAR_XDR."
            % (cli, pin["install"])
        )
    return resolved


def read_version(cli):
    """The version and vendored xdr commit `<cli> version` reports."""
    try:
        out = subprocess.run([cli, "version"], capture_output=True, text=True,
                             check=True).stdout
    except (OSError, subprocess.CalledProcessError) as error:
        raise PrerequisiteError(
            "'%s version' failed; is it the XDR reference CLI? (%s)" % (cli, error)
        )
    lines = out.splitlines()
    version = lines[0].split()[1] if lines and len(lines[0].split()) > 1 else "unknown"
    commit = "unknown"
    for line in lines:
        if line.startswith("xdr:"):
            commit = line.split()[1]
            break
    return version, commit


def verify_pin(cli, pin):
    """Refuses any build but the pinned one: key spellings differ between releases."""
    version, commit = read_version(cli)
    if version != pin["version"] or commit != pin["xdr_commit"]:
        raise PrerequisiteError(
            "reference CLI does not match the pin.\n"
            "    want: version %s, xdr %s\n"
            "    got:  version %s, xdr %s\n"
            "  Install the pinned build with:\n    %s"
            % (pin["version"], pin["xdr_commit"], version, commit, pin["install"])
        )


def encode(cli, type_name, document):
    result = subprocess.run(
        [cli, "encode", "--type", type_name],
        input=json.dumps(document, **DUMP), capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise GenerationError(
            "the reference CLI rejected the authored JSON for %s: %s"
            % (type_name, result.stderr.strip())
        )
    return result.stdout.strip()


def decode(cli, type_name, base64_text):
    result = subprocess.run(
        [cli, "decode", "--type", type_name, "--input", "single-base64",
         "--output", "json"],
        input=base64_text, capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise GenerationError(
            "the reference CLI could not decode its own encoding of %s: %s"
            % (type_name, result.stderr.strip())
        )
    return result.stdout.strip()


def try_encode(cli, type_name, text):
    """Encodes raw JSON text, returning (ok, stdout_or_stderr).

    Used for the probes that expect the reference to refuse, where a raised
    GenerationError would be the wrong shape.
    """
    result = subprocess.run(
        [cli, "encode", "--type", type_name],
        input=text, capture_output=True, text=True,
    )
    if result.returncode != 0:
        return False, result.stderr.strip()
    return True, result.stdout.strip()


def without_position(text):
    """Drops the reference's `at line N column N` suffix from an error message.

    The metadata quotes the reference's own wording as evidence for a divergence.
    The offset it reports is a property of the probe document rather than of the
    divergence, so it moves whenever an unrelated part of that document changes
    and turns a stable drift report into byte-offset noise.
    """
    return re.sub(r" at line \d+ column \d+", "", text)


def known_types(cli):
    result = subprocess.run([cli, "types", "list"], capture_output=True, text=True)
    if result.returncode != 0:
        raise PrerequisiteError("'%s types list' failed" % cli)
    return set(result.stdout.split())


# --- Committed artefacts ------------------------------------------------------


def read_json(path, what, remedy):
    """Reads a committed artefact, reporting an absent or malformed one as a prerequisite."""
    try:
        with open(path) as handle:
            return json.load(handle)
    except FileNotFoundError:
        raise PrerequisiteError("%s not found at %s. %s" % (what, path, remedy))
    except json.JSONDecodeError as error:
        raise PrerequisiteError("%s at %s is not valid JSON: %s. %s"
                                % (what, path, error, remedy))


def read_pin():
    return read_json(PIN_FILE, "the reference pin", "It is committed; restore it from git.")


def read_sdk_xdr_commit():
    """The XDR commit this SDK generates from, read from the repository Makefile."""
    try:
        handle = open(MAKEFILE)
    except FileNotFoundError:
        raise PrerequisiteError("the repository Makefile is not at %s" % MAKEFILE)
    with handle:
        for line in handle:
            match = re.match(r"^XDR_COMMIT\s*=\s*(\S+)", line)
            if match:
                return match.group(1)
    raise PrerequisiteError("XDR_COMMIT missing from %s" % MAKEFILE)


def read_name_map():
    return read_json(
        NAME_MAP_FILE, "the name table",
        "Rebuild it with: ruby tools/sep-51-oracle/name_map.rb --diff",
    )


def read_verification(name_map):
    """The name table's verification block, which records what the reference could not resolve.

    Both unresolvable lists are empty while the reference vendors an XDR commit
    at least as new as the SDK's. Reading them rather than hardcoding keeps the
    corpus honest about its own coverage when that stops being true.
    """
    verification = name_map.get("verification")
    # A plain `name_map.rb` run records a sentence here instead of the counts, because it
    # never probed the reference. The corpus needs the lists, so that is a prerequisite.
    if not isinstance(verification, dict):
        raise PrerequisiteError(
            "%s carries no verification block, so the name table was built without probing "
            "the reference. Rebuild it with: ruby tools/sep-51-oracle/name_map.rb --diff"
            % NAME_MAP_FILE
        )
    for key in ("enum_members_unresolvable", "struct_types_unresolvable"):
        if key not in verification:
            raise PrerequisiteError(
                "%s has a verification block without '%s'. Rebuild it with: "
                "ruby tools/sep-51-oracle/name_map.rb --diff" % (NAME_MAP_FILE, key)
            )
    return verification


def ruby_constant_map(path, constant):
    """Reads a `NAME => "value"` Ruby hash literal out of a generator override file."""
    try:
        source = open(path).read()
    except FileNotFoundError:
        raise PrerequisiteError("the generator override file %s is missing" % path)
    marker = constant + " = {"
    if marker not in source:
        raise PrerequisiteError("%s does not define %s" % (path, constant))
    body = source.split(marker, 1)[1].split("}.freeze", 1)[0]
    mapping = {}
    for match in re.finditer(r'"([^"]+)"\s*=>\s*"([^"]+)"', body):
        mapping[match.group(1)] = match.group(2)
    if not mapping:
        raise PrerequisiteError("%s in %s parsed as empty" % (constant, path))
    return mapping


def xdr_typedef_identifiers():
    """Every typedef identifier declared across the .x sources."""
    try:
        names = sorted(name for name in os.listdir(XDR_DIR) if name.endswith(".x"))
    except FileNotFoundError:
        raise PrerequisiteError(
            "the .x sources are not at %s. Fetch them with: make xdr-generate" % XDR_DIR
        )
    if not names:
        raise PrerequisiteError("no .x sources under %s" % XDR_DIR)
    identifiers = []
    for name in names:
        with open(os.path.join(XDR_DIR, name)) as handle:
            for line in handle:
                match = re.match(
                    r"\s*typedef\s+.*?([A-Za-z_][A-Za-z0-9_]*)\s*"
                    r"(\[[^\]]*\]|<[^>]*>)?\s*;", line)
                if match:
                    identifiers.append(match.group(1))
    return identifiers


def dart_json_classes():
    """Every class under lib/src/xdr that carries the SEP-0051 value reader.

    A seed naming a Dart type absent from this set names something the corpus
    cannot be driven through, whatever the name maps say.
    """
    try:
        files = sorted(f for f in os.listdir(LIB_XDR_DIR) if f.endswith(".dart"))
    except FileNotFoundError:
        raise PrerequisiteError("the generated XDR sources are not at %s" % LIB_XDR_DIR)
    classes = set()
    for name in files:
        with open(os.path.join(LIB_XDR_DIR, name)) as handle:
            text = handle.read()
        if "fromXdrJsonValue" not in text:
            continue
        for match in re.finditer(r"^class ([A-Za-z0-9_]+)", text, re.M):
            classes.add(match.group(1))
    if not classes:
        raise PrerequisiteError(
            "no class under %s declares fromXdrJsonValue; generate the SDK first "
            "with: make xdr-generate" % LIB_XDR_DIR
        )
    return classes


# --- SDK type resolution ------------------------------------------------------


def build_sdk_type_index(type_map):
    """Maps each XDR type name to the SDK class name the artefacts give it.

    Enums, structs and unions come from type_map.json, which is keyed on the .x
    identifier because the SDK's NAME_OVERRIDES is many-to-one and not
    invertible. Typedefs are absent from that file, so they resolve through the
    generator's own overrides against the .x typedef list.

    The index is keyed on the lowercased name, because the reference writes an
    acronym as an ordinary word (AccountId for AccountID). A name that arrives
    twice with two different SDK classes fails the run rather than resolving to
    whichever came first.
    """
    index = {}

    def record(name, dart, origin):
        key = name.lower()
        if key in index and index[key][1] != dart:
            raise PrerequisiteError(
                "the type name %s resolves to both %s (%s) and %s (%s)"
                % (name, index[key][1], index[key][2], dart, origin))
        index[key] = (name, dart, origin)

    for entry in type_map.values():
        record(entry["oracle"], entry["dart"], TYPE_MAP_FILE)

    name_overrides = ruby_constant_map(NAME_OVERRIDES_FILE, "NAME_OVERRIDES")
    type_overrides = ruby_constant_map(TYPE_OVERRIDES_FILE, "TYPE_OVERRIDES")
    for identifier in xdr_typedef_identifiers():
        if identifier.lower() in index:
            continue
        dart = name_overrides.get(
            identifier, "Xdr" + identifier[0].upper() + identifier[1:])
        record(identifier, type_overrides.get(dart, dart), NAME_OVERRIDES_FILE)
    return index


def check_type_names(index, available, classes):
    """Every seed must name a type the reference knows and the class the artefacts give it."""
    for seed in SEEDS:
        type_name, dart_type = seed["type"], seed["dart_type"]
        if type_name not in available:
            raise GenerationError(
                "the reference CLI does not know the type %s (seed for %s)"
                % (type_name, dart_type)
            )
        resolved = index.get(type_name.lower())
        if resolved is None:
            raise GenerationError(
                "no committed artefact resolves an SDK class for the type %s; the "
                "seed names %s" % (type_name, dart_type)
            )
        if resolved[1] != dart_type:
            raise GenerationError(
                "seed names %s as the SDK class for %s, but %s gives %s"
                % (dart_type, type_name, resolved[2], resolved[1])
            )
        if dart_type not in classes:
            raise GenerationError(
                "the seed for %s names the SDK class %s, which is not a generated "
                "class carrying fromXdrJsonValue" % (type_name, dart_type)
            )


# --- Specified forms ----------------------------------------------------------
#
# A transform returns the derived value and the set of paths it rewrote. A path
# is dotted object keys with "[n]" for an array index; the whole value is "".


def integer_string(value, path=""):
    """SEP-0051 Hyper Integer: a 64-bit value is a base-10 string, not a JSON number."""
    if not isinstance(value, int) or isinstance(value, bool):
        raise GenerationError(
            "integer_string expects a bare JSON number, got %r" % (value,)
        )
    return str(value), {path}


def opaque_hex(value, path=""):
    """SEP-0051 Opaque Data (Fixed Length): fixed opaque is lowercase hex, not a byte array.

    The rewrite is by value, not by type: any non-empty array whose every element
    is an integer in 0..255 becomes hex. The document carries no type information,
    so there is nothing else to key on, and the whole document is walked because
    an affected field can sit nested inside a larger value.

    That heuristic would also rewrite an array of small integers that is not
    opaque data at all -- a variable-length uint32 array whose values happened to
    stay under 256 would be turned into a hex string. What keeps it honest is the
    returned path set: every incomparable seed declares the locations it expects
    to be rewritten, and build_entry fails when the two sets differ in either
    direction. A rewrite that reaches an integer array is a mismatch, and so is a
    declared location the walk never reached.
    """
    if isinstance(value, dict):
        derived, paths = {}, set()
        for key, item in value.items():
            child = key if path == "" else "%s.%s" % (path, key)
            item_value, item_paths = opaque_hex(item, child)
            derived[key] = item_value
            paths |= item_paths
        return derived, paths
    if isinstance(value, list):
        if value and all(isinstance(item, int) and not isinstance(item, bool)
                         and 0 <= item <= 255 for item in value):
            return "".join("%02x" % item for item in value), {path}
        derived, paths = [], set()
        for index, item in enumerate(value):
            item_value, item_paths = opaque_hex(item, "%s[%d]" % (path, index))
            derived.append(item_value)
            paths |= item_paths
        return derived, paths
    return value, set()


SPEC_FORMS = {
    "integer_string": (
        integer_string,
        "SEP-0051 renders a 64-bit integer as a base-10 string; the reference "
        "emits a bare JSON number.",
    ),
    "opaque_hex": (
        opaque_hex,
        "SEP-0051 renders fixed-length opaque data as lowercase hex; the "
        "reference emits an array of byte numbers.",
    ),
}


# --- Entries ------------------------------------------------------------------


def build_entry(cli, seed, findings=None):
    """Builds one corpus entry.

    A seed problem normally raises. When ``findings`` is a list the problem is appended to
    it instead, so an advisory run reports every affected seed in one pass rather than
    stopping at the first. A seed the build cannot process at all yields no entry, and its
    absence shows up in the diff alongside the recorded finding.
    """
    try:
        base64_text = encode(cli, seed["type"], seed["json"])
        oracle_text = decode(cli, seed["type"], base64_text)
    except GenerationError as error:
        if findings is None:
            raise
        findings.append("%s: %s" % (seed["type"], error))
        return None
    oracle_value = json.loads(oracle_text)

    entry = {
        "type": seed["type"],
        "dart_type": seed["dart_type"],
        "xdr": base64_text,
        "json": None,
        "oracle": "reference",
        "note": seed["note"],
    }

    if seed.get("oracle") != "incomparable":
        entry["json"] = json.dumps(oracle_value, **DUMP)
        return entry

    form = seed.get("spec_form")
    if form is not None and form not in SPEC_FORMS:
        raise GenerationError(
            "seed for %s names an unknown spec_form (%r)" % (seed["type"], form)
        )
    if "spec_form_paths" not in seed:
        raise GenerationError(
            "seed for %s is incomparable but declares no spec_form_paths; every "
            "incomparable seed declares the locations its transformation rewrites, "
            "and the empty list when it rewrites none" % seed["type"]
        )

    if form is None:
        specified, rewritten = oracle_value, set()
        reason = seed.get("reason")
        if reason is None:
            raise GenerationError(
                "seed for %s is incomparable under no transformation and gives no "
                "reason" % seed["type"]
            )
    else:
        transform, reason = SPEC_FORMS[form]
        specified, rewritten = transform(oracle_value)

    # Total, with no exemption for a seed carrying no transform: declared paths
    # equal rewritten paths on every incomparable entry, so a transform that
    # reaches a location nobody declared fails here rather than pinning a wrong
    # expected value the SDK can then never match.
    declared = set(seed["spec_form_paths"])
    if declared != rewritten:
        raise GenerationError(
            "seed for %s declares spec_form_paths %s but the transformation "
            "rewrote %s"
            % (seed["type"], sorted(declared), sorted(rewritten))
        )

    if specified == oracle_value:
        message = (
            "seed for %s is marked incomparable under %s, but the reference "
            "already emits the specified form; the divergence is gone and the "
            "seed must be reclassified"
            % (seed["type"], form or "no transformation")
        )
        if findings is None:
            raise GenerationError(message)
        findings.append(message)

    entry["json"] = json.dumps(specified, **DUMP)
    entry["oracle"] = "incomparable"
    entry["reason"] = reason
    entry["oracle_json"] = json.dumps(oracle_value, **DUMP)
    return entry


# --- Completeness -------------------------------------------------------------


def oracle_name_for(index, xdr_name):
    """The reference spelling of an .x type name, via the committed type map."""
    resolved = index.get(xdr_name.lower())
    return resolved[0] if resolved else None


def check_completeness(name_map, index):
    """Asserts the seed set covers what the artefacts say it must.

    Every list here is read from a committed artefact rather than written out,
    so a pin bump that adds a member or a type moves the requirement with it.
    """
    verification = read_verification(name_map)
    seeded_types = {seed["type"] for seed in SEEDS}
    problems = []

    # Anything the reference could not resolve when the name table was built is
    # undiffed there, so the corpus has to carry it explicitly. Both lists are
    # empty while the two XDR pins agree closely enough.
    for xdr_name in verification["struct_types_unresolvable"]:
        oracle = oracle_name_for(index, xdr_name)
        if oracle is None or oracle not in seeded_types:
            problems.append(
                "the reference cannot resolve the type %s, so the corpus must seed "
                "it; no seed names it" % xdr_name)
    for member in verification["enum_members_unresolvable"]:
        enum_name = member.split(".", 1)[0]
        oracle = oracle_name_for(index, enum_name)
        if oracle is None or oracle not in seeded_types:
            problems.append(
                "the reference cannot resolve the enum member %s, so the corpus must "
                "seed %s; no seed names it" % (member, enum_name))

    # BinaryFuseFilterType is the only enum whose members exercise the
    # digit-leading branch of the name rule, so every member is seeded.
    for enum in name_map["enums"]:
        if enum["xdr_name"] != "BinaryFuseFilterType":
            continue
        wanted = {member["json"] for member in enum["members"]}
        seen = {seed["json"] for seed in SEEDS
                if seed["type"] == "BinaryFuseFilterType"}
        for missing in sorted(wanted - seen):
            problems.append(
                "BinaryFuseFilterType member %s is not seeded; it is one of the "
                "digit-leading names" % missing)
        break
    else:
        problems.append("the name table carries no BinaryFuseFilterType enum")

    # Every struct with an XDR field named `type` renders the key `type` and
    # accepts `type_` on input, so every one of them is seeded.
    type_field_types = [struct["xdr_name"] for struct in name_map["structs"]
                        if any(field["json"] == "type" for field in struct["fields"])]
    if not type_field_types:
        problems.append("the name table carries no struct with a `type` field")
    for xdr_name in type_field_types:
        oracle = oracle_name_for(index, xdr_name)
        if oracle is None:
            problems.append("no artefact resolves a reference name for %s" % xdr_name)
        elif oracle not in seeded_types:
            problems.append(
                "%s renders an XDR field named `type` and is not seeded" % xdr_name)

    if problems:
        raise GenerationError(
            "the seed set is incomplete:\n    " + "\n    ".join(problems))
    return sorted(type_field_types)


# --- Divergences that cannot be corpus entries --------------------------------
#
# Two of the four divergence classes have no emitted text to pin, so neither can
# be an entry: an entry's `json` is what the SDK must emit, and for these the SDK
# emits nothing at all. They are asserted live against the pinned reference and
# recorded in the metadata, so a divergence the reference quietly fixes fails the
# run rather than passing unnoticed.

# SignerKeyEd25519SignedPayload: 32 zero bytes of ed25519 followed by a
# zero-length payload<64>. 36 bytes, so 48 base64 characters and no padding.
# Valid XDR that no accepted strkey form renders.
ZERO_LENGTH_SIGNED_PAYLOAD_XDR = "A" * 48


def assert_zero_length_signed_payload(cli):
    """The reference decodes the empty payload to a strkey it then refuses to encode."""
    strkey = decode(cli, "SignerKeyEd25519SignedPayload",
                    ZERO_LENGTH_SIGNED_PAYLOAD_XDR)
    accepted, output = try_encode(cli, "SignerKeyEd25519SignedPayload", strkey)
    if accepted:
        raise GenerationError(
            "the reference now encodes the zero-length signed payload strkey %s back "
            "to %s. The divergence is gone; reclassify it as a corpus entry."
            % (strkey, output))
    return (
        "SignerKeyEd25519SignedPayload with a zero-length payload is valid XDR (%s) "
        "that the reference decodes to %s and then refuses to encode back. This SDK "
        "refuses it in both directions, so no emitted text exists for an entry to "
        "pin; it is covered by a hand-written negative test."
        % (ZERO_LENGTH_SIGNED_PAYLOAD_XDR, strkey.strip('"')))


def assert_schema_rejected(cli, probe_type):
    """The reference rejects $schema on input; SEP-0051 requires objects to allow it."""
    document = {"$schema": "https://example.com/schema.json",
                "type": "dont_have", "req_hash": "00" * 32}
    accepted, output = try_encode(cli, probe_type, json.dumps(document, **DUMP))
    if accepted:
        raise GenerationError(
            "the reference now accepts $schema on input for %s (it encoded to %s). "
            "The acceptance divergence is gone." % (probe_type, output))
    if "$schema" not in output:
        raise GenerationError(
            "the reference rejected the $schema probe for %s, but not for $schema: %s"
            % (probe_type, output))
    return (
        "SEP-0051 JSON Schema requires objects to allow a $schema property. The "
        "reference rejects it outright (%s). This SDK accepts it, strips it and "
        "never emits it, so no emitted text differs and there is nothing for an "
        "entry to pin; it is covered by a hand-written test."
        % without_position(output))


def assert_type_alias(cli, probe_type):
    """`type_` is an input alias for `type` and encodes identically."""
    canonical = {"type": "dont_have", "req_hash": "00" * 32}
    aliased = {"type_": "dont_have", "req_hash": "00" * 32}
    canonical_xdr = encode(cli, probe_type, canonical)
    accepted, aliased_xdr = try_encode(cli, probe_type, json.dumps(aliased, **DUMP))
    if not accepted:
        raise GenerationError(
            "the reference no longer accepts `type_` as an input alias for `type` "
            "on %s: %s" % (probe_type, aliased_xdr))
    if aliased_xdr != canonical_xdr:
        raise GenerationError(
            "`type_` and `type` no longer encode identically on %s: %s against %s"
            % (probe_type, aliased_xdr, canonical_xdr))
    both = dict(canonical)
    both["type_"] = "dont_have"
    accepted, output = try_encode(cli, probe_type, json.dumps(both, **DUMP))
    if accepted:
        raise GenerationError(
            "the reference now accepts `type` and `type_` together on %s" % probe_type)
    return (
        "%s renders its XDR `type` field under the key `type` and accepts `type_` as "
        "an input alias; both spellings encode to %s, and supplying them together is "
        "rejected (%s). This SDK matches, and never emits `type_`."
        % (probe_type, canonical_xdr, without_position(output)))


# --- Corpus -------------------------------------------------------------------


def check_prerequisites(advisory=False):
    """Verifies the reference build and every committed artefact this generator reads.

    Runs before anything is written, so a missing CLI can never be mistaken for a
    clean diff and can never leave a half-written artefact.
    """
    pin = read_pin()
    cli = resolve_cli(pin)
    if advisory:
        version, commit = read_version(cli)
    else:
        verify_pin(cli, pin)
        version, commit = pin["version"], pin["xdr_commit"]

    sdk_xdr_commit = read_sdk_xdr_commit()
    if pin.get("sdk_xdr_commit") != sdk_xdr_commit:
        raise PrerequisiteError(
            "the reference pin records sdk_xdr_commit %s but the Makefile pins "
            "XDR_COMMIT %s. Reconcile %s with the Makefile before regenerating."
            % (pin.get("sdk_xdr_commit"), sdk_xdr_commit, PIN_FILE))

    type_map = read_json(
        TYPE_MAP_FILE, "the type map",
        "Rebuild it with: ruby tools/sep-51-oracle/name_map.rb --diff",
    )["type_map"]
    name_map = read_name_map()
    read_verification(name_map)
    index = build_sdk_type_index(type_map)
    classes = dart_json_classes()
    return pin, cli, version, commit, sdk_xdr_commit, name_map, index, classes


def generate(output_path, advisory=False):
    """Builds the corpus.

    Normally the reference build must match the pin exactly. An advisory run instead
    accepts whatever build is on PATH and records its version in the metadata, so a newer
    release can be compared against the committed corpus without disturbing it. It never
    writes to the committed file; the caller supplies a scratch path.
    """
    if advisory and os.path.abspath(output_path) == os.path.abspath(DEFAULT_OUTPUT):
        raise PrerequisiteError(
            "an advisory run must not write the committed corpus; pass --output"
        )

    (pin, cli, version, commit, sdk_xdr_commit,
     name_map, index, classes) = check_prerequisites(advisory=advisory)
    findings = [] if advisory else None

    check_type_names(index, known_types(cli), classes)
    type_field_types = check_completeness(name_map, index)
    probe_type = oracle_name_for(index, "DontHave")

    signed_payload_note = assert_zero_length_signed_payload(cli)
    schema_note = assert_schema_rejected(cli, probe_type)
    type_alias_note = assert_type_alias(cli, probe_type)

    built = [build_entry(cli, seed, findings) for seed in SEEDS]
    entries = [entry for entry in built if entry is not None]
    verification = read_verification(name_map)

    corpus = {
        "metadata": {
            "description": (
                "SEP-0051 (XDR-JSON) conformance corpus. Each entry pins the "
                "exact JSON text the SDK must emit for one XDR value and the "
                "base64 XDR that value encodes to."
            ),
            "reference_tool": pin["tool"],
            "reference_version": version,
            "reference_xdr_commit": commit,
            "sdk_xdr_commit": sdk_xdr_commit,
            "entry_count": len(entries),
            "unresolvable_enum_members": sorted(
                verification["enum_members_unresolvable"]),
            "unresolvable_struct_types": sorted(
                verification["struct_types_unresolvable"]),
            "type_field_types": sorted(type_field_types),
            "type_field_alias": type_alias_note,
            "excluded_zero_length_signed_payload": signed_payload_note,
            "excluded_schema_input": schema_note,
        },
        "entries": entries,
    }

    with open(output_path, "w") as handle:
        json.dump(corpus, handle, ensure_ascii=False, indent=2, sort_keys=False)
        handle.write("\n")

    return corpus, findings or []


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--output", default=DEFAULT_OUTPUT,
                        help="where to write corpus.json (default: %(default)s)")
    parser.add_argument("--advisory", action="store_true",
                        help="accept a build other than the pinned one and record its "
                             "version; requires --output and never writes the committed "
                             "corpus. For comparing a new reference release.")
    parser.add_argument("--check-prerequisites", action="store_true",
                        help="verify the reference build and the committed artefacts, "
                             "write nothing, and exit 0 or 2.")
    args = parser.parse_args()

    if args.check_prerequisites:
        try:
            check_prerequisites(advisory=args.advisory)
        except PrerequisiteError as error:
            print("generate_corpus.py: %s" % error, file=sys.stderr)
            return 2
        return 0

    try:
        corpus, findings = generate(args.output, advisory=args.advisory)
    except PrerequisiteError as error:
        print("generate_corpus.py: %s" % error, file=sys.stderr)
        return 2
    except GenerationError as error:
        print("generate_corpus.py: %s" % error, file=sys.stderr)
        return 1

    entries = corpus["entries"]
    incomparable = [entry for entry in entries if entry["oracle"] == "incomparable"]
    incomparable_types = sorted({entry["type"] for entry in incomparable})
    if args.advisory:
        print("ADVISORY: generated against %s %s, not the pinned build."
              % (corpus["metadata"]["reference_tool"],
                 corpus["metadata"]["reference_version"]))
    print("Wrote %s" % args.output)
    print("  entries:        %d" % len(entries))
    print("  distinct types: %d" % len({entry["type"] for entry in entries}))
    print("  comparable:     %d" % (len(entries) - len(incomparable)))
    print("  incomparable:   %d (%s)" % (len(incomparable),
                                         ", ".join(incomparable_types)))

    if findings:
        print("")
        print("ADVISORY: %d seed(s) behave differently under this build:" % len(findings))
        for finding in findings:
            print("  - %s" % finding)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
