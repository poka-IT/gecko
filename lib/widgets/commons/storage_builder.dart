import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/connection_providers.dart';

/// A generic widget that checks if Durt storage is initialized before building child content.
/// Shows a placeholder when storage is not ready to prevent crashes.
class StorageBuilder extends ConsumerWidget {
  const StorageBuilder({super.key, required this.builder, this.placeholder, this.showShimmer = false});

  /// The widget to build when storage is ready
  final Widget Function(BuildContext context, WidgetRef ref) builder;

  /// Custom placeholder to show when storage is not ready
  final Widget? placeholder;

  /// Whether to show a shimmer effect for the placeholder
  final bool showShimmer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try to build content directly first (data might be cached)
    try {
      return builder(context, ref);
    } catch (e) {
      // If building failed (probably storage not ready), watch storage readiness
      if (e.toString().contains('DuniterStorageService not initialized')) {
        final storageState = ref.watch(storageStateProvider);
        final isReady = storageState != StorageState.notInitialized;

        if (isReady) {
          // Defer the builder call to avoid setState during build
          return Builder(
            builder: (context) {
              // Use addPostFrameCallback to defer actual building
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // This will trigger a rebuild on the next frame
                if (context.mounted) {
                  (context as Element).markNeedsBuild();
                }
              });

              // For now, show placeholder and rebuild on next frame
              try {
                return builder(context, ref);
              } catch (e) {
                return placeholder ?? _buildDefaultPlaceholder(context);
              }
            },
          );
        } else {
          // Storage not ready, show placeholder
          return placeholder ?? _buildDefaultPlaceholder(context);
        }
      } else {
        // Other error, rethrow
        rethrow;
      }
    }
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    if (showShimmer) {
      return _buildShimmerPlaceholder(context);
    }

    return Container(
      height: scaleSize(40),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: scaleSize(16),
          height: scaleSize(16),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(context.colorScheme.primary.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.3, end: 1.0),
      onEnd: () {
        // Restart animation by rebuilding
      },
      builder: (context, value, child) {
        return Container(
          height: scaleSize(40),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainer.withValues(alpha: value * 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

/// Specific builder for balance display that shows a shimmer effect
class BalanceStorageBuilder extends StorageBuilder {
  const BalanceStorageBuilder({super.key, required super.builder}) : super(showShimmer: true);

  @override
  Widget _buildDefaultPlaceholder(BuildContext context) {
    return Container(
      height: scaleSize(24),
      width: scaleSize(80),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
