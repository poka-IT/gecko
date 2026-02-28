import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:gecko/globals.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Source d'installation de l'application
enum InstallSource { playStore, appStore, sideloaded, desktop }

/// Type d'action pour la mise à jour
enum UpdateActionType {
  showDialogWithUrl, // Dialog custom + URL externe (App Store, sideloaded, desktop)
  playStoreFlexible, // Download en arrière-plan via Play Store natif
  playStoreImmediate, // Update bloquant plein écran (futur, pour patchs critiques)
}

/// Résultat d'une vérification de mise à jour
class UpdateCheckResult {
  final String latestVersion;
  final int latestBuildNumber;
  final String? updateUrl;
  final InstallSource installSource;
  final UpdateActionType actionType;

  const UpdateCheckResult({
    required this.latestVersion,
    required this.latestBuildNumber,
    this.updateUrl,
    required this.installSource,
    required this.actionType,
  });
}

/// Service for checking app updates from multiple sources depending on install origin
class AppUpdateService {
  static const _gitlabApiUrl = 'https://git.duniter.org/api/v4/projects/clients%2Fgecko/releases?per_page=1';
  static const _appStoreUrl = 'https://apps.apple.com/app/id6739944308';
  static const _itunesLookupUrl = 'https://itunes.apple.com/lookup?bundleId=fr.axiom-team.gecko';

  bool _checkedThisSession = false;

  /// Detect the installation source of the app
  Future<InstallSource> detectInstallSource() async {
    if (kIsWeb) return InstallSource.desktop;

    if (Platform.isAndroid) {
      final info = await PackageInfo.fromPlatform();
      final installer = info.installerStore;
      if (installer == 'com.android.vending' || installer == 'com.google.android.packageinstaller') {
        return InstallSource.playStore;
      }
      return InstallSource.sideloaded;
    }

    if (Platform.isIOS) return InstallSource.appStore;

    return InstallSource.desktop;
  }

  /// Check if we should perform an update check (once per session)
  bool shouldCheck() {
    if (_checkedThisSession) return false;
    _checkedThisSession = true;
    return true;
  }

  /// Check if user dismissed this specific update result
  bool isDismissed(UpdateCheckResult result) {
    // Play Store updates are managed natively, never dismissed by us
    if (result.installSource == InstallSource.playStore) return false;

    // App Store: dismiss by version string
    if (result.installSource == InstallSource.appStore) {
      final dismissed = configBox.get('updateDismissedVersion');
      return dismissed != null && dismissed == result.latestVersion;
    }

    // Sideloaded / Desktop: dismiss by build number (existing behavior)
    final dismissed = configBox.get('updateDismissedBuildNumber');
    return dismissed != null && dismissed == result.latestBuildNumber;
  }

  /// Dismiss an update so the user won't be prompted again
  void dismissUpdate(UpdateCheckResult result) {
    if (result.installSource == InstallSource.appStore) {
      configBox.put('updateDismissedVersion', result.latestVersion);
    } else {
      configBox.put('updateDismissedBuildNumber', result.latestBuildNumber);
    }
  }

  /// Check for available updates by dispatching to the appropriate source
  ///
  /// Returns [UpdateCheckResult] if an update is available, null otherwise.
  /// Gracefully returns null on any error.
  Future<UpdateCheckResult?> checkForUpdate(int currentBuildNumber, String currentVersion) async {
    try {
      final source = await detectInstallSource();
      return switch (source) {
        InstallSource.playStore => _checkPlayStore(),
        InstallSource.appStore => _checkAppStore(currentVersion),
        InstallSource.sideloaded => _checkGitLab(currentBuildNumber),
        InstallSource.desktop => _checkGitLab(currentBuildNumber),
      };
    } catch (e) {
      log.d('Update check failed: $e');
      return null;
    }
  }

  /// Check for Play Store update using Android In-App Update API
  Future<UpdateCheckResult?> _checkPlayStore() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return null;

      return UpdateCheckResult(
        latestVersion: '', // Not available from Play Store API
        latestBuildNumber: info.availableVersionCode ?? 0,
        installSource: InstallSource.playStore,
        actionType: UpdateActionType.playStoreFlexible,
      );
    } catch (e) {
      log.d('Play Store update check failed: $e');
      return null;
    }
  }

  /// Check for App Store update using iTunes Lookup API
  Future<UpdateCheckResult?> _checkAppStore(String currentVersion) async {
    try {
      final response = await http
          .get(Uri.parse(_itunesLookupUrl), headers: {'User-Agent': 'Gecko-Wallet'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final storeVersion = results[0]['version'] as String?;
      if (storeVersion == null) return null;

      if (!_isNewerVersion(storeVersion, currentVersion)) return null;

      return UpdateCheckResult(
        latestVersion: storeVersion,
        latestBuildNumber: 0,
        updateUrl: _appStoreUrl,
        installSource: InstallSource.appStore,
        actionType: UpdateActionType.showDialogWithUrl,
      );
    } catch (e) {
      log.d('App Store update check failed: $e');
      return null;
    }
  }

  /// Check for update via GitLab Releases API (sideloaded APK / desktop)
  Future<UpdateCheckResult?> _checkGitLab(int currentBuildNumber) async {
    final response = await http
        .get(Uri.parse(_gitlabApiUrl), headers: {'User-Agent': 'Gecko-Wallet'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;

    final List<dynamic> releases = json.decode(response.body);
    if (releases.isEmpty) return null;

    final latestRelease = releases[0] as Map<String, dynamic>;
    final tagName = latestRelease['tag_name'] as String?;
    if (tagName == null) return null;

    final parsed = _parseTag(tagName);
    if (parsed == null) return null;

    final (version, remoteBuildNumber) = parsed;

    if (remoteBuildNumber <= currentBuildNumber) return null;

    final source = await detectInstallSource();
    final url = await _getUpdateUrl(source, latestRelease);

    return UpdateCheckResult(
      latestVersion: version,
      latestBuildNumber: remoteBuildNumber,
      updateUrl: url,
      installSource: source,
      actionType: UpdateActionType.showDialogWithUrl,
    );
  }

  /// Compare two semantic versions. Returns true if [remote] is newer than [current].
  bool _isNewerVersion(String remote, String current) {
    final remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad to same length
    while (remoteParts.length < 3) {
      remoteParts.add(0);
    }
    while (currentParts.length < 3) {
      currentParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (remoteParts[i] > currentParts[i]) return true;
      if (remoteParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  /// Parse a git tag into (version, buildNumber)
  (String, int)? _parseTag(String tag) {
    // Remove leading 'v' if present
    final clean = tag.startsWith('v') ? tag.substring(1) : tag;
    final parts = clean.split('+');
    if (parts.length != 2) return null;

    final buildNumber = int.tryParse(parts[1]);
    if (buildNumber == null) return null;

    return (parts[0], buildNumber);
  }

  /// Get the appropriate update URL for sideloaded/desktop sources
  Future<String> _getUpdateUrl(InstallSource source, Map<String, dynamic> release) async {
    switch (source) {
      case InstallSource.sideloaded:
        return await _getSideloadedUrl(release);
      case InstallSource.desktop:
        return _getReleasePageUrl(release);
      default:
        return _getReleasePageUrl(release);
    }
  }

  /// Find the right APK URL for the current device architecture
  Future<String> _getSideloadedUrl(Map<String, dynamic> release) async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final abis = androidInfo.supportedAbis;

      final assets = release['assets'] as Map<String, dynamic>?;
      final links = assets?['links'] as List<dynamic>?;

      if (links != null && links.isNotEmpty) {
        // Try to find architecture-specific APK
        for (final abi in abis) {
          final archSuffix = _abiToSuffix(abi);
          if (archSuffix == null) continue;

          for (final link in links) {
            final url = link['direct_asset_url'] as String? ?? link['url'] as String? ?? '';
            final urlLower = url.toLowerCase();
            if (urlLower.contains('.apk') && urlLower.contains(archSuffix)) {
              return url;
            }
          }
        }

        // Fallback: try to find any APK
        for (final link in links) {
          final url = link['direct_asset_url'] as String? ?? link['url'] as String? ?? '';
          if (url.toLowerCase().contains('.apk')) {
            return url;
          }
        }
      }
    } catch (e) {
      log.d('Failed to get sideloaded URL: $e');
    }

    // Ultimate fallback: release page
    return _getReleasePageUrl(release);
  }

  /// Map Android ABI to filename suffixes used in GitLab release assets
  String? _abiToSuffix(String abi) {
    return switch (abi) {
      'arm64-v8a' => 'v8a',
      'armeabi-v7a' => 'v7a',
      'x86_64' => 'x86_64',
      'x86' => 'x86',
      _ => null,
    };
  }

  /// Get the GitLab release page URL
  String _getReleasePageUrl(Map<String, dynamic> release) {
    final links = release['_links'] as Map<String, dynamic>?;
    return links?['self'] as String? ?? 'https://git.duniter.org/clients/gecko/-/releases';
  }
}
