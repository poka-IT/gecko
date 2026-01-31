#!/usr/bin/env dart
// Script to display the certification queue for a given SS58 address
// Usage: dart run scripts/show_cert_queue.dart <SS58_ADDRESS>

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:ss58/ss58.dart' as ss58;
import 'package:base_codecs/base_codecs.dart';

const String cesiumPlusEndpoint = 'https://g1.data.e-is.pro';

/// Check if string is a valid SS58 address
bool isValidSs58(String input) {
  try {
    ss58.Address.decode(input);
    return true;
  } catch (_) {
    return false;
  }
}

/// Check if string looks like a base58 pubkey (not SS58)
/// Base58 pubkeys are typically 43-44 chars and don't start with common SS58 prefixes
bool looksLikeBase58Pubkey(String input) {
  // SS58 addresses for Substrate typically start with 5, for Duniter with 5 or others
  // Base58 pubkeys can start with various letters
  // If it's valid SS58, it's an address. If not but it's ~43-44 chars of base58, it's likely a pubkey
  if (input.length < 40 || input.length > 50) return false;

  // Try to decode as base58
  try {
    final decoded = base58BitcoinDecode(input);
    return decoded.length == 32; // Ed25519 pubkey is 32 bytes
  } catch (_) {
    return false;
  }
}

/// Convert input to base58 pubkey for Cesium+ API
/// Accepts either SS58 address or direct base58 pubkey
String toPubkeyBase58(String input) {
  // First check if it's a valid SS58 address
  if (isValidSs58(input)) {
    final pubkeyBytes = ss58.Address.decode(input).pubkey;
    return base58BitcoinEncode(Uint8List.fromList(pubkeyBytes));
  }

  // Check if it's already a base58 pubkey
  if (looksLikeBase58Pubkey(input)) {
    return input; // Already a pubkey, use as-is
  }

  throw FormatException('Invalid input: not a valid SS58 address or base58 pubkey');
}

/// Fetch profile from CesiumPlus
Future<Map<String, dynamic>?> getProfile(String pubkey) async {
  try {
    final response = await http
        .get(Uri.parse('$cesiumPlusEndpoint/user/profile/$pubkey'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['_source'] != null) {
        return data['_source'] as Map<String, dynamic>;
      }
    } else if (response.statusCode == 404) {
      return null;
    }
    return null;
  } catch (e) {
    stderr.writeln('Error fetching profile: $e');
    return null;
  }
}

/// Format a DateTime nicely
String formatDateTime(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

/// Get short address (first 8 chars)
String shortAddress(String address) {
  if (address.length <= 8) return address;
  return '${address.substring(0, 8)}...';
}

/// Emojis that take 2 visual columns but have length=1 in Dart
/// These need +1 adjustment because content.length underestimates visual width
const _shortWidthEmojis = ['⏳', '✅', '⚠'];

/// Count emojis that have length=1 but display as 2 columns
int _countShortWideEmojis(String s) {
  int count = 0;
  for (final emoji in _shortWidthEmojis) {
    int index = 0;
    while ((index = s.indexOf(emoji, index)) != -1) {
      count++;
      index += emoji.length;
    }
  }
  return count;
}

/// Pad string to target visual width, accounting for wide chars
/// Width is 65 chars for the content area (between "║ " and "║")
String padLine(String content) {
  const targetWidth = 65;
  // Emojis like ⏳, ✅, ⚠ have length=1 but take 2 visual columns
  // So visual width = content.length + count of such emojis
  final extraWidth = _countShortWideEmojis(content);
  final visualWidth = content.length + extraWidth;
  final padding = targetWidth - visualWidth;
  if (padding <= 0) return content;
  return content + ' ' * padding;
}

/// Parse a timestamp that can be either Unix ms (int) or ISO8601 (String)
DateTime? parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Print certification queue in a nice format
void printCertificationQueue(Map<String, dynamic> queueJson, String address) {
  print('');
  print('╔══════════════════════════════════════════════════════════════════╗');
  print('║               FILE DE CERTIFICATIONS                             ║');
  print('╠══════════════════════════════════════════════════════════════════╣');
  print('║ ${padLine('Adresse: $address')}║');

  final issuerAddress = queueJson['issuerAddress'] as String?;
  if (issuerAddress != null && issuerAddress != address) {
    print('║ ${padLine('Issuer:  $issuerAddress')}║');
  }

  final lastUpdated = parseTimestamp(queueJson['lastUpdated']);
  print('║ ${padLine('Mise à jour: ${formatDateTime(lastUpdated)}')}║');

  print('╠══════════════════════════════════════════════════════════════════╣');

  final pendingCerts = queueJson['pendingCertifications'] as List<dynamic>?;

  if (pendingCerts == null || pendingCerts.isEmpty) {
    print('║                                                                  ║');
    print('║ ${padLine('    📭 Aucune certification en attente')}║');
    print('║                                                                  ║');
  } else {
    print('║ ${padLine('${pendingCerts.length} certification(s) en attente:')}║');
    print('╠══════════════════════════════════════════════════════════════════╣');

    for (final cert in pendingCerts) {
      final position = cert['position'] as int? ?? 0;
      final receiverAddress = cert['receiverAddress'] as String? ?? '?';
      final receiverName = cert['receiverName'] as String?;
      final receiverUid = cert['receiverUid'] as String?;
      final certType = cert['certType'] as String? ?? 'certification';
      final addedAt = parseTimestamp(cert['addedAt']);
      final expectedDate = parseTimestamp(cert['expectedAvailableDate']);

      // Check if ready
      final isReady = expectedDate != null && DateTime.now().isAfter(expectedDate);
      final readyIndicator = isReady ? '🟢' : '🟡';

      // Display name
      final displayName = receiverName ?? receiverUid ?? shortAddress(receiverAddress);

      // Cert type emoji
      String typeEmoji;
      String typeLabel;
      switch (certType) {
        case 'invitation':
          typeEmoji = '📨';
          typeLabel = 'Invitation';
          break;
        case 'renewal':
          typeEmoji = '🔄';
          typeLabel = 'Renouvellement';
          break;
        default:
          typeEmoji = '📝';
          typeLabel = 'Certification';
      }

      print('║                                                                  ║');
      print('║ ${padLine(' $readyIndicator #$position - $displayName')}║');
      print('║ ${padLine('    $typeEmoji $typeLabel')}║');
      print('║ ${padLine('    📍 ${shortAddress(receiverAddress)}')}║');
      print('║ ${padLine('    📅 Ajouté: ${formatDateTime(addedAt)}')}║');

      if (isReady) {
        print('║ ${padLine('    ✅ PRÊT À CERTIFIER !')}║');
      } else if (expectedDate != null) {
        print('║ ${padLine('    ⏳ Disponible: ${formatDateTime(expectedDate)}')}║');
      }
    }
  }

  print('║                                                                  ║');
  print('╚══════════════════════════════════════════════════════════════════╝');
  print('');
}

void printUsage() {
  print('');
  print('Usage: ./scripts/show_cert_queue <ADDRESS_OR_PUBKEY>');
  print('');
  print('Affiche la file de certifications stockée sur CesiumPlus.');
  print('');
  print('Accepte:');
  print('  - Adresse SS58 (ex: 5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY)');
  print('  - Pubkey base58 (ex: HgTTJLAQ5sqfknMq7yLPZbehtuLSsKj9CxWN7k8QvYJd)');
  print('');
  print('Options:');
  print('  -v, --verbose  Affiche le JSON brut');
  print('');
}

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('❌ Erreur: Aucune adresse fournie');
    printUsage();
    exit(1);
  }

  final address = args[0];

  // Convert to base58 pubkey (accepts SS58 address or direct base58 pubkey)
  String pubkey;
  try {
    pubkey = toPubkeyBase58(address);
  } catch (e) {
    stderr.writeln('❌ Erreur: Format invalide: $address');
    stderr.writeln('   Attendu: adresse SS58 ou pubkey base58');
    stderr.writeln('   Détail: $e');
    exit(1);
  }

  print('');
  print('🔍 Recherche du profil CesiumPlus pour: ${shortAddress(address)}...');
  print('   Pubkey (base58): $pubkey');

  // Fetch profile
  final profile = await getProfile(pubkey);

  if (profile == null) {
    print('');
    print('⚠️  Aucun profil CesiumPlus trouvé pour cette adresse.');
    print('   La file de certifications est vide ou le profil n\'existe pas.');
    print('');
    exit(0);
  }

  // Check for certification queue at profile root level
  final certQueue = profile['certificationQueue'] as Map<String, dynamic>?;

  if (certQueue == null) {
    print('');
    print('✅ Profil CesiumPlus trouvé, mais aucune file de certifications.');
    if (profile['title'] != null) {
      print('   Nom du profil: ${profile['title']}');
    }
    print('');
    exit(0);
  }

  // Print the queue
  printCertificationQueue(certQueue, address);

  // Also print raw JSON if verbose
  if (args.contains('-v') || args.contains('--verbose')) {
    print('--- JSON brut ---');
    final encoder = JsonEncoder.withIndent('  ');
    print(encoder.convert(certQueue));
    print('');
  }
}
