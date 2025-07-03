import 'package:durt2/durt2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers.dart';

class CertsCounter extends ConsumerWidget {
  const CertsCounter({super.key, required this.address, this.isSent = false});
  final String address;
  final bool isSent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = ref.watch(storageServiceProvider);
    return FutureBuilder<CertificationData>(
      future: storageService.getCertsCounter(address),
      builder: (context, certsCounter) {
        if (certsCounter.connectionState != ConnectionState.done || certsCounter.hasError || !certsCounter.hasData) {
          return const SizedBox.shrink();
        }
        return Text(
          '(${isSent ? certsCounter.data!.sentCount : certsCounter.data!.receivedCount})',
          style: scaledTextStyle(fontSize: 16),
        );
      },
    );
  }
}
