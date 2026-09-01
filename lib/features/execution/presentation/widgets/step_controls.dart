import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/step_notifier.dart';

/// Step-by-step playback controls bar.
/// Shows: [⟨⟨] [⟨] [▶/⏸] [⟩] [⟩⟩] [×]  Step N/Total  [Speed slider]
class StepControls extends ConsumerStatefulWidget {
  const StepControls({super.key, required this.isDark});
  final bool isDark;

  @override
  ConsumerState<StepControls> createState() => _StepControlsState();
}

class _StepControlsState extends ConsumerState<StepControls> {
  double _speedMs = 600; // play interval in ms

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(stepNotifierProvider);
    final notifier = ref.read(stepNotifierProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final borderColor = widget.isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    return ClipRect(
      child: Container(
        width: double.infinity,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: widget.isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurface,
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 400;
            final showSpeed = constraints.maxWidth >= 300;

            final iconSize = isMobile ? 18.0 : 18.0;
            final buttonSize = isMobile ? 28.0 : 38.0;
            final spacing = isMobile ? 2.0 : 8.0;
            final fontSize = isMobile ? 11.0 : 11.0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // ── Playback buttons ───────────────────────────────────────
                _CtrlBtn(
                  icon: Icons.skip_previous_rounded,
                  tooltip: 'Jump to start',
                  enabled: step.canStepBack,
                  onTap: notifier.jumpToStart,
                  isDark: widget.isDark,
                  iconSize: iconSize,
                  buttonSize: buttonSize,
                ),
                SizedBox(width: spacing),
                _CtrlBtn(
                  icon: Icons.navigate_before_rounded,
                  tooltip: 'Step back',
                  enabled: step.canStepBack,
                  onTap: notifier.stepBackward,
                  isDark: widget.isDark,
                  iconSize: iconSize,
                  buttonSize: buttonSize,
                ),
                SizedBox(width: spacing),

                // Play / Pause
                GestureDetector(
                  onTap: () {
                    if (step.isPlaying) {
                      notifier.pause();
                    } else {
                      notifier.play(intervalMs: _speedMs.round());
                    }
                  },
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: AppRadius.smAll,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      step.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                ),
                SizedBox(width: spacing),

                _CtrlBtn(
                  icon: Icons.navigate_next_rounded,
                  tooltip: 'Step forward',
                  enabled: step.canStepForward,
                  onTap: notifier.stepForward,
                  isDark: widget.isDark,
                  iconSize: iconSize,
                  buttonSize: buttonSize,
                ),
                SizedBox(width: spacing),
                _CtrlBtn(
                  icon: Icons.skip_next_rounded,
                  tooltip: 'Jump to end',
                  enabled: step.canStepForward,
                  onTap: notifier.jumpToEnd,
                  isDark: widget.isDark,
                  iconSize: iconSize,
                  buttonSize: buttonSize,
                ),
                SizedBox(width: spacing),
                _CtrlBtn(
                  icon: Icons.close_rounded,
                  tooltip: 'Exit step mode',
                  enabled: true,
                  onTap: notifier.reset,
                  isDark: widget.isDark,
                  color: AppColors.error,
                  iconSize: iconSize,
                  buttonSize: buttonSize,
                ),

                SizedBox(width: spacing * 2),

                // ── Step counter ───────────────────────────────────────
                Flexible(
                  child: Text(
                    step.hasSteps
                        ? 'Step ${step.currentIndex + 1}/${step.totalSteps}'
                        : '—',
                    style: AppTextStyles.codeSmall.copyWith(
                      fontSize: fontSize,
                      color: cs.onSurface.withAlpha(180),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                // ── Speed picker (hidden on narrow panels) ───────────────
                if (showSpeed && !isMobile) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.speed_rounded,
                    size: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 60,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: cs.primary,
                        thumbColor: cs.primary,
                        inactiveTrackColor: cs.primary.withAlpha(30),
                        overlayColor: cs.primary.withAlpha(20),
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                      ),
                      child: Slider(
                        value: _speedMs,
                        min: 100,
                        max: 1500,
                        onChanged: (v) {
                          setState(() => _speedMs = v);
                          if (step.isPlaying) {
                            notifier.pause();
                            notifier.play(intervalMs: v.round());
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    required this.isDark,
    this.color,
    this.iconSize = 18,
    this.buttonSize = 38,
  });
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;
  final double iconSize;
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = enabled
        ? (color ?? cs.onSurface)
        : cs.onSurface.withAlpha(50);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.smAll,
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      ),
    );
  }
}
