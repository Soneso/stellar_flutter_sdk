"""
XDR Fetcher for Stellar XDR GitHub Releases

Fetch XDR definition files from the stellar/stellar-xdr GitHub repository.
Supports listing versions and downloading .x files for specific releases.

Uses only Python standard library for maximum compatibility.

Authentication:
    To avoid GitHub API rate limits (60 req/hour unauthenticated vs 5,000 authenticated),
    set a GitHub token via one of these methods:

    1. Environment variable: export GITHUB_TOKEN=your_token
    2. gh CLI config: The token is read from ~/.config/gh/hosts.yml if available

    To create a token: https://github.com/settings/tokens
    Required scope: No scopes needed for public repo access (just need authentication)

Example usage:
    from xdr_fetcher import (
        get_available_versions,
        get_latest_version,
        fetch_xdr_files,
    )

    # List all available versions
    versions = get_available_versions()
    print(f"Available versions: {[v.version for v in versions]}")

    # Get latest version
    latest = get_latest_version()
    print(f"Latest version: {latest.version}")

    # Fetch XDR files for a specific version
    xdr_files, failed_files = fetch_xdr_files("v22.0")
    for filename, content in xdr_files.items():
        print(f"{filename}: {len(content)} bytes")
"""

import json
import os
import time
import urllib.request
import urllib.error
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple


@dataclass
class XdrRelease:
    """Metadata for a stellar-xdr release."""

    version: str
    published_at: datetime
    html_url: str
    commit_sha: Optional[str] = None

    @classmethod
    def from_api_response(cls, data: Dict) -> 'XdrRelease':
        """
        Create XdrRelease from GitHub API response.

        Args:
            data: GitHub API release response dictionary

        Returns:
            XdrRelease instance

        Raises:
            KeyError: If required fields are missing from API response
            ValueError: If date parsing fails
        """
        published_at = datetime.strptime(
            data['published_at'],
            '%Y-%m-%dT%H:%M:%SZ'
        )

        # Extract commit SHA if available from target_commitish
        commit_sha = data.get('target_commitish')

        return cls(
            version=data['tag_name'],
            published_at=published_at,
            html_url=data['html_url'],
            commit_sha=commit_sha
        )


class GitHubFetchError(Exception):
    """Base exception for GitHub fetching errors."""
    pass


class ReleaseNotFoundError(GitHubFetchError):
    """Raised when no release is found."""
    pass


class XdrFileNotFoundError(GitHubFetchError):
    """Raised when XDR file cannot be fetched."""
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

    Includes retry logic with exponential backoff for transient errors:
    - Timeouts
    - 5xx server errors
    - Connection errors

    Uses 3 retries with exponential backoff (1s, 2s, 4s delays).

    Args:
        url: URL to fetch
        headers: Optional HTTP headers

    Returns:
        Response body as bytes

    Raises:
        GitHubFetchError: If request fails after all retries
    """
    if headers is None:
        headers = {}

    # Add User-Agent header (GitHub API requires it)
    if 'User-Agent' not in headers:
        headers['User-Agent'] = 'stellar-flutter-sdk-xdr-generator'

    # Add authentication if token is available
    token = get_github_token()
    if token and 'Authorization' not in headers:
        headers['Authorization'] = f'Bearer {token}'

    # Retry configuration
    max_retries = 3
    base_delay = 1.0  # seconds

    for attempt in range(max_retries + 1):
        try:
            request = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(request, timeout=30) as response:
                return response.read()

        except urllib.error.HTTPError as e:
            # Provide helpful message for rate limit errors (don't retry)
            if e.code == 403:
                error_body = e.read().decode('utf-8', errors='ignore')
                if 'rate limit' in error_body.lower():
                    auth_status = "authenticated" if token else "unauthenticated"
                    raise GitHubFetchError(
                        f"GitHub API rate limit exceeded ({auth_status}). "
                        f"Set GITHUB_TOKEN env var for 5,000 requests/hour. "
                        f"See: https://github.com/settings/tokens"
                    ) from e

            # Retry on 5xx server errors
            if e.code >= 500 and attempt < max_retries:
                delay = base_delay * (2 ** attempt)
                time.sleep(delay)
                continue

            # Don't retry on other HTTP errors (4xx, etc.)
            raise GitHubFetchError(
                f"HTTP {e.code} error fetching {url}: {e.reason}"
            ) from e

        except (urllib.error.URLError, TimeoutError, ConnectionError, OSError) as e:
            # Retry on network/connection errors
            if attempt < max_retries:
                delay = base_delay * (2 ** attempt)
                time.sleep(delay)
                continue

            # Provide specific error message based on error type
            if isinstance(e, TimeoutError):
                error_msg = f"Timeout fetching {url}"
            elif isinstance(e, ConnectionError):
                error_msg = f"Connection error fetching {url}: {e}"
            else:
                error_msg = f"Network error fetching {url}: {e.reason if hasattr(e, 'reason') else str(e)}"

            raise GitHubFetchError(error_msg) from e

    # This should never be reached due to the loop structure, but added for completeness
    raise GitHubFetchError(f"Failed to fetch {url} after {max_retries} retries")


def get_available_versions() -> List[XdrRelease]:
    """
    Fetch list of all available stellar-xdr releases from GitHub API.

    Returns:
        List of XdrRelease instances, sorted by published date (newest first)

    Raises:
        ReleaseNotFoundError: If no releases are found
        GitHubFetchError: If API request fails
    """
    api_url = 'https://api.github.com/repos/stellar/stellar-xdr/releases'

    try:
        response_data = _make_request(api_url)
        releases = json.loads(response_data.decode('utf-8'))

        if not releases:
            raise ReleaseNotFoundError("No releases found in stellar/stellar-xdr")

        # Convert to XdrRelease objects
        xdr_releases = [XdrRelease.from_api_response(r) for r in releases]

        # Already sorted by published date from GitHub API
        return xdr_releases

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


def get_latest_version() -> XdrRelease:
    """
    Fetch the latest stellar-xdr release metadata from GitHub API.

    Returns:
        XdrRelease instance for the latest release

    Raises:
        ReleaseNotFoundError: If no release is found
        GitHubFetchError: If API request fails
    """
    api_url = 'https://api.github.com/repos/stellar/stellar-xdr/releases/latest'

    try:
        response_data = _make_request(api_url)
        data = json.loads(response_data.decode('utf-8'))

        if not data:
            raise ReleaseNotFoundError("No release data returned from GitHub API")

        return XdrRelease.from_api_response(data)

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


def _fetch_file_from_tag(tag: str, filename: str) -> str:
    """
    Fetch a single file from a specific tag in stellar-xdr repository.

    Args:
        tag: Git tag name (e.g., 'v22.0')
        filename: Name of file to fetch (e.g., 'Stellar-types.x')

    Returns:
        File content as string

    Raises:
        ValueError: If tag parameter is empty
        XdrFileNotFoundError: If file cannot be fetched
        GitHubFetchError: If request fails
    """
    if not tag:
        raise ValueError("Tag parameter cannot be empty")

    # Construct raw GitHub URL for the file
    source_url = (
        f"https://raw.githubusercontent.com/stellar/stellar-xdr/"
        f"{tag}/{filename}"
    )

    try:
        response_data = _make_request(source_url)
        return response_data.decode('utf-8')
    except GitHubFetchError as e:
        raise XdrFileNotFoundError(
            f"Failed to fetch {filename} for tag {tag}: {e}"
        ) from e


def _get_xdr_file_list(tag: str) -> List[str]:
    """
    Get list of .x files in a specific release.

    Uses GitHub API to list contents of repository at a specific tag.

    Args:
        tag: Git tag name (e.g., 'v22.0')

    Returns:
        List of .x filenames

    Raises:
        GitHubFetchError: If API request fails
    """
    # Use GitHub API to list repository contents at specific tag
    api_url = f'https://api.github.com/repos/stellar/stellar-xdr/contents?ref={tag}'

    try:
        response_data = _make_request(api_url)
        contents = json.loads(response_data.decode('utf-8'))

        # Filter for .x files only
        xdr_files = [
            item['name']
            for item in contents
            if item.get('type') == 'file' and item.get('name', '').endswith('.x')
        ]

        return sorted(xdr_files)

    except json.JSONDecodeError as e:
        raise GitHubFetchError(
            f"Invalid JSON response from GitHub API: {e}"
        ) from e
    except (KeyError, TypeError) as e:
        raise GitHubFetchError(
            f"Unexpected API response format: {e}"
        ) from e


def fetch_xdr_files(version: str) -> Tuple[Dict[str, str], List[str]]:
    """
    Fetch all XDR definition files for a specific version.

    Args:
        version: Release version tag (e.g., 'v22.0' or 'latest')

    Returns:
        Tuple of (successful_files, failed_files):
        - successful_files: Dictionary mapping filename to file content
        - failed_files: List of filenames that failed to fetch

    Raises:
        ReleaseNotFoundError: If version not found
        XdrFileNotFoundError: If no XDR files can be fetched
        GitHubFetchError: If request fails
    """
    # Handle 'latest' version
    if version.lower() == 'latest':
        latest = get_latest_version()
        version = latest.version

    # Ensure version has 'v' prefix
    if not version.startswith('v'):
        version = f'v{version}'

    # Get list of .x files
    xdr_filenames = _get_xdr_file_list(version)

    if not xdr_filenames:
        raise XdrFileNotFoundError(
            f"No .x files found in stellar-xdr {version}"
        )

    # Fetch each file
    xdr_files = {}
    failed_files = []
    for filename in xdr_filenames:
        try:
            content = _fetch_file_from_tag(version, filename)
            xdr_files[filename] = content
        except XdrFileNotFoundError as e:
            # Continue on error, but collect error info
            print(f"Warning: Failed to fetch {filename}: {e}")
            failed_files.append(filename)
            continue

    if not xdr_files:
        raise XdrFileNotFoundError(
            f"Failed to fetch any .x files from stellar-xdr {version}"
        )

    return xdr_files, failed_files


def main() -> None:
    """
    Main function for standalone testing.

    Lists available versions and fetches files for latest version.
    """
    print("XDR Fetcher for stellar-xdr")
    print("-" * 60)

    # Show authentication status
    if is_authenticated():
        print("Authentication: Enabled (5,000 requests/hour)")
    else:
        print("Authentication: Not configured (60 requests/hour)")
        print("  Tip: Set GITHUB_TOKEN env var for higher rate limits")
    print("-" * 60)

    try:
        # Get available versions
        print("\nFetching available versions...")
        versions = get_available_versions()
        print(f"Found {len(versions)} releases:")
        for v in versions[:10]:  # Show first 10
            print(f"  {v.version} - {v.published_at.strftime('%Y-%m-%d')}")
        if len(versions) > 10:
            print(f"  ... and {len(versions) - 10} more")

        # Get latest version
        print("\nFetching latest version...")
        latest = get_latest_version()
        print(f"Latest version: {latest.version}")
        print(f"Published: {latest.published_at.strftime('%Y-%m-%d %H:%M:%S UTC')}")
        print(f"URL: {latest.html_url}")
        if latest.commit_sha:
            print(f"Commit SHA: {latest.commit_sha}")

        # Fetch XDR files
        print(f"\nFetching XDR files for {latest.version}...")
        xdr_files, failed_files = fetch_xdr_files(latest.version)
        print(f"Fetched {len(xdr_files)} XDR files:")
        for filename, content in sorted(xdr_files.items()):
            lines = content.count('\n') + 1
            print(f"  {filename}: {len(content)} bytes, {lines} lines")

        if failed_files:
            print(f"\nWarning: {len(failed_files)} files failed to fetch:")
            for filename in failed_files:
                print(f"  {filename}")

        print("-" * 60)
        print("Fetch successful!")

    except ReleaseNotFoundError as e:
        print(f"ERROR: {e}")
        return
    except XdrFileNotFoundError as e:
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
