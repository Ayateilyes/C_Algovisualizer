import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/sort_engine.dart';

/// Premium sorting visualizer with animated bar chart for 5 algorithms.
class SortingVisualizerScreen extends StatefulWidget {
  const SortingVisualizerScreen({super.key});

  @override
  State<SortingVisualizerScreen> createState() =>
      _SortingVisualizerScreenState();
}

class _SortingVisualizerScreenState extends State<SortingVisualizerScreen>
    with TickerProviderStateMixin {
  // State
  SortAlgorithm _algorithm = SortAlgorithm.bubble;
  List<SortStep> _steps = [];
  int _currentStep = 0;
  bool _isPlaying = false;
  Timer? _timer;
  int _arraySize = 20;
  int _speedMs = 120;
  List<int> _initialArray = [];

  // Animation
  late AnimationController _barAnimCtrl;

  @override
  void initState() {
    super.initState();
    _barAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _generateNewArray();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _barAnimCtrl.dispose();
    super.dispose();
  }

  void _generateNewArray() {
    _timer?.cancel();
    _isPlaying = false;
    _initialArray = SortEngine.generateArray(_arraySize);
    _steps = SortEngine.generate(_algorithm, List.from(_initialArray));
    _currentStep = 0;
    setState(() {});
  }

  void _changeAlgorithm(SortAlgorithm algo) {
    _timer?.cancel();
    _isPlaying = false;
    _algorithm = algo;
    _steps = SortEngine.generate(algo, List.from(_initialArray));
    _currentStep = 0;
    setState(() {});
  }

  void _play() {
    if (_currentStep >= _steps.length - 1) {
      _currentStep = 0;
    }
    _isPlaying = true;
    _timer = Timer.periodic(Duration(milliseconds: _speedMs), (_) {
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
      } else {
        _timer?.cancel();
        setState(() => _isPlaying = false);
      }
    });
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _isPlaying = false;
    setState(() {});
  }

  void _stepForward() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _stepBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _reset() {
    _timer?.cancel();
    _isPlaying = false;
    _currentStep = 0;
    setState(() {});
  }

  SortStep get _step => _steps.isNotEmpty
      ? _steps[_currentStep]
      : SortStep(array: _initialArray, comparing: [], swapping: [], sorted: []);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          _VisualizerHeader(
            isDark: isDark,
            algorithm: _algorithm,
            onAlgorithmChanged: _changeAlgorithm,
            onNewArray: _generateNewArray,
          ),

          // ── Bar chart ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _BarChart(
                step: _step,
                isDark: isDark,
                algorithm: _algorithm,
              ),
            ),
          ),

          // ── Step info ──────────────────────────────────────────────────
          _StepInfo(
            step: _step,
            stepIndex: _currentStep,
            totalSteps: _steps.length,
            isDark: isDark,
          ),

          // ── Controls ───────────────────────────────────────────────────
          _ControlBar(
            isDark: isDark,
            isPlaying: _isPlaying,
            currentStep: _currentStep,
            totalSteps: _steps.length,
            speedMs: _speedMs,
            arraySize: _arraySize,
            onPlay: _play,
            onPause: _pause,
            onStepForward: _stepForward,
            onStepBack: _stepBack,
            onReset: _reset,
            onSpeedChanged: (v) {
              _speedMs = v;
              if (_isPlaying) {
                _pause();
                _play();
              }
              setState(() {});
            },
            onSizeChanged: (v) {
              _arraySize = v;
              _generateNewArray();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _VisualizerHeader extends StatelessWidget {
  const _VisualizerHeader({
    required this.isDark,
    required this.algorithm,
    required this.onAlgorithmChanged,
    required this.onNewArray,
  });
  final bool isDark;
  final SortAlgorithm algorithm;
  final ValueChanged<SortAlgorithm> onAlgorithmChanged;
  final VoidCallback onNewArray;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sorting Visualizer',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                // New array button
                _ActionChip(
                  icon: Icons.shuffle_rounded,
                  label: 'Shuffle',
                  isDark: isDark,
                  onTap: onNewArray,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Algorithm chips
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: SortAlgorithm.values.map((algo) {
                  final isActive = algo == algorithm;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _AlgorithmChip(
                      algo: algo,
                      isActive: isActive,
                      isDark: isDark,
                      onTap: () => onAlgorithmChanged(algo),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlgorithmChip extends StatelessWidget {
  const _AlgorithmChip({
    required this.algo,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });
  final SortAlgorithm algo;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                )
              : null,
          color: isActive
              ? null
              : isDark
              ? Colors.white.withAlpha(8)
              : Colors.black.withAlpha(6),
          borderRadius: AppRadius.xlAll,
          border: isActive
              ? null
              : Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              algo.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : isDark
                    ? Colors.white70
                    : Colors.black87,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              algo.complexity,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white.withAlpha(180)
                    : isDark
                    ? Colors.white38
                    : Colors.black38,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bar Chart ────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.step,
    required this.isDark,
    required this.algorithm,
  });
  final SortStep step;
  final bool isDark;
  final SortAlgorithm algorithm;

  @override
  Widget build(BuildContext context) {
    final arr = step.array;
    if (arr.isEmpty) return const SizedBox();

    final maxVal = arr.reduce((a, b) => a > b ? a : b).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(arr.length, (i) {
            final value = arr[i];
            final heightFraction = value / maxVal;
            final barHeight = constraints.maxHeight * heightFraction * 0.9;

            // Determine bar color
            final color = _getBarColor(i);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: arr.length > 30 ? 0.5 : 1.0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: barHeight.clamp(4.0, constraints.maxHeight),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(arr.length > 30 ? 2 : 3),
                    ),
                    boxShadow:
                        step.swapping.contains(i) || step.comparing.contains(i)
                        ? [
                            BoxShadow(
                              color: color.withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ]
                        : null,
                  ),
                  child: arr.length <= 25
                      ? Center(
                          child: RotatedBox(
                            quarterTurns: arr.length > 15 ? 3 : 0,
                            child: Text(
                              '$value',
                              style: TextStyle(
                                fontSize: arr.length > 15 ? 7 : 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Color _getBarColor(int i) {
    if (step.sorted.contains(i)) {
      return const Color(0xFF00C896); // Green = sorted
    }
    if (step.pivot == i) {
      return const Color(0xFFFFD600); // Yellow = pivot
    }
    if (step.swapping.contains(i)) {
      return const Color(0xFFFF4081); // Pink = swapping
    }
    if (step.comparing.contains(i)) {
      return const Color(0xFF448AFF); // Blue = comparing
    }
    return isDark
        ? const Color(0xFF58617A) // Default dark
        : const Color(0xFFB0BEC5); // Default light
  }
}

// ─── Step Info ────────────────────────────────────────────────────────────────

class _StepInfo extends StatelessWidget {
  const _StepInfo({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.isDark,
  });
  final SortStep step;
  final int stepIndex;
  final int totalSteps;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Color legend
          _LegendDot(color: const Color(0xFF448AFF), label: 'Compare'),
          const SizedBox(width: 10),
          _LegendDot(color: const Color(0xFFFF4081), label: 'Swap'),
          const SizedBox(width: 10),
          _LegendDot(color: const Color(0xFF00C896), label: 'Sorted'),
          const SizedBox(width: 10),
          _LegendDot(color: const Color(0xFFFFD600), label: 'Pivot'),
          const Spacer(),
          // Step label
          Flexible(
            child: Text(
              step.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

// ─── Control Bar ──────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.isDark,
    required this.isPlaying,
    required this.currentStep,
    required this.totalSteps,
    required this.speedMs,
    required this.arraySize,
    required this.onPlay,
    required this.onPause,
    required this.onStepForward,
    required this.onStepBack,
    required this.onReset,
    required this.onSpeedChanged,
    required this.onSizeChanged,
  });
  final bool isDark;
  final bool isPlaying;
  final int currentStep;
  final int totalSteps;
  final int speedMs;
  final int arraySize;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStepForward;
  final VoidCallback onStepBack;
  final VoidCallback onReset;
  final ValueChanged<int> onSpeedChanged;
  final ValueChanged<int> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Progress slider
            Row(
              children: [
                Text(
                  '${currentStep + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      trackHeight: 3,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: isDark
                          ? Colors.white.withAlpha(15)
                          : Colors.black.withAlpha(12),
                      thumbColor: AppColors.primary,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: currentStep.toDouble(),
                      min: 0,
                      max: (totalSteps - 1).toDouble().clamp(
                        0,
                        double.infinity,
                      ),
                      onChanged: (v) {
                        // Not directly controllable — use step buttons
                      },
                    ),
                  ),
                ),
                Text(
                  '$totalSteps',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Playback controls + sliders
            Row(
              children: [
                // First/prev/play/next/last
                _ControlButton(
                  icon: Icons.skip_previous_rounded,
                  isDark: isDark,
                  onTap: onReset,
                  tooltip: 'Reset',
                ),
                _ControlButton(
                  icon: Icons.chevron_left_rounded,
                  isDark: isDark,
                  onTap: onStepBack,
                  tooltip: 'Previous',
                ),
                // Play/Pause
                GestureDetector(
                  onTap: isPlaying ? onPause : onPlay,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                _ControlButton(
                  icon: Icons.chevron_right_rounded,
                  isDark: isDark,
                  onTap: onStepForward,
                  tooltip: 'Next',
                ),
                _ControlButton(
                  icon: Icons.skip_next_rounded,
                  isDark: isDark,
                  onTap: () {
                    // Jump to end — not implemented, user can play
                  },
                  tooltip: 'End',
                ),

                const SizedBox(width: 12),

                // Speed slider
                Expanded(
                  child: _SliderControl(
                    label: 'Speed',
                    icon: Icons.speed_rounded,
                    value: (300 - speedMs).toDouble(),
                    min: 0,
                    max: 280,
                    isDark: isDark,
                    onChanged: (v) => onSpeedChanged(300 - v.round()),
                  ),
                ),

                const SizedBox(width: 8),

                // Size slider
                Expanded(
                  child: _SliderControl(
                    label: 'Size',
                    icon: Icons.view_column_rounded,
                    value: arraySize.toDouble(),
                    min: 5,
                    max: 50,
                    isDark: isDark,
                    onChanged: (v) => onSizeChanged(v.round()),
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

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(8)
                : Colors.black.withAlpha(5),
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _SliderControl extends StatelessWidget {
  const _SliderControl({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.isDark,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final bool isDark;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: isDark ? Colors.white38 : Colors.black38),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              trackHeight: 2,
              activeTrackColor: AppColors.primary.withAlpha(150),
              inactiveTrackColor: isDark
                  ? Colors.white.withAlpha(10)
                  : Colors.black.withAlpha(8),
              thumbColor: AppColors.primary,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
