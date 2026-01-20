"""
Dart Code Merger

Merges generated Dart XDR code with custom sections from existing files.
Preserves custom helper methods marked with CUSTOM_CODE markers while
updating all generated code.
"""

from typing import Dict, List, Optional
from pathlib import Path
import re

try:
    from .dart_analyzer import DartAnalyzer, CustomSection, DartClassInfo
    from .type_mapping import TypeMapper
except ImportError:
    # Allow running standalone
    from dart_analyzer import DartAnalyzer, CustomSection, DartClassInfo
    from type_mapping import TypeMapper


class DartMerger:
    """Merges generated code with custom sections from existing files."""

    def __init__(self, analyzer: Optional[DartAnalyzer] = None, type_mapper: Optional[TypeMapper] = None):
        """
        Initialize the merger.

        Args:
            analyzer: DartAnalyzer instance (creates new one if None)
            type_mapper: TypeMapper instance for checking inline struct aliases (creates new one if None)
        """
        self.analyzer = analyzer or DartAnalyzer()
        self.type_mapper = type_mapper or TypeMapper()
        self._last_missing_classes: List[str] = []

    def _detect_methods_in_custom_code(self, custom_content: str) -> List[str]:
        """
        Detect method names defined in custom code section.

        Args:
            custom_content: The content of the custom code section

        Returns:
            List of method names found in the custom code
        """
        method_names = []

        # Pattern matches static and instance methods:
        # - static void encode(...) or static Foo decode(...)
        # - void method(...) or Foo method(...)
        # Captures the method name
        pattern = r'(?:static\s+)?(?:\w+\??)\s+(\w+)\s*\('

        matches = re.finditer(pattern, custom_content)
        for match in matches:
            method_name = match.group(1)
            # Filter out common non-method patterns
            if method_name not in ['if', 'for', 'while', 'switch', 'return', 'get', 'set']:
                method_names.append(method_name)

        return method_names

    def merge_file(
        self,
        generated_content: str,
        existing_filepath: Optional[str] = None
    ) -> str:
        """
        Merge generated code with custom sections from existing file.

        If existing_filepath is None or doesn't exist, returns generated_content as-is.

        Args:
            generated_content: Newly generated Dart code
            existing_filepath: Path to existing file with custom sections (optional)

        Returns:
            Merged Dart code with custom sections inserted

        Raises:
            ValueError: If custom section class not found in generated code
        """
        # If no existing file, return generated content
        if not existing_filepath:
            return generated_content

        path = Path(existing_filepath)
        if not path.exists():
            return generated_content

        # Analyze existing file
        try:
            existing_classes = self.analyzer.analyze_file(existing_filepath)
        except Exception as e:
            # If analysis fails, raise error to prevent losing custom code
            raise RuntimeError(
                f"Failed to analyze {existing_filepath}: {e}. "
                f"Custom code may be lost if merge continues. "
                f"Please fix the file structure or markers and try again."
            )

        self._last_missing_classes = []  # Reset for this file
        merged_content = generated_content

        # Find all classes in existing file that aren't in generated content
        all_missing_classes = []
        for class_name in existing_classes.keys():
            class_pattern = rf'class\s+{re.escape(class_name)}\b'
            if not re.search(class_pattern, generated_content):
                # Also check if there's a version with Xdr prefix in generated content
                # to avoid duplicates like TrustLineEntryExtensionV2 vs XdrTrustLineEntryExtensionV2
                if not class_name.startswith('Xdr'):
                    xdr_prefixed_name = f'Xdr{class_name}'
                    xdr_pattern = rf'class\s+{re.escape(xdr_prefixed_name)}\b'
                    if re.search(xdr_pattern, generated_content):
                        # Generator already created this class with Xdr prefix, skip old version
                        continue

                # Check if this is an aliased inline struct that has been replaced
                # Example: XdrPathPaymentStrictReceiveResultSuccess -> XdrPathPaymentResultSuccess
                if class_name.startswith('Xdr'):
                    # Remove Xdr prefix to get original struct name
                    original_name = class_name[3:]  # Remove 'Xdr' prefix
                    # Check if this struct has an alias
                    alias = self.type_mapper.get_inline_struct_alias(original_name)
                    if alias:
                        # This struct was aliased, check if the aliased version exists
                        aliased_class_name = f'Xdr{alias}'
                        aliased_pattern = rf'class\s+{re.escape(aliased_class_name)}\b'
                        if re.search(aliased_pattern, generated_content):
                            # Aliased version exists, skip this obsolete class
                            continue

                all_missing_classes.append(class_name)

        # Merge custom sections for classes that ARE in generated content
        for class_name, class_info in existing_classes.items():
            if class_info.custom_sections:
                for section in class_info.custom_sections:
                    try:
                        merged_content = self.insert_custom_section(
                            merged_content, section
                        )
                    except ValueError as e:
                        # Class not found - already tracked in all_missing_classes
                        pass

        # Preserve entire missing classes (including those without custom code)
        self._last_missing_classes = all_missing_classes
        if all_missing_classes:
            merged_content = self.preserve_missing_classes(
                merged_content, existing_filepath, all_missing_classes
            )

        # Merge imports (preserve custom imports)
        if existing_classes:
            # Get first class info for file-level imports
            first_class = next(iter(existing_classes.values()))
            if first_class.imports:
                merged_content = self.merge_imports(
                    self._extract_imports(merged_content),
                    first_class.imports,
                    merged_content
                )

        # Preserve file header if exists
        if existing_classes:
            first_class = next(iter(existing_classes.values()))
            if first_class.file_header:
                merged_content = self.preserve_file_header(
                    merged_content, first_class.file_header
                )

        return merged_content

    def insert_custom_section(
        self, class_content: str, section: CustomSection
    ) -> str:
        """
        Insert a custom section into a class before the closing brace.

        Detects methods in custom code and removes conflicting generated methods
        to avoid duplicate method definitions.

        Args:
            class_content: Full file content containing the class
            section: CustomSection to insert

        Returns:
            Content with custom section inserted

        Raises:
            ValueError: If class not found in content
        """
        # Find the class definition (handle extends, with, implements)
        # Use word boundary \b to avoid matching XdrFooType when looking for XdrFoo
        class_pattern = rf'class\s+{re.escape(section.class_name)}\b[^{{]*\{{'
        class_match = re.search(class_pattern, class_content)

        if not class_match:
            raise ValueError(
                f"Class {section.class_name} not found in generated content"
            )

        # Find the closing brace for this class
        class_start = class_match.end()
        closing_brace_pos = self._find_class_end(class_content, class_start - 1)

        if closing_brace_pos == -1:
            raise ValueError(
                f"Could not find closing brace for class {section.class_name}"
            )

        # Check if custom section already exists (avoid duplicates)
        class_body = class_content[class_start:closing_brace_pos]
        if self.analyzer.start_marker in class_body:
            # Custom code already exists, skip insertion
            return class_content

        # Detect methods in custom code to avoid conflicts
        custom_methods = self._detect_methods_in_custom_code(section.content)

        # Remove conflicting methods from generated class body
        if custom_methods:
            class_content = self._remove_conflicting_methods(
                class_content, section.class_name, custom_methods, class_start, closing_brace_pos
            )
            # Re-find closing brace position after removal
            class_match = re.search(class_pattern, class_content)
            if class_match:
                class_start = class_match.end()
                closing_brace_pos = self._find_class_end(class_content, class_start - 1)

        # Format the custom section with proper indentation
        formatted_section = self._format_custom_section(section)

        # Insert before closing brace
        result = (
            class_content[:closing_brace_pos]
            + formatted_section
            + class_content[closing_brace_pos:]
        )

        return result

    def merge_imports(
        self,
        generated_imports: List[str],
        custom_imports: List[str],
        content: str
    ) -> str:
        """
        Merge generated imports with custom imports (no duplicates).

        Preserves original import order from existing file when merging.
        Only adds new imports from generated code that don't exist.

        Args:
            generated_imports: Import statements from generated code
            custom_imports: Import statements from existing custom code
            content: Full content string to update

        Returns:
            Content with merged imports
        """
        # Extract paths from imports for deduplication
        custom_paths = {}
        for imp in custom_imports:
            match = re.match(r"import\s+['\"]([^'\"]+)['\"];?", imp)
            if match:
                path = match.group(1)
                custom_paths[path] = imp

        generated_paths = {}
        for imp in generated_imports:
            match = re.match(r"import\s+['\"]([^'\"]+)['\"];?", imp)
            if match:
                path = match.group(1)
                generated_paths[path] = imp

        # Start with custom imports in original order (preserve existing)
        final_imports = list(custom_imports)

        # Add new imports from generated code that don't exist in custom
        for path, imp in generated_paths.items():
            if path not in custom_paths:
                # Extract filename for checking
                module_name = path.split('/')[-1].replace('.dart', '')

                # Check if a similar import exists (different path, same module)
                similar_exists = False
                for custom_path in custom_paths.keys():
                    custom_module = custom_path.split('/')[-1].replace('.dart', '')
                    if custom_module == module_name:
                        similar_exists = True
                        break

                # Only add if no similar import exists
                if not similar_exists:
                    final_imports.append(imp)

        # Replace imports in content
        return self._replace_imports(content, final_imports)

    def preserve_missing_classes(
        self,
        merged_content: str,
        existing_filepath: str,
        missing_classes: List[str]
    ) -> str:
        """Preserve entire classes from existing file that weren't generated."""
        if not missing_classes:
            return merged_content

        existing_content = Path(existing_filepath).read_text()
        preserved_classes = []
        normalized_names = {}  # Track original -> normalized names

        for class_name in missing_classes:
            class_code = self.analyzer.extract_class_code(existing_content, class_name)
            if class_code:
                # Rename class if it doesn't have Xdr prefix to match generator conventions
                class_code = self._normalize_preserved_class_names(class_code, class_name)
                preserved_classes.append(class_code)

                # Track normalization if prefix was added
                if not class_name.startswith('Xdr'):
                    normalized_names[class_name] = f'Xdr{class_name}'

        if preserved_classes:
            # Append preserved classes at end of file
            merged_content = merged_content.rstrip()
            merged_content += '\n\n// Preserved helper classes (not in XDR spec)\n'
            preserved_section = '\n\n'.join(preserved_classes)

            # Apply global normalization to fix cross-references between preserved classes
            # This handles cases where one preserved class references another that was normalized
            for old_name, new_name in normalized_names.items():
                pattern = rf'\b{re.escape(old_name)}\b'
                preserved_section = re.sub(pattern, new_name, preserved_section)

            # Also normalize references to generated classes that preserved classes might reference
            # Extract class names that exist in generated content (classes with Xdr prefix)
            generated_class_names = self._extract_generated_class_names(merged_content)
            for gen_class in generated_class_names:
                # If there's a version without Xdr prefix in preserved section, replace it
                if gen_class.startswith('Xdr'):
                    base_name = gen_class[3:]  # Remove 'Xdr' prefix
                    # Only replace if the base name would be a valid identifier
                    pattern = rf'\b{re.escape(base_name)}\b'
                    preserved_section = re.sub(pattern, gen_class, preserved_section)

            merged_content += preserved_section
            merged_content += '\n'

        return merged_content

    def preserve_file_header(
        self, generated: str, existing_header: str
    ) -> str:
        """
        Preserve copyright and file header from existing file.

        Args:
            generated: Generated content
            existing_header: Header from existing file

        Returns:
            Content with preserved header
        """
        # Remove any existing header from generated content
        # Find first import or class
        first_code_match = re.search(
            r'^(?:import\s+|class\s+)',
            generated,
            re.MULTILINE
        )

        if not first_code_match:
            return generated

        # Get content after any header
        code_start = first_code_match.start()
        generated_code = generated[code_start:].lstrip()

        # Combine preserved header with generated code
        return f"{existing_header}\n\n{generated_code}"

    def _extract_imports(self, content: str) -> List[str]:
        """Extract import statements from content."""
        import_pattern = r"^import\s+['\"][^'\"]+['\"];?\s*$"
        imports = []

        for line in content.split('\n'):
            if re.match(import_pattern, line.strip()):
                imports.append(line.strip())

        return imports

    def _replace_imports(self, content: str, new_imports: List[str]) -> str:
        """Replace import section in content with new imports."""
        # Find first and last import line
        lines = content.split('\n')
        first_import = -1
        last_import = -1

        for i, line in enumerate(lines):
            if re.match(r"^import\s+", line.strip()):
                if first_import == -1:
                    first_import = i
                last_import = i

        if first_import == -1:
            # No imports found, add them after header
            # Find first class definition
            for i, line in enumerate(lines):
                if re.match(r'^class\s+', line.strip()):
                    # Insert imports before class
                    lines = (
                        lines[:i]
                        + new_imports
                        + ['']
                        + lines[i:]
                    )
                    break
        else:
            # Replace existing imports
            lines = (
                lines[:first_import]
                + new_imports
                + lines[last_import + 1:]
            )

        return '\n'.join(lines)

    def _format_custom_section(self, section: CustomSection) -> str:
        """
        Format a custom section with proper indentation.

        Args:
            section: CustomSection to format

        Returns:
            Formatted string with markers and content
        """
        # Add proper indentation (2 spaces for class body)
        lines = section.content.split('\n')

        # Check if content already has indentation
        if lines and lines[0].startswith('  '):
            # Already indented, use as-is
            formatted_content = section.content
        else:
            # Add indentation
            formatted_content = '\n'.join(
                f"  {line}" if line.strip() else line
                for line in lines
            )

        return (
            f"\n  {section.start_marker}\n"
            f"{formatted_content}"
            f"  {section.end_marker}\n"
        )

    def _find_class_end(self, content: str, start_pos: int) -> int:
        """
        Find the position of the closing brace for a class.

        Args:
            content: Full content string
            start_pos: Position of the opening brace

        Returns:
            Position of closing brace, or -1 if not found
        """
        if start_pos >= len(content) or content[start_pos] != '{':
            return -1

        depth = 1
        pos = start_pos + 1
        in_string = False
        string_char = None

        while pos < len(content) and depth > 0:
            char = content[pos]
            prev_char = content[pos - 1] if pos > 0 else ''

            # Handle strings
            if char in ('"', "'") and prev_char != '\\':
                if not in_string:
                    in_string = True
                    string_char = char
                elif char == string_char:
                    in_string = False
                    string_char = None

            # Count braces only outside strings
            if not in_string:
                if char == '{':
                    depth += 1
                elif char == '}':
                    depth -= 1

            if depth == 0:
                return pos

            pos += 1

        return -1

    def _normalize_preserved_class_names(self, class_code: str, class_name: str) -> str:
        """
        Normalize preserved class names to match generator naming conventions.

        If a preserved class doesn't have the 'Xdr' prefix, add it to match
        the generator's naming conventions. Also update all references within
        the class code.

        Args:
            class_code: The source code of the preserved class
            class_name: The original class name

        Returns:
            Class code with normalized names
        """
        # If class already has Xdr prefix, no changes needed
        if class_name.startswith('Xdr'):
            return class_code

        # Add Xdr prefix
        new_class_name = f'Xdr{class_name}'

        # Replace ALL occurrences of the class name with word boundaries
        # This will catch:
        # - class ClassName {
        # - ClassName(...)  (constructors)
        # - ClassName value (parameters)
        # - ClassName? _field (nullable fields)
        # - static ClassName decode(...)
        # - return ClassName(...)
        # - ClassName get ext (getters)
        # - set ext(ClassName value) (setters)
        class_name_pattern = rf'\b{re.escape(class_name)}\b'
        class_code = re.sub(class_name_pattern, new_class_name, class_code)

        return class_code

    def _extract_generated_class_names(self, content: str) -> List[str]:
        """
        Extract all class names from generated content.

        Args:
            content: Generated Dart code

        Returns:
            List of class names found in content
        """
        # Pattern matches: class ClassName { or class ClassName extends/implements/with ...
        pattern = r'class\s+(\w+)[^{]*\{'
        matches = re.finditer(pattern, content)
        return [match.group(1) for match in matches]

    def _remove_conflicting_methods(
        self,
        content: str,
        class_name: str,
        method_names: List[str],
        class_start: int,
        class_end: int
    ) -> str:
        """
        Remove methods from generated class body that conflict with custom code.

        Args:
            content: Full file content
            class_name: Name of the class
            method_names: List of method names to remove
            class_start: Position where class body starts (after opening brace)
            class_end: Position of class closing brace

        Returns:
            Content with conflicting methods removed
        """
        if not method_names:
            return content

        class_body = content[class_start:class_end]
        modified_body = class_body

        for method_name in method_names:
            # Pattern to match static or instance method definitions
            # Matches: static void encode(...) { ... } or Foo decode(...) { ... }
            # This pattern captures the entire method including its body
            pattern = rf'\n\s*(?:static\s+)?(?:\w+\??)\s+{re.escape(method_name)}\s*\([^)]*\)\s*\{{'

            # Find all matches
            matches = list(re.finditer(pattern, modified_body))

            for match in matches:
                # Find the end of the method body
                method_start = match.start()
                brace_start = match.end() - 1  # Position of opening brace

                # Find matching closing brace
                method_end = self._find_method_end(modified_body, brace_start)

                if method_end != -1:
                    # Remove the entire method (including trailing newline)
                    modified_body = (
                        modified_body[:method_start] +
                        modified_body[method_end + 1:]
                    )

        # Reconstruct the content
        return content[:class_start] + modified_body + content[class_end:]

    def _find_method_end(self, content: str, start_pos: int) -> int:
        """
        Find the position of the closing brace for a method.

        Args:
            content: Content string
            start_pos: Position of the method's opening brace

        Returns:
            Position of closing brace, or -1 if not found
        """
        if start_pos >= len(content) or content[start_pos] != '{':
            return -1

        depth = 1
        pos = start_pos + 1
        in_string = False
        string_char = None

        while pos < len(content) and depth > 0:
            char = content[pos]
            prev_char = content[pos - 1] if pos > 0 else ''

            # Handle strings
            if char in ('"', "'") and prev_char != '\\':
                if not in_string:
                    in_string = True
                    string_char = char
                elif char == string_char:
                    in_string = False
                    string_char = None

            # Count braces only outside strings
            if not in_string:
                if char == '{':
                    depth += 1
                elif char == '}':
                    depth -= 1

            if depth == 0:
                return pos

            pos += 1

        return -1


def merge_directory(
    generated_files: Dict[str, str],
    existing_dir: str,
    output_dir: Optional[str] = None
) -> Dict[str, str]:
    """
    Merge all generated files with existing files in a directory.

    Args:
        generated_files: Dict mapping filenames to generated content
        existing_dir: Directory containing existing files
        output_dir: Optional output directory (uses existing_dir if None)

    Returns:
        Dict mapping filenames to merged content

    Example:
        >>> generated = {'xdr_memo.dart': '...generated code...'}
        >>> merged = merge_directory(generated, 'lib/src/xdr/')
    """
    merger = DartMerger()
    merged_files = {}

    existing_path = Path(existing_dir)
    output_path = Path(output_dir) if output_dir else existing_path

    for filename, generated_content in generated_files.items():
        existing_file = existing_path / filename

        # Merge with existing file if it exists
        merged_content = merger.merge_file(
            generated_content,
            str(existing_file) if existing_file.exists() else None
        )

        merged_files[filename] = merged_content

    return merged_files
