import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/widgets/global_search_palette_dialog.dart';

class GlobalSearchShortcutScope extends StatefulWidget {
  const GlobalSearchShortcutScope({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalSearchShortcutScope> createState() => _GlobalSearchShortcutScopeState();
}

class _GlobalSearchShortcutScopeState extends State<GlobalSearchShortcutScope> {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final isSearchShortcut =
        event.logicalKey == LogicalKeyboardKey.keyK &&
        (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed);

    if (isSearchShortcut) {
      _openPalette();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape && _dialogOpen) {
      Navigator.of(homeContext, rootNavigator: true).maybePop();
      return true;
    }

    return false;
  }

  void _openPalette() {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;
    final navigatorContext = homeContext;

    unawaited(
      showGeneralDialog<void>(
        context: navigatorContext,
        useRootNavigator: true,
        barrierLabel: 'global_search',
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 0),
        pageBuilder: (context, animation, secondaryAnimation) => const GlobalSearchPaletteDialog(),
      ).whenComplete(() {
        _dialogOpen = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
