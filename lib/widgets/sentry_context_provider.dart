import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/services/sentry_service.dart';

/// Widget that automatically provides current context and ref to SentryService
/// This ensures diagnostic data is always available for error reporting
class SentryContextProvider extends ConsumerWidget {
  final Widget child;

  const SentryContextProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Update Sentry service with current context and ref
    // This will be called whenever the widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SentryService.updateContext(context, ref);
    });

    return child;
  }
}
