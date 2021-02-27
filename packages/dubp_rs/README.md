# dubp

Flutter package that bind [dubp-rs-libs] Rust crates.

## Setup

### Prerequisites

* Android SDK
* Android **N**DK (**Native** Development Kit)
* Rust and cargo
* Cargo plugin cargo-make: `cargo install cargo-make`
* LLVM/Clang (see dedicated section below)

You must indicate where the SDK and NDK are located via the `ANDROID_SDK_ROOT` and `ANDROID_NDK_HOME` environment variables.
For example:

    export ANDROID_SDK_ROOT="/home/user/dev/android_sdk"
    export ANDROID_NDK_HOME="/home/user/dev/android_sdk/ndk/22.0.7026061"

You will also need to add targets for all Android architectures:

```sh
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
```

If you develop on mac, you can also add targets for iOS:

```sh
rustup target add aarch64-apple-ios x86_64-apple-ios
```

### LLVM/Clang

The project use [`dart-bindgen`](https://github.com/sunshine-protocol/dart-bindgen) which requires LLVM/Clang. Install LLVM (10+) in the following way:

#### ubuntu/linux

1. Install libclangdev - `sudo apt-get install libclang-dev`.

#### Windows

1. Install Visual Studio with C++ development support.
2. Install [LLVM](https://releases.llvm.org/download.html) or `winget install -e --id LLVM.LLVM`.

#### MacOS

1. Install Xcode.
2. Install LLVM - `brew install llvm`.

## Compile

### For development

**To reduce the compilation time of the Rust code** during your development, you can **compile only for the target corresponding to your android emulator**. Here is how to do it **depending on the architecture of your emulator**:

* 32bit emulator (`x86`/`i686` architecture)

```sh
cargo bd
```

* 64bit emulator (`x86_64` architecture)

```sh
cargo make android-dev
```

### For release

In the Root of the project simply run:

```sh
cargo br
```

WARNING: This will take a lot of time because the Rust code will have to be recompiled for each different architecture, 4 times for android and 2 times for iOS!

## Use

You must execute this instruction at startup of your application:

```dart
DubpRust.setup();
```

### Generate a random Mnemonic

#### Function signature

```dart
static Future<String> DubpRust.genMnemonic({Language language = Language.english});
```

#### Usage example

```dart
String mnemonic = await DubpRust.genMnemonic();
```

You can choose a language (english by default):

```dart
String mnemonic = await DubpRust.genMnemonic(language: Language.french);
```

### Generate a wallet

#### Function signature

```dart
static Future<NewWallet> genWalletFromMnemonic({
    String currency = "g1",
    Language language = Language.english,
    String mnemonic,
    SecretCodeType secretCodeType = SecretCodeType.letters
});
```

If the mnemonic is not in english, you must indicate the language of the mnemonic (necessary for the verification of its validity).
If the wallet to be generated is not dedicated to the Ğ1 currency, you must indicate the currency for which this wallet will be used.

#### Usage example

```dart
NewWallet new_wallet = await DubpRust.genWalletFromMnemonic(
    language: Language.english,
    mnemonic: "tongue cute mail fossil great frozen same social weasel impact brush kind"
);
```

You can choose a different secret code type:

```dart
NewWallet new_wallet = await DubpRust.genWalletFromMnemonic(
    language: Language.english,
    mnemonic: "tongue cute mail fossil great frozen same social weasel impact brush kind",
    secretCodeType: SecretCodeType.digits
);
```

### Sign a message

#### Function signature

```dart
static Future<String> signBip32Transparent({
    int accountIndex,
    String currency = "g1",
    String dewif,
    String secretCode,
    String message
});
```

If the wallet is not dedicated to the Ğ1 currency, you must indicate the currency.

#### Usage example

```dart
String signature = await DubpRust.signBip32Transparent(
    accountIndex: 3,
    dewif: "AAAAARAAAAGfFDAs+jVZYkfhBlHZZ2fEQIvBqnG16g5+02cY18wSOjW0cUg2JV3SUTJYN2CrbQeRDwGazWnzSFBphchMmiL0",
    pin: "CDJ4UB",
    message: "toto"
);
```

### Change secret code

You can change the secret code that encrypts the [DEWIF].

#### Function signature

```dart
static Future<NewWallet> changeDewifPin({
    String currency = "g1",
    String dewif,
    String oldPin,
    SecretCodeType secretCodeType = SecretCodeType.letters
});
```

If the wallet is not dedicated to the Ğ1 currency, you must indicate the currency.

#### Usage example

```dart
NewWallet new_wallet = await DubpRust.changeDewifPin(
    dewif: "AAAAARAAAAGfFDAs+jVZYkfhBlHZZ2fEQIvBqnG16g5+02cY18wSOjW0cUg2JV3SUTJYN2CrbQeRDwGazWnzSFBphchMmiL0",
    oldPin: "CDJAUB",
);
```

[dubp-rs-libs]: https://git.duniter.org/libs/dubp-rs-libs
[DEWIF]: https://git.duniter.org/documents/rfcs/blob/dewif/rfc/0013_Duniter_Encrypted_Wallet_Import_Format.md
