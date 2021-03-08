import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:isolate/ports.dart';
import "package:system_info/system_info.dart";

import 'ffi.dart' as native;

/// DEWIF meta data
class DewifMetaData {
  /// Currency name
  String currency;

  /// Secret code length
  int secretCodeLen;

  /// DEWIF version
  int version;

  /// Wallet type
  WalletType walletType;

  DewifMetaData._(this.currency, this.secretCodeLen, this.version) {
    if (version == 4) {
      walletType = WalletType.bip32Ed25519;
    } else {
      walletType = WalletType.ed25519;
    }
  }
}

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

  NewWallet._(this.dewif, this.pin);
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
      // utf8.encoder(dewif),
      StringUtf8Pointer(dewif).toNativeUtf8(),
      StringUtf8Pointer(oldPin).toNativeUtf8(),
      0,
      secretCodeType.index,
      ram,
    );
    List<String> newWallet = await completer.future;

    return Future.value(NewWallet._(newWallet[0], newWallet[1]));
  }

  /// Check validity of a base58 public key with its checksum
  static Future<void> checkPublicKey({String pubkey}) {
    final completer = Completer<void>();
    final sendPort =
        singleCompletePort<void, String>(completer, callback: _handleErrVoid);
    native.check_pubkey(
      sendPort.nativePort,
      StringUtf8Pointer(pubkey).toNativeUtf8(),
    );
    return completer.future;
  }

  /// Compute public key checksum
  static Future<String> computeChecksum({String pubkey}) {
    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.compute_checksum(
      sendPort.nativePort,
      StringUtf8Pointer(pubkey).toNativeUtf8(),
    );
    return completer.future;
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
    bool isMember = false,
  }) async {
    int ram = SysInfo.getTotalPhysicalMemory();
    print('ram=$ram');

    final completer = Completer<List<String>>();
    final sendPort = singleCompletePort<List<String>, List>(completer,
        callback: _handleErrList);
    native.gen_dewif_from_legacy(
      sendPort.nativePort,
      StringUtf8Pointer(currency).toNativeUtf8(),
      StringUtf8Pointer(salt).toNativeUtf8(),
      StringUtf8Pointer(password).toNativeUtf8(),
      isMember ? 1 : 0,
      secretCodeType.index,
      ram,
    );
    List<String> newWallet = await completer.future;

    return Future.value(NewWallet._(newWallet[0], newWallet[1]));
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
  }) async {
    int ram = SysInfo.getTotalPhysicalMemory();
    print('ram=$ram');

    final completer = Completer<List<String>>();
    final sendPort = singleCompletePort<List<String>, List>(completer,
        callback: _handleErrList);
    native.gen_dewif(
      sendPort.nativePort,
      StringUtf8Pointer(currency).toNativeUtf8(),
      language.index,
      StringUtf8Pointer(mnemonic).toNativeUtf8(),
      0,
      secretCodeType.index,
      ram,
    );
    List<String> newWallet = await completer.future;

    return Future.value(NewWallet._(newWallet[0], newWallet[1]));
  }

  /// Get next external public key of a specific opaque account
  static Future<String> getOpaqueAccountNextExternalPublicKey(
      {int accountIndex}) async {
    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.get_opaque_account_next_external_address(
        sendPort.nativePort, accountIndex.toUnsigned(31));
    return completer.future;
  }

  /// Get BIP32 accounts public keys (in base 58) of `dewif` master keypair.
  static Future<List<String>> getBip32DewifAccountsPublicKeys(
      {String currency = "g1",
      String dewif,
      String secretCode,
      List<int> accountsIndex}) async {
    final completer = Completer<List<String>>();
    final sendPort = singleCompletePort<List<String>, List>(completer,
        callback: _handleErrList);
    native.get_bip32_dewif_accounts_pubkeys(
        sendPort.nativePort,
        StringUtf8Pointer(currency).toNativeUtf8(),
        StringUtf8Pointer(dewif).toNativeUtf8(),
        StringUtf8Pointer(secretCode).toNativeUtf8(),
        accountsIndex.length,
        _listIntToPtrUint32(accountsIndex));
    return completer.future;
  }

  /// Get `dewif` keypair meta data.
  static Future<DewifMetaData> getDewifMetaData(
      {String dewif,
      SecretCodeType secretCodeType = SecretCodeType.letters}) async {
    final completer = Completer<List<String>>();
    final sendPort = singleCompletePort<List<String>, List>(completer,
        callback: _handleErrList);
    native.get_dewif_meta(sendPort.nativePort,
        StringUtf8Pointer(dewif).toNativeUtf8(), 0, secretCodeType.index);
    List<String> dewifMetaData = await completer.future;

    return Future.value(DewifMetaData._(dewifMetaData[0],
        int.parse(dewifMetaData[1]), int.parse(dewifMetaData[2])));
  }

  /// Get public key (in base 58) of `dewif` keypair.
  static Future<String> getDewifPublicKey(
      {int accountIndexOpt,
      int addressIndexOpt,
      String currency = "g1",
      String dewif,
      bool externalOpt,
      String pin}) async {
    var externalOptInt = -1;
    if (externalOpt != null) {
      externalOptInt = externalOpt ? 1 : 0;
    }
    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.get_dewif_pubkey(
      sendPort.nativePort,
      accountIndexOpt ?? -1,
      addressIndexOpt ?? -1,
      StringUtf8Pointer(currency).toNativeUtf8(),
      StringUtf8Pointer(dewif).toNativeUtf8(),
      externalOptInt,
      StringUtf8Pointer(pin).toNativeUtf8(),
    );
    return completer.future;
  }

  /// Get secret code length of `dewif` keypair.
  static int getDewifSecretCodeLen(
      {String currency = "g1",
      String dewif,
      SecretCodeType secretCodeType = SecretCodeType.letters}) {
    int res = native.get_dewif_secret_code_len(
      StringUtf8Pointer(dewif).toNativeUtf8(),
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
      StringUtf8Pointer(salt).toNativeUtf8(),
      StringUtf8Pointer(password).toNativeUtf8(),
    );
    return completer.future;
  }

  /// Load opaque accounts
  static Future<void> loadOpaqueAccounts(
    List<int> accountsIndex,
    String currency,
    String dewif,
    String secretCode,
  ) {
    final completer = Completer<void>();
    final sendPort =
        singleCompletePort<void, String>(completer, callback: _handleErrVoid);
    native.load_opaque_bip32_accounts(
        sendPort.nativePort,
        accountsIndex.length,
        _listIntToPtrUint32(accountsIndex),
        StringUtf8Pointer(currency).toNativeUtf8(),
        StringUtf8Pointer(dewif).toNativeUtf8(),
        StringUtf8Pointer(secretCode).toNativeUtf8());
    return completer.future;
  }

  /// Sign the message `message` with `dewif` keypair encryted
  /// in DEWIF format.
  ///
  /// If you have several messages to sign, use `signSeveral`
  /// method instead.
  static Future<String> sign(
      {int accountIndexOpt,
      int addressIndexOpt,
      String currency = "g1",
      String dewif,
      bool externalOpt,
      String secretCode,
      String message}) {
    var externalOptInt = -1;
    if (externalOpt != null) {
      externalOptInt = externalOpt ? 1 : 0;
    }

    final completer = Completer<String>();
    final sendPort =
        singleCompletePort<String, String>(completer, callback: _handleErr);
    native.sign(
      sendPort.nativePort,
      accountIndexOpt ?? -1,
      addressIndexOpt ?? -1,
      StringUtf8Pointer(currency).toNativeUtf8(),
      StringUtf8Pointer(dewif).toNativeUtf8(),
      externalOptInt,
      StringUtf8Pointer(secretCode).toNativeUtf8(),
      StringUtf8Pointer(message).toNativeUtf8(),
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
      {int accountIndexOpt,
      int addressIndexOpt,
      String currency = "g1",
      String dewif,
      bool externalOpt,
      String secretCode,
      List<String> messages}) {
    var externalOptInt = -1;
    if (externalOpt != null) {
      externalOptInt = externalOpt ? 1 : 0;
    }

    final completer = Completer<List<String>>();
    final sendPort = singleCompletePort<List<String>, List>(completer,
        callback: _handleErrList);

    native.sign_several(
      sendPort.nativePort,
      accountIndexOpt ?? -1,
      addressIndexOpt ?? -1,
      StringUtf8Pointer(currency).toNativeUtf8(),
      StringUtf8Pointer(dewif).toNativeUtf8(),
      externalOptInt,
      StringUtf8Pointer(secretCode).toNativeUtf8(),
      messages.length,
      _listStringToPtr(messages),
    );

    return completer.future;
  }

  static Pointer<Uint32> _listIntToPtrUint32(List<int> list) {
    final listUint32 = list.map((i) => i.toUnsigned(31)).toList();
    final Pointer<Uint32> ptr = malloc.allocate(listUint32.length);
    for (var i = 0; i < listUint32.length; i++) {
      ptr[i] = listUint32[i];
    }
    return ptr;
  }

  static Pointer<Pointer<Utf8>> _listStringToPtr(List<String> list) {
    final listUtf8 =
        list.map((s) => StringUtf8Pointer(s).toNativeUtf8()).toList();
    final Pointer<Pointer<Utf8>> ptr = malloc.allocate(listUtf8.length);
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

  static void _handleErrVoid(String res) {
    if (res.startsWith('DUBP_RS_ERROR: ')) {
      final error = res;
      print(error);
      throw error;
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
