import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/widgets/commons/shimmer_placeholder.dart';
import 'package:gecko/globals.dart';

class Certifications extends ConsumerWidget {
  const Certifications({super.key, required this.address, required this.size, this.color});
  final String address;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finalColor = color ?? Theme.of(context).colorScheme.onSecondaryContainer;

    // Use hybrid provider that combines streams with polling for reliable live updates
    final certificationAsync = ref.watch(hybridCertificationProvider(address));

    return certificationAsync.when(
      data: (certData) {
        return _buildCertificationsRow(certData.receivedCount, certData.sentCount, finalColor);
      },
      loading: () => ShimmerPlaceholder(
        width: scaleSize(50),
        height: scaleSize(size * 1.2),
        baseColor: finalColor,
      ),
      error: (error, stack) {
        log.e('❌ Certifications widget error for $address: $error');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCertificationsRow(int receivedCount, int sentCount, Color finalColor) {
    return Row(
      children: [
        Image.asset('assets/medal.png', color: finalColor, height: scaleSize(18)),
        ScaledSizedBox(width: 1),
        Text(
          receivedCount.toString(),
          style: scaledTextStyle(fontSize: size, color: finalColor),
        ),
        ScaledSizedBox(width: 5),
        Text(
          "($sentCount)",
          style: scaledTextStyle(fontSize: size * 0.7, color: finalColor),
        ),
      ],
    );
  }
}
