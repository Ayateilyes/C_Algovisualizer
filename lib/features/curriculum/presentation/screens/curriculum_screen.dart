import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/router/app_router.dart';
import '../../application/curriculum_progress_notifier.dart';
import '../../domain/curriculum_data.dart';

/// Premium curriculum home screen with 11 module cards, progress bar, and
/// difficulty badges. Device-local progress only (via SharedPreferences).
class CurriculumScreen extends ConsumerWidget {
  const CurriculumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    ref.watch(curriculumProgressProvider); // watch for reactivity
    final notifier = ref.read(curriculumProgressProvider.notifier);

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1600
        ? 4
        : width >= 1100
        ? 3
        : width >= 700
        ? 2
        : 1;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Stack(
        children: [
          // ── Cyber Grid Background ─────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _CurriculumGridPainter(isDark: isDark)),
          ),

          CustomScrollView(
            slivers: [
              // ── Hero header ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _CurriculumHeader(
                  isDark: isDark,
                  cs: cs,
                  notifier: notifier,
                ),
              ),

              // ── Sorting Visualizer Banner ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _SortingVisualizerBanner(isDark: isDark),
                ),
              ),

              // ── Module grid ─────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: crossAxisCount == 1
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final module = kCurriculumModules[index];
                          final prog = notifier.moduleProgress(module);
                          final completed = notifier.completedInModule(module);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _ModuleCard(
                              module: module,
                              progress: prog,
                              completedLessons: completed,
                              isDark: isDark,
                              index: index,
                              isMobile: true,
                            ),
                          );
                        }, childCount: kCurriculumModules.length),
                      )
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.55,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final module = kCurriculumModules[index];
                          final prog = notifier.moduleProgress(module);
                          final completed = notifier.completedInModule(module);
                          return _ModuleCard(
                            module: module,
                            progress: prog,
                            completedLessons: completed,
                            isDark: isDark,
                            index: index,
                            isMobile: false,
                          );
                        }, childCount: kCurriculumModules.length),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Grid Painter ───────────────────────────────────────────────────────────
class _CurriculumGridPainter extends CustomPainter {
  _CurriculumGridPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final paint = Paint()
      ..color = borderColor.withAlpha(isDark ? 30 : 50)
      ..strokeWidth = 1;

    const double spacing = 40.0;

    // Vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    // Horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _CurriculumHeader extends StatelessWidget {
  const _CurriculumHeader({
    required this.isDark,
    required this.cs,
    required this.notifier,
  });
  final bool isDark;
  final ColorScheme cs;
  final CurriculumProgressNotifier notifier;

  @override
  Widget build(BuildContext context) {
    // Global progress
    int totalLessons = 0;
    int totalDone = 0;
    for (final m in kCurriculumModules) {
      totalLessons += m.totalLessons;
      totalDone += notifier.completedInModule(m);
    }
    final globalProg = totalLessons > 0 ? totalDone / totalLessons : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F1117).withAlpha(150)
            : AppColors.lightBackground.withAlpha(200),
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
            // Back button + title
            Row(
              children: [
                InkWell(
                  onTap: () => context.go(AppRoutes.welcome),
                  borderRadius: AppRadius.mdAll,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Curriculum',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Master C programming with interactive lessons',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withAlpha(140)
                              : Colors.black.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _EditorNavButton(isDark: isDark),
              ],
            ),

            const SizedBox(height: 20),

            // Overall progress bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(10)
                    : Colors.white.withAlpha(180),
                borderRadius: AppRadius.lgAll,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(15)
                      : AppColors.primary.withAlpha(30),
                ),
              ),
              child: Row(
                children: [
                  // Circular progress
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: globalProg,
                          strokeWidth: 4,
                          backgroundColor: isDark
                              ? Colors.white.withAlpha(20)
                              : AppColors.primary.withAlpha(25),
                          color: AppColors.primary,
                        ),
                        Text(
                          '${(globalProg * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Labels
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Progress',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalDone of $totalLessons lessons completed',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? Colors.white.withAlpha(130)
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Module count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${kCurriculumModules.length} modules',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Module Card ──────────────────────────────────────────────────────────────

class _ModuleCard extends StatefulWidget {
  const _ModuleCard({
    required this.module,
    required this.progress,
    required this.completedLessons,
    required this.isDark,
    required this.index,
    this.isMobile = false,
  });
  final CurriculumModule module;
  final double progress;
  final int completedLessons;
  final bool isDark;
  final int index;
  final bool isMobile;

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 60),
    );
    _scaleAnim = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    final isDark = widget.isDark;
    final accent = m.accentColor;

    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(_hovering ? 1.02 : 1.0),
            transformAlignment: Alignment.center,
            child: GestureDetector(
              onTap: () => context.go('/course/${m.id}'),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hovering
                        ? accent.withAlpha(120)
                        : isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: _hovering ? 1.5 : 1.0,
                  ),
                  boxShadow: _hovering
                      ? [
                          BoxShadow(
                            color: accent.withAlpha(30),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 30 : 12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: widget.isMobile
                      ? MainAxisSize.min
                      : MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top: icon + number + difficulty badge ────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withAlpha(isDark ? 25 : 15),
                            accent.withAlpha(isDark ? 8 : 5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Module icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accent.withAlpha(isDark ? 50 : 30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(m.icon, size: 18, color: accent),
                          ),
                          const SizedBox(width: 10),
                          // Module number
                          Text(
                            '${(widget.index + 1).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: accent.withAlpha(150),
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                          const Spacer(),
                          // Difficulty badge
                          _DifficultyBadge(difficulty: m.difficulty),
                        ],
                      ),
                    ),

                    // ── Body: title + subtitle ──────────────────────────────
                    if (widget.isMobile)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.title,
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.subtitle,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title,
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  m.subtitle,
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (widget.isMobile)
                      const SizedBox(height: 16)
                    else
                      const Spacer(),

                    // ── Footer: progress bar + lesson count ─────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        0,
                        14,
                        widget.isMobile ? 16 : 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress bar
                          ClipRRect(
                            borderRadius: AppRadius.xsAll,
                            child: LinearProgressIndicator(
                              value: widget.progress,
                              minHeight: 5,
                              backgroundColor: isDark
                                  ? Colors.white.withAlpha(15)
                                  : Colors.black.withAlpha(12),
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Lesson count + percentage
                          Row(
                            mainAxisAlignment: widget.isMobile
                                ? MainAxisAlignment.spaceBetween
                                : MainAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.completedLessons}/${m.totalLessons} lessons',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (!widget.isMobile) const Spacer(),
                              Text(
                                '${(widget.progress * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Difficulty Badge ─────────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final ModuleDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: difficulty.color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: difficulty.color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(difficulty.icon, size: 11, color: difficulty.color),
          const SizedBox(width: 4),
          Text(
            difficulty.label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: difficulty.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sorting Visualizer Banner ────────────────────────────────────────────────

class _SortingVisualizerBanner extends StatefulWidget {
  const _SortingVisualizerBanner({required this.isDark});
  final bool isDark;

  @override
  State<_SortingVisualizerBanner> createState() =>
      _SortingVisualizerBannerState();
}

class _SortingVisualizerBannerState extends State<_SortingVisualizerBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovering = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _ctrl.reverse();
      },
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.sortingVisualizer),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.xlAll,
              border: Border.all(
                color: _hovering
                    ? AppColors.primary.withAlpha(150)
                    : widget.isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
                width: _hovering ? 1.5 : 1.0,
              ),
              boxShadow: _hovering
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(40),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(widget.isDark ? 30 : 10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(widget.isDark ? 50 : 30),
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interactive Sorting Visualizer',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          color: widget.isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Watch algorithms sort data step-by-step',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          color: widget.isDark
                              ? Colors.white60
                              : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.mdAll,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Open',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorNavButton extends StatefulWidget {
  const _EditorNavButton({required this.isDark});
  final bool isDark;

  @override
  State<_EditorNavButton> createState() => _EditorNavButtonState();
}

class _EditorNavButtonState extends State<_EditorNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.editor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primary.withAlpha(20)
                : Colors.transparent,
            border: Border.all(
              color: _hovered
                  ? AppColors.primary
                  : (widget.isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
            ),
            borderRadius: AppRadius.smAll,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(40),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.code_rounded,
                size: 16,
                color: _hovered ? AppColors.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Code Lab',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? AppColors.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
