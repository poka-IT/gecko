import 'dart:convert';
import 'package:durt2/durt2.dart' show Networks;
import 'package:gecko/globals.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

/// Service for fetching and caching the G1 genesis hash from a remote endpoint.
/// Called before Durt.init() to dynamically configure the G1 network.
class G1GenesisService {
  static const String _remoteUrl = 'https://get-g1-genesis-hash.p2p.legal';
  static const String _cacheKey = 'g1GenesisHash';
  static final RegExp _hashPattern = RegExp(r'^0x[0-9a-fA-F]{64}$');

  /// Called at startup BEFORE Durt.init().
  /// Returns true if the g1 network should be used.
  static Future<bool> initializeAtStartup(Box configBox) async {
    // 1. Check local cache
    final cachedHash = configBox.get(_cacheKey) as String?;
    if (cachedHash != null && _hashPattern.hasMatch(cachedHash)) {
      Networks.setG1GenesisHash(cachedHash);
      log.i('G1 genesis hash loaded from cache');
      return true;
    }

    // 2. No cache → blocking HTTP call
    try {
      final hash = await _fetchRemoteHash();
      if (hash != null && _hashPattern.hasMatch(hash)) {
        configBox.put(_cacheKey, hash);
        Networks.setG1GenesisHash(hash);
        log.i('G1 genesis hash fetched from remote and cached');
        return true;
      }
      // Empty or invalid hash → g1 not ready yet
      return false;
    } catch (e) {
      log.w('Failed to fetch G1 genesis hash: $e');
      return false;
    }
  }

  /// Background check (non-blocking).
  /// Returns true if the state has changed (hash updated or reset).
  static Future<bool> backgroundCheck(Box configBox) async {
    try {
      final remoteHash = await _fetchRemoteHash();
      if (remoteHash == null) return false; // network error, keep cache as-is

      final cachedHash = configBox.get(_cacheKey) as String?;

      // Remote returned a valid hash different from cache → update
      if (_hashPattern.hasMatch(remoteHash) && remoteHash != cachedHash) {
        configBox.put(_cacheKey, remoteHash);
        Networks.setG1GenesisHash(remoteHash);
        log.i('G1 genesis hash updated: $cachedHash → $remoteHash');
        return true;
      }

      // Remote returned empty/invalid hash but we have a cache → reset
      if (!_hashPattern.hasMatch(remoteHash) && cachedHash != null) {
        configBox.delete(_cacheKey);
        Networks.resetG1GenesisHash();
        log.i('G1 genesis hash reset: remote returned empty, cache cleared');
        return true;
      }

      return false;
    } catch (e) {
      log.w('Background G1 genesis check failed: $e');
      return false;
    }
  }

  /// Returns the hash string from the remote endpoint.
  /// Returns empty string if the server returned an empty/missing hash.
  /// Returns null only on network errors (timeout, HTTP error, parse error).
  static Future<String?> _fetchRemoteHash() async {
    final response = await http.get(Uri.parse(_remoteUrl)).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['hash'] as String?) ?? '';
    }
    return null;
  }
}
