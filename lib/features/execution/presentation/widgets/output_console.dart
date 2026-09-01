import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/execution_notifier.dart';
import '../../application/execution_state.dart';
import '../../domain/execution_result.dart';
import '../../domain/scanf_input.dart';

/// Output console showing stdout/stderr from the C program execution.
/// Displays in the right panel (desktop) or bottom panel (tablet).
class OutputConsole extends ConsumerWidget {
  const OutputConsole({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionNotifierProvider);

    // Determine current scanf prompt (if any)
    ScanfInput? currentScanfInput;
    if (state.isScanfPending && state.pendingInputs.isNotEmpty) {
      final idx = state.collectedInputs.length;
      if (idx < state.pendingInputs.length) {
        currentScanfInput = state.pendingInputs[idx];
      }
    }

    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Panel header ──────────────────────────────────────────────────
          _ConsoleHeader(
            isDark: isDark,
            state: state,
            onClear: () => ref.read(executionNotifierProvider.notifier).clear(),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: state.status == RunStatus.idle
                ? _EmptyState(isDark: isDark)
                : state.status == RunStatus.running
                ? const _RunningState()
                : state.status == RunStatus.scanfPending
                ? _ScanfWaitingState(isDark: isDark)
                : _OutputBody(state: state, isDark: isDark),
          ),

          // ── Scanf input overlay ─────────────────────────────────────────
          if (state.isScanfPending)
            _RunScanfInputOverlay(
              isDark: isDark,
              scanfInput: currentScanfInput,
              onSubmit: (value) {
                ref
                    .read(executionNotifierProvider.notifier)
                    .submitScanfInput(value);
              },
            ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ConsoleHeader extends StatelessWidget {
  const _ConsoleHeader({
    required this.isDark,
    required this.state,
    required this.onClear,
  });
  final bool isDark;
  final ExecutionState state;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Color statusDot = cs.onSurfaceVariant;
    String statusLabel = 'Output';
    if (state.status == RunStatus.running) {
      statusDot = AppColors.warning;
      statusLabel = 'Running…';
    } else if (state.status == RunStatus.done) {
      statusDot = AppColors.success;
      statusLabel =
          'Done  '
          '(${state.result.elapsed.inMilliseconds}ms'
          '  exit ${state.result.exitCode})';
    } else if (state.status == RunStatus.error) {
      statusDot = AppColors.error;
      statusLabel =
          'Error  '
          '(${state.result.elapsed.inMilliseconds}ms)';
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.terminal_rounded, size: 14, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusLabel,
              style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status dot
          AnimatedContainer(
            duration: AppDurations.fast,
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: statusDot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          // Clear
          if (state.hasOutput)
            Tooltip(
              message: 'Clear output',
              child: InkWell(
                onTap: onClear,
                borderRadius: AppRadius.smAll,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_sweep_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            size: 36,
            color: cs.onSurfaceVariant.withAlpha(80),
          ),
          const SizedBox(height: 8),
          Text(
            'Press Run to execute your C program',
            style: AppTextStyles.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningState extends StatelessWidget {
  const _RunningState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Running…',
            style: AppTextStyles.labelMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputBody extends StatelessWidget {
  const _OutputBody({required this.state, required this.isDark});
  final ExecutionState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final result = state.result;

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stdout
            if (result.stdout.isNotEmpty)
              _CodeBlock(
                label: 'stdout',
                text: result.stdout,
                textColor: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                isDark: isDark,
              ),

            // Stderr
            if (result.stderr.isNotEmpty) ...[
              if (result.stdout.isNotEmpty) const SizedBox(height: 8),
              result.hasErrorInfo
                  ? _ErrorBlock(result: result, isDark: isDark)
                  : _CodeBlock(
                      label: 'stderr',
                      text: result.stderr,
                      textColor: AppColors.error,
                      isDark: isDark,
                    ),
            ],

            // Exit code banner
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: result.success
                    ? AppColors.success.withAlpha(25)
                    : AppColors.error.withAlpha(25),
                borderRadius: AppRadius.smAll,
                border: Border.all(
                  color: result.success
                      ? AppColors.success.withAlpha(80)
                      : AppColors.error.withAlpha(80),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    result.success
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    size: 12,
                    color: result.success ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Process exited with code ${result.exitCode}  '
                    '(${result.elapsed.inMilliseconds} ms)',
                    style: AppTextStyles.codeSmall.copyWith(
                      fontSize: 11,
                      color: result.success
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.label,
    required this.text,
    required this.textColor,
    required this.isDark,
  });
  final String label;
  final String text;
  final Color textColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isDark
        ? AppColors.darkBackground
        : AppColors.lightSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(height: 1, color: cs.outline.withAlpha(30)),
            ),
            const SizedBox(width: 6),
            // Copy button
            InkWell(
              onTap: () => Clipboard.setData(ClipboardData(text: text)),
              borderRadius: AppRadius.xsAll,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.copy_rounded,
                  size: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smAll),
          child: Text(
            text,
            style: AppTextStyles.code.copyWith(
              fontSize: 13,
              color: textColor,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.result, required this.isDark});
  final ExecutionResult result;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1010) : const Color(0xFFFFF0F0);
    final borderColor = isDark
        ? const Color(0xFF4D2020)
        : const Color(0xFFFFCCCC);
    const bar =
        '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500'
        '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500'
        '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500'
        '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500';

    final errorLine = result.errorLine ?? -1;
    final sourceLine = result.errorSourceLine ?? '';
    final errorCol = result.errorColumn ?? -1;
    final message = result.errorMessage ?? result.stderr;
    final hint = result.errorHint ?? '';

    // Build caret line
    String caretLine = '';
    if (errorCol > 0 && errorLine > 0) {
      final prefix = ' $errorLine |  ';
      caretLine = '${' ' * prefix.length}${' ' * (errorCol - 1)}^';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: borderColor),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.code.copyWith(fontSize: 12, height: 1.7),
          children: [
            // Bar
            TextSpan(
              text: ' $bar\n',
              style: const TextStyle(color: Color(0xFF666666)),
            ),
            // ERROR on Line N
            const TextSpan(
              text: '  ERROR',
              style: TextStyle(
                color: Color(0xFFFF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: errorLine > 0 ? ' on Line $errorLine\n' : '\n',
              style: const TextStyle(color: Color(0xFFFF4444)),
            ),
            // Bar
            TextSpan(
              text: ' $bar\n',
              style: const TextStyle(color: Color(0xFF666666)),
            ),
            // Source line
            if (errorLine > 0 && sourceLine.isNotEmpty) ...[
              TextSpan(
                text: ' $errorLine |  $sourceLine\n',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
            // Caret
            if (caretLine.isNotEmpty)
              TextSpan(
                text: '$caretLine\n',
                style: const TextStyle(color: Color(0xFFFF8800)),
              ),
            // Error message
            TextSpan(
              text: ' $message\n',
              style: const TextStyle(color: Color(0xFFFF4444)),
            ),
            // Hint
            if (hint.isNotEmpty)
              TextSpan(
                text: ' Hint: $hint\n',
                style: const TextStyle(
                  color: Color(0xFFFFAA33),
                  fontStyle: FontStyle.italic,
                ),
              ),
            // Bar
            TextSpan(
              text: ' $bar',
              style: const TextStyle(color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Scanf waiting body state ────────────────────────────────────────────────

class _ScanfWaitingState extends StatelessWidget {
  const _ScanfWaitingState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_rounded, size: 32, color: cs.primary.withAlpha(140)),
          const SizedBox(height: 10),
          Text(
            'Waiting for scanf() input…',
            style: AppTextStyles.labelMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type your value below and press Enter',
            style: AppTextStyles.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scanf Input Overlay for Run Mode ──────────────────────────────────────────

class _RunScanfInputOverlay extends StatefulWidget {
  const _RunScanfInputOverlay({
    required this.isDark,
    required this.onSubmit,
    this.scanfInput,
  });
  final bool isDark;
  final ScanfInput? scanfInput;
  final void Function(String value) onSubmit;

  @override
  State<_RunScanfInputOverlay> createState() => _RunScanfInputOverlayState();
}

class _RunScanfInputOverlayState extends State<_RunScanfInputOverlay>
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
  void didUpdateWidget(_RunScanfInputOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
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
                    color: Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  prompt,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: const Color(0xFFFF9800),
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
