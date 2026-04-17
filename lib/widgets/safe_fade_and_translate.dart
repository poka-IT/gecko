import 'dart:async';

import 'package:flutter/material.dart';

/// Fade + translate transition that is safe against widget disposal.
///
/// Replaces the `fade_and_translate` package, whose `didUpdateWidget` spawns
/// an uncancellable `Timer(delay, ...)` that can call `AnimationController`
/// methods after dispose, crashing with "Null check operator used on a null
/// value" (Sentry AXIOM-TEAM-NE).
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

class _SafeFadeAndTranslateState extends State<SafeFadeAndTranslate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration, value: widget.visible ? 1.0 : 0.0);
    _controller.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(SafeFadeAndTranslate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.visible != widget.visible) {
      _delayTimer?.cancel();
      if (widget.delay > Duration.zero) {
        _delayTimer = Timer(widget.delay, _runAnimation);
      } else {
        _runAnimation();
      }
    }
  }

  void _runAnimation() {
    if (!mounted) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (!mounted) return;
    if ((status == AnimationStatus.completed && widget.visible) ||
        (status == AnimationStatus.dismissed && !widget.visible)) {
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        if (t == 0.0) return const SizedBox.shrink();
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(widget.translate.dx * (1.0 - t), widget.translate.dy * (1.0 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
