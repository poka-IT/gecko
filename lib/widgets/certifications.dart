import 'package:durt2/durt2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers.dart';

class Certifications extends ConsumerWidget {
  const Certifications({super.key, required this.address, required this.size, this.color});
  final String address;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<CertificationData>(
      future: ref.watch(storageServiceProvider).getCertsCounter(address),
      builder: (BuildContext context, AsyncSnapshot<CertificationData> certsCounter) {
        if (certsCounter.connectionState != ConnectionState.done || certsCounter.hasError || !certsCounter.hasData) {
          return const SizedBox.shrink();
        }

        final finalColor = color ?? Theme.of(context).colorScheme.onSecondaryContainer;

        return Row(
          children: [
            Image.asset('assets/medal.png', color: finalColor, height: scaleSize(18)),
            ScaledSizedBox(width: 1),
            Text(
              certsCounter.data!.receivedCount.toString(),
              style: scaledTextStyle(fontSize: size, color: finalColor),
            ),
            ScaledSizedBox(width: 5),
            Text(
              "(${certsCounter.data!.sentCount})",
              style: scaledTextStyle(fontSize: size * 0.7, color: finalColor),
            ),
          ],
        );
      },
    );
  }
}
