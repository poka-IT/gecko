import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/providers/providers.dart';

/// Search state model
class SearchState {
  final String searchText;
  final bool canPasteAddress;
  final String pastedAddress;

  const SearchState({this.searchText = '', this.canPasteAddress = false, this.pastedAddress = ''});

  SearchState copyWith({String? searchText, bool? canPasteAddress, String? pastedAddress}) {
    return SearchState(
      searchText: searchText ?? this.searchText,
      canPasteAddress: canPasteAddress ?? this.canPasteAddress,
      pastedAddress: pastedAddress ?? this.pastedAddress,
    );
  }

  bool get canValidate => searchText.length >= 2;
}

/// Notifier for search text state
class SearchTextNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

/// Search text state provider
final searchTextProvider = NotifierProvider<SearchTextNotifier, String>(SearchTextNotifier.new);

/// Notifier for paste address state
class PasteAddressNotifier extends Notifier<({bool canPaste, String address})> {
  @override
  ({bool canPaste, String address}) build() => (canPaste: false, address: '');

  void set(({bool canPaste, String address}) value) => state = value;
  void clear() => state = (canPaste: false, address: '');
}

/// Paste address state provider
final pasteAddressProvider = NotifierProvider<PasteAddressNotifier, ({bool canPaste, String address})>(
  PasteAddressNotifier.new,
);

/// Search controller provider
final searchControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();

  // Listen to changes and update the search text provider
  controller.addListener(() {
    ref.read(searchTextProvider.notifier).set(controller.text);
  });

  // Cleanup when provider is disposed
  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

/// Clear search function provider
final clearSearchProvider = Provider<VoidCallback>((ref) {
  return () {
    final controller = ref.read(searchControllerProvider);
    controller.clear();
    ref.read(searchTextProvider.notifier).clear();
  };
});

/// Address validation function provider
final _isValidAddressProvider = Provider<bool Function(String)>((ref) {
  return (String input) {
    try {
      final utils = ref.read(utilsProvider);
      return utils.isAddressValid(input);
    } catch (e) {
      return false;
    }
  };
});

/// Public key validation function provider
final _isValidPubkeyProvider = Provider<bool Function(String)>((ref) {
  return (String input) {
    final cleanInput = input.split(':')[0];
    final regExp = RegExp(r'^[a-zA-Z0-9]+$', caseSensitive: false, multiLine: false);
    return regExp.hasMatch(cleanInput) && cleanInput.length > 42 && cleanInput.length < 45;
  };
});

/// Convert input to address provider
final _convertToAddressProvider = Provider<String? Function(String)>((ref) {
  return (String input) {
    final utils = ref.read(utilsProvider);
    final isValidAddress = ref.read(_isValidAddressProvider);
    final isValidPubkey = ref.read(_isValidPubkeyProvider);

    input = input.trim().split(':')[0];

    try {
      if (isValidAddress(input)) {
        return utils.isAddressValidToSs58(input);
      } else if (isValidPubkey(input)) {
        return utils.pubkeyV1ToAddress(input);
      }
      return null;
    } catch (e) {
      return null;
    }
  };
});

/// Search results provider - automatically reacts to search text changes
final searchResultsProvider = FutureProvider<List<G1WalletsList>>((ref) async {
  final searchText = ref.watch(searchTextProvider).trim();

  // If search text is empty or too short, return empty list
  if (searchText.isEmpty || searchText.length < 2) {
    return [];
  }

  final convertToAddress = ref.read(_convertToAddressProvider);
  final address = convertToAddress(searchText);

  // If conversion failed, return empty list
  if (address == null) {
    return [];
  }

  // Return the wallet result
  return [G1WalletsList(address: address)];
});

/// Combined search state provider (for backwards compatibility if needed)
final searchStateProvider = Provider<SearchState>((ref) {
  final searchText = ref.watch(searchTextProvider);
  final pasteState = ref.watch(pasteAddressProvider);

  return SearchState(searchText: searchText, canPasteAddress: pasteState.canPaste, pastedAddress: pasteState.address);
});

/// Update paste address capability
final updatePasteAddressProvider = Provider<void Function(bool, String)>((ref) {
  return (bool canPaste, String address) {
    ref.read(pasteAddressProvider.notifier).set((canPaste: canPaste, address: address));
  };
});

/// Clipboard listener that uses native OS notifications instead of polling.
/// This avoids blocking the main thread on iOS (UIPasteboard semaphore).
class _ClipboardChangeListener with ClipboardListener {
  final void Function() onChanged;
  _ClipboardChangeListener(this.onChanged);

  @override
  void onClipboardChanged() => onChanged();
}

/// Clipboard monitoring state notifier using clipboard_watcher (native notifications).
class ClipboardMonitorNotifier extends Notifier<String?> {
  _ClipboardChangeListener? _listener;

  @override
  String? build() {
    _listener = _ClipboardChangeListener(_onClipboardChanged);
    clipboardWatcher.addListener(_listener!);
    clipboardWatcher.start();

    ref.onDispose(() {
      if (_listener != null) {
        clipboardWatcher.removeListener(_listener!);
      }
      clipboardWatcher.stop();
    });

    // Check clipboard once at init (on search screen open)
    _onClipboardChanged();
    return null;
  }

  void _onClipboardChanged() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final newContent = clipboardData?.text;
      if (newContent != null && newContent != state) {
        state = newContent;
        _processClipboardContent(newContent);
      }
    } catch (e) {
      // Clipboard access may fail (e.g. permission denied on iOS 16+)
    }
  }

  void _processClipboardContent(String content) {
    final updatePasteAddress = ref.read(updatePasteAddressProvider);
    final isValidAddress = ref.read(_isValidAddressProvider);
    final isValidPubkey = ref.read(_isValidPubkeyProvider);
    final convertToAddress = ref.read(_convertToAddressProvider);

    try {
      if (isValidAddress(content)) {
        final utils = ref.read(utilsProvider);
        final address = utils.isAddressValidToSs58(content);
        updatePasteAddress(true, address);
      } else if (isValidPubkey(content)) {
        final address = convertToAddress(content);
        if (address != null) {
          updatePasteAddress(true, address);
        } else {
          updatePasteAddress(false, '');
        }
      } else {
        updatePasteAddress(false, '');
      }
    } catch (e) {
      updatePasteAddress(false, '');
    }
  }
}

/// Clipboard monitoring provider
final clipboardMonitorProvider = NotifierProvider<ClipboardMonitorNotifier, String?>(ClipboardMonitorNotifier.new);

/// Provider to start clipboard monitoring (call this to initialize)
final startClipboardMonitoringProvider = Provider<void>((ref) {
  ref.watch(clipboardMonitorProvider);
  return;
});
