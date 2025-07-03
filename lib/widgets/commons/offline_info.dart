import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';

class OfflineInfo extends ConsumerWidget {
  const OfflineInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the connection status stream.
    // The widget will rebuild only when the status changes.
    final connectionStatus = ref.watch(connectionStatusProvider);

    // .when is the standard way to handle async providers in Riverpod
    return connectionStatus.when(
      data: (status) {
        final isConnected = status == d.ConnectionStatus.connected;
        return Visibility(
          visible: !isConnected,
          child: Container(
            width: double.infinity,
            color: Colors.orange,
            padding: const EdgeInsets.all(4),
            child: Text(
              'offline'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
      // While connecting, we don't show anything.
      loading: () => const SizedBox.shrink(),
      // In case of an error with the stream itself, we show nothing.
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
