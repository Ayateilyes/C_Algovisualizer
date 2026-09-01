import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/execution_notifier.dart';
import '../../application/step_notifier.dart';
import '../../domain/scanf_input.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
const _kTermGreen = Color(0xFF00FF88);
const _kTermOrange = Color(0xFFFF9800);
const _kTermRed = Color(0xFFFF4444);
const _kTermBg = Color(0xFF0D1117);
const _kTermBlue = Color(0xFF58A6FF);

// ─── Output Line Model ────────────────────────────────────────────────────────

enum _LineKind { stdout, stdin, stderr, system }

class _OutputLine {
  const _OutputLine(this.text, this.kind);
  final String text;
  final _LineKind kind;
}

// ─── Main Widget ─────────────────────────────────────────────────────────────

/// Premium I/O Console panel for the step debugger.
///
/// Shows accumulated stdout per execution step with a authentic terminal look,
/// blinking cursor, and color-coded output. Shows a scanf input overlay when
/// either run-mode or trace-mode is waiting for user input.
class IOConsolePanel extends ConsumerStatefulWidget {
  const IOConsolePanel({super.key, required this.isDark});
  final bool isDark;

  @override
  ConsumerState<IOConsolePanel> createState() => _IOConsolePanelState();
}

class _IOConsolePanelState extends ConsumerState<IOConsolePanel>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _cursorCtrl;
  late final Animation<double> _cursorAnim;

  // Track previous output to detect new lines (for typewriter)
  String _prevOutput = '';
  final List<_OutputLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _cursorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    _cursorAnim = _cursorCtrl;
  }

  @override
  void dispose() {
    _cursorCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_OutputLine> _buildLines(String output) {
    if (output.isEmpty) return [];
    final rawLines = output.split('\n');
    final result = <_OutputLine>[];

    // System prompt prefix
    result.add(const _OutputLine('▶  Program Output', _LineKind.system));
    result.add(const _OutputLine('', _LineKind.system));

    for (int i = 0; i < rawLines.length; i++) {
      final ln = rawLines[i];
      if (i < rawLines.length - 1 || ln.isNotEmpty) {
        result.add(_OutputLine(ln, _LineKind.stdout));
      }
    }
    return result;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _lineColor(_LineKind kind, bool isDark) {
    return switch (kind) {
      _LineKind.stdout => isDark ? _kTermGreen : const Color(0xFF1A7A3C),
      _LineKind.stdin => isDark ? _kTermBlue : const Color(0xFF1A5FA0),
      _LineKind.stderr => _kTermRed,
      _LineKind.system =>
        isDark ? Colors.white.withAlpha(100) : Colors.black.withAlpha(100),
    };
  }

  String _linePrefix(_LineKind kind) {
    return switch (kind) {
      _LineKind.stdout => '',
      _LineKind.stdin => '❯ ',
      _LineKind.stderr => '✗ ',
      _LineKind.system => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final stepState = ref.watch(stepNotifierProvider);
    final runState = ref.watch(executionNotifierProvider);

    // Determine output to show: prefer step output in step mode
    final String output;
    if (stepState.hasSteps || stepState.isTracing) {
      output = stepState.currentStep?.outputSoFar ?? '';
    } else {
      // run mode accumulation: show nothing here (output panel handles run mode)
      output = '';
    }

    // Determine if scanf is waiting
    final bool scanfPending;
    final ScanfInput? currentScanfInput;
    if (stepState.isScanfPending) {
      scanfPending = true;
      final idx = stepState.collectedInputs.length;
      currentScanfInput = idx < stepState.pendingInputs.length
          ? stepState.pendingInputs[idx]
          : null;
    } else if (runState.isScanfPending) {
      scanfPending = true;
      final idx = runState.collectedInputs.length;
      currentScanfInput = idx < runState.pendingInputs.length
          ? runState.pendingInputs[idx]
          : null;
    } else {
      scanfPending = false;
      currentScanfInput = null;
    }

    // Detect new output
    if (output != _prevOutput) {
      _prevOutput = output;
      _lines.clear();
      _lines.addAll(_buildLines(output));
      _scrollToBottom();
    }

    final isDark = widget.isDark;
    final termBg = isDark ? _kTermBg : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: Column(
        children: [
          // ── Terminal header ─────────────────────────────────────────────────
          _TerminalHeader(
            isDark: isDark,
            output: output,
            borderColor: borderColor,
          ),

          // ── Terminal body ───────────────────────────────────────────────────
          Expanded(
            child: Container(
              color: termBg,
              child: output.isEmpty && !scanfPending
                  ? _EmptyTerminalState(isDark: isDark)
                  : _TerminalBody(
                      lines: _lines,
                      scrollController: _scrollController,
                      cursorAnim: _cursorAnim,
                      isDark: isDark,
                      lineColor: _lineColor,
                      linePrefix: _linePrefix,
                    ),
            ),
          ),

          // ── Scanf input overlay ─────────────────────────────────────────────
          if (scanfPending)
            _ScanfInputOverlay(
              isDark: isDark,
              borderColor: borderColor,
              scanfInput: currentScanfInput,
              onSubmit: (value) {
                if (stepState.isScanfPending) {
                  ref
                      .read(stepNotifierProvider.notifier)
                      .submitScanfInput(value);
                } else if (runState.isScanfPending) {
                  ref
                      .read(executionNotifierProvider.notifier)
                      .submitScanfInput(value);
                }
              },
            ),
        ],
      ),
    );
  }
}

// ─── Terminal Header ──────────────────────────────────────────────────────────

class _TerminalHeader extends StatelessWidget {
  const _TerminalHeader({
    required this.isDark,
    required this.output,
    required this.borderColor,
  });
  final bool isDark;
  final String output;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceVariant,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Traffic-light dots
          _Dot(color: const Color(0xFFFF5F57)),
          const SizedBox(width: 5),
          _Dot(color: const Color(0xFFFFBD2E)),
          const SizedBox(width: 5),
          _Dot(color: const Color(0xFF28C840)),
          const SizedBox(width: 10),
          Container(width: 1, height: 14, color: borderColor),
          const SizedBox(width: 10),
          Icon(
            Icons.terminal_rounded,
            size: 12,
            color: isDark ? _kTermGreen : const Color(0xFF1A7A3C),
          ),
          const SizedBox(width: 5),
          Text(
            'I/O Console',
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Copy button
          if (output.isNotEmpty)
            Tooltip(
              message: 'Copy output',
              child: InkWell(
                onTap: () => Clipboard.setData(ClipboardData(text: output)),
                borderRadius: AppRadius.xsAll,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Terminal Body ────────────────────────────────────────────────────────────

class _TerminalBody extends StatelessWidget {
  const _TerminalBody({
    required this.lines,
    required this.scrollController,
    required this.cursorAnim,
    required this.isDark,
    required this.lineColor,
    required this.linePrefix,
  });

  final List<_OutputLine> lines;
  final ScrollController scrollController;
  final Animation<double> cursorAnim;
  final bool isDark;
  final Color Function(_LineKind, bool) lineColor;
  final String Function(_LineKind) linePrefix;

  @override
  Widget build(BuildContext context) {
    final promptColor = isDark
        ? _kTermGreen.withAlpha(180)
        : const Color(0xFF1A7A3C);

    return SelectionArea(
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: lines.length + 1, // +1 for prompt line
        itemBuilder: (context, i) {
          if (i < lines.length) {
            final line = lines[i];
            return _TerminalLine(
              line: line,
              isDark: isDark,
              lineColor: lineColor,
              linePrefix: linePrefix,
            );
          } else {
            // Prompt + blinking cursor on last line
            return Row(
              children: [
                Text(
                  'main.c:~ \$ ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    color: promptColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AnimatedBuilder(
                  animation: cursorAnim,
                  builder: (context, _) => Opacity(
                    opacity: cursorAnim.value > 0.5 ? 1.0 : 0.0,
                    child: Container(width: 7, height: 14, color: promptColor),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _TerminalLine extends StatelessWidget {
  const _TerminalLine({
    required this.line,
    required this.isDark,
    required this.lineColor,
    required this.linePrefix,
  });

  final _OutputLine line;
  final bool isDark;
  final Color Function(_LineKind, bool) lineColor;
  final String Function(_LineKind) linePrefix;

  @override
  Widget build(BuildContext context) {
    final color = lineColor(line.kind, isDark);
    final prefix = linePrefix(line.kind);

    if (line.kind == _LineKind.system) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          line.text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: color,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: color,
            height: 1.5,
          ),
          children: [
            if (prefix.isNotEmpty)
              TextSpan(
                text: prefix,
                style: TextStyle(
                  color: color.withAlpha(150),
                  fontWeight: FontWeight.w700,
                ),
              ),
            TextSpan(text: line.text),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Terminal State ─────────────────────────────────────────────────────

class _EmptyTerminalState extends StatefulWidget {
  const _EmptyTerminalState({required this.isDark});
  final bool isDark;

  @override
  State<_EmptyTerminalState> createState() => _EmptyTerminalStateState();
}

class _EmptyTerminalStateState extends State<_EmptyTerminalState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  String _typed = '';
  int _charIdx = 0;
  Timer? _timer;

  static const _prompt = 'main.c:~ \$ ';
  static const _message = 'printf("hello, world!\\n");';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = _ctrl;
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 85), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_charIdx < _message.length) {
          _typed = _message.substring(0, ++_charIdx);
        } else {
          t.cancel();
          Future.delayed(const Duration(milliseconds: 1800), () {
            if (mounted) {
              setState(() {
                _charIdx = 0;
                _typed = '';
              });
              _startTyping();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promptColor = widget.isDark ? _kTermGreen : const Color(0xFF1A7A3C);
    final dimColor = widget.isDark
        ? Colors.white.withAlpha(40)
        : Colors.black.withAlpha(40);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faded hint lines
          Text(
            '# Step through your C program',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: dimColor,
            ),
          ),
          Text(
            '# to see output here',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: dimColor,
            ),
          ),
          const SizedBox(height: 12),
          // Typing demo line
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _prompt,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: promptColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _typed,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: promptColor.withAlpha(180),
                ),
              ),
              AnimatedBuilder(
                animation: _anim,
                builder: (context, _) => Opacity(
                  opacity: _anim.value > 0.5 ? 1.0 : 0.0,
                  child: Container(width: 7, height: 14, color: promptColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Scanf Input Overlay ──────────────────────────────────────────────────────

class _ScanfInputOverlay extends StatefulWidget {
  const _ScanfInputOverlay({
    required this.isDark,
    required this.borderColor,
    required this.onSubmit,
    this.scanfInput,
  });
  final bool isDark;
  final Color borderColor;
  final ScanfInput? scanfInput;
  final void Function(String value) onSubmit;

  @override
  State<_ScanfInputOverlay> createState() => _ScanfInputOverlayState();
}

class _ScanfInputOverlayState extends State<_ScanfInputOverlay>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(_ScanfInputOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When overlay updates for the next scanf, play a brief re-enter animation
    if (oldWidget.scanfInput?.varName != widget.scanfInput?.varName) {
      _ctrl.clear();
      _slideCtrl.reset();
      _slideCtrl.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _ctrl.text.trim();
    widget.onSubmit(value.isEmpty ? '0' : value);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF161B22) : Colors.white;
    const accent = Color(0xFF7C4DFF);
    final prompt = widget.scanfInput?.prompt ?? 'scanf() awaiting input';

    return SlideTransition(
      position: _slideAnim,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: BorderSide(color: accent.withAlpha(120), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _kTermOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  prompt,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: _kTermOrange,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'Press Enter to submit',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 9,
                    color: isDark
                        ? AppColors.darkTextDisabled
                        : AppColors.lightTextDisabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '❯ ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
                      hintText: 'type input…',
                      hintStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withAlpha(60)
                            : Colors.black.withAlpha(60),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                    cursorColor: accent,
                    cursorWidth: 2,
                  ),
                ),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent.withAlpha(80)),
                    ),
                    child: Text(
                      'Enter',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
