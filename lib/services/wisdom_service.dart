import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';

/// Service for handling Gecko wisdom of the day easter egg
class WisdomService {
  static final WisdomService _instance = WisdomService._internal();
  factory WisdomService() => _instance;
  WisdomService._internal();

  /// Calculate the day of the year (1-365/366)
  int _getDayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final difference = date.difference(startOfYear).inDays;
    return difference + 1; // Add 1 because we want 1-based indexing
  }

  /// Get wisdom of the day from assets for a specific language
  Future<String?> getWisdomOfTheDay(String languageCode) async {
    try {
      // Try to load the wisdom file for the current language
      String filePath = 'assets/gecko-wisdom/$languageCode.txt';
      String content;

      try {
        content = await rootBundle.loadString(filePath);
      } catch (e) {
        // If the language file doesn't exist, fallback to French
        log.w('Wisdom file not found for language $languageCode, falling back to French');
        content = await rootBundle.loadString('assets/gecko-wisdom/fr.txt');
      }

      final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

      if (lines.isEmpty) {
        return null;
      }

      // Calculate day of year for today
      final today = DateTime.now();
      final dayOfYear = _getDayOfYear(today);

      // Select the appropriate line
      int lineIndex = (dayOfYear - 1);
      // In case the number of days in the year is less than the number of lines…
      lineIndex %= lines.length;

      return lines[lineIndex].trim();
    } catch (e) {
      log.e('Error loading wisdom of the day: $e');
      return null;
    }
  }
}
