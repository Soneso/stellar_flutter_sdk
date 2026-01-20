"""Dependency resolution for XDR type cross-file dependencies.

Analyzes type dependencies to generate correct import statements and
detect circular dependencies.
"""

import re
from typing import Dict, List, Set, Tuple, Optional
from collections import defaultdict, deque

try:
    from .type_mapping import TypeMapper
    from .file_mapping import FileMapper
    from .xdr_ast import (
        XdrFile, XdrEnum, XdrStruct, XdrUnion,
        XdrTypedef, XdrConstant, XdrField, XdrUnionCase
    )
except ImportError:
    from type_mapping import TypeMapper
    from file_mapping import FileMapper
    from xdr_ast import (
        XdrFile, XdrEnum, XdrStruct, XdrUnion,
        XdrTypedef, XdrConstant, XdrField, XdrUnionCase
    )


class DependencyResolver:
    """Resolves cross-file dependencies for XDR types."""

    def __init__(self, type_mapper: Optional[TypeMapper] = None,
                 file_mapper: Optional[FileMapper] = None):
        """Initialize the dependency resolver.

        Args:
            type_mapper: TypeMapper instance
            file_mapper: FileMapper instance
        """
        self.type_mapper = type_mapper or TypeMapper()
        self.file_mapper = file_mapper or FileMapper()

        # Type name -> filename mapping
        self.type_to_file: Dict[str, str] = {}

        # Filename -> set of filenames it depends on
        self.file_dependencies: Dict[str, Set[str]] = defaultdict(set)

        # Type name -> set of type names it references
        self.type_dependencies: Dict[str, Set[str]] = defaultdict(set)

    def build_dependency_graph(self, parsed_files: Dict[str, XdrFile]):
        """Build dependency graph from parsed XDR files.

        Args:
            parsed_files: Dict mapping XDR source filenames to parsed content
        """
        # First pass: assign all types to files
        for xdr_filename, xdr_file in parsed_files.items():
            # Process all definition types from XdrFile
            all_definitions = []
            all_definitions.extend(xdr_file.enums)
            all_definitions.extend(xdr_file.structs)
            all_definitions.extend(xdr_file.unions)
            all_definitions.extend(xdr_file.typedefs)

            for definition in all_definitions:
                dart_name = self.type_mapper.get_dart_class_name(definition.name)

                # Check if we already know the file from existing code
                target_file = self.file_mapper.get_target_file(dart_name)

                if not target_file:
                    # Infer file for new types
                    target_file = self.file_mapper.infer_file_for_type(dart_name)
                    self.file_mapper.assign_type_to_file(dart_name, target_file)

                self.type_to_file[dart_name] = target_file

        # Second pass: analyze dependencies
        for xdr_filename, xdr_file in parsed_files.items():
            all_definitions = []
            all_definitions.extend(xdr_file.enums)
            all_definitions.extend(xdr_file.structs)
            all_definitions.extend(xdr_file.unions)
            all_definitions.extend(xdr_file.typedefs)

            for definition in all_definitions:
                dart_name = self.type_mapper.get_dart_class_name(definition.name)
                source_file = self.type_to_file.get(dart_name)

                if not source_file:
                    continue

                # Extract type dependencies
                referenced_types = self._extract_type_references(definition)
                self.type_dependencies[dart_name] = referenced_types

                # Convert to file dependencies
                for ref_type in referenced_types:
                    ref_file = self.type_to_file.get(ref_type)
                    if ref_file and ref_file != source_file:
                        self.file_dependencies[source_file].add(ref_file)

    def _extract_type_references(self, definition) -> Set[str]:
        """Extract all type references from a definition.

        Args:
            definition: The XDR definition to analyze

        Returns:
            Set of referenced Dart type names
        """
        references: Set[str] = set()

        if isinstance(definition, XdrStruct):
            for field in definition.fields:
                refs = self._extract_field_type_references(field)
                references.update(refs)

        elif isinstance(definition, XdrUnion):
            # Add discriminant type
            disc_type_name = definition.discriminant_type
            # Primitive discriminants (int, unsigned int, bool) don't need imports
            if disc_type_name not in ('int', 'unsigned int', 'bool'):
                disc_type = self.type_mapper.get_dart_class_name(disc_type_name)
                if not self.type_mapper.is_primitive(disc_type_name):
                    references.add(disc_type)

            # Add case types
            for case in definition.cases:
                refs = self._extract_case_type_references(case)
                references.update(refs)

        elif isinstance(definition, XdrTypedef):
            # Handle typedef underlying type
            refs = self._extract_type_string_references(definition.underlying_type)
            references.update(refs)

            # Handle constant references in array sizes (e.g., opaque[MAX_SIZE])
            if '[' in definition.underlying_type and ']' in definition.underlying_type:
                # Extract constant name from array size specification
                match = re.search(r'\[([A-Z_][A-Z0-9_]*)\]', definition.underlying_type)
                if match:
                    # Constants don't create type dependencies, just note for future
                    pass

        return references

    def _extract_field_type_references(self, field: XdrField) -> Set[str]:
        """Extract type references from a struct field.

        Args:
            field: The struct field

        Returns:
            Set of referenced type names
        """
        return self._extract_type_string_references(field.type_name)

    def _extract_case_type_references(self, case: XdrUnionCase) -> Set[str]:
        """Extract type references from a union case.

        Args:
            case: The union case

        Returns:
            Set of referenced type names
        """
        if case.field and case.field.type_name != 'void':
            return self._extract_type_string_references(case.field.type_name)
        return set()

    def _extract_type_string_references(self, type_string: str) -> Set[str]:
        """Extract type references from a type string.

        Args:
            type_string: Type specification string

        Returns:
            Set of referenced Dart type names
        """
        references: Set[str] = set()

        # Extract base type by removing array/optional markers using regex
        # This handles: type*, type[], type[N], type<N>
        match = re.match(r'^([a-zA-Z_][a-zA-Z0-9_\s]*)', type_string)
        if not match:
            return references

        base_type = match.group(1).strip()

        # Handle primitive types with wrappers (XdrUint32, XdrInt64, etc.)
        if self.type_mapper.is_primitive(base_type):
            if self.type_mapper.needs_wrapper(base_type):
                # Map to wrapper type (e.g., uint32 -> XdrUint32)
                dart_type = self.type_mapper.map_type(base_type)
                references.add(dart_type)
            return references

        if base_type in ['void', 'opaque', 'string']:
            return references

        # Map to Dart type
        dart_type = self.type_mapper.get_dart_class_name(base_type)
        references.add(dart_type)

        return references

    def detect_circular_dependencies(self) -> List[Tuple[str, str]]:
        """Detect circular dependencies between files.

        Returns:
            List of (file_a, file_b) tuples representing circular deps
        """
        circles: List[Tuple[str, str]] = []

        for file_a, deps in self.file_dependencies.items():
            for file_b in deps:
                # Check if file_b also depends on file_a
                if file_a in self.file_dependencies.get(file_b, set()):
                    # Avoid duplicates by only adding if a < b
                    if file_a < file_b:
                        circles.append((file_a, file_b))

        return circles

    def get_topological_order(self) -> List[str]:
        """Return files in dependency order (dependencies first).

        Uses Kahn's algorithm for topological sorting.

        Returns:
            List of filenames in dependency order

        Raises:
            ValueError: If circular dependencies exist
        """
        # Check for circular dependencies first
        circles = self.detect_circular_dependencies()
        if circles:
            raise ValueError(f"Circular dependencies detected: {circles}")

        # Build in-degree map
        in_degree: Dict[str, int] = defaultdict(int)
        all_files = set(self.file_dependencies.keys())

        # Add files that are depended upon but don't have their own deps
        for deps in self.file_dependencies.values():
            all_files.update(deps)

        # Initialize in-degrees
        for file in all_files:
            in_degree[file] = 0

        # Calculate in-degrees
        for file, deps in self.file_dependencies.items():
            for dep in deps:
                in_degree[dep] += 1

        # Queue of files with no dependencies
        queue: deque = deque([f for f in all_files if in_degree[f] == 0])
        result: List[str] = []

        while queue:
            file = queue.popleft()
            result.append(file)

            # Reduce in-degree for files depending on this file
            for other_file in all_files:
                if file in self.file_dependencies.get(other_file, set()):
                    in_degree[other_file] -= 1
                    if in_degree[other_file] == 0:
                        queue.append(other_file)

        if len(result) != len(all_files):
            # This shouldn't happen if circular dep check passed
            raise ValueError("Unable to determine topological order")

        return result

    def generate_imports(self, target_file: str, needs_uint8list: bool = False) -> List[str]:
        """Generate import statements for a Dart file.

        Preserves original import order:
        1. dart: imports (only if needed)
        2. local imports (sorted alphabetically)

        Args:
            target_file: The target Dart filename
            needs_uint8list: Whether the file uses Uint8List

        Returns:
            List of import statements
        """
        imports: List[str] = []

        # Add dart:typed_data FIRST if needed (matches original order)
        if needs_uint8list:
            imports.append("import 'dart:typed_data';")

        # Get dependencies for this file (sorted)
        deps = sorted(self.file_dependencies.get(target_file, set()))

        # Add all local imports (including xdr_data_io.dart)
        all_local_imports = set(['xdr_data_io.dart'])
        all_local_imports.update(deps)

        # Sort and add local imports
        for local_import in sorted(all_local_imports):
            imports.append(f"import '{local_import}';")

        return imports

    def get_file_dependencies(self, filename: str) -> Set[str]:
        """Get all files that a given file depends on.

        Args:
            filename: The Dart filename

        Returns:
            Set of dependency filenames
        """
        return self.file_dependencies.get(filename, set())

    def get_type_dependencies(self, type_name: str) -> Set[str]:
        """Get all types that a given type depends on.

        Args:
            type_name: The Dart type name

        Returns:
            Set of dependency type names
        """
        return self.type_dependencies.get(type_name, set())

    def get_dependency_stats(self) -> Dict[str, Dict[str, int]]:
        """Get statistics about dependencies.

        Returns:
            Dict with 'files' and 'types' statistics
        """
        return {
            'files': {
                'total': len(self.file_dependencies),
                'max_deps': max(len(deps) for deps in self.file_dependencies.values())
                            if self.file_dependencies else 0,
                'avg_deps': sum(len(deps) for deps in self.file_dependencies.values()) /
                           len(self.file_dependencies) if self.file_dependencies else 0
            },
            'types': {
                'total': len(self.type_dependencies),
                'max_deps': max(len(deps) for deps in self.type_dependencies.values())
                            if self.type_dependencies else 0,
                'avg_deps': sum(len(deps) for deps in self.type_dependencies.values()) /
                           len(self.type_dependencies) if self.type_dependencies else 0
            }
        }

    def validate(self) -> List[str]:
        """Validate the dependency graph.

        Returns:
            List of validation warnings
        """
        warnings: List[str] = []

        # Check for circular dependencies
        circles = self.detect_circular_dependencies()
        if circles:
            for file_a, file_b in circles:
                warnings.append(f"Circular dependency: {file_a} <-> {file_b}")

        # Check for missing type mappings
        for type_name in self.type_dependencies.keys():
            if type_name not in self.type_to_file:
                warnings.append(f"Type '{type_name}' has no file assignment")

        return warnings


def create_resolver(type_mapper: Optional[TypeMapper] = None,
                   file_mapper: Optional[FileMapper] = None) -> DependencyResolver:
    """Create a DependencyResolver instance.

    Args:
        type_mapper: Optional TypeMapper instance
        file_mapper: Optional FileMapper instance

    Returns:
        DependencyResolver instance
    """
    return DependencyResolver(type_mapper, file_mapper)
