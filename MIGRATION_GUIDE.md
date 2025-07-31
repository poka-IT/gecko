# Migration Guide: GenerateWalletsProvider to Riverpod

This guide explains how to migrate from the deprecated `GenerateWalletsProvider` to the new Riverpod-based wallet generation system.

## Overview

The old `GenerateWalletsProvider` has been split into multiple services and providers following Riverpod best practices:

- **Services** (pure logic, no state): `MnemonicService`, `WalletScanService`
- **Providers** (state management): `mnemonic_providers.dart`, `wallet_scan_providers.dart`

## Key Changes

### 1. Import Changes

**Old:**
```dart
import 'package:gecko/providers_deprecated/generate_wallets.dart';
import 'package:provider/provider.dart' as old_provider;
```

**New:**
```dart
import 'package:gecko/providers/wallet_generation_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

### 2. Widget Changes

**Old:**
```dart
class MyWidget extends StatefulWidget {
  // ...
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final generateWalletProvider = old_provider.Provider.of<GenerateWalletsProvider>(context);
    // ...
  }
}
```

**New:**
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonicState = ref.watch(mnemonicStateProvider);
    final scanState = ref.watch(walletScanProvider);
    // ...
  }
}
```

## Migration Mappings

### Mnemonic Generation

**Old:**
```dart
generateWalletProvider.generateWordList(context);
String mnemonic = generateWalletProvider.generatedMnemonic;
String englishMnemonic = generateWalletProvider.getEnglishMnemonic();
```

**New:**
```dart
// Generate mnemonic
await ref.read(mnemonicStateProvider.notifier).generateMnemonic(
  targetLanguage: BidouilleLang.fromLanguageCode(context.locale.languageCode),
);

// Access mnemonic
final mnemonicState = ref.watch(mnemonicStateProvider);
String displayMnemonic = mnemonicState.mnemonicResult?.displayMnemonic ?? '';
String englishMnemonic = mnemonicState.mnemonicResult?.englishMnemonic ?? '';
```

### Mnemonic Input Validation

**Old:**
```dart
final controllers = [
  generateWalletProvider.cellController0,
  generateWalletProvider.cellController1,
  // ... up to cellController11
];

bool isComplete = await generateWalletProvider.isSentenceComplete();
```

**New:**
```dart
final controllers = ref.watch(mnemonicControllersProvider);
final inputState = ref.watch(mnemonicInputProvider);

bool isComplete = inputState.isComplete;
bool isValid = inputState.isValid;
```

### Word Challenge Validation

**Old:**
```dart
int wordIndex = generateWalletProvider.nbrWord;
String wordPosition = generateWalletProvider.nbrWordAlpha;
bool isValid = generateWalletProvider.isAskedWordValid;
Color? wordColor = generateWalletProvider.askedWordColor;

generateWalletProvider.checkAskedWord(inputValue, mnemonic);
```

**New:**
```dart
final challenge = ref.watch(wordValidationChallengeProvider);
final challengeState = ref.watch(wordChallengeProvider);

int wordIndex = challenge?.wordIndex ?? 0;
String wordPosition = challenge?.wordPosition ?? '';
bool isValid = challengeState.isValid;
Color? wordColor = challengeState.inputColor;

ref.read(wordChallengeProvider.notifier).checkWord(inputValue, expectedWord);
```

### Derivation Scanning

**Old:**
```dart
ScanDerivationsResult result = await generateWalletProvider.scanDerivations(context);

// Status monitoring
ScanDerivationsStatus status = generateWalletProvider.scanStatus;
int scannedCount = generateWalletProvider.scanedWalletNumber;
int validCount = generateWalletProvider.scanedValidWalletNumber;
```

**New:**
```dart
final mnemonicResult = await ref.read(mnemonicInputProvider.notifier).getValidatedMnemonic();
ScanDerivationsResult result = await ref.read(startScanProvider)(context, mnemonicResult!);

// Status monitoring
final scanState = ref.watch(walletScanProvider);
WalletScanStatus status = scanState.status;
int scannedCount = scanState.scannedWalletCount;
int validCount = scanState.validWalletCount;
```

### Cleanup and Reset

**Old:**
```dart
generateWalletProvider.resetImportView();
generateWalletProvider.isAskedWordValid = false;
generateWalletProvider.askedWordColor = Colors.black;
```

**New:**
```dart
ref.read(clearMnemonicInputProvider)();
ref.read(wordChallengeProvider.notifier).reset();
ref.read(resetMnemonicStateProvider)();
```

## Example Migrations

### 1. Mnemonic Display Screen (onBoarding/6.dart)

See: `gecko/lib/screens/onBoarding/6_migrated.dart`

Key changes:
- Convert to `ConsumerStatefulWidget`
- Use `wordValidationChallengeProvider` for challenge generation
- Use `wordChallengeProvider` for validation state

### 2. Mnemonic Input Screen (restore_safe.dart)

See: `gecko/lib/screens/myWallets/restore_safe_migrated.dart`

Key changes:
- Use `mnemonicControllersProvider` for input controllers
- Use `mnemonicInputProvider` for validation state
- Use `pasteMnemonicProvider` for clipboard functionality

### 3. Scan Progress Widget (scan_derivations_info.dart)

See: `gecko/lib/widgets/scan_derivations_info_migrated.dart`

Key changes:
- Use `scanDisplayInfoProvider` for consolidated scan information
- Better progress indication with `scanProgressProvider`

## Best Practices

1. **Use ConsumerWidget/ConsumerStatefulWidget** instead of StatefulWidget
2. **Read providers with ref.watch()** for reactive UI updates
3. **Modify state with ref.read().notifier** for actions
4. **Prefer specific providers** over monolithic state (e.g., use `wordChallengeProvider` instead of accessing everything through one provider)
5. **Use services directly** for one-off operations that don't need state management

## Benefits of the New System

1. **Better separation of concerns**: Services handle logic, providers handle state
2. **More granular reactivity**: Only rebuild what changes
3. **Better testability**: Services are pure functions, easier to test
4. **Type safety**: Better compile-time checking with Riverpod
5. **Memory efficiency**: Automatic cleanup when providers are no longer used
6. **Consistent patterns**: Follows Riverpod best practices used throughout the app

## Notes

- The old `GenerateWalletsProvider` is kept in `providers_deprecated/` for compatibility during migration
- All new functionality should use the new Riverpod providers
- Gradual migration is possible - old and new systems can coexist temporarily