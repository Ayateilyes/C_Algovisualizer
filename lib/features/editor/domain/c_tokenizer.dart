import 'c_token.dart';

/// A hand-written recursive-descent lexer for C source code.
/// Produces a flat list of [CToken] that covers every character
/// in the input (whitespace included), so the tokens can be
/// reassembled losslessly.
class CTokenizer {
  CTokenizer._();

  // ── C keywords ────────────────────────────────────────────────────────────
  static const _keywords = {
    'if',
    'else',
    'while',
    'for',
    'do',
    'return',
    'break',
    'continue',
    'switch',
    'case',
    'default',
    'sizeof',
    'typedef',
    'struct',
    'union',
    'enum',
    'goto',
    'extern',
    'static',
    'register',
    'volatile',
    'const',
    'restrict',
    'inline',
    'NULL',
    'true',
    'false',
  };

  // ── C types ───────────────────────────────────────────────────────────────
  static const _types = {
    'int',
    'char',
    'float',
    'double',
    'void',
    'long',
    'short',
    'unsigned',
    'signed',
    'bool',
    '_Bool',
    'size_t',
    'uint8_t',
    'uint16_t',
    'uint32_t',
    'uint64_t',
    'int8_t',
    'int16_t',
    'int32_t',
    'int64_t',
    'FILE',
    'wchar_t',
    'ptrdiff_t',
  };

  // ── Tokenize entry point ──────────────────────────────────────────────────
  static List<CToken> tokenize(String source) {
    final tokens = <CToken>[];
    int i = 0;
    final len = source.length;

    while (i < len) {
      final ch = source[i];

      // ─ Block comment ───────────────────────────────────────────
      if (ch == '/' && i + 1 < len && source[i + 1] == '*') {
        final end = source.indexOf('*/', i + 2);
        if (end == -1) {
          tokens.add(
            CToken(type: CTokenType.comment, text: source.substring(i)),
          );
          break;
        }
        tokens.add(
          CToken(type: CTokenType.comment, text: source.substring(i, end + 2)),
        );
        i = end + 2;
        continue;
      }

      // ─ Line comment ─────────────────────────────────────────────
      if (ch == '/' && i + 1 < len && source[i + 1] == '/') {
        final eol = _findEol(source, i + 2);
        tokens.add(
          CToken(type: CTokenType.comment, text: source.substring(i, eol)),
        );
        i = eol;
        continue;
      }

      // ─ Preprocessor directive ────────────────────────────────────
      if (ch == '#') {
        final eol = _findPreprocessorEnd(source, i);
        tokens.add(
          CToken(type: CTokenType.preprocessor, text: source.substring(i, eol)),
        );
        i = eol;
        continue;
      }

      // ─ String literal ────────────────────────────────────────────
      if (ch == '"') {
        final end = _readString(source, i);
        tokens.add(
          CToken(
            type: CTokenType.stringLiteral,
            text: source.substring(i, end),
          ),
        );
        i = end;
        continue;
      }

      // ─ Char literal ──────────────────────────────────────────────
      if (ch == "'") {
        final end = _readChar(source, i);
        tokens.add(
          CToken(type: CTokenType.charLiteral, text: source.substring(i, end)),
        );
        i = end;
        continue;
      }

      // ─ Number literal ────────────────────────────────────────────
      if (_isDigit(ch) ||
          (ch == '.' && i + 1 < len && _isDigit(source[i + 1]))) {
        final end = _readNumber(source, i);
        tokens.add(
          CToken(type: CTokenType.number, text: source.substring(i, end)),
        );
        i = end;
        continue;
      }

      // ─ Identifier / keyword / type / function call ───────────────
      if (_isIdentStart(ch)) {
        final end = _readIdent(source, i);
        final word = source.substring(i, end);
        // peek: is the next non-space character a '(' → function call
        final isFuncCall = _peekNextNonSpace(source, end) == '(';
        CTokenType type;
        if (_keywords.contains(word)) {
          type = CTokenType.keyword;
        } else if (_types.contains(word)) {
          type = CTokenType.type;
        } else if (isFuncCall) {
          type = CTokenType.function;
        } else {
          type = CTokenType.identifier;
        }
        tokens.add(CToken(type: type, text: word));
        i = end;
        continue;
      }

      // ─ Operators ─────────────────────────────────────────────────
      if (_isOperatorStart(ch)) {
        final end = _readOperator(source, i);
        tokens.add(
          CToken(type: CTokenType.operator_, text: source.substring(i, end)),
        );
        i = end;
        continue;
      }

      // ─ Punctuation ───────────────────────────────────────────────
      if (_isPunctuation(ch)) {
        tokens.add(CToken(type: CTokenType.punctuation, text: ch));
        i++;
        continue;
      }

      // ─ Whitespace (including newlines) ───────────────────────────
      if (_isWhitespace(ch)) {
        final start = i;
        while (i < len && _isWhitespace(source[i])) {
          i++;
        }
        tokens.add(
          CToken(type: CTokenType.whitespace, text: source.substring(start, i)),
        );
        continue;
      }

      // ─ Fallback: unknown character ─────────────────────────────
      tokens.add(CToken(type: CTokenType.identifier, text: ch));
      i++;
    }

    return tokens;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _findEol(String src, int start) {
    int i = start;
    while (i < src.length && src[i] != '\n') {
      i++;
    }
    return i;
  }

  /// Handles continuation lines in preprocessor directives (ending with \).
  static int _findPreprocessorEnd(String src, int start) {
    int i = start;
    while (i < src.length) {
      if (src[i] == '\n') {
        // Check for line continuation
        if (i > 0 && src[i - 1] == '\\') {
          i++;
          continue;
        }
        break;
      }
      i++;
    }
    return i;
  }

  static int _readString(String src, int start) {
    int i = start + 1;
    while (i < src.length) {
      if (src[i] == '\\') {
        i += 2;
        continue;
      }
      if (src[i] == '"') return i + 1;
      i++;
    }
    return i;
  }

  static int _readChar(String src, int start) {
    int i = start + 1;
    while (i < src.length) {
      if (src[i] == '\\') {
        i += 2;
        continue;
      }
      if (src[i] == "'") return i + 1;
      i++;
    }
    return i;
  }

  static int _readNumber(String src, int start) {
    int i = start;
    if (i + 1 < src.length &&
        src[i] == '0' &&
        (src[i + 1] == 'x' || src[i + 1] == 'X')) {
      i += 2;
      while (i < src.length && _isHexDigit(src[i])) {
        i++;
      }
    } else {
      while (i < src.length && _isDigit(src[i])) {
        i++;
      }
      if (i < src.length && src[i] == '.') {
        i++;
        while (i < src.length && _isDigit(src[i])) {
          i++;
        }
      }
      if (i < src.length && (src[i] == 'e' || src[i] == 'E')) {
        i++;
        if (i < src.length && (src[i] == '+' || src[i] == '-')) {
          i++;
        }
        while (i < src.length && _isDigit(src[i])) {
          i++;
        }
      }
    }
    while (i < src.length && _isNumberSuffix(src[i])) {
      i++;
    }
    return i;
  }

  static int _readIdent(String src, int start) {
    int i = start;
    while (i < src.length && _isIdentPart(src[i])) {
      i++;
    }
    return i;
  }

  static int _readOperator(String src, int start) {
    // Multi-char operators
    if (start + 1 < src.length) {
      final two = src.substring(start, start + 2);
      if (const {
        '==',
        '!=',
        '<=',
        '>=',
        '&&',
        '||',
        '++',
        '--',
        '->',
        '<<',
        '>>',
        '+=',
        '-=',
        '*=',
        '/=',
        '%=',
        '&=',
        '|=',
        '^=',
        '<<=',
        '>>=',
      }.contains(two)) {
        if (start + 2 < src.length &&
            const {'<<=', '>>='}.contains(src.substring(start, start + 3))) {
          return start + 3;
        }
        return start + 2;
      }
    }
    return start + 1;
  }

  static String? _peekNextNonSpace(String src, int i) {
    while (i < src.length && _isWhitespace(src[i])) {
      i++;
    }
    return i < src.length ? src[i] : null;
  }

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  static bool _isHexDigit(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 48 && code <= 57) ||
        (code >= 65 && code <= 70) ||
        (code >= 97 && code <= 102);
  }

  static bool _isNumberSuffix(String c) => 'uUlLfF'.contains(c);
  static bool _isIdentStart(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || // A-Z
        (code >= 97 && code <= 122) || // a-z
        code == 95; // _
  }

  static bool _isIdentPart(String c) => _isIdentStart(c) || _isDigit(c);
  static bool _isWhitespace(String c) =>
      c == ' ' || c == '\t' || c == '\n' || c == '\r';
  static bool _isPunctuation(String c) => '{}()[];,'.contains(c);
  static bool _isOperatorStart(String c) => '+-*/%=<>!&|^~.?:'.contains(c);
}
