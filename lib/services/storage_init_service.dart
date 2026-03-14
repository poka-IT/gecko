import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:gecko/services/certification_queue_service.dart';

/// Service for handling Hive initialization and storage setup
class StorageInitService {
  static final StorageInitService _instance = StorageInitService._internal();
  factory StorageInitService() => _instance;
  StorageInitService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Returns the base app directory (~/.gecko on desktop, documents dir on mobile)
  Future<Directory> _appBaseDirectory() async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final home = Platform.isWindows ? Platform.environment['UserProfile'] : Platform.environment['HOME'];
      if (home == null) {
        throw StateError('Home directory environment variable is not set');
      }
      return Directory('$home/.gecko');
    }
    return pp.getApplicationDocumentsDirectory();
  }

  /// Initialize Hive database and setup required boxes
  Future<void> initHive() async {
    if (_isInitialized) {
      log.d('Hive already initialized');
      return;
    }

    // Setup Hive path based on platform
    if (!kIsWeb) {
      final baseDir = await _appBaseDirectory();
      final hivePath = Directory('${baseDir.path}/db');
      if (!await hivePath.exists()) {
        await hivePath.create(recursive: true);
      }
      await Hive.initFlutter(hivePath.path);
    } else {
      await Hive.initFlutter();
    }

    // Setup app directories
    await _setupAppDirectories();

    // Register Hive adapters
    _registerHiveAdapters();

    // Open required boxes
    await _openRequiredBoxes();

    // Handle version compatibility
    await _handleVersionCompatibility();

    _isInitialized = true;
    log.d('Hive initialization completed');
  }

  /// Setup application directories
  Future<void> _setupAppDirectories() async {
    final baseDir = await _appBaseDirectory();
    avatarsDirectory = Directory('${baseDir.path}/avatars');
    avatarsCacheDirectory = Directory('${baseDir.path}/avatarsCache');

    if (!await avatarsDirectory.exists()) {
      await avatarsDirectory.create();
    }
    if (!await avatarsCacheDirectory.exists()) {
      await avatarsCacheDirectory.create();
    }
  }

  /// Register all required Hive adapters
  void _registerHiveAdapters() {
    if (!Hive.isAdapterRegistered(WalletHeaderDataAdapter().typeId)) {
      Hive.registerAdapter(WalletHeaderDataAdapter());
    }
    if (!Hive.isAdapterRegistered(BigIntAdapter().typeId)) {
      Hive.registerAdapter(BigIntAdapter());
    }
    if (!Hive.isAdapterRegistered(G1WalletsListAdapter().typeId)) {
      Hive.registerAdapter(G1WalletsListAdapter());
    }
    if (!Hive.isAdapterRegistered(IdAdapter().typeId)) {
      Hive.registerAdapter(IdAdapter());
    }
  }

  /// Open required Hive boxes
  Future<void> _openRequiredBoxes() async {
    // Open config box first
    configBox = await Hive.openBox("configBox");

    // Initialize certification queue service
    await CertificationQueueService.init();
  }

  /// Handle version compatibility and migrations
  Future<void> _handleVersionCompatibility() async {
    // Check if walletHeaderDataVersion non compatible, drop wallet_header_cache
    if (configBox.get('walletHeaderDataVersion') == null ||
        configBox.get('walletHeaderDataVersion') < walletHeaderDataVersion) {
      await Hive.deleteBoxFromDisk('wallet_header_cache');
      configBox.put('walletHeaderDataVersion', walletHeaderDataVersion);
      log.d('Updated walletHeaderDataVersion to $walletHeaderDataVersion');
    }
  }

  /// Get storage status information
  Map<String, dynamic> getStorageInfo() {
    return {
      'isInitialized': _isInitialized,
      'configBoxIsOpen': configBox.isOpen,
      'dataVersion': configBox.get('dataVersion'),
      'walletHeaderDataVersion': configBox.get('walletHeaderDataVersion'),
    };
  }
}
