import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';

class OfflineInfo extends ConsumerWidget {
  const OfflineInfo({super.key, this.forceHide = false});

  final bool forceHide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the connection status using the StateNotifierProvider
    final connectionStatus = ref.watch(connectionStatusProvider);

    // Since this is now a direct value, we don't need .when()
    final isConnected = connectionStatus == d.ConnectionStatus.connected;
    final shouldHide = isConnected || forceHide;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(sizeFactor: animation, child: child),
        );
      },
      child: shouldHide
          ? const SizedBox.shrink(key: ValueKey('hidden'))
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              color: Colors.orange,
              padding: const EdgeInsets.all(4),
              child: Text(
                'offline'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
    );
  }
}
