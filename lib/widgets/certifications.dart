import 'package:durt2/durt2.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class Certifications extends StatefulWidget {
  const Certifications({super.key, required this.address, required this.size, this.color});
  final String address;
  final double size;
  final Color? color;

  @override
  State<Certifications> createState() => _CertificationsState();
}

class _CertificationsState extends State<Certifications> {
  bool _isLoading = false;

  Future<void> _checkNetworkData(SubstrateSdk sdk) async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final networkData = await Durt.i.storage.getCertsCounter(widget.address);
      if (!mounted) return;

      final cachedData = sdk.certsCounterCache[widget.address];
      if (cachedData == null || !cachedData.equals(networkData)) {
        sdk.certsCounterCache[widget.address] = networkData;
        setState(() {});
      }
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubstrateSdk>(
      builder: (context, sdk, _) {
        // Display cached data immediately if available
        final cachedCerts = sdk.certsCounterCache[widget.address];

        // Check network data in the background
        if (!_isLoading) {
          Future.microtask(() => _checkNetworkData(sdk));
        }

        // If no cached data, show nothing while waiting
        if (cachedCerts == null) {
          return const SizedBox.shrink();
        }

        // Display cached data
        return _buildContent(cachedCerts.receivedCount, cachedCerts.sentCount);
      },
    );
  }

  Widget _buildContent(int receivedCount, int sentCount) {
    final finalColor = widget.color ?? Theme.of(context).colorScheme.onSecondaryContainer;
    return Row(
      children: [
        Image.asset('assets/medal.png', color: finalColor, height: scaleSize(18)),
        ScaledSizedBox(width: 1),
        Text(receivedCount.toString(), style: scaledTextStyle(fontSize: widget.size, color: finalColor)),
        ScaledSizedBox(width: 5),
        Text(
          "($sentCount)",
          style: scaledTextStyle(fontSize: widget.size * 0.7, color: finalColor),
        )
      ],
    );
  }
}
