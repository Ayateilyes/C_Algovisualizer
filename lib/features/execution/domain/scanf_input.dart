/// Represents a single scanf() call detected in C source code.
class ScanfInput {
  const ScanfInput({required this.format, required this.varName});

  /// The format specifier string, e.g. "%d", "%f", "%s", "%c".
  final String format;

  /// The variable name that will receive the input, e.g. "x".
  final String varName;

  /// Human-readable prompt label for the input field.
  String get prompt {
    switch (format) {
      case '%d':
      case '%i':
        return 'Enter integer for `$varName`';
      case '%f':
      case '%e':
      case '%g':
        return 'Enter float for `$varName`';
      case '%c':
        return 'Enter character for `$varName`';
      case '%s':
        return 'Enter string for `$varName`';
      default:
        return 'Enter value for `$varName` ($format)';
    }
  }
}
