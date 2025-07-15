import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';

/// Utility functions for identity status checks using Riverpod providers
class IdentityUtils {
  /// Check if an address has a validated identity (is member)
  static bool isMember(WidgetRef ref, String address) {
    final statusAsync = ref.read(smartIdtyStatusStreamProvider(address));
    if (!statusAsync.hasValue) return false;
    return statusAsync.value! == d.IdtyStatus.validated;
  }

  /// Check if an address has any identity (not none or unknown)
  static bool hasIdentity(WidgetRef ref, String address) {
    final statusAsync = ref.read(smartIdtyStatusStreamProvider(address));
    if (!statusAsync.hasValue) return false;
    final status = statusAsync.value!;
    return status != d.IdtyStatus.none && status != d.IdtyStatus.unknown;
  }

  /// Get the identity status for an address
  static d.IdtyStatus? getIdentityStatus(WidgetRef ref, String address) {
    final statusAsync = ref.read(smartIdtyStatusStreamProvider(address));
    if (!statusAsync.hasValue) return null;
    return statusAsync.value!;
  }

  /// Check if an address has a validated identity (is member) - async version
  static Future<bool> isMemberAsync(ProviderContainer container, String address) async {
    try {
      final status = await container.read(storageServiceProvider).getIdtyStatus(address);
      return status == d.IdtyStatus.validated;
    } catch (e) {
      return false;
    }
  }

  /// Check if an address has any identity (not none or unknown) - async version
  static Future<bool> hasIdentityAsync(ProviderContainer container, String address) async {
    try {
      final status = await container.read(storageServiceProvider).getIdtyStatus(address);
      return status != d.IdtyStatus.none && status != d.IdtyStatus.unknown;
    } catch (e) {
      return false;
    }
  }

  /// Get the identity status for an address - async version
  static Future<d.IdtyStatus?> getIdentityStatusAsync(ProviderContainer container, String address) async {
    try {
      return await container.read(storageServiceProvider).getIdtyStatus(address);
    } catch (e) {
      return null;
    }
  }
}
