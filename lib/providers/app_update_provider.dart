import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/services/app_update_service.dart';

/// Provider for AppUpdateService (singleton)
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

/// Provider that checks for app updates
///
/// Returns [UpdateCheckResult] if an update is available and not dismissed,
/// null otherwise. Rate-limited to once per session.
final appUpdateCheckProvider = FutureProvider<UpdateCheckResult?>((ref) async {
  final updateService = ref.watch(appUpdateServiceProvider);

  // Rate-limit: only check once per session
  if (!updateService.shouldCheck()) return null;

  // Get current app info
  final appInfoService = ref.watch(appInfoServiceProvider);
  await appInfoService.init();
  final currentBuildNumber = int.tryParse(appInfoService.buildNumber) ?? 0;
  final currentVersion = appInfoService.appVersionShort;

  // Check for update
  final result = await updateService.checkForUpdate(currentBuildNumber, currentVersion);
  if (result == null) return null;

  // Skip if user dismissed this version
  if (updateService.isDismissed(result)) return null;

  return result;
});
