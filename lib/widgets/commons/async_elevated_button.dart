import 'package:flutter/material.dart';

/// An ElevatedButton that disables itself while its async callback is running,
/// preventing multi-click issues on slow devices.
class AsyncElevatedButton extends StatefulWidget {
  const AsyncElevatedButton({super.key, required this.onPressed, required this.child, this.style});

  final Future<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;

  @override
  State<AsyncElevatedButton> createState() => _AsyncElevatedButtonState();
}

class _AsyncElevatedButtonState extends State<AsyncElevatedButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: widget.style,
      onPressed: (widget.onPressed == null || _isProcessing)
          ? null
          : () async {
              if (_isProcessing) return;
              setState(() => _isProcessing = true);
              try {
                await widget.onPressed!();
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
      child: widget.child,
    );
  }
}
