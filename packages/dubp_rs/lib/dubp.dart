import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:isolate/ports.dart';

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

  /// Pin code
  String pin;

  /// Public key
  String publicKey;

  NewWallet._(this.dewif, this.pin, this.publicKey);
}

/// Pin code length
enum PinLength {
  /// 6 characters
  six,

  /// 8 characters
  eight,

  /// 10 characters
  ten,
}

/// DUBP Rust utilities
///
/// All the functions of this package are static methods of this
/// class `DubpRust`.
class DubpRust {
  /// Must be called only once at the start of your application.
  static void setup() {
    native.store_dart_post_cobject(NativeApi.postCObject);
    print("Dubp Setup Done");
  }

  /// Generate a random mnemonic
  static Future<String> genMnemonic({Language language = Language.english}) {
    final completer = Completer<String>();
    final sendPort = singleCompletePort<String, String>(completer);
    final res = native.gen_mnemonic(
      sendPort.nativePort,
      language.index,
    );
    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  static Future<String> _genPin(PinLength pinLength) {
    final completer = Completer<String>();
    final sendPort = singleCompletePort<String, String>(completer);
    switch (pinLength) {
      case PinLength.ten:
        final res = native.gen_pin10(
          sendPort.nativePort,
        );
        if (res != 1) {
          DubpRust._throwError();
        }
        break;
      case PinLength.eight:
        final res = native.gen_pin8(
          sendPort.nativePort,
        );
        if (res != 1) {
          DubpRust._throwError();
        }
        break;
      case PinLength.six:
      default:
        final res = native.gen_pin6(
          sendPort.nativePort,
        );
        if (res != 1) {
          DubpRust._throwError();
        }
        break;
    }
    return completer.future;
  }

  /// Change the pin code that encrypts the `dewif` keypair.
  static Future<NewWallet> changeDewifPin(
      {String currency = "g1",
      String dewif,
      String oldPin,
      PinLength newPinLength = PinLength.six}) async {
    // pin
    String newPin = await _genPin(newPinLength);
    // dewif
    String newDewif;
    {
      final completer = Completer<String>();
      final sendPort = singleCompletePort<String, String>(completer);
      final res = native.change_dewif_pin(
        sendPort.nativePort,
        Utf8.toUtf8(currency),
        Utf8.toUtf8(dewif),
        Utf8.toUtf8(oldPin),
        Utf8.toUtf8(newPin),
      );
      if (res != 1) {
        DubpRust._throwError();
      }
      newDewif = await completer.future;
    }
    // publicKey
    String publicKey;
    {
      final completer = Completer<String>();
      final sendPort = singleCompletePort<String, String>(completer);
      final res = native.get_dewif_pubkey(
        sendPort.nativePort,
        Utf8.toUtf8(currency),
        Utf8.toUtf8(newDewif),
        Utf8.toUtf8(newPin),
      );
      if (res != 1) {
        _throwError();
      }
      publicKey = await completer.future;
    }

    return Future.value(NewWallet._(newDewif, newPin, publicKey));
  }

  /// Generate a wallet from a mnemonic phrase.
  ///
  /// If the mnemonic is not in English, you must indicate the language of
  /// the mnemonic (necessary for the verification of its validity).
  ///
  /// If the wallet to be generated is not dedicated to the Ğ1 currency, you
  /// must indicate the currency for which this wallet will be used.
  static Future<NewWallet> genWalletFromMnemonic(
      {String currency = "g1",
      Language language = Language.english,
      String mnemonic,
      PinLength pinLength = PinLength.six}) async {
    // pin
    String pin = await _genPin(pinLength);
    // publicKey
    String publicKey;
    {
      final completer = Completer<String>();
      final sendPort = singleCompletePort<String, String>(completer);
      final res = native.mnemonic_to_pubkey(
        sendPort.nativePort,
        language.index,
        Utf8.toUtf8(mnemonic),
      );
      if (res != 1) {
        DubpRust._throwError();
      }
      publicKey = await completer.future;
    }
    // dewif
    String dewif;
    {
      final completer = Completer<String>();
      final sendPort = singleCompletePort<String, String>(completer);
      final res = native.gen_dewif(
        sendPort.nativePort,
        Utf8.toUtf8(currency),
        language.index,
        Utf8.toUtf8(mnemonic),
        Utf8.toUtf8(pin),
      );
      if (res != 1) {
        DubpRust._throwError();
      }
      dewif = await completer.future;
    }
    return Future.value(NewWallet._(dewif, pin, publicKey));
  }

  /// Get pulblic key (in base 58) of `dewif` keypair.
  static Future<String> getDewifPublicKey(
      {String currency = "g1", String dewif, String pin}) {
    final completer = Completer<String>();
    final sendPort = singleCompletePort<String, String>(completer);
    final res = native.get_dewif_pubkey(
      sendPort.nativePort,
      Utf8.toUtf8(currency),
      Utf8.toUtf8(dewif),
      Utf8.toUtf8(pin),
    );
    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  /// Sign the message `message` with `dewif` keypair encryted in DEWIF format.
  ///
  /// If you have several messages to sign, use `signSeveral` method instead.
  static Future<String> sign(
      {String currency = "g1", String dewif, String pin, String message}) {
    final completer = Completer<String>();
    final sendPort = singleCompletePort<String, String>(completer);
    final res = native.sign(
      sendPort.nativePort,
      Utf8.toUtf8(currency),
      Utf8.toUtf8(dewif),
      Utf8.toUtf8(pin),
      Utf8.toUtf8(message),
    );
    if (res != 1) {
      _throwError();
    }
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
    final sendPort = singleCompletePort<List<String>, List<String>>(completer);

    final res = native.sign_several(
      sendPort.nativePort,
      Utf8.toUtf8(currency),
      Utf8.toUtf8(dewif),
      Utf8.toUtf8(pin),
      messages.length,
      _listStringToPtr(messages),
    );
    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  static Pointer<Pointer<Utf8>> _listStringToPtr(List<String> list) {
    final listUtf8 = list.map(Utf8.toUtf8).toList();
    final Pointer<Pointer<Utf8>> ptr = allocate(count: listUtf8.length);
    for (var i = 0; i < listUtf8.length; i++) {
      ptr[i] = listUtf8[i];
    }
    return ptr;
  }

  static void _throwError() {
    final length = native.last_error_length();
    final Pointer<Utf8> message = allocate(count: length);
    native.error_message_utf8(message, length);
    final error = Utf8.fromUtf8(message);
    print(error);
    throw error;
  }
}
