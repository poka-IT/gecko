import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';

/// Reusable card container used by every settings section.
///
/// Provides consistent decoration: surfaceContainer background,
/// rounded corners, and a subtle shadow.
class SettingsCard extends StatelessWidget {
  final Widget child;

  /// Optional border (used by the danger-zone card).
  final Border? border;

  const SettingsCard({super.key, required this.child, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        border: border,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
