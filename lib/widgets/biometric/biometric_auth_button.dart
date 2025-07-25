import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/extensions.dart';
import 'package:easy_localization/easy_localization.dart';

/// A button widget for biometric authentication
class BiometricAuthButton extends ConsumerWidget {
  const BiometricAuthButton({
    super.key,
    required this.onAuthSuccess,
    this.onAuthFailure,
    this.size = 60.0,
    this.iconColor,
    this.backgroundColor,
    this.tooltip = 'Use biometric authentication',
  });

  final Function(String pin) onAuthSuccess;
  final Function(String error)? onAuthFailure;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final String tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricState = ref.watch(biometricProvider);
    final biometricNotifier = ref.read(biometricProvider.notifier);

    // Don't show button if biometric is not available or not enrolled
    if (!biometricState.canAuthenticate) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: scaleSize(size),
        height: scaleSize(size),
        decoration: BoxDecoration(
          color: backgroundColor ?? context.colorScheme.surface.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.3), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: biometricState.isLoading ? null : () => _handleBiometricAuth(context, biometricNotifier),
            borderRadius: BorderRadius.circular(size / 2),
            child: Center(
              child: biometricState.isLoading
                  ? SizedBox(
                      width: scaleSize(size * 0.4),
                      height: scaleSize(size * 0.4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor ?? context.colorScheme.primary),
                      ),
                    )
                  : Icon(
                      _getBiometricIcon(biometricState.availableTypes),
                      size: scaleSize(size * 0.5),
                      color: iconColor ?? context.colorScheme.primary,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle biometric authentication
  Future<void> _handleBiometricAuth(BuildContext context, BiometricNotifier notifier) async {
    try {
      final result = await notifier.authenticateWithBiometric();

      if (result.success && result.pin != null) {
        onAuthSuccess(result.pin!);
      } else {
        final errorMessage = result.errorMessage ?? 'biometricAuthFailed'.tr();
        onAuthFailure?.call(errorMessage);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: context.colorScheme.error));
        }
      }
    } catch (e) {
      final errorMessage = 'authenticationError'.tr(args: [e.toString()]);
      onAuthFailure?.call(errorMessage);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: context.colorScheme.error));
      }
    }
  }

  /// Get appropriate icon based on available biometric types
  IconData _getBiometricIcon(List<BiometricType> availableTypes) {
    // Priority: physical types first, then intelligent fallback for strong/weak
    if (availableTypes.contains(BiometricType.face)) {
      return Icons.face;
    } else if (availableTypes.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (availableTypes.contains(BiometricType.iris)) {
      return Icons.visibility;
    } else if (availableTypes.contains(BiometricType.strong)) {
      // Strong biometric is usually fingerprint or face - default to fingerprint as most common
      return Icons.fingerprint;
    } else if (availableTypes.contains(BiometricType.weak)) {
      // Weak biometric might be pattern/PIN-based, but could also be fingerprint
      // Use fingerprint as it's the most recognizable biometric icon
      return Icons.fingerprint;
    } else {
      return Icons.security; // Final fallback
    }
  }
}
