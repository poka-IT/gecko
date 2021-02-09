import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:isolate/ports.dart';
import "package:system_info/system_info.dart";

import 'ffi.dart' as native;

/// Language
enum Language {
  /// English
  english,

  /// French
  french,
}

/// New wallet
class NewWallet {
  /// DEWIF: Encrypted wallet
  String dewif;

  /// Secret code
  String pin;

  /// Public key
  String publicKey;

  NewWallet._(this.dewif, this.pin, this.publicKey);
}

/// Secret code type
enum SecretCodeType {
  /// Digits
  digits,

  /// Letters
  letters,
}

/// Wallet type
enum WalletType {
  /// Ed25519
  ed25519,

  /// BIP32-Ed25519
  bip32Ed25519,
}

/// DUBP Rust utilities
///
/// All the functions of this package are static methods of this
/// class `DubpRust`.
class DubpRust {
  /// Must be called only once at the start of your application.
  static void setup() {
    native.store_dart_post_cobject(NativeApi.postCObject);
    print("DUBP_RS Setup Done");
  }

  /// Change the secret code that encrypts the `dewif` keypair.
  static Future<NewWallet> changeDewifPin({
    String currency = "g1",
    String dewif,
    String oldPin,
    SecretCodeType secretCodeType = SecretCodeType.letters,
  }) async {
    int ram = SysInfo.getTotalPhysicalMemory();

    final completer = Completer<List<String>>();
    final sendPort = singleCompletePort<List<String>, List>(completer,
        callback: _handleErrList);
    native.change_dewif_secret_code(
      sendPort.nativePort,
      Utf8.toUtf8(currency),
      Utf8.toUtf8(dewif),
      Utf8.toUtf8(oldPin),
      0,
      secretCodeType.index,
      ram,
    );
    List<String> newWallet = await completer.future;

    return Future.value(NewWallet._(newWallet[0], newWallet[1], newWallet[2]));
  }

  /// Generate a random mnemonic
  static Future<String> genMnemonic({Language language = Language.english}) {
    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.gen_mnemonic(
      sendPort.nativePort,
      language.index,
    );
    return completer.future;
  }

  /// Generate a wallet from a deprecated salt + password couple.
  ///
  /// This deprecated method must be used only for compatibility purpose !
  static Future<NewWallet> genWalletFromDeprecatedSaltPassword({
    String currency = "g1",
    String salt,
    String password,
    SecretCodeType secretCodeType = SecretCodeType.letters,
  }) async {
    int ram = SysInfo.getTotalPhysicalMemory();
    print('ram=$ram');

    final completer = Completer<List<String>>();
    final sendPort = singleCompletePort<List<String>, List>(completer,
        callback: _handleErrList);
    native.gen_dewif_from_legacy(
      sendPort.nativePort,
      Utf8.toUtf8(currency),
      Utf8.toUtf8(salt),
      Utf8.toUtf8(password),
      0,
      secretCodeType.index,
      ram,
    );
    List<String> newWallet = await completer.future;

    return Future.value(NewWallet._(newWallet[0], newWallet[1], newWallet[2]));
  }

  /// Generate a wallet from a mnemonic phrase.
  ///
  /// If the mnemonic is not in English, you must indicate the language of
  /// the mnemonic (necessary for the verification of its validity).
  ///
  /// If the wallet to be generated is not dedicated to the Ğ1 currency, you
  /// must indicate the currency for which this wallet will be used.
  static Future<NewWallet> genWalletFromMnemonic({
    String currency = "g1",
    Language language = Language.english,
    String mnemonic,
    SecretCodeType secretCodeType = SecretCodeType.letters,
    WalletType walletType = WalletType.ed25519,
  }) async {
    int ram = SysInfo.getTotalPhysicalMemory();
    print('ram=$ram');

    final completer = Completer<List<String>>();
    final sendPort = singleCompletePort<List<String>, List>(completer,
        callback: _handleErrList);
    native.gen_dewif(
      sendPort.nativePort,
      Utf8.toUtf8(currency),
      language.index,
      Utf8.toUtf8(mnemonic),
      0,
      secretCodeType.index,
      ram,
      walletType.index,
    );
    List<String> newWallet = await completer.future;

    return Future.value(NewWallet._(newWallet[0], newWallet[1], newWallet[2]));
  }

  //get_bip32_dewif_accounts_pubkeys

  /// Get BIP32 accounts public keys (in base 58) of `dewif` master keypair.
  static Future<String> getBip32DewifAccountsPublicKeys(
      {String currency = "g1",
      String dewif,
      String secretCode,
      List<int> accountsIndex}) async {
    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.get_bip32_dewif_accounts_pubkeys(
        sendPort.nativePort,
        Utf8.toUtf8(currency),
        Utf8.toUtf8(dewif),
        Utf8.toUtf8(secretCode),
        accountsIndex.length,
        _listIntToPtr(accountsIndex));
    return completer.future;
  }

  /// Get public key (in base 58) of `dewif` keypair.
  static Future<String> getDewifPublicKey(
      {String currency = "g1", String dewif, String pin}) async {
    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.get_dewif_pubkey(
      sendPort.nativePort,
      Utf8.toUtf8(currency),
      Utf8.toUtf8(dewif),
      Utf8.toUtf8(pin),
    );
    return completer.future;
  }

  /// Get secret code length of `dewif` keypair.
  static int getDewifSecretCodeLen(
      {String currency = "g1",
      String dewif,
      SecretCodeType secretCodeType = SecretCodeType.letters}) {
    int res = native.get_dewif_secret_code_len(
      Utf8.toUtf8(dewif),
      0,
      secretCodeType.index,
    );
    if (res == -1) {
      print('DUBP_RS_ERROR: DEWIF file content is corrupted.');
      throw 'DUBP_RS_ERROR: DEWIF file content is corrupted.';
    } else {
      return res;
    }
  }

  /// Get public key (in base 58) of legacy wallet (password + salt)
  ///
  /// This deprecated method must be used only for compatibility purpose !
  static Future<String> getLegacyPublicKey({String password, String salt}) {
    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.get_legacy_pubkey(
      sendPort.nativePort,
      Utf8.toUtf8(password),
      Utf8.toUtf8(salt),
    );
    return completer.future;
  }

  /// Sign the message `message` with `dewif` keypair encryted in DEWIF format.
  ///
  /// If you have several messages to sign, use `signSeveral` method instead.
  static Future<String> sign(
      {String currency = "g1", String dewif, String pin, String message}) {
    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.sign(
      sendPort.nativePort,
      Utf8.toUtf8(currency),
      Utf8.toUtf8(dewif),
      Utf8.toUtf8(pin),
      Utf8.toUtf8(message),
    );
    return completer.future;
  }

  /// Sign the message `message` with `dewif` Bip32-Ed25519 keypair encryted
  /// in DEWIF format.
  ///
  /// If you have several messages to sign, use `signSeveralBip32Transparent`
  /// method instead.
  static Future<String> signBip32Transparent(
      {int accountIndex,
      String currency = "g1",
      String dewif,
      String secretCode,
      String message}) {
    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.sign_bip32_transparent(
      sendPort.nativePort,
      accountIndex,
      Utf8.toUtf8(currency),
      Utf8.toUtf8(dewif),
      Utf8.toUtf8(secretCode),
      Utf8.toUtf8(message),
    );
    return completer.future;
  }

  /// Sign the message `message` with legacy wallet (password + salt)
  ///
  /// This deprecated method must be used only for compatibility purpose !
  static Future<String> signLegacy(
      {String password, String salt, String message}) {
    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.sign_legacy(
      sendPort.nativePort,
      Utf8.toUtf8(password),
      Utf8.toUtf8(salt),
      Utf8.toUtf8(message),
    );
    return completer.future;
  }

  /// Sign several messages `messages` with `dewif` keypair encryted in DEWIF
  /// format.
  ///
  /// This method is optimized to sign several messages at once. If you have
  /// several messages to sign, avoid calling the `sign` method for each
  /// message. Use this `signSeveral` method instead.
  static Future<List<String>> signSeveral(
      {String currency = "g1",
      String dewif,
      String pin,
      List<String> messages}) {
    final completer = Completer<List<String>>();
    final sendPort = singleCompletePort<List<String>, List>(completer,
        callback: _handleErrList);

    native.sign_several(
      sendPort.nativePort,
      Utf8.toUtf8(currency),
      Utf8.toUtf8(dewif),
      Utf8.toUtf8(pin),
      messages.length,
      _listStringToPtr(messages),
    );

    return completer.future;
  }

  /// Sign several messages `messages` with `dewif` keypair encryted in DEWIF
  /// format.
  ///
  /// This method is optimized to sign several messages at once. If you have
  /// several messages to sign, avoid calling the `sign` method for each
  /// message. Use this `signSeveral` method instead.
  static Future<List<String>> signSeveralBip32Transparent(
      {int accountIndex,
      String currency = "g1",
      String dewif,
      String pin,
      List<String> messages}) {
    final completer = Completer<List<String>>();
    final sendPort = singleCompletePort<List<String>, List>(completer,
        callback: _handleErrList);

    native.sign_several_bip32_transparent(
      sendPort.nativePort,
      accountIndex,
      Utf8.toUtf8(currency),
      Utf8.toUtf8(dewif),
      Utf8.toUtf8(pin),
      messages.length,
      _listStringToPtr(messages),
    );

    return completer.future;
  }

  static Pointer<Uint32> _listIntToPtr(List<int> list) {
    //final listUint32 = list.map(int.toUnsigned).toList();
    final Pointer<Uint32> ptr = allocate(count: list.length);
    for (var i = 0; i < list.length; i++) {
      ptr[i] = list[i];
    }
    return ptr;
  }

  static Pointer<Pointer<Utf8>> _listStringToPtr(List<String> list) {
    final listUtf8 = list.map(Utf8.toUtf8).toList();
    final Pointer<Pointer<Utf8>> ptr = allocate(count: listUtf8.length);
    for (var i = 0; i < listUtf8.length; i++) {
      ptr[i] = listUtf8[i];
    }
    return ptr;
  }

  static String _handleErr(String res) {
    if (res.startsWith('DUBP_RS_ERROR: ')) {
      final error = res;
      print(error);
      throw error;
    } else {
      return res;
    }
  }

  static List<String> _handleErrList(List res) {
    final List<String> arr = res.cast();
    if (arr.isNotEmpty && arr[0].startsWith('DUBP_RS_ERROR: ')) {
      final error = arr[0];
      print(error);
      throw error;
    } else {
      return arr;
    }
  }

  /*static int _handleErrInt(String res) {
    if (res.startsWith('DUBP_RS_ERROR: ')) {
      final error = res;
      print(error);
      throw error;
    } else {
      return int.parse(res);
    }
  }*/
}
