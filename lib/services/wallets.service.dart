import 'package:durt2/durt2.dart';
import 'package:gecko/globals.dart';

class WalletsService {
  Future<void> createSafe({
    required String mnemonic,
    required int pinCode,
  }) async {
    try {
      final keypair = await KeyPair.sr25519.fromMnemonic(mnemonic);

      await WalletService.storeMnemonic(
        address: keypair.address,
        mnemonic: mnemonic,
        pinCode: pinCode,
      );
    } catch (e) {
      log.e('Invalid mnemonic: $e');
    }
  }

  Future<WalletData?> generateNextDerivation({
    required String pinCode,
    int? safeBoxNumber,
    String? walletName,
    bool setAsDefault = false,
  }) async {
    return await WalletService.generateNextDerivation(
      pinCode: pinCode,
      safeBoxNumber: safeBoxNumber,
      walletName: walletName,
      setAsDefault: setAsDefault,
    );
  }

  Mnemonic generateMnemonic(Language language) => WalletService.generateMnemonic(language);

  Future<KeyPair?> getKeyPairFromMnemonic(String mnemonic, {int? derivation}) async =>
      await WalletService.getKeyPairFromMnemonic(mnemonic, derivation: derivation);

  Future<List<WalletData>> importDerivations({
    required String pinCode,
    required List<int> derivations,
    int? safeBoxNumber,
  }) async =>
      await WalletService.importDerivations(pinCode: pinCode, derivations: derivations, safeBoxNumber: safeBoxNumber);

  Future<WalletData?> importRootWallet({
    required String pinCode,
    int? safeBoxNumber,
  }) async =>
      await WalletService.importRootWallet(pinCode: pinCode, safeBoxNumber: safeBoxNumber);
}
