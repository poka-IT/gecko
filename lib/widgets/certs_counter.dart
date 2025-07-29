import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';

class CertsCounter extends ConsumerWidget {
  const CertsCounter({super.key, required this.address, this.isSent = false});
  final String address;
  final bool isSent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certificationStream = ref.watch(smartCertificationStreamProvider(address));

    return certificationStream.when(
      data: (certsCounter) {
        final count = isSent ? certsCounter.sentCount : certsCounter.receivedCount;

        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(6), vertical: scaleSize(3)),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(scaleSize(12)),
            border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            count.toString(),
            style: scaledTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colorScheme.primary),
          ),
        );
      },
      error: (error, stackTrace) {
        log.e('❌ Certifications widget error for $address: $error');
        return const SizedBox.shrink();
      },
      loading: () {
        return SizedBox(
          width: scaleSize(16),
          height: scaleSize(16),
          child: CircularProgressIndicator(strokeWidth: 2, color: context.colorScheme.primary.withValues(alpha: 0.6)),
        );
      },
    );
  }
}
