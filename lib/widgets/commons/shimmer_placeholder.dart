import 'package:flutter/material.dart';

/// A subtle shimmer placeholder widget for loading states.
/// Uses animated dots for a minimal, non-intrusive loading effect.
class ShimmerPlaceholder extends StatefulWidget {
  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
    this.baseColor,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.baseColor ?? Theme.of(context).colorScheme.onSurface;
    final dotSize = widget.height * 0.35;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Stagger the animation for each dot
              final delay = index * 0.2;
              final progress = (_controller.value + delay) % 1.0;
              // Smooth pulse: fade in then fade out
              final opacity = (progress < 0.5)
                  ? (progress * 2) // 0 -> 1
                  : (1 - (progress - 0.5) * 2); // 1 -> 0

              return Container(
                margin: EdgeInsets.only(right: index < 2 ? dotSize * 0.5 : 0),
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2 + opacity * 0.5),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// A wrapper that shows shimmer while loading, then fades to content.
/// Provides a smooth transition from loading to data state.
class ShimmerToContent extends StatelessWidget {
  const ShimmerToContent({
    super.key,
    required this.isLoading,
    required this.child,
    required this.shimmerWidth,
    required this.shimmerHeight,
    this.shimmerBorderRadius = 4,
    this.shimmerColor,
    this.duration = const Duration(milliseconds: 300),
  });

  final bool isLoading;
  final Widget child;
  final double shimmerWidth;
  final double shimmerHeight;
  final double shimmerBorderRadius;
  final Color? shimmerColor;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isLoading
          ? ShimmerPlaceholder(
              key: const ValueKey('shimmer'),
              width: shimmerWidth,
              height: shimmerHeight,
              borderRadius: shimmerBorderRadius,
              baseColor: shimmerColor,
            )
          : KeyedSubtree(key: const ValueKey('content'), child: child),
    );
  }
}
