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
        get_latest_release, fetch_router_source, fetch_latest_horizon_source,
        get_latest_rpc_release, fetch_rpc_jsonrpc_source, fetch_latest_rpc_source
    )

    # Horizon
    release = get_latest_release()
    print(f"Latest Horizon version: {release.version}")
    source = fetch_router_source("v25.0.0")
    release, source = fetch_latest_horizon_source()

    # RPC
    rpc_release = get_latest_rpc_release()
    print(f"Latest RPC version: {rpc_release.version}")
    jsonrpc_source = fetch_rpc_jsonrpc_source("v21.5.0")
    rpc_release, jsonrpc_source = fetch_latest_rpc_source()
"""

import json
import os
import urllib.request
import urllib.error
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, Tuple, Optional, List


@dataclass
class GitHubRelease:
    """Metadata for a GitHub release (Horizon or RPC)."""

    version: str
    published_at: datetime
    html_url: str
    commit_sha: Optional[str] = None

    @classmethod
    def from_api_response(cls, data: Dict) -> 'GitHubRelease':
        """
        Create GitHubRelease from GitHub API response.

        Args:
            data: GitHub API release response dictionary

        Returns:
            GitHubRelease instance

        Raises:
            KeyError: If required fields are missing from API response
            ValueError: If date parsing fails
        """
        published_at = datetime.strptime(
            data['published_at'],
            '%Y-%m-%dT%H:%M:%SZ'
        )

        commit_sha = data.get('target_commitish')

        return cls(
            version=data['tag_name'],
            published_at=published_at,
            html_url=data['html_url'],
            commit_sha=commit_sha
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
            return response.read()
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


def get_latest_release() -> HorizonRelease:
    """
    Fetch the latest Horizon release metadata from GitHub API.

    Returns:
        HorizonRelease instance with release metadata

    Raises:
        ReleaseNotFoundError: If no release is found
        GitHubFetchError: If API request fails
    """
    api_url = 'https://api.github.com/repos/stellar/stellar-horizon/releases/latest'

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
        tag: Git tag name (e.g., 'v2.31.0')

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


def fetch_latest_horizon_source() -> Tuple[HorizonRelease, str]:
    """
    Convenience function to fetch both release metadata and router source.

    This function combines get_latest_release() and fetch_router_source()
    to retrieve the latest Horizon release information and its router.go
    source code in a single operation.

    Returns:
        Tuple of (HorizonRelease metadata, router.go source code)

    Raises:
        ReleaseNotFoundError: If no release is found
        SourceFileNotFoundError: If source file cannot be fetched
        GitHubFetchError: If any request fails
    """
    release = get_latest_release()
    source = fetch_router_source(release.version)
    return release, source


def get_latest_rpc_release() -> RPCRelease:
    """
    Fetch the latest Stellar RPC server release metadata from GitHub API.

    This function filters out client library releases (rpcclient-*) and returns
    only server releases (v*).

    Returns:
        RPCRelease instance with release metadata for the latest server release

    Raises:
        ReleaseNotFoundError: If no server release is found
        GitHubFetchError: If API request fails
    """
    # Fetch all releases instead of just /latest to allow filtering
    api_url = 'https://api.github.com/repos/stellar/stellar-rpc/releases'

    try:
        response_data = _make_request(api_url)
        releases = json.loads(response_data.decode('utf-8'))

        if not releases:
            raise ReleaseNotFoundError("No release data returned from GitHub API")

        # Filter for server releases only (exclude client library releases)
        # Server releases: v25.0.0, v24.0.0, etc.
        # Client releases (exclude): rpcclient-v24.0.0, rpcclient-v23.0.0, etc.
        server_releases = [
            release for release in releases
            if release.get('tag_name', '').startswith('v')
            and not release.get('tag_name', '').startswith('rpcclient-')
        ]

        if not server_releases:
            raise ReleaseNotFoundError(
                "No RPC server releases found (all releases are client libraries)"
            )

        # Releases are already sorted by published date (newest first) from GitHub API
        latest_server_release = server_releases[0]

        return RPCRelease.from_api_response(latest_server_release)

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


def fetch_latest_rpc_source() -> Tuple[RPCRelease, str]:
    """
    Convenience function to fetch both RPC release metadata and jsonrpc source.

    This function combines get_latest_rpc_release() and fetch_rpc_jsonrpc_source()
    to retrieve the latest RPC release information and its jsonrpc.go
    source code in a single operation.

    Returns:
        Tuple of (RPCRelease metadata, jsonrpc.go source code)

    Raises:
        ReleaseNotFoundError: If no release is found
        SourceFileNotFoundError: If source file cannot be fetched
        GitHubFetchError: If any request fails
    """
    release = get_latest_rpc_release()
    source = fetch_rpc_jsonrpc_source(release.version)
    return release, source


def fetch_rpc_response_file(tag: str, method_name: str) -> str:
    """
    Fetch response struct source file from go-stellar-sdk for a specific method.

    Response structs are defined in the go-stellar-sdk repository:
    protocols/rpc/get_<method_name>.go

    Args:
        tag: Git tag name (e.g., 'v21.5.0' for RPC). We'll use master/main branch
             since go-stellar-sdk uses different versioning
        method_name: Method name in snake_case (e.g., 'latest_ledger' for getLatestLedger)

    Returns:
        Content of the response file as string

    Raises:
        SourceFileNotFoundError: If source file cannot be fetched
        GitHubFetchError: If request fails
    """
    if not method_name:
        raise ValueError("method_name parameter cannot be empty")

    # Construct raw GitHub URL for the response file in go-stellar-sdk
    # Note: go-stellar-sdk uses different versioning, so we use master branch
    # which contains the latest protocol definitions
    source_url = (
        f"https://raw.githubusercontent.com/stellar/go-stellar-sdk/"
        f"master/protocols/rpc/get_{method_name}.go"
    )

    try:
        response_data = _make_request(source_url)
        return response_data.decode('utf-8')
    except GitHubFetchError as e:
        raise SourceFileNotFoundError(
            f"Failed to fetch get_{method_name}.go from master branch: {e}"
        ) from e


def fetch_all_rpc_response_files(tag: str, method_names: List[str]) -> Dict[str, str]:
    """
    Fetch multiple RPC response files for a given tag.

    Args:
        tag: Git tag name (e.g., 'v21.5.0')
        method_names: List of method names in camelCase (e.g., ['getLatestLedger', 'getHealth'])

    Returns:
        Dictionary mapping method_name -> file content
        Failed fetches are omitted from the result

    Raises:
        GitHubFetchError: If request fails
    """
    results = {}

    for method_name in method_names:
        # Convert camelCase to snake_case
        # getLatestLedger -> latest_ledger
        snake_case = _camel_to_snake(method_name)

        # Remove 'get_' prefix if present (we'll add it in the fetch function)
        if snake_case.startswith('get_'):
            snake_case = snake_case[4:]

        try:
            content = fetch_rpc_response_file(tag, snake_case)
            results[method_name] = content
        except SourceFileNotFoundError:
            # Skip methods that don't have response files
            # (e.g., sendTransaction might use a different pattern)
            continue

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


def main() -> None:
    """
    Main function for standalone testing.

    Fetches latest Horizon release and displays information.
    """
    print("GitHub Fetcher for Stellar Horizon")
    print("-" * 60)

    # Show authentication status
    if is_authenticated():
        print("Authentication: Enabled (5,000 requests/hour)")
    else:
        print("Authentication: Not configured (60 requests/hour)")
        print("  Tip: Set GITHUB_TOKEN env var for higher rate limits")
    print("-" * 60)

    print("Fetching latest Horizon release...")

    try:
        release, source = fetch_latest_horizon_source()

        print(f"Version: {release.version}")
        print(f"Published: {release.published_at.strftime('%Y-%m-%d %H:%M:%S UTC')}")
        print(f"URL: {release.html_url}")
        if release.commit_sha:
            print(f"Commit SHA: {release.commit_sha}")
        print("-" * 60)
        print(f"Router source length: {len(source)} bytes")
        print(f"Router source lines: {source.count(chr(10)) + 1}")
        print("-" * 60)

        # Display first 20 lines of router.go
        lines = source.split('\n')
        print("First 20 lines of router.go:")
        for i, line in enumerate(lines[:20], 1):
            print(f"{i:3d}: {line}")

        if len(lines) > 20:
            print(f"... ({len(lines) - 20} more lines)")

        print("-" * 60)
        print("Fetch successful!")

    except ReleaseNotFoundError as e:
        print(f"ERROR: {e}")
        return
    except SourceFileNotFoundError as e:
        print(f"ERROR: {e}")
        return
    except GitHubFetchError as e:
        print(f"ERROR: {e}")
        return
    except Exception as e:
        print(f"UNEXPECTED ERROR: {e}")
        raise


if __name__ == '__main__':
    main()
