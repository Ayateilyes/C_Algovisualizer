import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/editor_state.dart';
import 'c_highlight_controller.dart';

// ─── Bracket Auto-Close Formatter ────────────────────────────────────────────

/// Inserts matching closing bracket when an opening bracket is typed.
/// Skips auto-close when the next character is already the closing bracket.
class _BracketAutoCloseFormatter extends TextInputFormatter {
  static const _pairs = {'{': '}', '(': ')', '[': ']'};

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only act on a single character insertion
    if (newValue.text.length != oldValue.text.length + 1) return newValue;

    final insertedAt = newValue.selection.baseOffset - 1;
    if (insertedAt < 0) return newValue;

    final ch = newValue.text[insertedAt];
    final closing = _pairs[ch];
    if (closing == null) return newValue;

    // Don't double-close if the next char is already the closing bracket
    if (insertedAt + 1 < newValue.text.length &&
        newValue.text[insertedAt + 1] == closing) {
      return newValue;
    }

    final text =
        newValue.text.substring(0, insertedAt + 1) +
        closing +
        newValue.text.substring(insertedAt + 1);

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: insertedAt + 1),
      composing: TextRange.empty,
    );
  }
}

// ─── Code Editor Widget ───────────────────────────────────────────────────────

/// The core code editor widget. Features:
/// - C syntax highlighting via [CHighlightController]
/// - Animated line number gutter (current line highlighted)
/// - Smart auto-indent on Enter (preserves level, bumps after `{`)
/// - Bracket auto-close: `{` → `{}`, `(` → `()`, `[` → `[]`
/// - Tab → 4 spaces; Shift+Tab → remove 4 leading spaces
/// - Cursor position tracking → [editorCursorProvider]
/// - Content sync → [editorContentProvider]
class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late final CHighlightController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _verticalScroll;
  late final ScrollController _lineNumberScroll;

  static const double _lineHeight = 22.4; // 14px * 1.6 line-height
  static const double _gutterWidth = 52.0;
  static const double _editorPaddingTop = 4.0;

  // Track shift key state for Shift+Tab
  bool _shiftHeld = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(editorContentProvider);
    _controller = CHighlightController(text: initial);
    _focusNode = FocusNode();
    _verticalScroll = ScrollController();
    _lineNumberScroll = ScrollController();

    _controller.addListener(_onTextChanged);
    _verticalScroll.addListener(_syncLineNumbers);

    // Listen to font-size changes and update the controller AFTER the
    // current build frame (safe: avoids notifyListeners-during-build loop).
    ref.listenManual(editorFontSizeProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.fontSize = next;
      });
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _verticalScroll.removeListener(_syncLineNumbers);
    _controller.dispose();
    _focusNode.dispose();
    _verticalScroll.dispose();
    _lineNumberScroll.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    ref.read(editorContentProvider.notifier).state = _controller.text;
    // Clear error highlight when user edits code
    ref.read(errorLineProvider.notifier).state = null;
    _updateCursor();
    if (mounted) setState(() {});
  }

  void _syncLineNumbers() {
    if (_lineNumberScroll.hasClients) {
      _lineNumberScroll.jumpTo(_verticalScroll.offset);
    }
  }

  void _updateCursor() {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset.clamp(0, text.length);
    final before = text.substring(0, offset);
    final lines = before.split('\n');
    ref.read(editorCursorProvider.notifier).state = (
      line: lines.length,
      col: lines.last.length + 1,
    );
  }

  int get _currentLine {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset.clamp(0, text.length);
    return text.substring(0, offset).split('\n').length;
  }

  int get _lineCount => _controller.text.split('\n').length;

  // ─── Key event handling ───────────────────────────────────────────────────

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    // Track Shift key state
    if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight) {
      _shiftHeld = event is KeyDownEvent || event is KeyRepeatEvent;
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    // Tab / Shift+Tab
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _shiftHeld ? _handleShiftTab() : _insertTab();
      return KeyEventResult.handled;
    }

    // Enter → smart indent
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _handleEnter();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Insert 4 spaces at cursor position.
  void _insertTab() {
    final sel = _controller.selection;
    if (!sel.isValid) return;
    final text = _controller.text;
    _controller.value = TextEditingValue(
      text: text.replaceRange(sel.start, sel.end, '    '),
      selection: TextSelection.collapsed(offset: sel.start + 4),
    );
  }

  /// Remove up to 4 leading spaces from the current line.
  void _handleShiftTab() {
    final sel = _controller.selection;
    if (!sel.isValid) return;
    final text = _controller.text;

    final lineStart = text.lastIndexOf('\n', sel.baseOffset - 1) + 1;
    final lineContent = text.substring(lineStart, sel.baseOffset);

    int spacesToRemove = 0;
    for (int i = 0; i < lineContent.length && i < 4; i++) {
      if (lineContent[i] == ' ') {
        spacesToRemove++;
      } else {
        break;
      }
    }

    if (spacesToRemove == 0) return;

    _controller.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineStart + spacesToRemove, ''),
      selection: TextSelection.collapsed(
        offset: (sel.baseOffset - spacesToRemove).clamp(lineStart, text.length),
      ),
    );
  }

  /// Smart Enter: preserves current indentation.
  /// - After `{`: bumps indent by 4 spaces
  /// - After `}`: reduces indent by 4 spaces
  /// - Normal: matches current line's indent level
  void _handleEnter() {
    final sel = _controller.selection;
    if (!sel.isValid) return;
    final text = _controller.text;
    final cursorPos = sel.baseOffset;

    // Find start of current line
    final lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;
    final currentLineText = text.substring(lineStart, cursorPos);

    // Count leading spaces
    int baseIndent = 0;
    for (int i = 0; i < currentLineText.length; i++) {
      if (currentLineText[i] == ' ') {
        baseIndent++;
      } else if (currentLineText[i] == '\t') {
        baseIndent += 4;
      } else {
        break;
      }
    }

    final trimmed = currentLineText.trimRight();
    int newIndent = baseIndent;

    if (trimmed.endsWith('{')) {
      newIndent += 4;
    }

    final indent = ' ' * newIndent;

    // Special case: cursor is between { and }
    // Insert the closing brace on a de-indented line
    if (trimmed.endsWith('{') &&
        cursorPos < text.length &&
        text[cursorPos] == '}') {
      final closingIndent = ' ' * (baseIndent);
      final insertion = '\n$indent\n$closingIndent';
      final newText = text.replaceRange(sel.start, sel.end, insertion);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: sel.start + indent.length + 1,
        ),
      );
      return;
    }

    final insertion = '\n$indent';
    _controller.value = TextEditingValue(
      text: text.replaceRange(sel.start, sel.end, insertion),
      selection: TextSelection.collapsed(offset: sel.start + insertion.length),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update isDark after the frame — same reason as fontSize: setter calls
    // notifyListeners() and we must not trigger that during a build phase.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.isDark = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontSize = ref.watch(editorFontSizeProvider);
    // NOTE: do NOT set _controller.isDark / _controller.fontSize here.
    // Those setters call notifyListeners() which fires setState() mid-build,
    // causing an infinite render loop. Updates are handled via post-frame
    // callbacks in didChangeDependencies() and ref.listenManual (initState).

    final bgColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final gutterBg = isDark ? const Color(0xFF13161F) : const Color(0xFFECF0F9);
    final lineHighlight = isDark
        ? const Color(0xFF1E2235)
        : const Color(0xFFE6EBF7);
    final gutterText = isDark
        ? AppColors.darkTextDisabled
        : AppColors.lightTextDisabled;
    final errorLine = ref.watch(errorLineProvider);
    const errorHighlightColor = Color(0x30FF3333);

    return Container(
      color: bgColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Line number gutter ──────────────────────────────────────────
          SizedBox(
            width: _gutterWidth,
            child: Container(
              color: gutterBg,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => _LineNumberGutter(
                  lineCount: _lineCount,
                  currentLine: _currentLine,
                  errorLine: errorLine,
                  fontSize: fontSize,
                  lineHeight: _lineHeight,
                  scrollController: _lineNumberScroll,
                  textColor: gutterText,
                  highlightColor: lineHighlight,
                  primaryColor: AppColors.primary,
                  gutterBg: gutterBg,
                ),
              ),
            ),
          ),

          // ── Code text field ─────────────────────────────────────────────
          Expanded(
            child: Focus(
              onKeyEvent: _onKeyEvent,
              child: Stack(
                children: [
                  // Current line highlight
                  AnimatedBuilder(
                    animation: Listenable.merge([_controller, _verticalScroll]),
                    builder: (context, _) => _buildCurrentLineHighlight(
                      lineHighlight: lineHighlight,
                      fontSize: fontSize,
                    ),
                  ),

                  // Error line highlight (red)
                  if (errorLine != null)
                    AnimatedBuilder(
                      animation: _verticalScroll,
                      builder: (context, _) {
                        final scrollOffset = _verticalScroll.hasClients
                            ? _verticalScroll.offset
                            : 0.0;
                        final top =
                            (errorLine - 1) * _lineHeight +
                            _editorPaddingTop -
                            scrollOffset;
                        if (top + _lineHeight < 0) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
                          left: 0,
                          right: 0,
                          top: top.clamp(0.0, double.infinity),
                          height: _lineHeight,
                          child: Container(color: errorHighlightColor),
                        );
                      },
                    ),

                  // The TextField
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    scrollController: _verticalScroll,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    autocorrect: false,
                    enableSuggestions: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    cursorColor: AppColors.primary,
                    cursorWidth: 2,
                    inputFormatters: [_BracketAutoCloseFormatter()],
                    style: AppTextStyles.code.copyWith(
                      fontSize: fontSize,
                      // Transparent so the controller's colored spans show through
                      color: Colors.transparent,
                      height: _lineHeight / fontSize,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.only(
                        left: 12,
                        top: _editorPaddingTop,
                        right: 8,
                        bottom: 8,
                      ),
                      isDense: true,
                      filled: false,
                    ),
                    onChanged: (_) => _updateCursor(),
                    onTap: _updateCursor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLineHighlight({
    required Color lineHighlight,
    required double fontSize,
  }) {
    final line = _currentLine;
    final scrollOffset = _verticalScroll.hasClients
        ? _verticalScroll.offset
        : 0.0;
    final top = (line - 1) * _lineHeight + _editorPaddingTop - scrollOffset;

    // Only hide the highlight if it's scrolled fully above the top edge.
    // Do NOT read context.size here — size is unavailable during build.
    // The Stack already clips children to its bounds, so the bottom cutoff
    // is handled automatically.
    if (top + _lineHeight < 0) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      top: top.clamp(0.0, double.infinity),
      height: _lineHeight,
      child: Container(color: lineHighlight),
    );
  }
}

// ─── Line Number Gutter ───────────────────────────────────────────────────────

class _LineNumberGutter extends StatelessWidget {
  const _LineNumberGutter({
    required this.lineCount,
    required this.currentLine,
    this.errorLine,
    required this.fontSize,
    required this.lineHeight,
    required this.scrollController,
    required this.textColor,
    required this.highlightColor,
    required this.primaryColor,
    required this.gutterBg,
  });

  final int lineCount;
  final int currentLine;
  final int? errorLine;
  final double fontSize;
  final double lineHeight;
  final ScrollController scrollController;
  final Color textColor;
  final Color highlightColor;
  final Color primaryColor;
  final Color gutterBg;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4),
      itemCount: lineCount,
      itemExtent: lineHeight,
      itemBuilder: (context, index) {
        final lineNum = index + 1;
        final isCurrent = lineNum == currentLine;
        final isError = errorLine != null && lineNum == errorLine;

        Color bgColor = gutterBg;
        if (isError) {
          bgColor = const Color(0x40FF3333);
        } else if (isCurrent) {
          bgColor = highlightColor;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          color: bgColor,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 8),
          child: isError
              ? const Text('❌', style: TextStyle(fontSize: 12, height: 1.0))
              : Text(
                  '$lineNum',
                  style: AppTextStyles.codeSmall.copyWith(
                    fontSize: (fontSize - 2).clamp(8.0, 20.0),
                    color: isCurrent ? primaryColor : textColor,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    height: 1.0,
                  ),
                ),
        );
      },
    );
  }
}
