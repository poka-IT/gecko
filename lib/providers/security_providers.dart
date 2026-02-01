import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';

/// Combined seed data for show seed page
typedef SeedDisplayData = ({String englishMnemonic, String displayMnemonic, int? safeBoxNumber});

/// Combined provider for seed display page - loads everything at once to avoid multiple loaders
final seedDisplayProvider = FutureProvider.family.autoDispose<SeedDisplayData, ({String address, String pin})>((
  ref,
  params,
) async {
  final walletService = ref.read(walletServiceProvider);

  // Get the English mnemonic first
  final englishMnemonic = await walletService.getSeed(address: params.address, pin: params.pin);
  if (englishMnemonic.isEmpty) {
    throw Exception('Failed to retrieve seed');
  }

  // Get safe box number for the address (reactive to safe changes)
  final allSafes = walletService.safeBox.getAll();
  final defaultSafeNumber = ref.watch(defaultSafeBoxNumberProvider);
  final defaultSafe = allSafes.firstWhere((safe) => safe.number == defaultSafeNumber, orElse: () => allSafes.first);

  final wallet = defaultSafe.wallets.where((w) => w.address == params.address).firstOrNull;
  final safeBoxNumber = wallet?.safe.target?.number;

  // Convert to display language
  String displayMnemonic;
  try {
    displayMnemonic = await walletService.convertEnglishToSafeLanguage(englishMnemonic, safeBoxNumber);
  } catch (e) {
    // Fallback to English if conversion fails
    displayMnemonic = englishMnemonic;
  }

  return (englishMnemonic: englishMnemonic, displayMnemonic: displayMnemonic, safeBoxNumber: safeBoxNumber);
});

/// Provider for getting seed from wallet - auto-disposes for security
final seedProvider = FutureProvider.family.autoDispose<String?, ({String address, String pin})>((ref, params) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.getSeed(address: params.address, pin: params.pin);
});

/// Provider for converting English mnemonic to safe's stored language - auto-disposes for security
final displayMnemonicProvider = FutureProvider.family
    .autoDispose<String, ({String englishMnemonic, int? safeBoxNumber})>((ref, params) async {
      try {
        final walletService = ref.read(walletServiceProvider);
        return await walletService.convertEnglishToSafeLanguage(params.englishMnemonic, params.safeBoxNumber);
      } catch (e) {
        // Fallback to English if conversion fails
        return params.englishMnemonic;
      }
    });
