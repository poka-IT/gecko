import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class Certifications extends StatefulWidget {
  const Certifications({super.key, required this.address, required this.size, this.color = Colors.black});
  final String address;
  final double size;
  final Color color;

  @override
  State<Certifications> createState() => _CertificationsState();
}

class _CertificationsState extends State<Certifications> {
  bool _isLoading = false;

  Future<void> _checkNetworkData(SubstrateSdk sdk) async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final networkData = await sdk.getCertsCounter(widget.address);
      if (!mounted) return;

      final cachedData = sdk.certsCounterCache[widget.address];
      if (cachedData == null || cachedData.isEmpty || networkData[0] != cachedData[0] || networkData[1] != cachedData[1]) {
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
        // Afficher les données du cache immédiatement si disponibles
        final cachedCerts = sdk.certsCounterCache[widget.address];

        // Vérifier les données réseau en arrière-plan
        if (!_isLoading) {
          Future.microtask(() => _checkNetworkData(sdk));
        }

        // Si pas de données en cache, on affiche rien en attendant
        if (cachedCerts == null || cachedCerts.isEmpty) {
          return const SizedBox.shrink();
        }

        // Afficher les données du cache
        return _buildContent(cachedCerts[0], cachedCerts[1]);
      },
    );
  }

  Widget _buildContent(int receivedCount, int sentCount) {
    return Row(
      children: [
        Image.asset('assets/medal.png', color: widget.color, height: scaleSize(18)),
        ScaledSizedBox(width: 1),
        Text(receivedCount.toString(), style: scaledTextStyle(fontSize: widget.size, color: widget.color)),
        ScaledSizedBox(width: 5),
        Text(
          "($sentCount)",
          style: scaledTextStyle(fontSize: widget.size * 0.7, color: widget.color),
        )
      ],
    );
  }
}
