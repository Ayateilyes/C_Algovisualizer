import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../application/step_notifier.dart';

/// Premium variable inspector with animated rows.
///
/// Features:
/// - Variables appear with slide-in + fade animation
/// - Changed values pulse/flash amber
/// - New variables flash blue
/// - Type badges for int/char/float/pointer
/// - Glassmorphic card rows with subtle gradient borders
/// - Smooth height transitions
class VariableInspector extends ConsumerStatefulWidget {
  const VariableInspector({super.key, required this.isDark});
  final bool isDark;

  @override
  ConsumerState<VariableInspector> createState() => _VariableInspectorState();
}

class _VariableInspectorState extends ConsumerState<VariableInspector> {
  // Track previous vars for diffing
  Map<String, String> _prevVars = {};
  int _prevIndex = -1;

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(stepNotifierProvider);

    if (step.isIdle || !step.hasSteps) {
      return const EmptyState(
        icon: Icons.bug_report_outlined,
        title: 'Step Debugger',
        message: 'Press Step to trace execution',
      );
    }

    if (step.isTracing) {
      return _TracingIndicator(isDark: widget.isDark);
    }

    if (step.status == StepStatus.error) {
      return _ErrorView(message: step.errorMessage, isDark: widget.isDark);
    }

    final current = step.currentStep;
    final vars = current?.variables ?? {};

    // Compute prev vars from previous step (not from widget state, to avoid
    // stale data). Only update when step index actually changes.
    Map<String, String> prevVarsForDiff;
    if (step.currentIndex != _prevIndex) {
      prevVarsForDiff = Map.from(_prevVars);
      _prevVars = Map.from(vars);
      _prevIndex = step.currentIndex;
    } else {
      prevVarsForDiff = _prevVars;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Line indicator bar ──────────────────────────────────────────
        _LineIndicator(
          line: current?.line,
          isDark: widget.isDark,
          isEndStep: current?.isEndStep ?? false,
        ),

        // ── Variable cards ──────────────────────────────────────────────
        if (vars.isEmpty)
          const Expanded(
            child: EmptyState(
              icon: Icons.data_object_rounded,
              title: 'No variables yet',
              message: 'Local variables will appear here',
            ),
          )
        else
          Expanded(
            child: _AnimatedVarList(
              vars: vars,
              prevVars: prevVarsForDiff,
              isDark: widget.isDark,
            ),
          ),

        // ── Output preview bar ──────────────────────────────────────────
        if (current?.outputSoFar.isNotEmpty ?? false)
          _OutputPreview(output: current!.outputSoFar, isDark: widget.isDark),
      ],
    );
  }
}

// ─── Animated Variable List ──────────────────────────────────────────────────

class _AnimatedVarList extends StatelessWidget {
  const _AnimatedVarList({
    required this.vars,
    required this.prevVars,
    required this.isDark,
  });
  final Map<String, String> vars;
  final Map<String, String> prevVars;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final entries = vars.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        final isNew = !prevVars.containsKey(e.key);
        final isChanged = !isNew && prevVars[e.key] != e.value;
        final prevValue = prevVars[e.key];

        return _VariableCard(
          key: ValueKey('var_${e.key}'),
          name: e.key,
          value: e.value,
          prevValue: prevValue,
          isNew: isNew,
          isChanged: isChanged,
          isDark: isDark,
          index: index,
        );
      },
    );
  }
}

// ─── Variable Card ───────────────────────────────────────────────────────────

class _VariableCard extends StatefulWidget {
  const _VariableCard({
    super.key,
    required this.name,
    required this.value,
    required this.prevValue,
    required this.isNew,
    required this.isChanged,
    required this.isDark,
    required this.index,
  });

  final String name;
  final String value;
  final String? prevValue;
  final bool isNew;
  final bool isChanged;
  final bool isDark;
  final int index;

  @override
  State<_VariableCard> createState() => _VariableCardState();
}

class _VariableCardState extends State<_VariableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _flashAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnim = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

    // Flash for changed values: 0 → 1 → 0
    _flashAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));

    if (widget.isNew || widget.isChanged) {
      _anim.forward();
    } else {
      _anim.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _VariableCard old) {
    super.didUpdateWidget(old);
    // Re-trigger animation when value changes
    if (old.value != widget.value || old.isNew != widget.isNew) {
      _anim.reset();
      _anim.forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Infer C type from value string.
  String _inferType(String value) {
    if (value.startsWith('0x') || value.startsWith('&')) return 'ptr';
    if (value.startsWith("'") && value.endsWith("'")) return 'char';
    if (value.contains('.')) return 'float';
    if (value == 'NULL') return 'ptr';
    return 'int';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final type = _inferType(widget.value);
    final borderColor = widget.isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    // Status colors
    Color accentColor = cs.onSurface.withAlpha(40);
    if (widget.isNew) accentColor = AppColors.primary;
    if (widget.isChanged) accentColor = AppColors.warning;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final flashValue = widget.isChanged ? _flashAnim.value : 0.0;

        return Transform.translate(
          offset: Offset(widget.isNew ? _slideAnim.value : 0, 0),
          child: Opacity(
            opacity: widget.isNew ? _fadeAnim.value : 1.0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Color.lerp(
                  widget.isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurface,
                  widget.isChanged
                      ? AppColors.warning.withAlpha(30)
                      : AppColors.primary.withAlpha(30),
                  flashValue,
                ),
                borderRadius: AppRadius.smAll,
                border: Border.all(
                  color:
                      Color.lerp(borderColor, accentColor, flashValue * 0.6) ??
                      borderColor,
                  width: 0.5,
                ),
                boxShadow: flashValue > 0
                    ? [
                        BoxShadow(
                          color: accentColor.withAlpha(
                            (flashValue * 30).toInt(),
                          ),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // ── Status dot ──────────────────────────────────────────
                  AnimatedContainer(
                    duration: AppDurations.fast,
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isNew
                          ? AppColors.primary
                          : widget.isChanged
                          ? AppColors.warning
                          : cs.onSurface.withAlpha(30),
                      boxShadow: (widget.isNew || widget.isChanged)
                          ? [
                              BoxShadow(
                                color:
                                    (widget.isNew
                                            ? AppColors.primary
                                            : AppColors.warning)
                                        .withAlpha(80),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Type badge ──────────────────────────────────────────
                  _TypeBadge(type: type, isDark: widget.isDark),
                  const SizedBox(width: 8),

                  // ── Name ────────────────────────────────────────────────
                  Text(
                    widget.name,
                    style: AppTextStyles.code.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),

                  const SizedBox(width: 6),
                  Text(
                    '=',
                    style: AppTextStyles.code.copyWith(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── Value ───────────────────────────────────────────────
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.value,
                            style: AppTextStyles.code.copyWith(
                              fontSize: 12,
                              color: _valueColor(type),
                              fontWeight: widget.isChanged
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // ── Previous value badge ──────────────────────────
                        if (widget.isChanged && widget.prevValue != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlpha(20),
                              border: Border.all(
                                color: AppColors.warning.withAlpha(40),
                                width: 0.5,
                              ),
                              borderRadius: AppRadius.xsAll,
                            ),
                            child: Text(
                              '← ${widget.prevValue}',
                              style: AppTextStyles.codeSmall.copyWith(
                                fontSize: 9,
                                color: AppColors.warning.withAlpha(180),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _valueColor(String type) {
    return switch (type) {
      'ptr' => AppColors.accentLight,
      'char' => AppColors.codeString,
      'float' => AppColors.codeNumber,
      _ => AppColors.success,
    };
  }
}

// ─── Type Badge ──────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.isDark});
  final String type;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case 'int':
        bg = AppColors.primary.withAlpha(25);
        fg = AppColors.primaryLight;
      case 'char':
        bg = AppColors.success.withAlpha(25);
        fg = AppColors.success;
      case 'float':
        bg = AppColors.warning.withAlpha(25);
        fg = AppColors.warning;
      case 'ptr':
        bg = AppColors.accent.withAlpha(25);
        fg = AppColors.accentLight;
      default:
        bg = AppColors.info.withAlpha(25);
        fg = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.xsAll,
        border: Border.all(color: fg.withAlpha(40), width: 0.5),
      ),
      child: Text(
        type,
        style: AppTextStyles.badge.copyWith(
          color: fg,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Line Indicator ──────────────────────────────────────────────────────────

class _LineIndicator extends StatelessWidget {
  const _LineIndicator({
    required this.line,
    required this.isDark,
    required this.isEndStep,
  });
  final int? line;
  final bool isDark;
  final bool isEndStep;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AnimatedContainer(
      duration: AppDurations.fast,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: isEndStep
            ? LinearGradient(
                colors: [AppColors.success.withAlpha(15), Colors.transparent],
              )
            : null,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: AppDurations.fast,
            child: Icon(
              isEndStep
                  ? Icons.check_circle_rounded
                  : Icons.play_circle_outline_rounded,
              key: ValueKey(isEndStep),
              size: 14,
              color: isEndStep ? AppColors.success : cs.primary,
            ),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: AppDurations.fast,
            child: Text(
              isEndStep
                  ? 'Program complete'
                  : line != null
                  ? 'Line $line'
                  : '',
              key: ValueKey('$isEndStep-$line'),
              style: AppTextStyles.labelSmall.copyWith(
                color: isEndStep ? AppColors.success : cs.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isEndStep && line != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withAlpha(150),
                boxShadow: [
                  BoxShadow(color: cs.primary.withAlpha(60), blurRadius: 4),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Output Preview ──────────────────────────────────────────────────────────

class _OutputPreview extends StatelessWidget {
  const _OutputPreview({required this.output, required this.isDark});
  final String output;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Container(
      constraints: const BoxConstraints(maxHeight: 80),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
        color: isDark
            ? AppColors.darkBackground
            : AppColors.lightSurfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.terminal_rounded,
                size: 10,
                color: cs.onSurfaceVariant.withAlpha(120),
              ),
              const SizedBox(width: 4),
              Text(
                'stdout',
                style: AppTextStyles.badge.copyWith(
                  fontSize: 8,
                  color: cs.onSurfaceVariant.withAlpha(150),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                output,
                style: AppTextStyles.code.copyWith(
                  fontSize: 11,
                  color: AppColors.success,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tracing Indicator ───────────────────────────────────────────────────────

class _TracingIndicator extends StatelessWidget {
  const _TracingIndicator({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Generating trace…',
            style: AppTextStyles.labelMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Transpiling C → JS',
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10,
              color: cs.onSurfaceVariant.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.isDark});
  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(15),
              borderRadius: AppRadius.smAll,
              border: Border.all(color: AppColors.error.withAlpha(30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  'Trace Error',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(8),
              borderRadius: AppRadius.smAll,
              border: Border.all(color: AppColors.error.withAlpha(20)),
            ),
            child: Text(
              message,
              style: AppTextStyles.code.copyWith(
                fontSize: 11,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
