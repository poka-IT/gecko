# dubp

Flutter package that bind [dubp-rs-libs] Rust crates.

## Use

You must execute this instruction at startup of your application:

```dart
DubpRust.setup();
```

### Generate a random Mnemonic

#### Function signature

```dart
static Future<String> DubpRust.genMnemonic({Language language = Language.English});
```

#### Usage example

```dart
String mnemonic = await DubpRust.genMnemonic();
```

You can choose a language (English by default):

```dart
String mnemonic = await DubpRust.genMnemonic(language: Language.French);
```

### Generate a wallet

#### Function signature

```dart
static Future<NewWallet> genWalletFromMnemonic({
    String currency = "g1",
    Language language = Language.English,
    String mnemonic,
    PinLength pinLength = PinLength.Six
});
```

If the mnemonic is not in English, you must indicate the language of the mnemonic (necessary for the verification of its validity).
If the wallet to be generated is not dedicated to the Ğ1 currency, you must indicate the currency for which this wallet will be used.

#### Usage example

```dart
NewWallet new_wallet = await DubpRust.genWalletFromMnemonic(
    language: Language.English,
    mnemonic: "tongue cute mail fossil great frozen same social weasel impact brush kind"
);
```

You can choose a different length for the pin code (6 by default):

```dart
NewWallet new_wallet = await DubpRust.genWalletFromMnemonic(
    language: Language.English,
    mnemonic: "tongue cute mail fossil great frozen same social weasel impact brush kind",
    pinLength: PinLength.Eight
);
```

### Sign a message

#### Function signature

```dart
static Future<String> sign({
    String currency = "g1",
    String dewif,
    String pin,
    String message
});
```

If the wallet is not dedicated to the Ğ1 currency, you must indicate the currency.

#### Usage example

```dart
String signature = await DubpRust.sign(
    dewif: "AAAAARAAAAGfFDAs+jVZYkfhBlHZZ2fEQIvBqnG16g5+02cY18wSOjW0cUg2JV3SUTJYN2CrbQeRDwGazWnzSFBphchMmiL0",
    pin: "CDJ4UB",
    message: "toto"
);
```

### Change pin code

You can change the pin code that encrypts the [DEWIF].

#### Function signature

```dart
static Future<NewWallet> changeDewifPin({
    String currency = "g1",
    String dewif,
    String oldPin,
    PinLength newPinLength = PinLength.Six
});
```

If the wallet is not dedicated to the Ğ1 currency, you must indicate the currency.

#### Usage example

```dart
NewWallet new_wallet = await DubpRust.changeDewifPin(
    dewif: "AAAAARAAAAGfFDAs+jVZYkfhBlHZZ2fEQIvBqnG16g5+02cY18wSOjW0cUg2JV3SUTJYN2CrbQeRDwGazWnzSFBphchMmiL0",
    oldPin: "CDJ4UB",
);
```

[dubp-rs-libs]: https://git.duniter.org/libs/dubp-rs-libs
[DEWIF]: https://git.duniter.org/documents/rfcs/blob/dewif/rfc/0013_Duniter_Encrypted_Wallet_Import_Format.md
