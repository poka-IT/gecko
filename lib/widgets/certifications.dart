import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/certifications_cache_provider.dart';

class Certifications extends ConsumerStatefulWidget {
  const Certifications({super.key, required this.address, required this.size, this.color});
  final String address;
  final double size;
  final Color? color;

  @override
  ConsumerState<Certifications> createState() => _CertificationsState();
}

class _CertificationsState extends ConsumerState<Certifications> {
  @override
  void initState() {
    super.initState();
    // Trigger data fetch immediately on widget initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(certificationsCacheProvider.notifier).getCertificationData(widget.address);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the certification state for this address
    final certState = ref.watch(certificationDataProvider(widget.address));

    // If no data at all (first load), show shrink
    if (certState?.data == null) {
      return const SizedBox.shrink();
    }

    final finalColor = widget.color ?? Theme.of(context).colorScheme.onSecondaryContainer;

    return Row(
      children: [
        Image.asset('assets/medal.png', color: finalColor, height: scaleSize(18)),
        ScaledSizedBox(width: 1),
        Text(
          certState!.data!.receivedCount.toString(),
          style: scaledTextStyle(fontSize: widget.size, color: finalColor),
        ),
        ScaledSizedBox(width: 5),
        Text(
          "(${certState.data!.sentCount})",
          style: scaledTextStyle(fontSize: widget.size * 0.7, color: finalColor),
        ),
      ],
    );
  }
}
