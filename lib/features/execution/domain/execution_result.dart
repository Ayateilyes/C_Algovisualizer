/// Result of a C program execution.
class ExecutionResult {
  const ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.elapsed,
    required this.success,
    this.errorLine,
    this.errorColumn,
    this.errorMessage,
    this.errorHint,
    this.errorSourceLine,
  });

  /// Standard output text.
  final String stdout;

  /// Compiler / runtime error message (formatted for console display).
  final String stderr;

  /// Process exit code (0 = success).
  final int exitCode;

  /// Wall-clock time the execution took.
  final Duration elapsed;

  /// True if the program exited with code 0 and no errors.
  final bool success;

  /// Line number in the C source where the error occurred (1-indexed, null if no error).
  final int? errorLine;

  /// Column number in the C source where the error occurred (1-indexed, null if no error).
  final int? errorColumn;

  /// Raw error message string (without formatting).
  final String? errorMessage;

  /// Human-friendly hint for the error.
  final String? errorHint;

  /// The C source line that caused the error.
  final String? errorSourceLine;

  /// Whether this result contains structured error info.
  bool get hasErrorInfo => errorLine != null && errorLine! > 0;

  static const ExecutionResult empty = ExecutionResult(
    stdout: '',
    stderr: '',
    exitCode: 0,
    elapsed: Duration.zero,
    success: true,
  );
}
