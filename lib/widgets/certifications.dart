import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/safe_data_provider.dart';
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

    // Try to get certifications from centralized safe data first (for owned wallets)
    final isOwnedWallet = ref.watch(isWalletInCurrentSafeProvider(address));

    if (isOwnedWallet) {
      // Use centralized batch-loaded data for owned wallets
      final safeCert = ref.watch(safeWalletCertProvider(address));

      return ShimmerToContent(
        isLoading: safeCert == null,
        shimmerWidth: scaleSize(50),
        shimmerHeight: scaleSize(size * 1.2),
        shimmerColor: finalColor,
        child: safeCert != null
            ? _buildCertificationsRow(safeCert.receivedCount, safeCert.sentCount, finalColor)
            : const SizedBox.shrink(),
      );
    }

    // Fallback to stream provider for external wallets
    final certificationStream = ref.watch(smartCertificationStreamProvider(address));

    return certificationStream.when(
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
