/// All token types recognized by the C lexer.
enum CTokenType {
  /// Keywords: if, else, while, for, return, int, void, etc.
  keyword,

  /// Standard C types: int, char, float, double, void, etc.
  type,

  /// Preprocessor directives: #include, #define, #ifdef, etc.
  preprocessor,

  /// String literals: "hello world"
  stringLiteral,

  /// Char literals: 'a', '\n'
  charLiteral,

  /// Numeric literals: 42, 3.14f, 0xFF, 0777
  number,

  /// Single-line or block comments
  comment,

  /// Function call identifier: foo(
  function,

  /// Operators: +, -, *, /, =, ==, !=, etc.
  operator_,

  /// Punctuation: { } ( ) [ ] ; , .
  punctuation,

  /// Unknown plain identifier
  identifier,

  /// Plain whitespace (preserved for positioning)
  whitespace,
}

/// A single lexed token with its type and raw text.
class CToken {
  const CToken({required this.type, required this.text});

  final CTokenType type;
  final String text;

  @override
  String toString() => 'CToken($type, ${text.replaceAll('\n', '\\n')})';
}
