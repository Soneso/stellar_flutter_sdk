#!/usr/bin/env python3
"""
GitHub Fetcher for Stellar Horizon and RPC Source Code

This module provides functionality to fetch the latest Horizon and RPC release information
and source code from the stellar/stellar-horizon and stellar/stellar-rpc GitHub repositories.

Uses only Python standard library for maximum compatibility.

Authentication:
    To avoid GitHub API rate limits (60 req/hour unauthenticated vs 5,000 authenticated),
    set a GitHub token via one of these methods:

    1. Environment variable: export GITHUB_TOKEN=your_token
    2. gh CLI config: The token is read from ~/.config/gh/hosts.yml if available

    To create a token: https://github.com/settings/tokens
    Required scope: No scopes needed for public repo access (just need authentication)

Example usage:
    from github_fetcher import (
        get_horizon_release, fetch_router_source,
        get_latest_rpc_release, get_rpc_release, fetch_rpc_jsonrpc_source
    )

    # Horizon
    release = get_horizon_release()
    source = fetch_router_source(release.version)

    # RPC
    rpc_release = get_latest_rpc_release()
    pinned_release = get_rpc_release("v28.0.1")
    jsonrpc_source = fetch_rpc_jsonrpc_source(pinned_release.version)
"""

import json
import os
import re
import urllib.request
import urllib.error
from dataclasses import dataclass
from datetime import datetime
from email.message import Message
from pathlib import Path
from typing import Any, Dict, Tuple, Optional, List


@dataclass
class GitHubRelease:
    """Metadata for a GitHub release (Horizon or RPC)."""

    version: str
    published_at: Optional[datetime]
    html_url: str

    @classmethod
    def from_api_response(cls, data: Dict) -> 'GitHubRelease':
        """
        Create GitHubRelease from GitHub API response.

        Args:
            data: GitHub API release response dictionary

        Returns:
            GitHubRelease instance; published_at is None when the record's
            published_at is null

        Raises:
            KeyError: If required fields are missing from API response
            ValueError: If date parsing fails
        """
        published_at = None
        if data['published_at'] is not None:
            published_at = datetime.strptime(
                data['published_at'],
                '%Y-%m-%dT%H:%M:%SZ'
            )

        return cls(
            version=data['tag_name'],
            published_at=published_at,
            html_url=data['html_url']
        )


# Backwards-compatible aliases
HorizonRelease = GitHubRelease
RPCRelease = GitHubRelease


class GitHubFetchError(Exception):
    """Base exception for GitHub fetching errors."""
    pass


class ReleaseNotFoundError(GitHubFetchError):
    """Raised when no release is found."""
    pass


class SourceFileNotFoundError(GitHubFetchError):
    """Raised when source file cannot be fetched."""
    pass


# Cache for GitHub token
_github_token_cache: Optional[str] = None
_github_token_checked: bool = False


def get_github_token() -> Optional[str]:
    """
    Get GitHub token for authenticated API requests.

    Checks in order:
    1. GITHUB_TOKEN environment variable
    2. gh CLI config file (~/.config/gh/hosts.yml)

    Returns:
        GitHub token string, or None if not found

    Note:
        Authenticated requests get 5,000 requests/hour vs 60 for unauthenticated.
    """
    global _github_token_cache, _github_token_checked

    if _github_token_checked:
        return _github_token_cache

    _github_token_checked = True

    # Check environment variable first
    token = os.environ.get('GITHUB_TOKEN')
    if token:
        _github_token_cache = token
        return token

    # Check gh CLI config
    gh_config_path = Path.home() / '.config' / 'gh' / 'hosts.yml'
    if gh_config_path.exists():
        try:
            content = gh_config_path.read_text()
            # Simple YAML parsing for the token (avoid external dependencies)
            # Format: github.com:\n    oauth_token: TOKEN
            for line in content.split('\n'):
                if 'oauth_token:' in line:
                    token = line.split('oauth_token:')[1].strip()
                    if token:
                        _github_token_cache = token
                        return token
        except (IOError, IndexError):
            pass

    return None


def is_authenticated() -> bool:
    """Check if GitHub authentication is available."""
    return get_github_token() is not None


def _make_request(url: str, headers: Optional[Dict[str, str]] = None) -> bytes:
    """
    Make HTTP request with proper error handling and authentication.

    Args:
        url: URL to fetch
        headers: Optional HTTP headers

    Returns:
        Response body as bytes

    Raises:
        GitHubFetchError: If request fails
    """
    body, _ = _make_request_with_headers(url, headers)
    return body


def _make_request_with_headers(
    url: str,
    headers: Optional[Dict[str, str]] = None
) -> Tuple[bytes, Message]:
    """
    Make HTTP request and return the response body with the response headers.

    Paginated GitHub API lists announce their next page in the Link header.

    Args:
        url: URL to fetch
        headers: Optional HTTP headers

    Returns:
        Tuple of (response body as bytes, response headers)

    Raises:
        GitHubFetchError: If request fails
    """
    if headers is None:
        headers = {}

    # Add User-Agent header (GitHub API requires it)
    if 'User-Agent' not in headers:
        headers['User-Agent'] = 'stellar-flutter-sdk-compatibility-tools'

    # Add authentication if token is available
    token = get_github_token()
    if token and 'Authorization' not in headers:
        headers['Authorization'] = f'Bearer {token}'

    request = urllib.request.Request(url, headers=headers)

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.read(), response.headers
    except urllib.error.HTTPError as e:
        # Provide helpful message for rate limit errors
        if e.code == 403 and 'rate limit' in str(e.reason).lower():
            auth_status = "authenticated" if token else "unauthenticated"
            raise GitHubFetchError(
                f"GitHub API rate limit exceeded ({auth_status}). "
                f"Set GITHUB_TOKEN env var for 5,000 requests/hour. "
                f"See: https://github.com/settings/tokens"
            ) from e
        raise GitHubFetchError(
            f"HTTP {e.code} error fetching {url}: {e.reason}"
        ) from e
    except urllib.error.URLError as e:
        raise GitHubFetchError(
            f"Network error fetching {url}: {e.reason}"
        ) from e
    except TimeoutError as e:
        raise GitHubFetchError(
            f"Timeout fetching {url}"
        ) from e


def get_horizon_release(tag: Optional[str] = None) -> HorizonRelease:
    """
    Fetch a Horizon release record from GitHub API.

    Args:
        tag: Release tag (e.g. 'v28.0.1'). None selects the latest release.

    Returns:
        HorizonRelease instance with release metadata

    Raises:
        ReleaseNotFoundError: If no release is found
        GitHubFetchError: If API request fails
    """
    api_url = 'https://api.github.com/repos/stellar/stellar-horizon/releases/' + (
        f'tags/{tag}' if tag else 'latest'
    )

    try:
        response_data = _make_request(api_url)
        data = json.loads(response_data.decode('utf-8'))

        if not data:
            raise ReleaseNotFoundError("No release data returned from GitHub API")

        return HorizonRelease.from_api_response(data)

    except json.JSONDecodeError as e:
        raise GitHubFetchError(
            f"Invalid JSON response from GitHub API: {e}"
        ) from e
    except KeyError as e:
        raise GitHubFetchError(
            f"Missing required field in API response: {e}"
        ) from e
    except ValueError as e:
        raise GitHubFetchError(
            f"Invalid data format in API response: {e}"
        ) from e


def fetch_router_source(tag: str) -> str:
    """
    Fetch router.go source code for a specific Horizon release tag.

    Args:
        tag: Git tag name (e.g., 'v28.0.1')

    Returns:
        Content of router.go as string

    Raises:
        SourceFileNotFoundError: If source file cannot be fetched
        GitHubFetchError: If request fails
    """
    if not tag:
        raise ValueError("Tag parameter cannot be empty")

    # Construct raw GitHub URL for router.go
    source_url = (
        f"https://raw.githubusercontent.com/stellar/stellar-horizon/"
        f"{tag}/internal/httpx/router.go"
    )

    try:
        response_data = _make_request(source_url)
        return response_data.decode('utf-8')
    except GitHubFetchError as e:
        raise SourceFileNotFoundError(
            f"Failed to fetch router.go for tag {tag}: {e}"
        ) from e


_RPC_RELEASES_URL = (
    'https://api.github.com/repos/stellar/stellar-rpc/releases?per_page=100'
)

# Tag of a stable stellar-rpc server release, applied with fullmatch. Client
# library releases (rpcclient-v*) and release candidates (v29.0.0-rc.1) do not
# match.
_STABLE_RPC_TAG = re.compile(r'v([0-9]+)\.([0-9]+)\.([0-9]+)')

# Tag a --rpc-version override may name, applied with fullmatch: a server
# release, stable or prerelease. The matrix header's RPC Version line carries
# this form.
_RPC_RELEASE_TAG = re.compile(r'v[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.]+)?')

# Next-page entry of a GitHub Link header: <url>; rel="next"
_NEXT_PAGE_LINK = re.compile(r'<([^>]+)>\s*;\s*rel="next"')


def _is_release_record(record: Any) -> bool:
    """Check that a release list entry carries the fields selection reads."""
    return (
        isinstance(record, dict)
        and isinstance(record.get('tag_name'), str)
        and isinstance(record.get('draft'), bool)
        and isinstance(record.get('prerelease'), bool)
    )


def _fetch_rpc_release_records() -> List[Dict[str, Any]]:
    """
    Fetch every stellar-rpc release record, following Link rel="next" pages.

    Returns:
        Release records in API order, drafts included

    Raises:
        GitHubFetchError: If a request fails, a page is not a JSON array of
            release records, or the pagination repeats a page
    """
    records: List[Dict[str, Any]] = []
    requested = set()
    url: Optional[str] = _RPC_RELEASES_URL

    while url:
        if url in requested:
            raise GitHubFetchError(
                f"stellar-rpc release list pagination repeats {url}"
            )
        requested.add(url)

        body, headers = _make_request_with_headers(url)
        try:
            page = json.loads(body.decode('utf-8'))
        except ValueError as e:
            raise GitHubFetchError(
                f"Invalid JSON in the stellar-rpc release list at {url}: {e}"
            ) from e

        if not isinstance(page, list):
            raise GitHubFetchError(
                f"The stellar-rpc release list at {url} is not a JSON array"
            )
        for record in page:
            if not _is_release_record(record):
                raise GitHubFetchError(
                    f"Invalid release record in the stellar-rpc release list "
                    f"at {url}: {record!r:.200}"
                )
        records.extend(page)

        next_link = _NEXT_PAGE_LINK.search(headers.get('Link') or '')
        url = next_link.group(1) if next_link else None

    return records


def _stable_version(record: Dict[str, Any]) -> Optional[Tuple[int, int, int]]:
    """
    Return the numeric version of a published stable server release.

    Returns:
        (major, minor, patch), or None for a draft, a prerelease (flagged by
        the API even when the tag has no suffix), or a tag that is not vX.Y.Z
    """
    if record['draft'] or record['prerelease']:
        return None
    match = _STABLE_RPC_TAG.fullmatch(record['tag_name'])
    if not match:
        return None
    major, minor, patch = (int(part) for part in match.groups())
    return major, minor, patch


def _rpc_release_from_record(record: Dict[str, Any]) -> RPCRelease:
    """
    Build an RPCRelease from a validated release list record.

    Raises:
        GitHubFetchError: If the record lacks html_url or published_at, or
            published_at is neither null nor an ISO 8601 UTC timestamp
    """
    try:
        return RPCRelease.from_api_response(record)
    except KeyError as e:
        raise GitHubFetchError(
            f"Missing field {e} in stellar-rpc release {record['tag_name']}"
        ) from e
    except (TypeError, ValueError) as e:
        raise GitHubFetchError(
            f"Invalid published_at in stellar-rpc release "
            f"{record['tag_name']}: {e}"
        ) from e


def get_latest_rpc_release() -> RPCRelease:
    """
    Fetch the newest stable Stellar RPC server release from GitHub API.

    Candidates are the records whose tag is vX.Y.Z with draft and prerelease
    both false, across every page of the release list. The highest version by
    numeric comparison wins: the API lists releases by creation date, and a
    patch release on an older line is created after newer versions.

    Returns:
        RPCRelease instance with release metadata for the newest stable release

    Raises:
        ReleaseNotFoundError: If no record qualifies
        GitHubFetchError: If the release list cannot be fetched or is invalid
    """
    records = _fetch_rpc_release_records()

    candidates = []
    for record in records:
        version = _stable_version(record)
        if version is not None:
            candidates.append((version, record))

    if not candidates:
        raise ReleaseNotFoundError(
            f"No stable stellar-rpc release (tag vX.Y.Z, not draft, not "
            f"prerelease) among {len(records)} release records"
        )

    _, newest = max(candidates, key=lambda candidate: candidate[0])
    return _rpc_release_from_record(newest)


def get_rpc_release(tag: str) -> RPCRelease:
    """
    Fetch the Stellar RPC release record for a given tag.

    A prerelease is accepted. A draft is rejected: it is unpublished. A client
    library tag (rpcclient-v*) is rejected: it is not a server release.

    Args:
        tag: stellar-rpc release tag (e.g. 'v28.0.1')

    Returns:
        RPCRelease instance built from that tag's release record

    Raises:
        ReleaseNotFoundError: If the tag is not of the form vX.Y.Z or
            vX.Y.Z-suffix, is not in the release list, or is a draft
        GitHubFetchError: If the release list cannot be fetched or is invalid
    """
    if not _RPC_RELEASE_TAG.fullmatch(tag):
        raise ReleaseNotFoundError(
            f"{tag!r} is not a stellar-rpc release tag of the form vX.Y.Z or vX.Y.Z-suffix"
        )

    records = _fetch_rpc_release_records()

    record = next((r for r in records if r['tag_name'] == tag), None)
    if record is None:
        raise ReleaseNotFoundError(
            f"stellar-rpc release {tag} is not in the release list of "
            f"stellar/stellar-rpc"
        )
    if record['draft']:
        raise ReleaseNotFoundError(
            f"stellar-rpc release {tag} is a draft; only published releases "
            f"can be cited"
        )

    return _rpc_release_from_record(record)


def fetch_rpc_jsonrpc_source(tag: str) -> str:
    """
    Fetch jsonrpc.go source code for a specific Stellar RPC release tag.

    Args:
        tag: Git tag name (e.g., 'v21.5.0')

    Returns:
        Content of jsonrpc.go as string

    Raises:
        SourceFileNotFoundError: If source file cannot be fetched
        GitHubFetchError: If request fails
    """
    if not tag:
        raise ValueError("Tag parameter cannot be empty")

    # Construct raw GitHub URL for jsonrpc.go
    source_url = (
        f"https://raw.githubusercontent.com/stellar/stellar-rpc/"
        f"{tag}/cmd/stellar-rpc/internal/jsonrpc.go"
    )

    try:
        response_data = _make_request(source_url)
        return response_data.decode('utf-8')
    except GitHubFetchError as e:
        raise SourceFileNotFoundError(
            f"Failed to fetch jsonrpc.go for tag {tag}: {e}"
        ) from e


# Cache of resolved go-stellar-sdk refs, keyed by the stellar-rpc tag, so the
# dependency is read from go.mod at most once per analysis run.
_GO_STELLAR_SDK_REF_CACHE: Dict[str, str] = {}


def _resolve_go_stellar_sdk_ref(rpc_tag: str) -> str:
    """
    Resolve the go-stellar-sdk git ref pinned by stellar-rpc at a given tag.

    The RPC response structs (protocols/rpc/get_<method>.go) live in
    go-stellar-sdk, which versions independently of stellar-rpc. Reading them
    from the ref that stellar-rpc@<rpc_tag> depends on (per its go.mod) keeps the
    field comparison matched to the RPC release under review rather than drifting
    with go-stellar-sdk master.

    Args:
        rpc_tag: stellar-rpc release tag (e.g. 'v27.0.0').

    Returns:
        A git ref usable on raw.githubusercontent.com: the release tag for a
        normal version (e.g. 'v0.6.0'), or the commit hash for a pseudo-version.

    Raises:
        SourceFileNotFoundError: If go.mod or the dependency cannot be read.
    """
    if rpc_tag in _GO_STELLAR_SDK_REF_CACHE:
        return _GO_STELLAR_SDK_REF_CACHE[rpc_tag]

    go_mod_url = (
        f"https://raw.githubusercontent.com/stellar/stellar-rpc/"
        f"{rpc_tag}/go.mod"
    )
    try:
        content = _make_request(go_mod_url).decode('utf-8')
    except GitHubFetchError as e:
        raise SourceFileNotFoundError(
            f"Failed to fetch go.mod for stellar-rpc tag {rpc_tag}: {e}"
        ) from e

    match = re.search(r'github\.com/stellar/go-stellar-sdk\s+(\S+)', content)
    if not match:
        raise SourceFileNotFoundError(
            f"go-stellar-sdk dependency not found in stellar-rpc@{rpc_tag} go.mod"
        )

    version = match.group(1)
    # A Go pseudo-version is not a git tag; its git ref is the trailing commit
    # hash. Both pseudo-version forms carry a 14-digit UTC timestamp directly
    # before the final hash segment: vX.Y.Z-yyyymmddhhmmss-<12 hex> (no base
    # release) and vX.Y.Z-0.yyyymmddhhmmss-<12 hex> / -pre.0.yyyymmddhhmmss-
    # (base-incremented). A normal release tag is used as-is.
    pseudo = re.match(r'^v\S*\d{14}-([0-9a-f]{12})$', version)
    ref = pseudo.group(1) if pseudo else version

    _GO_STELLAR_SDK_REF_CACHE[rpc_tag] = ref
    return ref


def fetch_rpc_response_file(tag: str, method_name: str) -> str:
    """
    Fetch a response-struct source file from go-stellar-sdk for a method.

    Response structs are defined in go-stellar-sdk at
    protocols/rpc/<method_name>.go. go-stellar-sdk versions independently of
    stellar-rpc, so the ref is resolved from stellar-rpc@<tag>'s go.mod
    (see _resolve_go_stellar_sdk_ref) to match the RPC release under review.

    Args:
        tag: stellar-rpc release tag (e.g. 'v27.0.0').
        method_name: Full method name in snake_case (e.g. 'get_latest_ledger'
            for getLatestLedger, 'send_transaction' for sendTransaction).

    Returns:
        Content of the response file as string.

    Raises:
        SourceFileNotFoundError: If the source file cannot be fetched.
        GitHubFetchError: If a request fails.
    """
    if not tag:
        raise ValueError("Tag parameter cannot be empty")
    if not method_name:
        raise ValueError("method_name parameter cannot be empty")

    sdk_ref = _resolve_go_stellar_sdk_ref(tag)
    source_url = (
        f"https://raw.githubusercontent.com/stellar/go-stellar-sdk/"
        f"{sdk_ref}/protocols/rpc/{method_name}.go"
    )

    try:
        response_data = _make_request(source_url)
        return response_data.decode('utf-8')
    except GitHubFetchError as e:
        raise SourceFileNotFoundError(
            f"Failed to fetch {method_name}.go from "
            f"go-stellar-sdk@{sdk_ref}: {e}"
        ) from e


def fetch_all_rpc_response_files(tag: str, method_names: List[str]) -> Dict[str, str]:
    """
    Fetch the response file of every given RPC method for a given tag.

    Every RPC method has a response struct in go-stellar-sdk, so the first
    file that cannot be fetched stops the run.

    Args:
        tag: Git tag name (e.g., 'v21.5.0')
        method_names: List of method names in camelCase (e.g., ['getLatestLedger', 'getHealth'])

    Returns:
        Dictionary mapping each method_name -> file content

    Raises:
        SourceFileNotFoundError: If a response file cannot be fetched
        GitHubFetchError: If request fails
    """
    results = {}

    for method_name in method_names:
        # Convert camelCase to snake_case: the response file is named after the
        # full method name (getLatestLedger -> get_latest_ledger.go,
        # sendTransaction -> send_transaction.go).
        snake_case = _camel_to_snake(method_name)
        results[method_name] = fetch_rpc_response_file(tag, snake_case)

    return results


def _camel_to_snake(name: str) -> str:
    """
    Convert camelCase to snake_case.

    Args:
        name: camelCase string (e.g., 'getLatestLedger')

    Returns:
        snake_case string (e.g., 'get_latest_ledger')
    """
    # Insert underscore before uppercase letters
    result = []
    for i, char in enumerate(name):
        if char.isupper() and i > 0:
            result.append('_')
        result.append(char.lower())
    return ''.join(result)
