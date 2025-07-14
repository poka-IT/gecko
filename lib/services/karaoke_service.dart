import 'dart:async';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';

class KaraokeLine {
  final double timestamp;
  final String text;

  KaraokeLine({required this.timestamp, required this.text});
}

class KaraokeService {
  static const String _lyricsPath = 'assets/sounds/gecko-lyrics.txt';

  List<KaraokeLine> _lines = [];
  Timer? _timer;
  DateTime? _startTime;
  Function(String)? _onTextUpdate;

  bool get isActive => _timer != null;

  Future<void> loadLyrics() async {
    try {
      final content = await rootBundle.loadString(_lyricsPath);
      _lines = _parseLyrics(content);
    } catch (e) {
      log.e('Error loading lyrics: $e');
      _lines = [];
    }
  }

  List<KaraokeLine> _parseLyrics(String content) {
    final lines = content.split('\n');
    final karaokeLines = <KaraokeLine>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Parse format: [timestamp]text ou [timestamp] pour ligne vide
      final timestampMatch = RegExp(r'^\[(\d+\.?\d*)\](.*)$').firstMatch(trimmed);
      if (timestampMatch != null) {
        final timestamp = double.parse(timestampMatch.group(1)!);
        final text = timestampMatch.group(2)?.trim() ?? '';
        karaokeLines.add(KaraokeLine(timestamp: timestamp, text: text));
      }
    }

    return karaokeLines;
  }

  void startKaraoke(Function(String) onTextUpdate) {
    if (_lines.isEmpty) {
      log.e('No lyrics loaded');
      return;
    }

    _onTextUpdate = onTextUpdate;
    _startTime = DateTime.now();

    // Timer qui vérifie toutes les 100ms quelle ligne afficher
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _updateCurrentLine();
    });
  }

  void stopKaraoke() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    _onTextUpdate = null;
  }

  void _updateCurrentLine() {
    if (_startTime == null || _onTextUpdate == null) return;

    final elapsed = DateTime.now().difference(_startTime!).inMilliseconds / 1000.0;

    // Trouver la ligne actuelle basée sur le timestamp
    String currentText = '';

    for (int i = 0; i < _lines.length; i++) {
      if (elapsed >= _lines[i].timestamp) {
        // Vérifier s'il y a une ligne suivante
        if (i + 1 < _lines.length) {
          // Si on n'a pas encore atteint la ligne suivante
          if (elapsed < _lines[i + 1].timestamp) {
            currentText = _lines[i].text;
            break;
          }
        } else {
          // Dernière ligne
          currentText = _lines[i].text;
        }
      }
    }

    _onTextUpdate!(currentText);
  }

  void dispose() {
    stopKaraoke();
  }
}
