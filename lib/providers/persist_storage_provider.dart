import 'dart:io';
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:path/path.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';

/// Global provider for the shared persist storage.
///
/// Uses SQLite on Android/iOS/macOS. Falls back to in-memory storage
/// on unsupported platforms (Linux, Web) - persistence across restarts
/// is disabled but the app works normally without errors.
final persistStorageProvider = FutureProvider<Storage<String, String>>((ref) async {
  try {
    final dbPath = join(await getDatabasesPath(), 'gecko_riverpod_cache.db');

    // Nuke the SQLite cache when persistCacheVersion changes (or is absent).
    // This covers upgrades from versions that predate the variable.
    final storedVersion = configBox.get('persistCacheVersion') as String?;
    if (storedVersion != persistCacheVersion) {
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
        log.i('Persist cache DB deleted (version: $storedVersion → $persistCacheVersion)');
      }
      await configBox.put('persistCacheVersion', persistCacheVersion);
    }

    return await JsonSqFliteStorage.open(dbPath);
  } catch (e) {
    log.w('SQLite not available, using in-memory storage (no persistence): $e');
    // ignore: invalid_use_of_visible_for_testing_member
    return Storage.inMemory();
  }
});
