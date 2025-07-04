import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';

class OfflineInfo extends ConsumerWidget {
  const OfflineInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the connection status using the StateNotifierProvider
    final connectionStatus = ref.watch(connectionStatusProvider);

    // Since this is now a direct value, we don't need .when()
    final isConnected = connectionStatus == d.ConnectionStatus.connected;

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
  }
}
