import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost }

/// A premium, delightful button component that automatically scales down when pressed
/// using `AnimatedScale`, requiring no AnimationController.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final bool isFullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() => _isPressed = false);
      widget.onTap();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = _isPressed ? 0.95 : 1.0;

    // Define colors based on variant and state
    Color bgColor;
    Color fgColor;
    Color borderColor;
    List<BoxShadow>? shadows;

    final disabledOpacity = isDark ? 0.3 : 0.4;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bgColor = AppColors.primary;
        fgColor = Colors.white;
        borderColor = Colors.transparent;
        if (!widget.isDisabled && !widget.isLoading) {
          shadows = [
            BoxShadow(
              color: AppColors.primary.withAlpha(_isHovered ? 120 : 60),
              blurRadius: _isHovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ];
        }
        break;
      case AppButtonVariant.secondary:
        bgColor = isDark
            ? Colors.white.withAlpha(15)
            : Colors.black.withAlpha(10);
        fgColor = isDark ? Colors.white : Colors.black87;
        borderColor = isDark
            ? Colors.white.withAlpha(30)
            : Colors.black.withAlpha(20);
        break;
      case AppButtonVariant.ghost:
        bgColor = _isHovered
            ? (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5))
            : Colors.transparent;
        fgColor = isDark ? Colors.white70 : Colors.black87;
        borderColor = Colors.transparent;
        break;
    }

    if (widget.isDisabled) {
      bgColor = bgColor.withOpacity(disabledOpacity);
      fgColor = fgColor.withOpacity(disabledOpacity);
      borderColor = borderColor.withOpacity(disabledOpacity);
      shadows = null;
    }

    final content = AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: shadows,
      ),
      child: Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
            )
          else ...[
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 18, color: fgColor),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
          ],
        ],
      ),
    );

    return MouseRegion(
      cursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: content,
        ),
      ),
    );
  }
}
