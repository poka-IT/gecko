import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Provider that fetches the Ğ1 monetary license for a given language code.
/// Falls back to English if the requested language is not available.
final licenseProvider = FutureProvider.family<String, String>((ref, langCode) async {
  final supportedLangs = {'fr', 'en', 'es', 'it'};
  final lang = supportedLangs.contains(langCode) ? langCode : 'en';

  final url = Uri.parse(
    'https://git.duniter.org/documents/g1_monetary_license/-/raw/master/g1_monetary_license_$lang.rst',
  );

  final response = await http.get(url, headers: {'User-Agent': 'Gecko-Wallet'});

  if (response.statusCode != 200) {
    // Fallback to English if the requested language fails
    if (lang != 'en') {
      final fallbackUrl = Uri.parse(
        'https://git.duniter.org/documents/g1_monetary_license/-/raw/master/g1_monetary_license_en.rst',
      );
      final fallbackResponse = await http.get(fallbackUrl, headers: {'User-Agent': 'Gecko-Wallet'});
      if (fallbackResponse.statusCode == 200) {
        return _rstToMarkdown(fallbackResponse.body);
      }
    }
    throw Exception('Failed to load license (HTTP ${response.statusCode})');
  }

  return _rstToMarkdown(response.body);
});

/// Converts basic reStructuredText to Markdown.
String _rstToMarkdown(String rst) {
  final lines = rst.split('\n');
  final result = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Skip RST underline markers and convert previous line to heading
    if (i > 0 && line.isNotEmpty && _isUnderline(line)) {
      // Replace the previous line with a markdown heading
      final previousLine = result.removeLast();
      final level = line.trimRight().startsWith('=') ? '#' : '##';
      result.add('$level $previousLine');
      continue;
    }

    // Convert RST links: `text <url>`_ → [text](url)
    final convertedLine = line.replaceAllMapped(
      RegExp(r'`([^<]+?)\s*<([^>]+)>`_'),
      (match) => '[${match.group(1)!.trim()}](${match.group(2)})',
    );

    // Convert RST metadata fields :Key: value → **Key:** value
    final metaConverted = convertedLine.replaceAllMapped(
      RegExp(r'^:(Date|Modified):\s*(.+)$'),
      (match) => '**${match.group(1)}:** ${match.group(2)}',
    );

    result.add(metaConverted);
  }

  return result.join('\n');
}

bool _isUnderline(String line) {
  final trimmed = line.trimRight();
  if (trimmed.length < 3) return false;
  return trimmed.split('').every((c) => c == '=' || c == '-');
}
