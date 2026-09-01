import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../application/step_notifier.dart';
import '../../domain/execution_step.dart';

/// Premium call-stack visualization panel.
///
/// Shows stack frames as stacked cards from bottom (main) to top (current).
/// New frames slide in from the right, popped frames slide out.
/// Each frame shows: function name, line number, and a depth indicator.
class StackFramePanel extends ConsumerStatefulWidget {
  const StackFramePanel({super.key, required this.isDark});
  final bool isDark;

  @override
  ConsumerState<StackFramePanel> createState() => _StackFramePanelState();
}

class _StackFramePanelState extends ConsumerState<StackFramePanel> {
  List<StackFrame> _prevFrames = [];
  int _prevIndex = -1;

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(stepNotifierProvider);
    final cs = Theme.of(context).colorScheme;
    final borderColor = widget.isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    if (step.isIdle || !step.hasSteps) {
      return const EmptyState(
        icon: Icons.layers_outlined,
        title: 'Call Stack',
        message: 'Trace to view function frames',
      );
    }

    if (step.isTracing) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final frames = step.currentStep?.callStack ?? [];

    // Determine which frames are new vs existing for animation
    List<StackFrame> prevForDiff;
    if (step.currentIndex != _prevIndex) {
      prevForDiff = List.from(_prevFrames);
      _prevFrames = List.from(frames);
      _prevIndex = step.currentIndex;
    } else {
      prevForDiff = _prevFrames;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Icon(Icons.layers_rounded, size: 13, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Call Stack',
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 11,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(15),
                  borderRadius: AppRadius.fullAll,
                  border: Border.all(color: cs.primary.withAlpha(30)),
                ),
                child: Text(
                  '${frames.length} ${frames.length == 1 ? 'frame' : 'frames'}',
                  style: AppTextStyles.badge.copyWith(
                    fontSize: 8,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Stack visualization ─────────────────────────────────────────
        Expanded(
          child: frames.isEmpty
              ? const Center(
                  child: EmptyState(
                    icon: Icons.layers_clear_rounded,
                    title: 'Empty Stack',
                    message: 'No active frames',
                  ),
                )
              : ListView.builder(
                  reverse: true, // stack grows upward visually
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  itemCount: frames.length,
                  itemBuilder: (context, index) {
                    // index 0 = bottom of visual list = top of stack
                    final frameIndex = frames.length - 1 - index;
                    final frame = frames[frameIndex];
                    final isTop = frameIndex == frames.length - 1;
                    final isNew = frameIndex >= prevForDiff.length;
                    final depth = frameIndex;

                    return _FrameCard(
                      key: ValueKey('frame_${frame.functionName}_$frameIndex'),
                      frame: frame,
                      depth: depth,
                      isTop: isTop,
                      isNew: isNew,
                      isDark: widget.isDark,
                    );
                  },
                ),
        ),

        // ── Depth meter ─────────────────────────────────────────────────
        _DepthMeter(depth: frames.length, isDark: widget.isDark),
      ],
    );
  }
}

// ─── Frame Card ──────────────────────────────────────────────────────────────

class _FrameCard extends StatefulWidget {
  const _FrameCard({
    super.key,
    required this.frame,
    required this.depth,
    required this.isTop,
    required this.isNew,
    required this.isDark,
  });

  final StackFrame frame;
  final int depth;
  final bool isTop;
  final bool isNew;
  final bool isDark;

  @override
  State<_FrameCard> createState() => _FrameCardState();
}

class _FrameCardState extends State<_FrameCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

    if (widget.isNew) {
      _anim.forward();
    } else {
      _anim.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _FrameCard old) {
    super.didUpdateWidget(old);
    if (old.isNew != widget.isNew && widget.isNew) {
      _anim.reset();
      _anim.forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = widget.isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    // Gradient accent based on depth
    final depthColors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    final accentColor = depthColors[widget.depth % depthColors.length];

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isTop
                ? accentColor.withAlpha(15)
                : widget.isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightSurface,
            borderRadius: AppRadius.smAll,
            border: Border.all(
              color: widget.isTop ? accentColor.withAlpha(60) : borderColor,
              width: widget.isTop ? 1.0 : 0.5,
            ),
            boxShadow: widget.isTop
                ? [BoxShadow(color: accentColor.withAlpha(20), blurRadius: 8)]
                : null,
          ),
          child: Row(
            children: [
              // ── Depth indicator ───────────────────────────────────────
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isTop
                      ? accentColor.withAlpha(30)
                      : cs.onSurface.withAlpha(10),
                  border: Border.all(
                    color: widget.isTop
                        ? accentColor.withAlpha(80)
                        : cs.onSurface.withAlpha(20),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '#${widget.depth}',
                    style: AppTextStyles.badge.copyWith(
                      fontSize: 7,
                      color: widget.isTop ? accentColor : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // ── Function icon ─────────────────────────────────────────
              Icon(
                widget.isTop
                    ? Icons.play_circle_filled_rounded
                    : Icons.circle_outlined,
                size: 12,
                color: widget.isTop ? accentColor : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),

              // ── Function name ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.frame.functionName}()',
                      style: AppTextStyles.code.copyWith(
                        fontSize: 12,
                        fontWeight: widget.isTop
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: widget.isTop
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    if (widget.frame.line > 0)
                      Text(
                        'line ${widget.frame.line}',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 9,
                          color: cs.onSurfaceVariant.withAlpha(120),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Active indicator ──────────────────────────────────────
              if (widget.isTop) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(20),
                    borderRadius: AppRadius.xsAll,
                    border: Border.all(
                      color: accentColor.withAlpha(40),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withAlpha(80),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'active',
                        style: AppTextStyles.badge.copyWith(
                          fontSize: 7,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Depth Meter ─────────────────────────────────────────────────────────────

class _DepthMeter extends StatelessWidget {
  const _DepthMeter({required this.depth, required this.isDark});
  final int depth;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final maxDepth = 10;
    final ratio = (depth / maxDepth).clamp(0.0, 1.0);

    // Color lerp: green (shallow) → amber → red (deep)
    final barColor = Color.lerp(
      AppColors.success,
      depth > 5 ? AppColors.error : AppColors.warning,
      ratio,
    )!;

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
      ),
      child: Row(
        children: [
          Icon(
            Icons.stacked_bar_chart_rounded,
            size: 10,
            color: cs.onSurfaceVariant.withAlpha(100),
          ),
          const SizedBox(width: 6),
          Text(
            'Depth',
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 9,
              color: cs.onSurfaceVariant.withAlpha(120),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.fullAll,
              child: SizedBox(
                height: 3,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: ratio),
                  duration: AppDurations.normal,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [barColor.withAlpha(120), barColor],
                        ),
                        borderRadius: AppRadius.fullAll,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$depth',
            style: AppTextStyles.code.copyWith(
              fontSize: 10,
              color: barColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
