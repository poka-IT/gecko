import 'package:flutter/material.dart';
import 'package:fade_and_translate/fade_and_translate.dart';

/// A safer wrapper around FadeAndTranslate that handles widget lifecycle properly
/// to prevent null check operator errors on animation controllers.
class SafeFadeAndTranslate extends StatefulWidget {
  const SafeFadeAndTranslate({
    super.key,
    required this.child,
    required this.visible,
    this.translate = const Offset(0, -20),
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.onCompleted,
  });

  final Widget child;
  final bool visible;
  final Offset translate;
  final Duration delay;
  final Duration duration;
  final VoidCallback? onCompleted;

  @override
  State<SafeFadeAndTranslate> createState() => _SafeFadeAndTranslateState();
}

class _SafeFadeAndTranslateState extends State<SafeFadeAndTranslate> {
  bool _isCompleted = false;

  void _handleCompleted() {
    // Ensure we only call onCompleted once and only if the widget is still mounted
    if (!_isCompleted && mounted && widget.onCompleted != null) {
      _isCompleted = true;
      widget.onCompleted!();
    }
  }

  @override
  void didUpdateWidget(SafeFadeAndTranslate oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset completion state if visibility changes
    if (oldWidget.visible != widget.visible) {
      _isCompleted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the widget is not mounted, return an empty container
    if (!mounted) {
      return const SizedBox.shrink();
    }

    return FadeAndTranslate(
      visible: widget.visible,
      translate: widget.translate,
      delay: widget.delay,
      duration: widget.duration,
      onCompleted: _handleCompleted,
      child: widget.child,
    );
  }
}
