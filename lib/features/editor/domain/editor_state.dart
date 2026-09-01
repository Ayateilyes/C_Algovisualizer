import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the current editor content.
/// Updated whenever the user types in the editor.
final editorContentProvider = StateProvider<String>((ref) => _defaultCode);

/// Provider for the current cursor position (line, column).
final editorCursorProvider = StateProvider<({int line, int col})>(
  (ref) => (line: 1, col: 1),
);

/// Provider for font size preference (14.0 default).
final editorFontSizeProvider = StateProvider<double>((ref) => 14.0);

/// Currently executing line (1-indexed C source). Null when not in step mode.
/// Set by StepNotifier; watched by CodeEditorWidget for amber line highlight.
final debugLineProvider = StateProvider<int?>((ref) => null);

/// Error line (1-indexed C source). Non-null when the last execution had an error.
/// Set by ExecutionNotifier; watched by CodeEditorWidget for red line/gutter highlight.
final errorLineProvider = StateProvider<int?>((ref) => null);

/// The starter code shown when the app first opens.
const String _defaultCode = '''#include <stdio.h>

int main() {
    int x = 10;
    int y = 20;
    int sum = x + y;

    printf("Sum: %d\\n", sum);
    return 0;
}
''';
