import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';

/// Observer class that forwards lifecycle events to the notifier.
/// Same pattern as _BottomAppBarObserver in bottom_app_bar_provider.dart.
class _AppLifecycleObserver with WidgetsBindingObserver {
  final AppLifecycleNotifier notifier;
  bool _isDisposed = false;

  _AppLifecycleObserver(this.notifier) {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    notifier._onLifecycleChanged(state);
  }
}

/// Notifier that observes app lifecycle and triggers WebSocket reconnection
/// when the app returns from background after a significant pause.
class AppLifecycleNotifier extends Notifier<AppLifecycleState> {
  _AppLifecycleObserver? _observer;
  DateTime? _pausedAt;
  bool _isReconnecting = false;

  static const _backgroundThreshold = Duration(seconds: 10);

  @override
  AppLifecycleState build() {
    _observer = _AppLifecycleObserver(this);
    ref.onDispose(() => _observer?.dispose());
    return AppLifecycleState.resumed;
  }

  void _onLifecycleChanged(AppLifecycleState lifecycleState) {
    state = lifecycleState;

    if (lifecycleState == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      _handleResumed();
    }
  }

  void _handleResumed() {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;

    final elapsed = DateTime.now().difference(pausedAt);
    _pausedAt = null;

    if (elapsed >= _backgroundThreshold) {
      log.i('App resumed after ${elapsed.inSeconds}s in background, triggering reconnection');
      _triggerReconnection();
    }
  }

  Future<void> _triggerReconnection() async {
    if (_isReconnecting) return;
    _isReconnecting = true;

    try {
      final durt = ref.read(durtProvider);
      durt.resetConnectionStatus();
      await durt.connect(verbose: false);
    } catch (e) {
      log.e('Error during lifecycle reconnection: $e');
    } finally {
      _isReconnecting = false;
    }
  }
}

/// Provider that monitors app lifecycle and triggers WebSocket reconnection
/// after returning from background. Must be watched at the root level.
final appLifecycleProvider = NotifierProvider<AppLifecycleNotifier, AppLifecycleState>(AppLifecycleNotifier.new);
