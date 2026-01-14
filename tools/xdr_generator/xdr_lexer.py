"""
XDR Lexer (Tokenizer)

Tokenizes XDR source code into a stream of tokens for parsing.

Handles:
- Keywords (typedef, enum, struct, union, switch, case, default, void, const, etc.)
- Identifiers (type and variable names)
- Numeric literals (decimal and hexadecimal)
- Symbols ({, }, [, ], <, >, (, ), ;, :, ,, =, *)
- Comments (// and /* */)
- Whitespace (ignored)
- Preprocessor directives (%#include - ignored)
"""

from dataclasses import dataclass
from typing import List, Optional
import re


@dataclass
class Token:
    """
    Represents a single token in the XDR source.

    Attributes:
        type: Token type (KEYWORD, IDENTIFIER, NUMBER, SYMBOL, EOF)
        value: String value of the token
        line: Line number in source (1-indexed)
        column: Column number in source (1-indexed)
    """
    type: str
    value: str
    line: int
    column: int

    def __repr__(self) -> str:
        return f"Token({self.type}, '{self.value}', {self.line}:{self.column})"


class XdrLexerError(Exception):
    """Raised when lexer encounters invalid syntax."""
    pass


class XdrLexer:
    """
    Tokenizer for XDR source code.

    Converts raw XDR source text into a sequence of tokens for parsing.
    """

    # XDR keywords
    KEYWORDS = {
        'typedef', 'enum', 'struct', 'union', 'switch', 'case', 'default',
        'void', 'const', 'opaque', 'string', 'unsigned', 'int', 'hyper',
        'float', 'double', 'bool', 'namespace'
    }

    # Symbol tokens (single or multi-character)
    SYMBOLS = {
        '{', '}', '[', ']', '<', '>', '(', ')', ';', ':', ',', '=', '*'
    }

    def __init__(self, source: str, filename: str = "<unknown>"):
        """
        Initialize lexer with source code.

        Args:
            source: XDR source code to tokenize
            filename: Name of source file (for error reporting)
        """
        self.source = source
        self.filename = filename
        self.pos = 0
        self.line = 1
        self.column = 1
        self.tokens: List[Token] = []

    def tokenize(self) -> List[Token]:
        """
        Tokenize the entire source code.

        Returns:
            List of tokens (including EOF token at end)

        Raises:
            XdrLexerError: If invalid syntax is encountered
        """
        while self.pos < len(self.source):
            self._skip_whitespace_and_comments()

            if self.pos >= len(self.source):
                break

            # Try to match different token types
            if self._try_symbol():
                continue
            if self._try_number():
                continue
            if self._try_identifier_or_keyword():
                continue
            if self._try_preprocessor():
                continue

            # If nothing matched, invalid character
            char = self.source[self.pos]
            raise XdrLexerError(
                f"{self.filename}:{self.line}:{self.column}: "
                f"Invalid character: '{char}'"
            )

        # Add EOF token
        self.tokens.append(Token('EOF', '', self.line, self.column))
        return self.tokens

    def _current_char(self) -> Optional[str]:
        """Return current character or None if at end."""
        if self.pos < len(self.source):
            return self.source[self.pos]
        return None

    def _peek_char(self, offset: int = 1) -> Optional[str]:
        """Look ahead at character without consuming it."""
        pos = self.pos + offset
        if pos < len(self.source):
            return self.source[pos]
        return None

    def _advance(self) -> Optional[str]:
        """Consume and return current character, updating position."""
        if self.pos >= len(self.source):
            return None

        char = self.source[self.pos]
        self.pos += 1

        if char == '\n':
            self.line += 1
            self.column = 1
        else:
            self.column += 1

        return char

    def _skip_whitespace_and_comments(self):
        """Skip whitespace and comments."""
        while self.pos < len(self.source):
            char = self._current_char()

            # Whitespace
            if char in ' \t\n\r':
                self._advance()
                continue

            # Single-line comment
            if char == '/' and self._peek_char() == '/':
                self._skip_line_comment()
                continue

            # Multi-line comment
            if char == '/' and self._peek_char() == '*':
                self._skip_block_comment()
                continue

            break

    def _skip_line_comment(self):
        """Skip // comment until end of line."""
        while self._current_char() and self._current_char() != '\n':
            self._advance()
        if self._current_char() == '\n':
            self._advance()

    def _skip_block_comment(self):
        """Skip /* ... */ block comment."""
        # Skip /*
        self._advance()
        self._advance()

        while self.pos < len(self.source):
            if self._current_char() == '*' and self._peek_char() == '/':
                # Skip */
                self._advance()
                self._advance()
                return
            self._advance()

        raise XdrLexerError(
            f"{self.filename}:{self.line}:{self.column}: "
            "Unterminated block comment"
        )

    def _try_symbol(self) -> bool:
        """Try to match a symbol token."""
        char = self._current_char()
        if char in self.SYMBOLS:
            token_line = self.line
            token_col = self.column
            self._advance()
            self.tokens.append(Token('SYMBOL', char, token_line, token_col))
            return True
        return False

    def _try_number(self) -> bool:
        """Try to match a numeric literal (decimal or hexadecimal)."""
        char = self._current_char()

        # Must start with digit or - for negative numbers
        if not (char.isdigit() or char == '-'):
            return False

        token_line = self.line
        token_col = self.column
        value = ''

        # Handle negative sign
        if char == '-':
            value += self._advance()
            if not self._current_char() or not self._current_char().isdigit():
                # Just a minus sign, not a number
                self.pos -= 1
                self.column -= 1
                return False

        # Hexadecimal number (0x...)
        if self._current_char() == '0' and self._peek_char() in ('x', 'X'):
            value += self._advance()  # 0
            value += self._advance()  # x
            if not self._current_char() or not self._is_hex_digit(self._current_char()):
                raise XdrLexerError(
                    f"{self.filename}:{token_line}:{token_col}: "
                    "Invalid hexadecimal number"
                )
            while self._current_char() and self._is_hex_digit(self._current_char()):
                value += self._advance()
        else:
            # Decimal number
            while self._current_char() and self._current_char().isdigit():
                value += self._advance()

        self.tokens.append(Token('NUMBER', value, token_line, token_col))
        return True

    def _try_identifier_or_keyword(self) -> bool:
        """Try to match an identifier or keyword."""
        char = self._current_char()

        # Must start with letter or underscore
        if not (char.isalpha() or char == '_'):
            return False

        token_line = self.line
        token_col = self.column
        value = ''

        # Collect identifier characters
        while self._current_char() and (
            self._current_char().isalnum() or self._current_char() == '_'
        ):
            value += self._advance()

        # Determine if keyword or identifier
        if value in self.KEYWORDS:
            token_type = 'KEYWORD'
        else:
            token_type = 'IDENTIFIER'

        self.tokens.append(Token(token_type, value, token_line, token_col))
        return True

    def _try_preprocessor(self) -> bool:
        """Try to match and skip preprocessor directive (%#include)."""
        if self._current_char() != '%':
            return False

        # Skip the entire preprocessor line
        while self._current_char() and self._current_char() != '\n':
            self._advance()
        if self._current_char() == '\n':
            self._advance()

        return True

    @staticmethod
    def _is_hex_digit(char: str) -> bool:
        """Check if character is valid hexadecimal digit."""
        return char in '0123456789abcdefABCDEF'


def tokenize_xdr(source: str, filename: str = "<unknown>") -> List[Token]:
    """
    Convenience function to tokenize XDR source code.

    Args:
        source: XDR source code
        filename: Name of source file (for error reporting)

    Returns:
        List of tokens

    Raises:
        XdrLexerError: If invalid syntax is encountered
    """
    lexer = XdrLexer(source, filename)
    return lexer.tokenize()
