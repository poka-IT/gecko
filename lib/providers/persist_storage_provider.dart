import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:path/path.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';

/// Global provider for the shared persist storage.
///
/// Uses SQLite on Android/iOS/macOS. Falls back to in-memory storage
/// on unsupported platforms (Linux, Web) — persistence across restarts
/// is disabled but the app works normally without errors.
final persistStorageProvider = FutureProvider<Storage<String, String>>((ref) async {
  try {
    return await JsonSqFliteStorage.open(join(await getDatabasesPath(), 'gecko_riverpod_cache.db'));
  } catch (e) {
    log.w('SQLite not available, using in-memory storage (no persistence): $e');
    // ignore: invalid_use_of_visible_for_testing_member
    return Storage.inMemory();
  }
});
