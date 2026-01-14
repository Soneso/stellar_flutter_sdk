"""
Dart File Analyzer

Analyzes existing Dart XDR files to extract custom code sections and metadata.
Supports the CUSTOM_CODE_START/CUSTOM_CODE_END marker pattern for preserving
custom helper methods during code regeneration.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional
from pathlib import Path
import re


@dataclass
class CustomSection:
    """Represents a custom code section marked with CUSTOM_CODE markers."""
    content: str
    class_name: str
    start_marker: str = "// CUSTOM_CODE_START"
    end_marker: str = "// CUSTOM_CODE_END"

    def __str__(self) -> str:
        """Return formatted custom section with markers."""
        return f"{self.start_marker}\n{self.content}{self.end_marker}"


@dataclass
class DartClassInfo:
    """Information about an existing Dart class."""
    name: str
    has_custom_code: bool
    custom_sections: List[CustomSection] = field(default_factory=list)
    imports: List[str] = field(default_factory=list)
    extends_clause: Optional[str] = None
    file_header: Optional[str] = None


class DartAnalyzer:
    """Analyzer for existing Dart XDR files."""

    def __init__(self):
        """Initialize the analyzer with default markers."""
        self.start_marker = "// CUSTOM_CODE_START"
        self.end_marker = "// CUSTOM_CODE_END"

    def analyze_file(self, filepath: str) -> Dict[str, DartClassInfo]:
        """
        Analyze a Dart file and extract class info and custom sections.

        Args:
            filepath: Path to the Dart file to analyze

        Returns:
            Dictionary mapping class names to DartClassInfo objects

        Raises:
            FileNotFoundError: If file doesn't exist
            ValueError: If file has malformed custom code markers
        """
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError(f"File not found: {filepath}")

        content = path.read_text(encoding='utf-8')

        # Validate custom code markers first (check for mismatches and nesting)
        start_count = content.count(self.start_marker)
        end_count = content.count(self.end_marker)
        if start_count != end_count:
            raise ValueError(
                f"Mismatched custom code markers in {filepath}: "
                f"{start_count} starts, {end_count} ends"
            )

        # Check for nested markers if any exist
        if start_count > 0:
            self._validate_no_nested_markers(content)

        # Extract file header (copyright/license before first import)
        file_header = self._extract_file_header(content)

        # Extract imports
        imports = self.extract_imports(content)

        # Extract class names
        class_names = self.extract_class_names(content)

        # Build class info for each class
        classes = {}
        for class_name in class_names:
            custom_sections = self._extract_custom_sections_for_class(content, class_name)
            extends_clause = self._extract_extends_clause(content, class_name)

            classes[class_name] = DartClassInfo(
                name=class_name,
                has_custom_code=len(custom_sections) > 0,
                custom_sections=custom_sections,
                imports=imports,
                extends_clause=extends_clause,
                file_header=file_header
            )

        return classes

    def extract_custom_sections(self, content: str) -> List[CustomSection]:
        """
        Extract all CUSTOM_CODE_START...CUSTOM_CODE_END blocks from content.

        This is a simpler version that doesn't associate sections with classes.
        Use extract_custom_sections_for_class for class-specific extraction.

        Args:
            content: Dart file content

        Returns:
            List of CustomSection objects

        Raises:
            ValueError: If markers are mismatched or nested
        """
        # Verify no unclosed markers
        start_count = content.count(self.start_marker)
        end_count = content.count(self.end_marker)
        if start_count != end_count:
            raise ValueError(
                f"Mismatched custom code markers: {start_count} starts, {end_count} ends"
            )

        # Verify no nested markers
        self._validate_no_nested_markers(content)

        pattern = rf'{re.escape(self.start_marker)}\n(.*?){re.escape(self.end_marker)}'
        matches = list(re.finditer(pattern, content, re.DOTALL))

        sections = []
        for match in matches:
            section_content = match.group(1)
            # Try to determine which class this belongs to
            class_name = self._find_containing_class(content, match.start())
            sections.append(CustomSection(
                content=section_content,
                class_name=class_name or "Unknown"
            ))

        return sections

    def _extract_custom_sections_for_class(
        self, content: str, class_name: str
    ) -> List[CustomSection]:
        """
        Extract custom sections that belong to a specific class.

        Args:
            content: Full Dart file content
            class_name: Name of the class to extract sections for

        Returns:
            List of CustomSection objects for this class
        """
        # Find the class definition (matches extends, with, implements, etc.)
        # Use word boundary \b to avoid matching XdrPublicKey when searching for XdrPublicKeyType
        class_pattern = rf'class\s+{re.escape(class_name)}\b[^{{]*\{{'
        class_match = re.search(class_pattern, content)
        if not class_match:
            return []

        # Find the closing brace for this class
        class_start = class_match.end()
        class_end = self._find_matching_brace(content, class_start - 1)
        if class_end == -1:
            return []

        class_body = content[class_start:class_end]

        # Extract custom sections within this class
        pattern = rf'{re.escape(self.start_marker)}\n(.*?){re.escape(self.end_marker)}'
        matches = re.finditer(pattern, class_body, re.DOTALL)

        sections = []
        for match in matches:
            sections.append(CustomSection(
                content=match.group(1),
                class_name=class_name
            ))

        return sections

    def extract_imports(self, content: str) -> List[str]:
        """
        Extract import statements from a Dart file.

        Args:
            content: Dart file content

        Returns:
            List of import statement strings (e.g., "import 'dart:typed_data';")
        """
        import_pattern = r"^import\s+['\"]([^'\"]+)['\"];?\s*$"
        imports = []

        for line in content.split('\n'):
            match = re.match(import_pattern, line.strip())
            if match:
                # Store the full import statement
                imports.append(line.strip())

        return imports

    def extract_class_names(self, content: str) -> List[str]:
        """
        Extract all class names from a Dart file.

        Args:
            content: Dart file content

        Returns:
            List of class names
        """
        # Match class definitions: class ClassName with various clauses
        # Pattern matches: extends, with, implements, or combinations
        pattern = r'class\s+(\w+)[^{]*\{'
        matches = re.finditer(pattern, content)
        return [match.group(1) for match in matches]

    def _extract_extends_clause(self, content: str, class_name: str) -> Optional[str]:
        """
        Extract the extends clause for a class if it exists.

        Args:
            content: Full Dart file content
            class_name: Name of the class

        Returns:
            The parent class name if extends clause exists, None otherwise
        """
        # Match extends before with/implements/{
        pattern = rf'class\s+{re.escape(class_name)}\s+extends\s+([\w<>,\s]+?)(?:\s+with|\s+implements|\s*\{{)'
        match = re.search(pattern, content)
        if match:
            # Clean up whitespace and return parent class
            return match.group(1).strip()
        return None

    def _extract_file_header(self, content: str) -> Optional[str]:
        """
        Extract file header (copyright/license) before first import.

        Args:
            content: Full Dart file content

        Returns:
            File header string or None if no header found
        """
        # Find first import statement
        import_match = re.search(r'^import\s+', content, re.MULTILINE)
        if not import_match:
            # No imports, check for class definition
            class_match = re.search(r'^class\s+', content, re.MULTILINE)
            if not class_match:
                return None
            header_end = class_match.start()
        else:
            header_end = import_match.start()

        header = content[:header_end].strip()
        return header if header else None

    def _find_containing_class(self, content: str, position: int) -> Optional[str]:
        """
        Find the class that contains the given position in the content.

        Args:
            content: Full Dart file content
            position: Character position in the content

        Returns:
            Class name or None if not inside a class
        """
        # Find all class definitions before this position
        pattern = r'class\s+(\w+)[^{]*\{'
        matches = list(re.finditer(pattern, content[:position]))

        if not matches:
            return None

        # Get the last class before this position
        last_match = matches[-1]
        class_name = last_match.group(1)
        class_start = last_match.end() - 1  # Position of opening brace

        # Verify position is before the closing brace
        class_end = self._find_matching_brace(content, class_start)
        if class_end != -1 and position < class_end:
            return class_name

        return None

    def _validate_no_nested_markers(self, content: str):
        """
        Ensure markers are not nested (which is invalid).

        Args:
            content: Dart file content

        Raises:
            ValueError: If nested markers are detected
        """
        positions = []

        # Find all marker positions
        for match in re.finditer(re.escape(self.start_marker), content):
            positions.append(('start', match.start()))
        for match in re.finditer(re.escape(self.end_marker), content):
            positions.append(('end', match.start()))

        # Sort by position
        positions.sort(key=lambda x: x[1])

        # Track depth - should never exceed 1
        depth = 0
        for marker_type, pos in positions:
            if marker_type == 'start':
                if depth > 0:
                    # Find the line number for better error message
                    line_num = content[:pos].count('\n') + 1
                    raise ValueError(
                        f"Nested CUSTOM_CODE_START marker detected at line {line_num}. "
                        f"Markers cannot be nested."
                    )
                depth += 1
            else:
                depth -= 1
                if depth < 0:
                    line_num = content[:pos].count('\n') + 1
                    raise ValueError(
                        f"CUSTOM_CODE_END marker without matching START at line {line_num}"
                    )

    def extract_class_code(self, content: str, class_name: str) -> Optional[str]:
        """Extract the complete source code for a class including its body."""
        class_pattern = rf'class\s+{re.escape(class_name)}\b[^{{]*\{{'
        class_match = re.search(class_pattern, content)
        if not class_match:
            return None

        class_start = class_match.start()
        class_end = self._find_matching_brace(content, class_match.end() - 1)
        if class_end == -1:
            return None

        return content[class_start:class_end + 1]

    def _find_matching_brace(self, content: str, start_pos: int) -> int:
        """
        Find the position of the closing brace matching an opening brace.

        Handles strings and comments properly:
        - Ignores braces inside single-line comments (// ... \n)
        - Ignores braces inside multi-line comments (/* ... */)
        - Ignores braces inside strings

        Args:
            content: Full content string
            start_pos: Position of the opening brace

        Returns:
            Position of matching closing brace, or -1 if not found
        """
        if start_pos >= len(content) or content[start_pos] != '{':
            return -1

        depth = 1
        pos = start_pos + 1
        in_string = False
        string_char = None
        in_single_comment = False
        in_multi_comment = False

        while pos < len(content) and depth > 0:
            char = content[pos]
            prev_char = content[pos - 1] if pos > 0 else ''
            next_char = content[pos + 1] if pos + 1 < len(content) else ''

            # Handle single-line comment start
            if not in_string and not in_multi_comment and char == '/' and next_char == '/':
                in_single_comment = True
                pos += 2
                continue

            # Handle single-line comment end
            if in_single_comment and char == '\n':
                in_single_comment = False
                pos += 1
                continue

            # Handle multi-line comment start
            if not in_string and not in_single_comment and char == '/' and next_char == '*':
                in_multi_comment = True
                pos += 2
                continue

            # Handle multi-line comment end
            if in_multi_comment and char == '*' and next_char == '/':
                in_multi_comment = False
                pos += 2
                continue

            # Skip processing if in comment
            if in_single_comment or in_multi_comment:
                pos += 1
                continue

            # Handle strings
            if char in ('"', "'") and prev_char != '\\':
                if not in_string:
                    in_string = True
                    string_char = char
                elif char == string_char:
                    in_string = False
                    string_char = None

            # Count braces only outside strings and comments
            if not in_string:
                if char == '{':
                    depth += 1
                elif char == '}':
                    depth -= 1

            if depth == 0:
                return pos

            pos += 1

        return -1


def analyze_xdr_directory(directory: str) -> Dict[str, Dict[str, DartClassInfo]]:
    """
    Analyze all Dart XDR files in a directory.

    Args:
        directory: Path to directory containing Dart XDR files

    Returns:
        Dictionary mapping filenames to their class information

    Example:
        >>> results = analyze_xdr_directory('lib/src/xdr/')
        >>> for filename, classes in results.items():
        ...     print(f"{filename}: {len(classes)} classes")
    """
    analyzer = DartAnalyzer()
    results = {}

    dir_path = Path(directory)
    if not dir_path.exists():
        raise FileNotFoundError(f"Directory not found: {directory}")

    for dart_file in dir_path.glob('xdr_*.dart'):
        try:
            classes = analyzer.analyze_file(str(dart_file))
            results[dart_file.name] = classes
        except Exception as e:
            # Log error but continue processing other files
            print(f"Warning: Failed to analyze {dart_file.name}: {e}")

    return results
