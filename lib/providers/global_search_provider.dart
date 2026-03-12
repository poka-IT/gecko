import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef DesktopSearchHandler = FutureOr<bool> Function();

class GlobalSearchState {
  final bool isOverlayOpen;

  const GlobalSearchState({this.isOverlayOpen = false});

  GlobalSearchState copyWith({bool? isOverlayOpen}) {
    return GlobalSearchState(isOverlayOpen: isOverlayOpen ?? this.isOverlayOpen);
  }
}

class GlobalSearchNotifier extends Notifier<GlobalSearchState> {
  DesktopSearchHandler? _desktopSearchHandler;

  @override
  GlobalSearchState build() => const GlobalSearchState();

  void registerDesktopSearchHandler(DesktopSearchHandler handler) {
    _desktopSearchHandler = handler;
  }

  void unregisterDesktopSearchHandler(DesktopSearchHandler handler) {
    _desktopSearchHandler = null;
  }

  void clearDesktopSearchHandler() {
    _desktopSearchHandler = null;
  }

  Future<void> handleShortcut() async {
    final handler = _desktopSearchHandler;
    if (handler != null) {
      final handled = await handler();
      if (handled) {
        closeOverlay();
        return;
      }
    }

    openOverlay();
  }

  void openOverlay() {
    state = state.copyWith(isOverlayOpen: true);
  }

  void closeOverlay() {
    if (!state.isOverlayOpen) return;
    state = state.copyWith(isOverlayOpen: false);
  }
}

final globalSearchProvider = NotifierProvider<GlobalSearchNotifier, GlobalSearchState>(GlobalSearchNotifier.new);
