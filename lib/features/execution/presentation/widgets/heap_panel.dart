import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../application/step_notifier.dart';
import '../../domain/execution_step.dart';

/// Premium heap memory grid panel.
///
/// Features:
/// - Animated cells appear with ScaleTransition on malloc
/// - Freed blocks pulse red then fade to muted grey
/// - Each block shows: label, hex address, size, byte cells
/// - Glassmorphic card container per allocation
/// - Legend and empty state with animated pulse
class HeapPanel extends ConsumerStatefulWidget {
  const HeapPanel({super.key, required this.isDark});
  final bool isDark;

  @override
  ConsumerState<HeapPanel> createState() => _HeapPanelState();
}

class _HeapPanelState extends ConsumerState<HeapPanel> {
  List<HeapBlock> _prevHeap = const [];

  @override
  Widget build(BuildContext context) {
    final stepState = ref.watch(stepNotifierProvider);
    final currentStep = stepState.currentStep;

    final heap = currentStep?.heap ?? const [];

    // Detect newly allocated/freed blocks for animation triggers
    final prevAddresses = {..._prevHeap.map((b) => b.address)};
    final newAddresses = {
      ...heap
          .where((b) => !prevAddresses.contains(b.address))
          .map((b) => b.address),
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prevHeap = heap;
    });

    final isDark = widget.isDark;
    final bgColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (heap.isEmpty) {
      return Container(
        color: bgColor,
        child: const EmptyState(
          icon: Icons.memory_rounded,
          title: 'No heap allocations',
          message: 'Use malloc() or calloc() to allocate memory',
        ),
      );
    }

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          _HeapHeader(
            isDark: isDark,
            blockCount: heap.length,
            borderColor: borderColor,
          ),

          // ── Block list ───────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: heap.length,
              itemBuilder: (context, i) {
                final block = heap[i];
                final isNew = newAddresses.contains(block.address);
                return _HeapBlockCard(
                  key: ValueKey(block.address),
                  block: block,
                  isNew: isNew,
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _HeapHeader extends StatelessWidget {
  const _HeapHeader({
    required this.isDark,
    required this.blockCount,
    required this.borderColor,
  });
  final bool isDark;
  final int blockCount;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceVariant,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.memory_rounded, size: 14, color: Color(0xFF7C4DFF)),
          const SizedBox(width: 6),
          Text(
            'Heap Memory',
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _LegendDot(color: const Color(0xFF00C896), label: 'allocd'),
          const SizedBox(width: 8),
          _LegendDot(color: const Color(0xFFFF4444), label: 'freed'),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(fontSize: 10, color: color),
        ),
      ],
    );
  }
}

// ─── Heap Block Card ─────────────────────────────────────────────────────────

class _HeapBlockCard extends StatefulWidget {
  const _HeapBlockCard({
    super.key,
    required this.block,
    required this.isNew,
    required this.isDark,
  });
  final HeapBlock block;
  final bool isNew;
  final bool isDark;

  @override
  State<_HeapBlockCard> createState() => _HeapBlockCardState();
}

class _HeapBlockCardState extends State<_HeapBlockCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _wasFreed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    if (widget.isNew) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _HeapBlockCard old) {
    super.didUpdateWidget(old);
    // Trigger freed animation
    if (!old.block.isFree && widget.block.isFree && !_wasFreed) {
      _wasFreed = true;
      _ctrl.reverse(from: 1.0).then((_) => _ctrl.forward());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final isDark = widget.isDark;

    Color borderColor;
    Color headerColor;
    Color accentColor;

    if (block.isFree) {
      borderColor = const Color(0x55FF4444);
      headerColor = const Color(0x18FF4444);
      accentColor = const Color(0xFFFF4444);
    } else {
      borderColor = const Color(0x557C4DFF);
      headerColor = const Color(0x187C4DFF);
      accentColor = const Color(0xFF7C4DFF);
    }

    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151820) : Colors.white,
            borderRadius: AppRadius.smAll,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Block header ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: Row(
                  children: [
                    // Status dot
                    _PulsingDot(color: accentColor, isPulsing: !block.isFree),
                    const SizedBox(width: 8),
                    // Variable label
                    Text(
                      block.label,
                      style: AppTextStyles.code.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (block.isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4D2020),
                          borderRadius: AppRadius.xsAll,
                        ),
                        child: const Text(
                          'freed',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF4444),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Hex address
                    Text(
                      '0x${block.address.toRadixString(16).toUpperCase()}',
                      style: AppTextStyles.codeSmall.copyWith(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextDisabled
                            : AppColors.lightTextDisabled,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Size badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: AppRadius.xsAll,
                      ),
                      child: Text(
                        '${block.size * 4}B',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Memory cells grid ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(10),
                child: _MemoryCellGrid(
                  block: block,
                  accentColor: accentColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Memory Cell Grid ────────────────────────────────────────────────────────

class _MemoryCellGrid extends StatelessWidget {
  const _MemoryCellGrid({
    required this.block,
    required this.accentColor,
    required this.isDark,
  });
  final HeapBlock block;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cells = block.values.isEmpty
        ? List.filled(block.size, '0')
        : block.values;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(math.max(cells.length, block.size), (i) {
        final value = i < cells.length ? cells[i] : '0';
        final addr = block.address + i * 4;
        return _MemoryCell(
          index: i,
          value: value,
          address: addr,
          accentColor: accentColor,
          isFreed: block.isFree,
          isDark: isDark,
        );
      }),
    );
  }
}

class _MemoryCell extends StatefulWidget {
  const _MemoryCell({
    required this.index,
    required this.value,
    required this.address,
    required this.accentColor,
    required this.isFreed,
    required this.isDark,
  });
  final int index;
  final String value;
  final int address;
  final Color accentColor;
  final bool isFreed;
  final bool isDark;

  @override
  State<_MemoryCell> createState() => _MemoryCellState();
}

class _MemoryCellState extends State<_MemoryCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _colorAnim = ColorTween(
      begin: const Color(0xFFFFAA33),
      end: Colors.transparent,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _MemoryCell old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isZero = widget.value == '0';
    final isFreed = widget.isFreed;
    final accent = isFreed ? const Color(0xFFFF4444) : widget.accentColor;

    return AnimatedBuilder(
      animation: _colorAnim,
      builder: (context, _) => Container(
        width: 56,
        decoration: BoxDecoration(
          color: isFreed
              ? const Color(0x10FF4444)
              : _colorAnim.value != Colors.transparent
              ? _colorAnim.value?.withOpacity(0.15) ?? Colors.transparent
              : isDark
              ? const Color(0xFF1E2235)
              : const Color(0xFFF0F2FA),
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isFreed
                ? const Color(0x33FF4444)
                : isZero
                ? (isDark ? const Color(0xFF2A2D3A) : const Color(0xFFDDE3F0))
                : accent.withOpacity(0.4),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cell value
            Text(
              widget.value,
              style: AppTextStyles.code.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isFreed
                    ? const Color(0x66FF4444)
                    : isZero
                    ? (isDark
                          ? AppColors.darkTextDisabled
                          : AppColors.lightTextDisabled)
                    : accent,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Address sub-label
            Text(
              '+${(widget.index * 4).toRadixString(16).toUpperCase()}',
              style: TextStyle(
                fontSize: 8,
                color: isDark
                    ? AppColors.darkTextDisabled
                    : AppColors.lightTextDisabled,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pulsing Dot ─────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, required this.isPulsing});
  final Color color;
  final bool isPulsing;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isPulsing) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.isPulsing && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isPulsing) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(widget.isPulsing ? _anim.value : 0.4),
          shape: BoxShape.circle,
          boxShadow: widget.isPulsing
              ? [BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 4)]
              : null,
        ),
      ),
    );
  }
}
