import 'package:package_info_plus/package_info_plus.dart';

/// Service for handling app information and metadata
class AppInfoService {
  static final AppInfoService _instance = AppInfoService._internal();
  factory AppInfoService() => _instance;
  AppInfoService._internal();

  PackageInfo? _packageInfo;

  /// Initialize the service by loading package info
  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Get app version in format "version+buildNumber"
  String get appVersion {
    if (_packageInfo == null) {
      throw StateError('AppInfoService not initialized. Call init() first.');
    }
    return '${_packageInfo!.version}+${_packageInfo!.buildNumber}';
  }

  /// Get app version without build number
  String get appVersionShort {
    if (_packageInfo == null) {
      throw StateError('AppInfoService not initialized. Call init() first.');
    }
    return _packageInfo!.version;
  }

  /// Get build number
  String get buildNumber {
    if (_packageInfo == null) {
      throw StateError('AppInfoService not initialized. Call init() first.');
    }
    return _packageInfo!.buildNumber;
  }

  /// Get app name
  String get appName {
    if (_packageInfo == null) {
      throw StateError('AppInfoService not initialized. Call init() first.');
    }
    return _packageInfo!.appName;
  }

  /// Get package name
  String get packageName {
    if (_packageInfo == null) {
      throw StateError('AppInfoService not initialized. Call init() first.');
    }
    return _packageInfo!.packageName;
  }
}
