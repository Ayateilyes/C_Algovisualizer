import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/curriculum_progress_notifier.dart';
import '../../domain/curriculum_data.dart';
import '../../domain/lesson_content.dart';
import '../../../shared/analytics_service.dart';
import '../../../execution/application/execution_notifier.dart';
import '../../../execution/application/execution_state.dart';
import '../../../execution/application/step_notifier.dart';

/// Full lesson screen with:
/// - Theory panel (rendered markdown)
/// - Embedded C code editor
/// - Run button + output display
/// - Mark as complete button
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.moduleId,
    required this.lessonId,
  });

  final String moduleId;
  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late TextEditingController _codeCtrl;
  late ConfettiController _confettiCtrl;
  bool _showTheory = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logLessonStart(widget.moduleId, widget.lessonId);

    final content = kLessonContents[widget.lessonId];
    _codeCtrl = TextEditingController(
      text: content?.starterCode ?? '// No code',
    );
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  CurriculumModule? get _module =>
      kCurriculumModules.where((m) => m.id == widget.moduleId).firstOrNull;

  Lesson? get _lesson =>
      _module?.lessons.where((l) => l.id == widget.lessonId).firstOrNull;

  LessonContent? get _content => kLessonContents[widget.lessonId];

  // Find next lesson in the module
  String? get _nextLessonId {
    final m = _module;
    if (m == null) return null;
    final idx = m.lessons.indexWhere((l) => l.id == widget.lessonId);
    if (idx < 0 || idx >= m.lessons.length - 1) return null;
    return m.lessons[idx + 1].id;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final module = _module;
    final lesson = _lesson;
    final content = _content;
    final completed = ref.watch(curriculumProgressProvider);
    final isComplete = completed.contains(widget.lessonId);

    // Track step execution via state changes
    ref.listen(stepNotifierProvider, (previous, next) {
      if (previous != null && next.currentIndex > previous.currentIndex) {
        AnalyticsService.logStepExecuted(widget.moduleId, widget.lessonId);
      }
    });

    if (module == null || lesson == null || content == null) {
      return Scaffold(body: Center(child: Text('Lesson not found')));
    }

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Stack(
        children: [
          // ── Main Content ───────────────────────────────────────────────────
          Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────────
              _LessonTopBar(
                module: module,
                lesson: lesson,
                isDark: isDark,
                isComplete: isComplete,
                showTheory: _showTheory,
                onToggleTheory: () =>
                    setState(() => _showTheory = !_showTheory),
                onBack: () => context.go('/course/${widget.moduleId}'),
                onMarkComplete: () {
                  if (isComplete) {
                    ref
                        .read(curriculumProgressProvider.notifier)
                        .uncompleteLesson(widget.lessonId);
                  } else {
                    ref
                        .read(curriculumProgressProvider.notifier)
                        .completeLesson(widget.lessonId);

                    final remaining = module.lessons.where(
                      (l) =>
                          l.id != widget.lessonId && !completed.contains(l.id),
                    );
                    if (remaining.isEmpty) {
                      AnalyticsService.logModuleCompleted(widget.moduleId);
                      _confettiCtrl.play();
                    }
                  }
                },
              ),

              // ── Body ─────────────────────────────────────────────────────────
              Expanded(
                child: isDesktop
                    ? _DesktopBody(
                        content: content,
                        codeCtrl: _codeCtrl,
                        isDark: isDark,
                        showTheory: _showTheory,
                      )
                    : _MobileBody(
                        content: content,
                        codeCtrl: _codeCtrl,
                        isDark: isDark,
                        showTheory: _showTheory,
                      ),
              ),

              // ── Bottom bar ───────────────────────────────────────────────────
              _LessonBottomBar(
                isDark: isDark,
                isComplete: isComplete,
                module: module,
                codeCtrl: _codeCtrl,
                nextLessonId: _nextLessonId,
                moduleId: widget.moduleId,
              ),
            ],
          ),

          // ── Confetti ───────────────────────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _LessonTopBar extends StatelessWidget {
  const _LessonTopBar({
    required this.module,
    required this.lesson,
    required this.isDark,
    required this.isComplete,
    required this.showTheory,
    required this.onToggleTheory,
    required this.onBack,
    required this.onMarkComplete,
  });
  final CurriculumModule module;
  final Lesson lesson;
  final bool isDark;
  final bool isComplete;
  final bool showTheory;
  final VoidCallback onToggleTheory;
  final VoidCallback onBack;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context) {
    final accent = module.accentColor;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back
          InkWell(
            onTap: onBack,
            borderRadius: AppRadius.smAll,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Module dot + lesson title
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lesson.title,
              style: AppTextStyles.labelMedium.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Theory toggle
          Tooltip(
            message: showTheory ? 'Hide theory' : 'Show theory',
            child: InkWell(
              onTap: onToggleTheory,
              borderRadius: AppRadius.smAll,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  showTheory ? Icons.menu_book_rounded : Icons.code_rounded,
                  size: 16,
                  color: showTheory
                      ? accent
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Mark complete
          _MarkCompleteButton(
            isComplete: isComplete,
            isDark: isDark,
            accent: accent,
            onPressed: onMarkComplete,
          ),
        ],
      ),
    );
  }
}

class _MarkCompleteButton extends StatefulWidget {
  const _MarkCompleteButton({
    required this.isComplete,
    required this.isDark,
    required this.accent,
    required this.onPressed,
  });
  final bool isComplete;
  final bool isDark;
  final Color accent;
  final VoidCallback onPressed;

  @override
  State<_MarkCompleteButton> createState() => _MarkCompleteButtonState();
}

class _MarkCompleteButtonState extends State<_MarkCompleteButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.isComplete ? 'Mark incomplete' : 'Mark complete',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: widget.isComplete
                    ? widget.accent.withAlpha(widget.isDark ? 40 : 20)
                    : Colors.transparent,
                borderRadius: AppRadius.smAll,
                border: Border.all(
                  color: widget.isComplete
                      ? widget.accent.withAlpha(80)
                      : (widget.isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      widget.isComplete
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      key: ValueKey(widget.isComplete),
                      size: 13,
                      color: widget.isComplete
                          ? widget.accent
                          : (widget.isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      widget.isComplete ? 'Done' : 'Complete',
                      key: ValueKey(widget.isComplete),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.isComplete
                            ? widget.accent
                            : (widget.isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
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

// ─── Desktop Body (side-by-side) ──────────────────────────────────────────────

class _DesktopBody extends StatelessWidget {
  const _DesktopBody({
    required this.content,
    required this.codeCtrl,
    required this.isDark,
    required this.showTheory,
  });
  final LessonContent content;
  final TextEditingController codeCtrl;
  final bool isDark;
  final bool showTheory;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Row(
      children: [
        if (showTheory) ...[
          Expanded(
            flex: 45,
            child: _TheoryPanel(theory: content.theory, isDark: isDark),
          ),
          Container(width: 1, color: dividerColor),
        ],
        Expanded(
          flex: 55,
          child: _EditorPanel(codeCtrl: codeCtrl, isDark: isDark),
        ),
      ],
    );
  }
}

// ─── Mobile Body (toggle between theory and editor) ──────────────────────────

class _MobileBody extends StatelessWidget {
  const _MobileBody({
    required this.content,
    required this.codeCtrl,
    required this.isDark,
    required this.showTheory,
  });
  final LessonContent content;
  final TextEditingController codeCtrl;
  final bool isDark;
  final bool showTheory;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTheory) ...[
            _TheoryPanel(
              key: const ValueKey('theory'),
              theory: content.theory,
              isDark: isDark,
              scrollable: false,
            ),
            Container(height: 1, color: dividerColor),
          ],
          SizedBox(
            height: 250,
            child: _EditorPanel(
              key: const ValueKey('editor'),
              codeCtrl: codeCtrl,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Theory Panel ─────────────────────────────────────────────────────────────

class _TheoryPanel extends StatelessWidget {
  const _TheoryPanel({
    super.key,
    required this.theory,
    required this.isDark,
    this.scrollable = true,
  });
  final String theory;
  final bool isDark;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = _SimpleMarkdownRenderer(markdown: theory, isDark: isDark);
    return Container(
      color: isDark ? AppColors.darkBackground : const Color(0xFFFAFBFF),
      child: scrollable
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: content,
            )
          : Padding(padding: const EdgeInsets.all(24), child: content),
    );
  }
}

/// Lightweight markdown renderer without external dependencies.
/// Supports: headers, bold, inline code, code blocks, tables, blockquotes, lists.
class _SimpleMarkdownRenderer extends StatelessWidget {
  const _SimpleMarkdownRenderer({required this.markdown, required this.isDark});
  final String markdown;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lines = markdown.split('\n');
    final widgets = <Widget>[];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Code block
      if (line.trimLeft().startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        i++; // skip closing ```
        widgets.add(
          _CodeBlockWidget(code: codeLines.join('\n'), isDark: isDark),
        );
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Table
      if (line.contains('|') && line.trim().startsWith('|')) {
        final tableLines = <String>[];
        while (i < lines.length &&
            lines[i].contains('|') &&
            lines[i].trim().isNotEmpty) {
          tableLines.add(lines[i]);
          i++;
        }
        widgets.add(_TableWidget(lines: tableLines, isDark: isDark));
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Headers
      if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              line.substring(2),
              style: AppTextStyles.titleLarge.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
        );
        i++;
        continue;
      }
      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 16),
            child: Text(
              line.substring(3),
              style: AppTextStyles.titleMedium.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        );
        i++;
        continue;
      }
      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 12),
            child: Text(
              line.substring(4),
              style: AppTextStyles.labelLarge.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      // Blockquote
      if (line.trimLeft().startsWith('> ')) {
        widgets.add(
          _BlockquoteWidget(text: line.trimLeft().substring(2), isDark: isDark),
        );
        widgets.add(const SizedBox(height: 8));
        i++;
        continue;
      }

      // List items
      if (line.trimLeft().startsWith('- ') ||
          line.trimLeft().startsWith('* ')) {
        widgets.add(
          _ListItemWidget(text: line.trimLeft().substring(2), isDark: isDark),
        );
        i++;
        continue;
      }

      // Numbered list
      final numberedMatch = RegExp(r'^\d+\.\s').firstMatch(line.trimLeft());
      if (numberedMatch != null) {
        widgets.add(
          _ListItemWidget(
            text: line.trimLeft().substring(numberedMatch.end),
            isDark: isDark,
            isNumbered: true,
            number: line.trimLeft().substring(0, numberedMatch.end - 2),
          ),
        );
        i++;
        continue;
      }

      // Empty line
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        i++;
        continue;
      }

      // Regular text (with inline formatting)
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _InlineText(text: line, isDark: isDark),
        ),
      );
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

// ─── Markdown sub-widgets ─────────────────────────────────────────────────────

class _InlineText extends StatelessWidget {
  const _InlineText({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Parse inline formatting: **bold**, `code`, *italic*
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|`(.+?)`|\*(.+?)\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        );
      }
      if (match.group(1) != null) {
        // Bold
        spans.add(
          TextSpan(
            text: match.group(1),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        );
      } else if (match.group(2) != null) {
        // Inline code
        spans.add(
          WidgetSpan(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : const Color(0xFFEEF0F8),
                borderRadius: AppRadius.xsAll,
              ),
              child: Text(
                match.group(2)!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF79C0FF)
                      : const Color(0xFFD63384),
                ),
              ),
            ),
          ),
        );
      } else if (match.group(3) != null) {
        // Italic
        spans.add(
          TextSpan(
            text: match.group(3),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        );
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextStyle(
            fontSize: 13.5,
            height: 1.6,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}

class _CodeBlockWidget extends StatelessWidget {
  const _CodeBlockWidget({required this.code, required this.isDark});
  final String code;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(10),
        ),
      ),
      child: SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
          color: isDark ? const Color(0xFFE6EDF3) : Colors.black87,
        ),
      ),
    );
  }
}

class _BlockquoteWidget extends StatelessWidget {
  const _BlockquoteWidget({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.primary.withAlpha(120), width: 3),
        ),
        color: AppColors.primary.withAlpha(isDark ? 10 : 8),
      ),
      child: _InlineText(text: text, isDark: isDark),
    );
  }
}

class _ListItemWidget extends StatelessWidget {
  const _ListItemWidget({
    required this.text,
    required this.isDark,
    this.isNumbered = false,
    this.number,
  });
  final String text;
  final bool isDark;
  final bool isNumbered;
  final String? number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNumbered ? '$number. ' : '• ',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: _InlineText(text: text, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _TableWidget extends StatelessWidget {
  const _TableWidget({required this.lines, required this.isDark});
  final List<String> lines;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Parse table rows.
    // Protect | characters inside backtick code spans before splitting,
    // since | is used as the column separator.
    const placeholder = '\u0000';
    final rows = <List<String>>[];
    for (final line in lines) {
      if (line.contains('---')) continue; // skip separator
      // Replace | inside `...` with a placeholder, split on bare |, restore.
      final protected = line.replaceAllMapped(
        RegExp(r'`[^`]*`'),
        (m) => m.group(0)!.replaceAll('|', placeholder),
      );
      final cells = protected
          .split('|')
          .map((c) => c.trim().replaceAll(placeholder, '|'))
          .where((c) => c.isNotEmpty)
          .toList();
      if (cells.isNotEmpty) rows.add(cells);
    }
    if (rows.isEmpty) return const SizedBox();

    final headerCells = rows[0];
    final dataRows = rows.length > 1 ? rows.sublist(1) : <List<String>>[];

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(15)
              : Colors.black.withAlpha(10),
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Table(
          border: TableBorder.symmetric(
            inside: BorderSide(
              color: isDark
                  ? Colors.white.withAlpha(10)
                  : Colors.black.withAlpha(8),
            ),
          ),
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(8)
                    : Colors.black.withAlpha(5),
              ),
              children: headerCells.map((cell) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    cell,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
            // Data rows
            ...dataRows.map((cells) {
              // Pad cells to match header length
              while (cells.length < headerCells.length) {
                cells.add('');
              }
              return TableRow(
                children: cells.take(headerCells.length).map((cell) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: _InlineText(text: cell, isDark: isDark),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Editor Panel ─────────────────────────────────────────────────────────────

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({super.key, required this.codeCtrl, required this.isDark});
  final TextEditingController codeCtrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        children: [
          // Editor header
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.code_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'lesson.c',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const Spacer(),
                // Reset button
                Tooltip(
                  message: 'Reset code',
                  child: InkWell(
                    onTap: () {
                      // Reset handled externally
                    },
                    borderRadius: AppRadius.xsAll,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.restart_alt_rounded,
                        size: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code text field
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0D1117) : Colors.white,
              child: TextField(
                controller: codeCtrl,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? const Color(0xFFE6EDF3) : Colors.black87,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
                cursorColor: AppColors.primary,
                cursorWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _LessonBottomBar extends ConsumerWidget {
  const _LessonBottomBar({
    required this.isDark,
    required this.isComplete,
    required this.module,
    required this.codeCtrl,
    required this.nextLessonId,
    required this.moduleId,
  });
  final bool isDark;
  final bool isComplete;
  final CurriculumModule module;
  final TextEditingController codeCtrl;
  final String? nextLessonId;
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionNotifierProvider);
    final isRunning = execState.status == RunStatus.running;
    final accent = module.accentColor;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Output preview
          Expanded(
            child: _OutputPreview(state: execState, isDark: isDark),
          ),
          const SizedBox(width: 8),
          // Run button
          InkWell(
            onTap: isRunning
                ? null
                : () {
                    ref
                        .read(executionNotifierProvider.notifier)
                        .run(codeCtrl.text);
                  },
            borderRadius: AppRadius.mdAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: isRunning
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                color: isRunning ? AppColors.primary.withAlpha(80) : null,
                borderRadius: AppRadius.mdAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRunning)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 5),
                  Text(
                    isRunning ? 'Running…' : 'Run',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Next lesson
          if (nextLessonId != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Next lesson',
              child: InkWell(
                onTap: () => context.go('/lesson/$moduleId/$nextLessonId'),
                borderRadius: AppRadius.mdAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(isDark ? 30 : 15),
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: accent.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OutputPreview extends StatelessWidget {
  const _OutputPreview({required this.state, required this.isDark});
  final ExecutionState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (state.status == RunStatus.idle) {
      return Text(
        'Press Run to execute',
        style: TextStyle(
          fontSize: 11,
          color: isDark
              ? Colors.white.withAlpha(77)
              : Colors.black.withAlpha(77),
        ),
      );
    }

    if (state.status == RunStatus.running) {
      return Row(
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Running…',
            style: TextStyle(fontSize: 11, color: AppColors.warning),
          ),
        ],
      );
    }

    final result = state.result;
    final output = result.stdout.isNotEmpty ? result.stdout : result.stderr;
    final isErr = result.stderr.isNotEmpty && result.stdout.isEmpty;
    final color = isErr ? AppColors.error : AppColors.success;

    return Row(
      children: [
        Icon(
          isErr
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            output.replaceAll('\n', ' ↵ ').trim(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
