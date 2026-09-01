import 'package:flutter/material.dart';
import 'package:c_algovisualizer/config/theme/app_theme.dart';

/// A universal shimmering skeleton loader.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  /// Creates a circular shimmer.
  const AppShimmer.circle({super.key, required double size, this.margin})
    : width = size,
      height = size,
      borderRadius = const BorderRadius.all(Radius.circular(9999));

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? Colors.white.withAlpha(12)
        : Colors.black.withAlpha(8);
    final highlightColor = isDark
        ? Colors.white.withAlpha(30)
        : Colors.black.withAlpha(20);

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? AppRadius.mdAll,
              gradient: LinearGradient(
                colors: [baseColor, highlightColor, baseColor],
                stops: const [0.0, 0.5, 1.0],
                begin: const Alignment(-2.0, -0.2),
                end: const Alignment(2.0, 0.2),
                transform: _SlidingGradientTransform(slidePercent: _ctrl.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0.0,
      0.0,
    );
  }
}
