import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gecko/models/network_config.dart';
import 'package:gecko/globals.dart';

class NetworkConfigService {
  static NetworkConfig? _cachedConfig;
  static DateTime? _lastFetchTime;
  static const Duration _cacheValidity = Duration(minutes: 5);
  static const String _configUrl = 'https://git.duniter.org/nodes/networks/-/raw/master/gdev.json';

  static Future<NetworkConfig> getNetworkConfig() async {
    // Retourner le cache s'il est valide
    if (_cachedConfig != null && _lastFetchTime != null) {
      final age = DateTime.now().difference(_lastFetchTime!);
      if (age < _cacheValidity) {
        return _cachedConfig!;
      }
    }

    try {
      final response = await http.get(Uri.parse(_configUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw 'Status code: ${response.statusCode}';
      }

      _cachedConfig = NetworkConfig.fromJson(jsonDecode(response.body));
      _lastFetchTime = DateTime.now();
      return _cachedConfig!;
    } catch (e) {
      log.e('Erreur fetch network config: $e');
      rethrow;
    }
  }
}
