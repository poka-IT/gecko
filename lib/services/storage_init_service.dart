import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/services/config_service.dart';
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
      // Use Hive.init() directly instead of Hive.initFlutter() to avoid
      // calling getApplicationDocumentsDirectory() which fails on Linux
      // with atypical window managers (dwm, jwm) that lack XDG support.
      Hive.init(hivePath.path);
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
    try {
      configBox = await Hive.openBox("configBox");
      g1WalletsBox = await Hive.openBox('g1WalletsBox');
      contactsBox = await Hive.openBox('contactsBox');
    } on OSError catch (e) {
      // errno 11 (EAGAIN) or 35 (EWOULDBLOCK): another Gecko instance holds the lock
      if (e.errorCode == 11 || e.errorCode == 35) {
        throw StateError(
          'Another instance of Gecko is already running. '
          'Please close it before starting a new one.',
        );
      }
      rethrow;
    }

    // Initialize certification queue service
    await CertificationQueueService.init();
  }

  /// Handle version compatibility and migrations
  Future<void> _handleVersionCompatibility() async {
    final config = ConfigService(configBox);
    // Check if walletHeaderDataVersion non compatible, drop wallet_header_cache
    if (config.walletHeaderDataVersion == null || config.walletHeaderDataVersion! < walletHeaderDataVersion) {
      await Hive.deleteBoxFromDisk('wallet_header_cache');
      config.walletHeaderDataVersion = walletHeaderDataVersion;
      log.d('Updated walletHeaderDataVersion to $walletHeaderDataVersion');
    }
  }

  /// Returns a custom ObjectBox directory on desktop (~/.gecko/objectbox),
  /// or null on mobile (lets durt2 use its default path).
  Future<String?> desktopObjectBoxDirectory() async {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) return null;
    final base = await _appBaseDirectory();
    final dir = Directory('${base.path}/objectbox');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// Returns the macOS secure storage path (~/.gecko/secure_storage.json),
  /// or null on non-macOS platforms.
  Future<String?> macosSecureStoragePath() async {
    if (!Platform.isMacOS) return null;
    final base = await _appBaseDirectory();
    return '${base.path}/secure_storage.json';
  }

  /// Returns the desktop Riverpod SQLite cache path (~/.gecko/cache/riverpod.db),
  /// or null on non-desktop platforms.
  Future<String?> desktopRiverpodCachePath() async {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) return null;
    final base = await _appBaseDirectory();
    final cacheDir = Directory('${base.path}/cache');
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
    return '${cacheDir.path}/riverpod.db';
  }

  /// Run silent data migrations from legacy paths to ~/.gecko/.
  /// Must be called AFTER initHive() and BEFORE Durt.init().
  Future<void> runDesktopMigrations() async {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) return;
    final base = await _appBaseDirectory();
    await _migrateObjectBox(base);
    if (Platform.isMacOS) {
      await _migrateMacosSecureStorage(base);
      await _migrateRiverpodCache(base);
    }
  }

  /// Migrate ObjectBox from ~/Documents/objectbox/ to ~/.gecko/objectbox/
  Future<void> _migrateObjectBox(Directory base) async {
    final home = Platform.isWindows ? Platform.environment['UserProfile'] ?? '' : Platform.environment['HOME'] ?? '';
    final oldDir = Directory('$home/Documents/objectbox');
    final newDir = Directory('${base.path}/objectbox');

    if (!await oldDir.exists()) return;
    if (await newDir.exists()) {
      // New path already has data — old path is a leftover, remove it
      await oldDir.delete(recursive: true);
      log.i('ObjectBox migration: removed leftover old path');
      return;
    }

    log.i('ObjectBox migration: ${oldDir.path} → ${newDir.path}');
    await _copyDirectory(oldDir, newDir);

    // Verify at least one file was transferred
    final newFiles = newDir.listSync(recursive: true).whereType<File>().toList();
    if (newFiles.isNotEmpty) {
      await oldDir.delete(recursive: true);
      log.i('ObjectBox migration complete (${newFiles.length} files)');
    } else {
      log.w('ObjectBox migration: copy produced no files, keeping original');
      await newDir.delete(recursive: true);
    }
  }

  /// Migrate macOS secure storage from ~/.durt2_secure_storage to ~/.gecko/secure_storage.json
  Future<void> _migrateMacosSecureStorage(Directory base) async {
    final home = Platform.environment['HOME'] ?? '';
    final oldFile = File('$home/.durt2_secure_storage');
    final newFile = File('${base.path}/secure_storage.json');

    if (!await oldFile.exists()) return;
    if (await newFile.exists()) {
      await oldFile.delete();
      log.i('Secure storage migration: removed leftover old file');
      return;
    }

    log.i('Secure storage migration: ${oldFile.path} → ${newFile.path}');
    await oldFile.copy(newFile.path);
    await Process.run('chmod', ['600', newFile.path]);
    if (await newFile.exists()) {
      await oldFile.delete();
      log.i('Secure storage migration complete');
    } else {
      log.w('Secure storage migration: copy failed, keeping original');
    }
  }

  /// Migrate Riverpod SQLite cache from ~/Documents/ to ~/.gecko/cache/
  Future<void> _migrateRiverpodCache(Directory base) async {
    final home = Platform.environment['HOME'] ?? '';
    final oldFile = File('$home/Documents/gecko_riverpod_cache.db');
    final newFile = File('${base.path}/cache/riverpod.db');

    if (!await oldFile.exists()) return;
    if (await newFile.exists()) {
      await oldFile.delete();
      return;
    }

    final cacheDir = Directory('${base.path}/cache');
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

    log.i('Riverpod cache migration: ${oldFile.path} → ${newFile.path}');
    await oldFile.copy(newFile.path);
    if (await newFile.exists()) {
      await oldFile.delete();
      log.i('Riverpod cache migration complete');
    }
  }

  /// Recursively copy a directory tree
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list()) {
      final newPath = '${destination.path}/${entity.uri.pathSegments.last}';
      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      }
    }
  }

  /// Get storage status information
  Map<String, dynamic> getStorageInfo() {
    final config = ConfigService(configBox);
    return {
      'isInitialized': _isInitialized,
      'configBoxIsOpen': config.isOpen,
      'dataVersion': config.dataVersion,
      'walletHeaderDataVersion': config.walletHeaderDataVersion,
    };
  }
}
