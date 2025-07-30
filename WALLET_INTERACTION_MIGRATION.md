# Wallet Interaction Migration Guide

This guide explains how to migrate from the old `WalletsProfilesProvider` to the new Riverpod-based providers and services.

## Overview

The old `WalletsProfilesProvider` has been split into multiple specialized services and providers following Riverpod best practices:

### New Services (in `lib/services/`)
- **`QrScannerService`** - Handles QR code scanning with permissions and validation
- **`ContactService`** - Manages contact operations (add/remove/check)
- **`IdenticonService`** - Generates SVG identicons for avatars
- **`SnackbarService`** - Provides consistent snackbar styling and behavior

### New Providers (in `lib/providers/wallet_interaction_providers.dart`)
- **`walletInteractionProvider`** - State management for payment forms and comments
- **`payAmountControllerProvider`** - TextEditingController for payment amounts
- **`payCommentControllerProvider`** - TextEditingController for payment comments
- **`qrScanProvider`** - QR scanning functionality
- **`identiconProvider`** - Identicon generation
- **`isContactProvider`** - Check if address is a contact
- **`toggleContactProvider`** - Add/remove contacts
- **`copyAddressProvider`** - Copy address with snackbar
- **`copyMnemonicProvider`** - Copy mnemonic with snackbar
- **`showSnackbarProvider`** - General snackbar messages

## Migration Examples

### 1. State Management

**Before:**
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late WalletsProfilesProvider walletsProvider;

  @override
  void initState() {
    super.initState();
    walletsProvider = WalletsProfilesProvider('someAddress');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: walletsProvider.payAmount,
      onChanged: (value) => walletsProvider.notifyListeners(),
    );
  }
}
```

**After:**
```dart
class MyWidget extends ConsumerWidget {
  final String? address;
  
  const MyWidget({this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payAmountController = ref.watch(payAmountControllerProvider(address));
    final interaction = ref.watch(walletInteractionProvider(address));
    
    return TextField(
      controller: payAmountController,
      // State automatically syncs - no manual notifyListeners needed
    );
  }
}
```

### 2. QR Code Scanning

**Before:**
```dart
walletsProvider.scan(context);
```

**After:**
```dart
final scanQr = ref.read(qrScanProvider);
await scanQr(context);
```

### 3. Contact Management

**Before:**
```dart
await walletsProvider.addContact(profile);
```

**After:**
```dart
final toggleContact = ref.read(toggleContactProvider);
await toggleContact(profile, context);
```

### 4. Identicon Generation

**Before:**
```dart
final svg = walletsProvider.generateIdenticon(pubkey);
```

**After:**
```dart
final svg = ref.watch(identiconProvider(pubkey));
```

### 5. Contact Check

**Before:**
```dart
final isContact = walletsProvider.isContact(address);
```

**After:**
```dart
final isContact = ref.watch(isContactProvider(address));
```

### 6. Snackbar Messages

**Before:**
```dart
snackMessage(context, message: 'Hello World');
snackCopyKey(context);
snackCopySeed(context);
```

**After:**
```dart
final showSnackbar = ref.read(showSnackbarProvider);
showSnackbar(context, 'Hello World');

final copyAddress = ref.read(copyAddressProvider);
copyAddress(context);

final copyMnemonic = ref.read(copyMnemonicProvider);
copyMnemonic(context);
```

### 7. Comment Visibility Toggle

**Before:**
```dart
walletsProvider.toggleCommentVisibility();
```

**After:**
```dart
ref.read(walletInteractionProvider(address).notifier).toggleCommentVisibility();
```

## Key Benefits

1. **Separation of Concerns**: Business logic separated into services
2. **Better Testability**: Services can be tested independently
3. **Reactive State**: Automatic UI updates when state changes
4. **Type Safety**: Better type safety with Riverpod
5. **Performance**: Automatic optimization and caching
6. **Family Providers**: Support for multiple wallet addresses simultaneously

## Utility Functions

The utility functions are now deprecated. Use the utils service directly:

**Before:**
```dart
bool valid = isAddress(address);
String ss58 = isAddressValidToSs58(address);
bool isPubkey = isPubkey(input);
```

**After:**
```dart
final utils = ref.read(utilsProvider);
bool valid = utils.isAddressValid(address);
String ss58 = utils.isAddressValidToSs58(address);
// Use the pubkey validation from QrScannerService if needed
```

## Notes

- The old `WalletsProfilesProvider` file is kept for backward compatibility but marked as deprecated
- All new code should use the new providers and services
- The migration maintains the same functionality while improving architecture
- State is automatically managed and persisted across widget rebuilds