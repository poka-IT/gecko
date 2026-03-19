import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/main.dart';
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

    final hasModifier = HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;
    final isSearchShortcut =
        (event.logicalKey == LogicalKeyboardKey.keyK && hasModifier) ||
        (event.logicalKey == LogicalKeyboardKey.keyF && hasModifier);

    if (isSearchShortcut) {
      _openPalette();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape && _dialogOpen) {
      final navCtx = Gecko.navigatorContext;
      if (navCtx != null) Navigator.of(navCtx, rootNavigator: true).maybePop();
      return true;
    }

    return false;
  }

  void _openPalette() {
    if (_dialogOpen || !mounted) return;
    final navCtx = Gecko.navigatorContext;
    if (navCtx == null) return;
    _dialogOpen = true;

    unawaited(
      showGeneralDialog<void>(
        context: navCtx,
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
