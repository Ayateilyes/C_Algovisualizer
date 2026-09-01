import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';

/// Standardized delightful empty state with a floating icon animation.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(
      begin: -4.0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating animated icon inside a dashed-like or soft circle
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: child,
                );
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(10)
                      : Colors.black.withAlpha(5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(15),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 28,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              widget.title,
              style: AppTextStyles.labelLarge.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Message
            Text(
              widget.message,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white38 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),

            if (widget.action != null) ...[
              const SizedBox(height: 20),
              widget.action!,
            ],
          ],
        ),
      ),
    );
  }
}
