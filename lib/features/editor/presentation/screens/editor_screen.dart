import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/router/app_router.dart';

import '../../../../features/execution/application/execution_notifier.dart';
import '../../../../features/execution/application/step_notifier.dart';
import '../../../../features/execution/presentation/widgets/output_console.dart';
import '../../../../features/execution/presentation/widgets/step_controls.dart';
import '../../../../features/execution/presentation/widgets/variable_inspector.dart';
import '../../../../features/execution/presentation/widgets/stack_frame_panel.dart';
import '../../../../features/execution/presentation/widgets/heap_panel.dart';
import '../../../../features/execution/presentation/widgets/pointer_graph_panel.dart';
import '../../../../features/execution/presentation/widgets/io_console_panel.dart';
import '../../../../features/execution/domain/scanf_input.dart';
import '../../domain/editor_state.dart';
import '../widgets/code_editor_widget.dart';

/// Full-screen editor with the following layout:
///
/// Desktop (≥900px):  [Gutter | Code Editor] + [Right placeholder panels]
/// Tablet  (≥600px):  [Code Editor] + [Bottom output stub]
/// Mobile  (<600px):  [Code Editor] only, panels via bottom navigation
class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 900;

          return Column(
            children: [
              // ── Gradient top border ─────────────
              Container(
                height: 1,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1A56DB),
                      Color(0xFF7C3AED),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              _EditorAppBar(isDesktop: isDesktop),
              Expanded(
                child: width < 600 ? const _MobileLayout() : _DesktopLayout(),
              ),
              _EditorStatusBar(),
            ],
          );
        },
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _EditorAppBar extends ConsumerWidget {
  const _EditorAppBar({required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final showTitle = screenWidth >= 700;
    final showFileTab = screenWidth >= 500;

    return Container(
      height: 52,
      clipBehavior: Clip.hardEdge,
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
          const SizedBox(width: 16),

          // App logo
          Icon(Icons.code_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),

          if (showTitle) ...[
            Text(
              'C-AlgoVisualizer',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 16,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(width: 12),
          ],

          // File name
          if (showFileTab) ...[
            Text(
              'main.c',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 13,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.circle, size: 8, color: AppColors.warning),

            if (showTitle) ...[
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 16,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              const SizedBox(width: 12),
            ],
          ],

          // Push to RIGHT edge
          Expanded(child: const SizedBox.shrink()),

          // Curriculum Button
          _CurriculumNavButton(compact: screenWidth < 800),
          const SizedBox(width: 8),

          // Toolbar actions (Run, Step, Save)
          _ToolbarActions(isDesktop: isDesktop),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _CurriculumNavButton extends StatefulWidget {
  const _CurriculumNavButton({required this.compact});
  final bool compact;

  @override
  State<_CurriculumNavButton> createState() => _CurriculumNavButtonState();
}

class _CurriculumNavButtonState extends State<_CurriculumNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.curriculum),
        child: AnimatedContainer(
          height: 44,
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primary.withAlpha(20)
                : Colors.transparent,
            border: Border.all(
              color: _hovered
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                Icons.menu_book_rounded,
                size: 16,
                color: _hovered ? AppColors.primary : cs.onSurfaceVariant,
              ),
              if (!widget.compact) ...[
                const SizedBox(width: 6),
                Text(
                  'Curriculum →',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _hovered ? AppColors.primary : cs.onSurfaceVariant,
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

class _ToolbarActions extends ConsumerWidget {
  const _ToolbarActions({required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTracing = ref.watch(
      stepNotifierProvider.select((s) => s.isTracing),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDesktop) ...[
          _FontSizeButton(isDark: isDark),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(width: 8),
        ],

        // Step button
        _StepButton(isTracing: isTracing),

        const SizedBox(width: 8),

        // Run button (primary CTA)
        _RunButton(),
      ],
    );
  }
}

/// Step/Debug button — triggers trace mode.
class _StepButton extends ConsumerWidget {
  const _StepButton({required this.isTracing});
  final bool isTracing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Step through execution',
      child: InkWell(
        onTap: isTracing
            ? null
            : () {
                final code = ref.read(editorContentProvider);
                ref.read(stepNotifierProvider.notifier).startTrace(code);
              },
        borderRadius: AppRadius.smAll,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.warning.withAlpha(isTracing ? 60 : 120),
            ),
            borderRadius: AppRadius.smAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTracing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.warning,
                  ),
                )
              else
                const Icon(
                  Icons.bug_report_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
              const SizedBox(width: 5),
              Text(
                isTracing ? 'Tracing…' : 'Step',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.warning,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Font size control with popover slider.
class _FontSizeButton extends ConsumerStatefulWidget {
  const _FontSizeButton({required this.isDark});
  final bool isDark;

  @override
  ConsumerState<_FontSizeButton> createState() => _FontSizeButtonState();
}

class _FontSizeButtonState extends ConsumerState<_FontSizeButton> {
  OverlayEntry? _overlayEntry;
  final _layerLink = LayerLink();
  bool _open = false;

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _open = true;
      _overlayEntry = _buildOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _open = false);
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-80, 40),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {}, // prevent close on panel tap
                  child: _FontSizePanel(isDark: widget.isDark, onClose: _close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(editorFontSizeProvider);
    final cs = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: 'Font size (${fontSize.toInt()}px)',
        child: InkWell(
          onTap: _toggle,
          borderRadius: AppRadius.smAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.text_fields_rounded,
                  size: 16,
                  color: _open ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${fontSize.toInt()}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _open ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: _open ? cs.primary : cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FontSizePanel extends ConsumerWidget {
  const _FontSizePanel({required this.isDark, required this.onClose});
  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(editorFontSizeProvider);
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: border),
        boxShadow: AppShadows.lg(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Font Size',
                style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface),
              ),
              const Spacer(),
              // Reset
              InkWell(
                onTap: () =>
                    ref.read(editorFontSizeProvider.notifier).state = 14.0,
                borderRadius: AppRadius.smAll,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'Reset',
                    style: AppTextStyles.labelSmall.copyWith(color: cs.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: cs.primary,
              thumbColor: cs.primary,
              inactiveTrackColor: cs.primary.withAlpha(40),
              overlayColor: cs.primary.withAlpha(25),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: fontSize.clamp(10.0, 24.0),
              min: 10,
              max: 24,
              divisions: 14,
              onChanged: (v) =>
                  ref.read(editorFontSizeProvider.notifier).state = v,
            ),
          ),

          // Size labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10',
                style: AppTextStyles.labelSmall.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                '${fontSize.toInt()}px',
                style: AppTextStyles.labelMedium.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '24',
                style: AppTextStyles.labelSmall.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Keyboard hints
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightSurfaceVariant,
              borderRadius: AppRadius.smAll,
            ),
            child: Column(
              children: [
                _KbdHint(key_: 'Tab', label: 'Indent 4 spaces'),
                _KbdHint(key_: '⇧ Tab', label: 'De-indent'),
                _KbdHint(key_: 'Enter', label: 'Smart indent'),
                _KbdHint(key_: '{ ( [', label: 'Auto-close'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KbdHint extends StatelessWidget {
  const _KbdHint({required this.key_, required this.label});
  final String key_;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: AppRadius.xsAll,
              border: Border.all(color: cs.outline.withAlpha(80)),
            ),
            child: Text(
              key_,
              style: AppTextStyles.codeSmall.copyWith(
                fontSize: 9,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _IconAction removed because curriculum is now a custom _CurriculumNavButton

class _RunButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(
      executionNotifierProvider.select((s) => s.isRunning),
    );

    return AnimatedContainer(
      duration: AppDurations.fast,
      decoration: BoxDecoration(
        gradient: isRunning
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isRunning ? AppColors.primary.withAlpha(120) : null,
        borderRadius: AppRadius.smAll,
        boxShadow: isRunning
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withAlpha(77),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          onTap: isRunning
              ? null
              : () {
                  final code = ref.read(editorContentProvider);
                  ref.read(executionNotifierProvider.notifier).run(code);
                },
          borderRadius: AppRadius.smAll,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRunning)
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                const SizedBox(width: 6),
                Text(
                  isRunning ? 'Running…' : 'Run',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status Bar ───────────────────────────────────────────────────────────────

class _EditorStatusBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursor = ref.watch(editorCursorProvider);
    final content = ref.watch(editorContentProvider);
    final lineCount = content.split('\n').length;

    return Container(
      height: 26,
      decoration: BoxDecoration(color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _StatusItem(
            icon: Icons.my_location_rounded,
            label: 'Ln ${cursor.line}, Col ${cursor.col}',
          ),
          _StatusDivider(),
          _StatusItem(
            icon: Icons.format_list_numbered_rounded,
            label: '$lineCount lines',
          ),
          _StatusDivider(),
          _StatusItem(icon: Icons.code_rounded, label: 'C'),
          _StatusDivider(),
          _StatusItem(icon: Icons.text_fields_rounded, label: 'UTF-8'),
          const Spacer(),
          _StatusItem(
            icon: Icons.circle,
            label: 'Ready',
            iconSize: 7,
            iconColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.icon,
    required this.label,
    this.iconSize = 11,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: iconColor ?? Colors.white.withAlpha(179),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white.withAlpha(230),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _StatusDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withAlpha(51),
    );
  }
}

// ─── Layouts ──────────────────────────────────────────────────────────────────

class _DesktopLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inStepMode = ref.watch(stepNotifierProvider.select((s) => !s.isIdle));

    return Row(
      children: [
        Expanded(flex: 60, child: CodeEditorWidget()),
        Container(width: 1, color: dividerColor),
        Expanded(
          flex: 40,
          child: inStepMode
              ? _StepPanel(isDark: isDark)
              : OutputConsole(isDark: isDark),
        ),
      ],
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inStepMode = ref.watch(stepNotifierProvider.select((s) => !s.isIdle));

    return Column(
      children: [
        const Expanded(flex: 50, child: CodeEditorWidget()),
        Container(height: 1, color: dividerColor),
        Expanded(
          flex: 50,
          child: inStepMode
              ? _StepPanel(isDark: isDark)
              : OutputConsole(isDark: isDark),
        ),
      ],
    );
  }
}

/// Panel that shows when the user is in step/debug mode.
/// Top: StepControls bar + tab selector. Body: Variables or Call Stack.
class _StepPanel extends ConsumerStatefulWidget {
  const _StepPanel({required this.isDark});
  final bool isDark;

  @override
  ConsumerState<_StepPanel> createState() => _StepPanelState();
}

enum _StepTab { variables, stack, heap, pointers, console }

class _StepPanelState extends ConsumerState<_StepPanel> {
  _StepTab _tab = _StepTab.variables;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    final stepState = ref.watch(stepNotifierProvider);
    final isScanfPending = stepState.isScanfPending;

    // Current scanf input prompt
    ScanfInput? currentScanfInput;
    if (isScanfPending && stepState.pendingInputs.isNotEmpty) {
      final idx = stepState.collectedInputs.length;
      if (idx < stepState.pendingInputs.length) {
        currentScanfInput = stepState.pendingInputs[idx];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepControls(isDark: widget.isDark),

        // ── Tab bar ──────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          height: 30,
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkSurface
                : AppColors.lightSurfaceVariant,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                _TabChip(
                  label: 'Variables',
                  icon: Icons.data_object_rounded,
                  isActive: _tab == _StepTab.variables,
                  onTap: () => setState(() => _tab = _StepTab.variables),
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 4),
                _TabChip(
                  label: 'Call Stack',
                  icon: Icons.layers_rounded,
                  isActive: _tab == _StepTab.stack,
                  onTap: () => setState(() => _tab = _StepTab.stack),
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 4),
                _TabChip(
                  label: 'Heap',
                  icon: Icons.memory_rounded,
                  isActive: _tab == _StepTab.heap,
                  onTap: () => setState(() => _tab = _StepTab.heap),
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 4),
                _TabChip(
                  label: 'Pointers',
                  icon: Icons.account_tree_rounded,
                  isActive: _tab == _StepTab.pointers,
                  onTap: () => setState(() => _tab = _StepTab.pointers),
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 4),
                _TabChip(
                  label: 'Console',
                  icon: Icons.terminal_rounded,
                  isActive: _tab == _StepTab.console,
                  onTap: () => setState(() => _tab = _StepTab.console),
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),

        // ── Content ──────────────────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: AppDurations.fast,
            child: switch (_tab) {
              _StepTab.variables => VariableInspector(
                key: const ValueKey('vars'),
                isDark: widget.isDark,
              ),
              _StepTab.stack => StackFramePanel(
                key: const ValueKey('stack'),
                isDark: widget.isDark,
              ),
              _StepTab.heap => HeapPanel(
                key: const ValueKey('heap'),
                isDark: widget.isDark,
              ),
              _StepTab.pointers => PointerGraphPanel(
                key: const ValueKey('ptrs'),
                isDark: widget.isDark,
              ),
              _StepTab.console => IOConsolePanel(
                key: const ValueKey('console'),
                isDark: widget.isDark,
              ),
            },
          ),
        ),

        // ── Scanf overlay (always visible during scanfPending) ────────────
        if (isScanfPending)
          _StepScanfOverlay(
            isDark: widget.isDark,
            scanfInput: currentScanfInput,
            onSubmit: (value) {
              ref.read(stepNotifierProvider.notifier).submitScanfInput(value);
            },
          ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.xsAll,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? cs.primary.withAlpha(20) : Colors.transparent,
          borderRadius: AppRadius.xsAll,
          border: Border.all(
            color: isActive ? cs.primary.withAlpha(40) : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isActive ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 10,
                color: isActive ? cs.primary : cs.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step-mode Scanf Input Overlay ──────────────────────────────────────────

class _StepScanfOverlay extends StatefulWidget {
  const _StepScanfOverlay({
    required this.isDark,
    required this.onSubmit,
    this.scanfInput,
  });
  final bool isDark;
  final ScanfInput? scanfInput;
  final void Function(String value) onSubmit;

  @override
  State<_StepScanfOverlay> createState() => _StepScanfOverlayState();
}

class _StepScanfOverlayState extends State<_StepScanfOverlay>
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
  void didUpdateWidget(_StepScanfOverlay oldWidget) {
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
                Expanded(
                  child: Text(
                    prompt,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 10,
                      color: const Color(0xFFFF9800),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
