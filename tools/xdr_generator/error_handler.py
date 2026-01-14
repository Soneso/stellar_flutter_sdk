"""
Error handling classes for XDR code generator.

Provides structured error and warning types for different failure modes,
plus a centralized error handler to collect and report issues.
"""

import sys
from typing import List


class XdrParseError(Exception):
    """
    Failed to parse XDR file - FATAL.

    Raised when XDR syntax cannot be parsed into AST nodes.
    Generation cannot continue after this error.
    """
    pass


class UnknownTypeError(Exception):
    """
    Referenced type not found in XDR definitions.

    Raised when a field references a type that doesn't exist
    in the parsed XDR definitions.
    """

    def __init__(self, type_name: str, referenced_in: str):
        """
        Initialize UnknownTypeError.

        Args:
            type_name: Name of the unknown type
            referenced_in: Name of the type/struct where reference occurs
        """
        self.type_name = type_name
        self.referenced_in = referenced_in
        super().__init__(
            f"Unknown type '{type_name}' referenced in '{referenced_in}'"
        )


class CircularDependencyError(Exception):
    """
    Circular import dependency detected - FATAL.

    Raised when two or more files have circular dependencies,
    making proper import ordering impossible.
    """

    def __init__(self, file_a: str, file_b: str):
        """
        Initialize CircularDependencyError.

        Args:
            file_a: First file in circular dependency
            file_b: Second file in circular dependency
        """
        self.file_a = file_a
        self.file_b = file_b
        super().__init__(
            f"Circular dependency between '{file_a}' and '{file_b}'"
        )


class CustomCodeConflict(Exception):
    """
    Custom code conflicts with generated code.

    Raised when custom code sections cannot be properly merged
    with generated code (e.g., method name collisions).
    """

    def __init__(self, class_name: str, conflict_description: str):
        """
        Initialize CustomCodeConflict.

        Args:
            class_name: Name of the class with conflict
            conflict_description: Description of the conflict
        """
        self.class_name = class_name
        self.conflict_description = conflict_description
        super().__init__(
            f"Custom code conflict in '{class_name}': {conflict_description}"
        )


class RemovedTypeWarning(Warning):
    """
    Type exists in Dart but not in new XDR version.

    Raised when an existing Dart XDR type is not present in
    the new XDR definitions being generated.
    """

    def __init__(self, type_name: str, version: str):
        """
        Initialize RemovedTypeWarning.

        Args:
            type_name: Name of the removed type
            version: XDR version where type is missing
        """
        self.type_name = type_name
        self.version = version
        super().__init__(
            f"Type '{type_name}' not found in stellar-xdr {version}"
        )


class GeneratorErrorHandler:
    """
    Central error handler for XDR code generator.

    Collects errors and warnings during generation process,
    provides formatted reporting, and determines exit status.
    """

    def __init__(self, verbose: bool = False):
        """
        Initialize GeneratorErrorHandler.

        Args:
            verbose: Enable verbose error reporting
        """
        self.errors: List[Exception] = []
        self.warnings: List[Warning] = []
        self.verbose = verbose

    def handle_parse_error(self, error: Exception, file: str) -> None:
        """
        Handle fatal parse error - exits immediately.

        Args:
            error: The parse exception
            file: Name of file that failed to parse
        """
        print(f"FATAL: Failed to parse {file}: {error}", file=sys.stderr)
        sys.exit(1)

    def handle_circular_dependency(self, file_a: str, file_b: str) -> None:
        """
        Handle circular dependency - exits immediately.

        Args:
            file_a: First file in circular dependency
            file_b: Second file in circular dependency
        """
        print(
            f"FATAL: Circular dependency detected between {file_a} and {file_b}",
            file=sys.stderr
        )
        print(
            "This must be resolved by adjusting file_mapping.py configuration.",
            file=sys.stderr
        )
        sys.exit(1)

    def add_error(self, error: Exception) -> None:
        """
        Add non-fatal error to collection.

        Args:
            error: The error to collect
        """
        self.errors.append(error)
        if self.verbose:
            print(f"ERROR: {error}", file=sys.stderr)

    def add_warning(self, warning: Warning) -> None:
        """
        Add warning to collection.

        Args:
            warning: The warning to collect
        """
        self.warnings.append(warning)
        if self.verbose:
            print(f"WARNING: {warning}", file=sys.stderr)

    def add_removed_type_warning(self, type_name: str, version: str) -> None:
        """
        Add warning for type not present in new XDR version.

        Args:
            type_name: Name of removed type
            version: XDR version where type is missing
        """
        warning = RemovedTypeWarning(type_name, version)
        self.add_warning(warning)

    def add_unknown_type_error(self, type_name: str, referenced_in: str) -> None:
        """
        Add error for unknown type reference.

        Args:
            type_name: Name of unknown type
            referenced_in: Location of reference
        """
        error = UnknownTypeError(type_name, referenced_in)
        self.add_error(error)

    def add_custom_code_conflict(self, class_name: str, conflict: str) -> None:
        """
        Add error for custom code conflict.

        Args:
            class_name: Name of class with conflict
            conflict: Description of conflict
        """
        error = CustomCodeConflict(class_name, conflict)
        self.add_error(error)

    def has_errors(self) -> bool:
        """Check if any errors were collected."""
        return len(self.errors) > 0

    def has_warnings(self) -> bool:
        """Check if any warnings were collected."""
        return len(self.warnings) > 0

    def print_summary(self) -> None:
        """Print summary of all collected errors and warnings."""
        if self.errors:
            print(f"\n{len(self.errors)} error(s) occurred:", file=sys.stderr)
            for i, error in enumerate(self.errors, 1):
                print(f"  {i}. {error}", file=sys.stderr)

        if self.warnings:
            print(f"\n{len(self.warnings)} warning(s):", file=sys.stderr)
            for i, warning in enumerate(self.warnings, 1):
                print(f"  {i}. {warning}", file=sys.stderr)

    def finalize(self) -> None:
        """
        Finalize error handling and exit if errors occurred.

        Prints summary and exits with code 1 if any errors were collected.
        Exits with code 0 if only warnings (or no issues) occurred.
        """
        self.print_summary()

        if self.errors:
            print(f"\nGeneration FAILED with {len(self.errors)} error(s)", file=sys.stderr)
            sys.exit(1)

        if self.warnings:
            print(f"\nGeneration completed with {len(self.warnings)} warning(s)")
        else:
            print("\nGeneration completed successfully")
