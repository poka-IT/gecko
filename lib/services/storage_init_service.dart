import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/services/config_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
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
    // Migrations must never prevent the app from starting: a read-only or full
    // filesystem, a permission error, etc. should be logged and skipped rather
    // than crashing `main()` before runApp().
    try {
      await _migrateObjectBox(base);
    } catch (e, st) {
      log.e('ObjectBox migration failed, continuing without it: $e', error: e, stackTrace: st);
    }
    if (Platform.isMacOS) {
      try {
        await _migrateMacosSecureStorage(base);
      } catch (e, st) {
        log.e('macOS secure storage migration failed, continuing: $e', error: e, stackTrace: st);
      }
      try {
        await _migrateRiverpodCache(base);
      } catch (e, st) {
        log.e('Riverpod cache migration failed, continuing: $e', error: e, stackTrace: st);
      }
    }
  }

  /// Migrate the ObjectBox database from its pre-1.2.6 location to
  /// ~/.gecko/objectbox/.
  ///
  /// Before 1.2.6 durt2 stored ObjectBox under
  /// `getApplicationDocumentsDirectory()/objectbox`. The previous migration
  /// hardcoded `%UserProfile%/Documents/objectbox`, which is WRONG on Windows
  /// whenever the Documents folder is redirected (OneDrive →
  /// `%UserProfile%/OneDrive/Documents`) or localized — and on Linux when the
  /// XDG documents dir differs from `$HOME/Documents`. In those cases the
  /// source was never found, the DB started empty and users lost their safes,
  /// wallet names, colors and profile photos after updating.
  ///
  /// We now resolve the authoritative previous path via
  /// [pp.getApplicationDocumentsDirectory] (same API durt2 used), with the
  /// hardcoded `$HOME/Documents` and `$HOME/OneDrive/Documents` kept as
  /// fallbacks, and migrate from the first candidate that actually holds data.
  Future<void> _migrateObjectBox(Directory base) async {
    final newDir = Directory('${base.path}/objectbox');

    // Already migrated (new path holds data) — clean up any stray legacy dirs
    // and stop. An empty newDir is treated as "not migrated yet".
    if (await newDir.exists() && _directoryHasFiles(newDir)) {
      return;
    }

    final candidates = <Directory>[];

    // 1. Authoritative previous default: durt2 used getApplicationDocumentsDirectory().
    //    On Windows this resolves OneDrive/localized Documents; on Linux the XDG
    //    documents dir. It can throw on headless Linux WMs, hence the guard.
    try {
      final docs = await pp.getApplicationDocumentsDirectory();
      candidates.add(Directory('${docs.path}/objectbox'));
    } catch (e) {
      log.w('ObjectBox migration: getApplicationDocumentsDirectory() unavailable: $e');
    }

    // 2. Hardcoded fallbacks (the old behavior + the common OneDrive redirect).
    final home = Platform.isWindows ? Platform.environment['UserProfile'] ?? '' : Platform.environment['HOME'] ?? '';
    if (home.isNotEmpty) {
      candidates.add(Directory('$home/Documents/objectbox'));
      if (Platform.isWindows) {
        candidates.add(Directory('$home/OneDrive/Documents/objectbox'));
      }
    }

    Directory? oldDir;
    for (final candidate in candidates) {
      if (candidate.path == newDir.path) continue; // never copy onto ourselves
      if (await candidate.exists() && _directoryHasFiles(candidate)) {
        oldDir = candidate;
        break;
      }
    }

    if (oldDir == null) {
      // Could be a genuine fresh install, or a legacy DB in an unexpected
      // location. Log it so the rare "lost data after update" case is
      // diagnosable via Sentry breadcrumbs instead of failing silently.
      log.i('ObjectBox migration: no legacy database found in ${candidates.map((c) => c.path).toList()}');
      return;
    }

    log.i('ObjectBox migration: ${oldDir.path} → ${newDir.path}');
    await _copyDirectory(oldDir, newDir);

    // Verify at least one file was transferred before removing the original.
    final newFiles = newDir.listSync(recursive: true).whereType<File>().toList();
    if (newFiles.isNotEmpty) {
      await oldDir.delete(recursive: true);
      log.i('ObjectBox migration complete (${newFiles.length} files)');
    } else {
      log.w('ObjectBox migration: copy produced no files, keeping original');
      if (await newDir.exists()) await newDir.delete(recursive: true);
    }
  }

  /// Returns true if [dir] contains at least one regular file (recursively).
  bool _directoryHasFiles(Directory dir) {
    try {
      return dir.listSync(recursive: true).whereType<File>().isNotEmpty;
    } catch (_) {
      return false;
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

  /// Recursively copy a directory tree.
  ///
  /// Skips ObjectBox/LMDB `lock.mdb` files: the lock embeds a PID and live
  /// transaction state, and ObjectBox recreates it on open. Copying it can
  /// leave the destination DB referencing a stale/foreign lock and fail to
  /// open. Only the actual data (`data.mdb`) must travel.
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list()) {
      // Use the filesystem path basename, not `uri.pathSegments.last`, which is
      // an empty string for directories (their URI ends with a trailing slash).
      final name = p.basename(entity.path);
      if (entity is File) {
        if (name == 'lock.mdb') continue;
        await entity.copy('${destination.path}/$name');
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory('${destination.path}/$name'));
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
