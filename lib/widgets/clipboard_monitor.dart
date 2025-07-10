import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:provider/provider.dart';

class ClipboardMonitor extends ChangeNotifier {
  String? _lastClipboardContent;
  Timer? _debounceTimer;
  final searchProvider = Provider.of<SearchProvider>(homeContext, listen: false);

  void startMonitoring() {
    _checkClipboard();
  }

  void _checkClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final newContent = clipboardData?.text;

    if (newContent != null && newContent != _lastClipboardContent) {
      _lastClipboardContent = newContent;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        if (isAddress(newContent)) {
          searchProvider.pastedAddress = newContent;
          searchProvider.canPasteAddress = true;
          searchProvider.reload();
        } else {
          searchProvider.pastedAddress = '';
          searchProvider.canPasteAddress = false;
          searchProvider.reload();
        }
      });
    }

    Future.delayed(const Duration(seconds: 1), _checkClipboard);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchProvider.canPasteAddress = false;
    super.dispose();
  }
}
