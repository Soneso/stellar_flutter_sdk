#!/usr/bin/env python3
"""Generates a Dart source file that embeds a pinned Stellar Asset Contract spec.

The pin names an upstream file by repository, commit, path and sha256 digest, and a
template holds the Dart layout. The script downloads the file (or reads --source),
verifies its digest, fills the placeholders and writes the output. It uses only the
Python standard library and writes no timestamp, so a run at the same pin reproduces
the output byte for byte.

Exit status is 0 on success, 1 on any failure of the run, and 2 for a usage error.
Each failure prints one line that names the URL or path and the cause to stderr.
"""

import argparse
import base64
import hashlib
import http.client
import json
import os
import re
import sys
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PIN = os.path.join(HERE, "pin.json")
DEFAULT_ROOT = os.path.abspath(os.path.join(HERE, os.pardir, os.pardir))
DOWNLOAD_TIMEOUT_SECONDS = 60
PIN_KEYS = ("repository", "commit", "file", "sha256", "template", "output")
COMMIT_PATTERN = re.compile(r"[0-9a-f]{40}\Z")
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}\Z")
CONTROL_PATTERN = re.compile(r"[\x00-\x1f\x7f-\x9f\u2028\u2029]")
PLACEHOLDER_PATTERN = re.compile(r"\{\{[A-Za-z0-9_]*\}\}|\{\{")


def escape_control(text):
    """Replaces each control or line separator with \\xNN (up to U+00FF) or \\uXXXX."""

    def escape(match):
        code = ord(match.group(0))
        if code <= 0xFF:
            return "\\x{:02x}".format(code)
        return "\\u{:04x}".format(code)

    return CONTROL_PATTERN.sub(escape, text)


class GenerationError(Exception):
    """A failure that ends the run with exit status 1.

    Control characters in the message, such as those in a path given on the command
    line, are escaped so that the error stays on one line.
    """

    def __init__(self, message):
        super().__init__(escape_control(message))


def load_pin(path):
    """Reads and validates the pin file; returns its fields as a dict."""
    try:
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
    except (OSError, ValueError) as error:
        raise GenerationError(
            "cannot read pin file {}: {}".format(path, getattr(error, "strerror", None) or error)
        )
    try:
        pin = json.loads(text)
    except ValueError as error:
        raise GenerationError("pin file {} is not valid JSON: {}".format(path, error))
    if not isinstance(pin, dict):
        raise GenerationError("pin file {} must hold a JSON object".format(path))
    for key in PIN_KEYS:
        if key not in pin:
            raise GenerationError("pin file {} lacks the key {!r}".format(path, key))
        if not isinstance(pin[key], str) or not pin[key]:
            raise GenerationError(
                "pin key {!r} in {} must be a non-empty string".format(key, path)
            )
        if CONTROL_PATTERN.search(pin[key]):
            raise GenerationError(
                "pin key {!r} in {} must not contain control characters".format(key, path)
            )
    if not COMMIT_PATTERN.match(pin["commit"]):
        raise GenerationError(
            "pin key 'commit' in {} must be 40 lowercase hex characters".format(path)
        )
    if not SHA256_PATTERN.match(pin["sha256"]):
        raise GenerationError(
            "pin key 'sha256' in {} must be 64 lowercase hex characters".format(path)
        )
    for key in ("template", "output"):
        if os.path.isabs(pin[key]):
            raise GenerationError(
                "pin key {!r} in {} must be relative to the root".format(key, path)
            )
    return pin


def raw_url(pin):
    """Returns the raw.githubusercontent.com URL of the pinned file."""
    return "https://raw.githubusercontent.com/{}/{}/{}".format(
        pin["repository"], pin["commit"], pin["file"]
    )


def download(url):
    """Returns the bytes at url, with a 60-second timeout."""
    try:
        with urllib.request.urlopen(url, timeout=DOWNLOAD_TIMEOUT_SECONDS) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        raise GenerationError(
            "cannot download {}: HTTP {} {}".format(url, error.code, error.reason)
        )
    except (urllib.error.URLError, OSError, ValueError, http.client.HTTPException) as error:
        cause = getattr(error, "reason", None) or error
        raise GenerationError("cannot download {}: {}".format(url, cause))


def read_source(path):
    """Returns the bytes of a local copy of the pinned file."""
    try:
        with open(path, "rb") as handle:
            return handle.read()
    except (OSError, ValueError) as error:
        raise GenerationError(
            "cannot read source file {}: {}".format(path, getattr(error, "strerror", None) or error)
        )


def read_template(path):
    """Returns the template text with LF line endings."""
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except UnicodeDecodeError as error:
        raise GenerationError("template {} is not valid UTF-8: {}".format(path, error))
    except (OSError, ValueError) as error:
        raise GenerationError(
            "cannot read template {}: {}".format(path, getattr(error, "strerror", None) or error)
        )


def verify_digest(data, expected, label):
    """Raises GenerationError, naming both digests, unless data matches expected."""
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected:
        raise GenerationError(
            "sha256 mismatch for {}: expected {}, actual {}".format(label, expected, actual)
        )


def render(template, pin, template_path, data):
    """Fills the placeholders; raises GenerationError if any placeholder is left."""
    values = {
        "REPOSITORY": pin["repository"],
        "FILE": pin["file"],
        "COMMIT": pin["commit"],
        "SHA256": pin["sha256"],
        "SIZE": str(len(data)),
        "BASE64": base64.b64encode(data).decode("ascii"),
    }
    text = re.sub(
        r"\{\{([A-Za-z0-9_]+)\}\}",
        lambda match: values.get(match.group(1), match.group(0)),
        template,
    )
    leftover = PLACEHOLDER_PATTERN.search(text)
    if leftover:
        line = text.count("\n", 0, leftover.start()) + 1
        raise GenerationError(
            "template {} has an unfilled placeholder {} at line {}".format(
                template_path, leftover.group(0), line
            )
        )
    return text


def write_atomic(path, text):
    """Writes text as UTF-8 with LF endings through a temporary file and os.replace."""
    temporary = path + ".tmp"
    try:
        directory = os.path.dirname(path)
        if directory:
            os.makedirs(directory, exist_ok=True)
        with open(temporary, "wb") as handle:
            handle.write(text.encode("utf-8"))
        os.replace(temporary, path)
    except (OSError, ValueError) as error:
        try:
            os.remove(temporary)
        except (OSError, ValueError):
            pass
        raise GenerationError(
            "cannot write {}: {}".format(path, getattr(error, "strerror", None) or error)
        )


def run(args):
    """Performs one generation; raises GenerationError on any failure."""
    pin = load_pin(args.pin)
    root = os.path.abspath(args.root)
    template_path = os.path.join(root, pin["template"])
    output_path = os.path.join(root, pin["output"])
    template = read_template(template_path)
    url = raw_url(pin)
    if args.source is not None:
        data = read_source(args.source)
        label = args.source
    else:
        data = download(url)
        label = url
    verify_digest(data, pin["sha256"], label)
    text = render(template, pin, template_path, data)
    write_atomic(output_path, text)
    print("Wrote {}".format(output_path))
    return 0


def main(argv=None):
    """Runs the generator with the given arguments and returns the exit status."""
    parser = argparse.ArgumentParser(
        description="Generate the embedded Stellar Asset Contract spec Dart file."
    )
    parser.add_argument(
        "--pin",
        default=DEFAULT_PIN,
        help="pin file (default: pin.json beside this script)",
    )
    parser.add_argument(
        "--root",
        default=DEFAULT_ROOT,
        help="repository root that pin paths resolve against (default: two directories up)",
    )
    parser.add_argument(
        "--source",
        default=None,
        help="local copy of the pinned file, used instead of downloading it",
    )
    args = parser.parse_args(argv)
    try:
        return run(args)
    except GenerationError as error:
        print("generate_sac_spec: error: {}".format(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
