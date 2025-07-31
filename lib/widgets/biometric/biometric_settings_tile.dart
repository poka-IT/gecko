import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/biometric_provider.dart';

import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/extensions.dart';
import 'package:easy_localization/easy_localization.dart';

/// Settings tile for biometric authentication management
class BiometricSettingsTile extends ConsumerWidget {
  const BiometricSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricState = ref.watch(biometricProvider);
    final biometricNotifier = ref.read(biometricProvider.notifier);

    // Don't show if device doesn't support biometric
    if (!biometricState.isDeviceSupported || !biometricState.isAvailable) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: biometricState.isLoading ? null : () => _handleTap(context, biometricState, biometricNotifier),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
        child: Row(
          children: [
            Icon(
              _getBiometricIcon(biometricState.availableTypes),
              size: scaleSize(24),
              color: biometricState.isEnrolledForCurrentSafe
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurface,
            ),
            SizedBox(width: scaleSize(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'biometricAuth'.tr(),
                    style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                    softWrap: true,
                  ),
                  SizedBox(height: scaleSize(2)),
                  Text(
                    biometricState.isEnrolledForCurrentSafe
                        ? 'biometricEnabledForSafe'.tr()
                        : 'useBiometricToUnlock'.tr(args: [_getBiometricTypeName(biometricState.availableTypes)]),
                    style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            if (biometricState.isLoading)
              SizedBox(width: scaleSize(20), height: scaleSize(20), child: CircularProgressIndicator(strokeWidth: 2))
            else
              Switch(
                value: biometricState.isEnrolledForCurrentSafe,
                onChanged: (value) => _handleToggle(context, value, biometricNotifier),
              ),
          ],
        ),
      ),
    );
  }

  /// Handle tap on the biometric settings tile
  Future<void> _handleTap(BuildContext context, BiometricState biometricState, BiometricNotifier notifier) async {
    // Toggle the current state when tapping on the tile
    await _handleToggle(context, !biometricState.isEnrolledForCurrentSafe, notifier);
  }

  /// Handle toggle switch change
  Future<void> _handleToggle(BuildContext context, bool enableBiometric, BiometricNotifier notifier) async {
    if (enableBiometric) {
      // Enable biometric - need PIN first
      if (!await PinCodeService.askPinCode(force: true)) return;

      if (context.mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _BiometricSetupBottomSheet(
            pin: PinCodeService.pinCode,
            onSetupComplete: () {
              // Refresh state after setup
              notifier.refresh();
            },
          ),
        );
      }
    } else {
      // Disable biometric - show confirmation
      final confirmed = await showConfirmationDialog(
        context: context,
        title: 'disableBiometricAuth'.tr(),
        message: 'disableBiometricConfirm'.tr(),
        confirmText: 'disable'.tr(),
        cancelText: 'cancel'.tr(),
      );

      if (confirmed == true) {
        final success = await notifier.disableBiometric();

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: scaleSize(8)),
                    Text('biometricDisabled'.tr()),
                  ],
                ),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('biometricDisableFailed'.tr()), backgroundColor: context.colorScheme.error),
            );
          }
        }
      }
    }
  }

  /// Get appropriate icon based on available biometric types
  IconData _getBiometricIcon(List<BiometricType> availableTypes) {
    // Filter out non-physical biometric types
    final physicalTypes = availableTypes
        .where((type) => type != BiometricType.weak && type != BiometricType.strong)
        .toList();

    if (physicalTypes.contains(BiometricType.face)) {
      return Icons.face;
    } else if (physicalTypes.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (physicalTypes.contains(BiometricType.iris)) {
      return Icons.visibility;
    } else {
      return Icons.security;
    }
  }

  /// Get biometric type name for display
  String _getBiometricTypeName(List<BiometricType> availableTypes) {
    // Filter out non-physical biometric types
    final physicalTypes = availableTypes
        .where((type) => type != BiometricType.weak && type != BiometricType.strong)
        .toList();

    if (physicalTypes.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (physicalTypes.contains(BiometricType.fingerprint)) {
      return 'Touch ID';
    } else if (physicalTypes.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }
}

/// Bottom sheet for biometric setup
class _BiometricSetupBottomSheet extends ConsumerStatefulWidget {
  const _BiometricSetupBottomSheet({required this.pin, this.onSetupComplete});

  final String pin;
  final VoidCallback? onSetupComplete;

  @override
  ConsumerState<_BiometricSetupBottomSheet> createState() => _BiometricSetupBottomSheetState();
}

class _BiometricSetupBottomSheetState extends ConsumerState<_BiometricSetupBottomSheet> {
  bool _isEnrolling = false;

  @override
  Widget build(BuildContext context) {
    final biometricState = ref.watch(biometricProvider);
    final biometricNotifier = ref.read(biometricProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: EdgeInsets.all(scaleSize(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title section
          Row(
            children: [
              Icon(
                _getBiometricIcon(biometricState.availableTypes),
                color: context.colorScheme.primary,
                size: scaleSize(24),
              ),
              SizedBox(width: scaleSize(12)),
              Expanded(
                child: Text(
                  'enableBiometricAuth'.tr(),
                  style: TextStyle(fontSize: scaleSize(18), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: scaleSize(16)),

          // Description
          Text(
            'biometricAuthDescription'.tr(),
            style: TextStyle(fontSize: scaleSize(14), color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          SizedBox(height: scaleSize(16)),

          // Security note
          Container(
            padding: EdgeInsets.all(scaleSize(12)),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(scaleSize(8)),
              border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.security, size: scaleSize(16), color: context.colorScheme.primary),
                SizedBox(width: scaleSize(8)),
                Expanded(
                  child: Text(
                    'biometricSecurityNote'.tr(),
                    style: TextStyle(fontSize: scaleSize(11), color: context.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (biometricState.errorMessage != null) ...[
            SizedBox(height: scaleSize(12)),
            Container(
              padding: EdgeInsets.all(scaleSize(12)),
              decoration: BoxDecoration(
                color: context.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(scaleSize(8)),
                border: Border.all(color: context.colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: scaleSize(16), color: context.colorScheme.error),
                  SizedBox(width: scaleSize(8)),
                  Expanded(
                    child: Text(
                      biometricState.errorMessage!,
                      style: TextStyle(fontSize: scaleSize(11), color: context.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: scaleSize(20)),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancel button
              SizedBox(
                height: scaleSize(50),
                width: scaleSize(140),
                child: OutlinedButton(
                  onPressed: _isEnrolling ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colorScheme.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleSize(8))),
                    padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
                  ),
                  child: Text('cancel'.tr(), style: TextStyle(fontSize: scaleSize(15))),
                ),
              ),

              SizedBox(width: scaleSize(16)),

              // Enable button
              SizedBox(
                height: scaleSize(50),
                width: scaleSize(140),
                child: ElevatedButton(
                  onPressed: _isEnrolling || !biometricState.canEnroll
                      ? null
                      : () => _handleEnrollBiometric(biometricNotifier),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleSize(8))),
                    padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
                  ),
                  child: _isEnrolling
                      ? SizedBox(
                          width: scaleSize(16),
                          height: scaleSize(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('enable'.tr(), style: TextStyle(fontSize: scaleSize(15))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handle biometric enrollment
  Future<void> _handleEnrollBiometric(BiometricNotifier notifier) async {
    setState(() {
      _isEnrolling = true;
    });

    try {
      final result = await notifier.enrollBiometric(widget.pin);

      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });

        if (result.success) {
          // Success - call callback and close
          widget.onSetupComplete?.call();
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: scaleSize(8)),
                  Text('biometricEnabled'.tr()),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 3),
            ),
          );
        }
        // If failed, error message will be shown in the UI automatically via state
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });
      }
    }
  }

  /// Get appropriate biometric icon based on available types
  IconData _getBiometricIcon(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return Icons.face;
    } else if (types.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else {
      return Icons.lock;
    }
  }
}
