import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';

/// Utility functions for identity status checks using Riverpod providers
class IdentityUtils {
  /// Returns true if the identity status is [IdtyStatus.created]
  static bool isCreatedStatus(d.IdtyStatus? status) {
    return status == d.IdtyStatus.created;
  }

  /// Returns true if the squid indexer status string corresponds to IdtyStatus.created.
  /// In the squid indexer, "Unconfirmed" = identity created but not confirmed by owner.
  static bool isCreatedStatusString(String? status) {
    return status == 'Unconfirmed';
  }

  /// Returns the translated "Infinite Name" placeholder if status is created,
  /// otherwise returns the original name.
  static String? getDisplayName(String? name, d.IdtyStatus? status) {
    if (isCreatedStatus(status)) return 'undefinedName'.tr();
    return name;
  }

  /// Returns the translated "Infinite Name" placeholder if the squid indexer
  /// status string corresponds to created, otherwise returns the original name.
  static String getDisplayNameFromString(String name, String? status) {
    if (isCreatedStatusString(status)) return 'undefinedName'.tr();
    return name;
  }

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
