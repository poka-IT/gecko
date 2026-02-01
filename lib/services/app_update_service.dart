import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:gecko/globals.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Source d'installation de l'application
enum InstallSource { playStore, appStore, sideloaded, desktop }

/// Résultat d'une vérification de mise à jour
class UpdateCheckResult {
  final String latestVersion;
  final int latestBuildNumber;
  final String updateUrl;
  final InstallSource installSource;

  const UpdateCheckResult({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.updateUrl,
    required this.installSource,
  });
}

/// Service for checking app updates from GitLab releases
class AppUpdateService {
  static const _gitlabApiUrl = 'https://git.duniter.org/api/v4/projects/clients%2Fgecko/releases?per_page=1';
  static const _playStoreUrl = 'https://play.google.com/store/apps/details?id=fr.axiomteam.gecko';
  static const _appStoreUrl = 'https://apps.apple.com/app/id6739944308';

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

  /// Check if user dismissed this specific build number
  bool isDismissed(int buildNumber) {
    final dismissed = configBox.get('updateDismissedBuildNumber');
    return dismissed != null && dismissed == buildNumber;
  }

  /// Dismiss a specific build number so the user won't be prompted again
  void dismissVersion(int buildNumber) {
    configBox.put('updateDismissedBuildNumber', buildNumber);
  }

  /// Check for available updates by querying GitLab releases API
  ///
  /// Returns [UpdateCheckResult] if an update is available, null otherwise.
  /// Gracefully returns null on any error.
  Future<UpdateCheckResult?> checkForUpdate(int currentBuildNumber) async {
    try {
      final response = await http
          .get(Uri.parse(_gitlabApiUrl), headers: {'User-Agent': 'Gecko-Wallet'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final List<dynamic> releases = json.decode(response.body);
      if (releases.isEmpty) return null;

      final latestRelease = releases[0] as Map<String, dynamic>;
      final tagName = latestRelease['tag'] as String?;
      if (tagName == null) return null;

      // Parse tag like "v0.5.7+162" or "0.5.7+162"
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
      );
    } catch (e) {
      log.d('Update check failed: $e');
      return null;
    }
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

  /// Get the appropriate update URL based on install source
  Future<String> _getUpdateUrl(InstallSource source, Map<String, dynamic> release) async {
    switch (source) {
      case InstallSource.playStore:
        return _playStoreUrl;
      case InstallSource.appStore:
        return _appStoreUrl;
      case InstallSource.sideloaded:
        return await _getSideloadedUrl(release);
      case InstallSource.desktop:
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
            final url = link['directAssetUrl'] as String? ?? link['url'] as String? ?? '';
            final name = (link['name'] as String? ?? '').toLowerCase();
            if (name.contains('.apk') && name.contains(archSuffix)) {
              return url;
            }
          }
        }

        // Fallback: try to find any APK
        for (final link in links) {
          final url = link['directAssetUrl'] as String? ?? link['url'] as String? ?? '';
          final name = (link['name'] as String? ?? '').toLowerCase();
          if (name.contains('.apk')) {
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

  /// Map Android ABI to common filename suffixes
  String? _abiToSuffix(String abi) {
    return switch (abi) {
      'arm64-v8a' => 'arm64',
      'armeabi-v7a' => 'armeabi',
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
