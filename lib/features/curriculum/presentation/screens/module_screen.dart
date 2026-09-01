import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/router/app_router.dart';
import '../../application/curriculum_progress_notifier.dart';
import '../../domain/curriculum_data.dart';

/// Module detail screen showing a list of lessons with progress indicators.
class ModuleScreen extends ConsumerWidget {
  const ModuleScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final completed = ref.watch(curriculumProgressProvider);

    // Find the module
    final module = kCurriculumModules
        .where((m) => m.id == moduleId)
        .firstOrNull;
    if (module == null) {
      return Scaffold(
        body: Center(child: Text('Module "$moduleId" not found')),
      );
    }

    final doneCount = module.lessons
        .where((l) => completed.contains(l.id))
        .length;
    final progress = module.lessons.isEmpty
        ? 0.0
        : doneCount / module.lessons.length;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ModuleHeader(
              module: module,
              isDark: isDark,
              cs: cs,
              progress: progress,
              doneCount: doneCount,
            ),
          ),

          // ── Lesson list ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final lesson = module.lessons[index];
                final isDone = completed.contains(lesson.id);
                return _LessonTile(
                  lesson: lesson,
                  module: module,
                  index: index,
                  isDone: isDone,
                  isDark: isDark,
                );
              }, childCount: module.lessons.length),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Module Header ────────────────────────────────────────────────────────────

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({
    required this.module,
    required this.isDark,
    required this.cs,
    required this.progress,
    required this.doneCount,
  });
  final CurriculumModule module;
  final bool isDark;
  final ColorScheme cs;
  final double progress;
  final int doneCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            module.accentColor.withAlpha(isDark ? 40 : 20),
            isDark ? const Color(0xFF0D1117) : Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Row(
              children: [
                InkWell(
                  onTap: () => context.go(AppRoutes.curriculum),
                  borderRadius: AppRadius.mdAll,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(12)
                          : Colors.black.withAlpha(8),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                const Spacer(),
                // Difficulty badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: module.difficulty.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: module.difficulty.color.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        module.difficulty.icon,
                        size: 12,
                        color: module.difficulty.color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        module.difficulty.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: module.difficulty.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Module icon + title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: module.accentColor.withAlpha(isDark ? 50 : 30),
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: Icon(module.icon, size: 22, color: module.accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        module.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadius.xsAll,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.white.withAlpha(15)
                          : Colors.black.withAlpha(10),
                      color: module.accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$doneCount/${module.totalLessons}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: module.accentColor,
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

// ─── Lesson Tile ──────────────────────────────────────────────────────────────

class _LessonTile extends StatefulWidget {
  const _LessonTile({
    required this.lesson,
    required this.module,
    required this.index,
    required this.isDone,
    required this.isDark,
  });
  final Lesson lesson;
  final CurriculumModule module;
  final int index;
  final bool isDone;
  final bool isDark;

  @override
  State<_LessonTile> createState() => _LessonTileState();
}

class _LessonTileState extends State<_LessonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200 + widget.index * 50),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.module.accentColor;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: _ctrl,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () =>
                context.go('/lesson/${widget.module.id}/${widget.lesson.id}'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _hovering
                    ? accent.withAlpha(widget.isDark ? 15 : 8)
                    : widget.isDark
                    ? const Color(0xFF161B22)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hovering
                      ? accent.withAlpha(80)
                      : widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  // Lesson number
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: widget.isDone
                          ? accent.withAlpha(widget.isDark ? 50 : 30)
                          : widget.isDark
                          ? Colors.white.withAlpha(8)
                          : Colors.black.withAlpha(6),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: widget.isDone
                          ? Icon(Icons.check_rounded, size: 14, color: accent)
                          : Text(
                              '${widget.index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: widget.isDark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      widget.lesson.title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: widget.isDark ? Colors.white : Colors.black87,
                        fontWeight: widget.isDone
                            ? FontWeight.w600
                            : FontWeight.w500,
                        decoration: widget.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: widget.isDark
                            ? Colors.white38
                            : Colors.black38,
                      ),
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _hovering
                        ? accent
                        : widget.isDark
                        ? Colors.white30
                        : Colors.black.withAlpha(77),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
