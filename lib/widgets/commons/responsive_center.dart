import 'package:flutter/material.dart';

/// Wraps content with a max-width constraint and centers it.
/// On narrow screens (< maxWidth), this has no visual effect.
/// On wide screens, content is centered with constrained width.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    this.maxWidth = 600,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    required this.child,
  });

  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
