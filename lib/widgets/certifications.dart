import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/globals.dart';

class Certifications extends ConsumerWidget {
  const Certifications({super.key, required this.address, required this.size, this.color});
  final String address;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the smart certification provider that automatically chooses between persistent and auto-dispose
    final certificationStream = ref.watch(smartCertificationStreamProvider(address));

    return certificationStream.when(
      data: (certData) {
        final finalColor = color ?? Theme.of(context).colorScheme.onSecondaryContainer;

        return Row(
          children: [
            Image.asset('assets/medal.png', color: finalColor, height: scaleSize(18)),
            ScaledSizedBox(width: 1),
            Text(
              certData.receivedCount.toString(),
              style: scaledTextStyle(fontSize: size, color: finalColor),
            ),
            ScaledSizedBox(width: 5),
            Text(
              "(${certData.sentCount})",
              style: scaledTextStyle(fontSize: size * 0.7, color: finalColor),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        log.e('❌ Certifications widget error for $address: $error');
        return const SizedBox.shrink();
      },
    );
  }
}
