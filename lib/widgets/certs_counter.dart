import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers.dart';

class CertsCounter extends ConsumerWidget {
  const CertsCounter({super.key, required this.address, this.isSent = false});
  final String address;
  final bool isSent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certificationStream = ref.watch(smartCertificationStreamProvider(address));

    return certificationStream.when(
      data: (certsCounter) {
        return Text(
          '(${isSent ? certsCounter.sentCount : certsCounter.receivedCount})',
          style: scaledTextStyle(fontSize: 16),
        );
      },
      error: (error, stackTrace) {
        log.e('❌ Certifications widget error for $address: $error');
        return const SizedBox.shrink();
      },
      loading: () {
        return const SizedBox.shrink();
      },
    );
  }
}
