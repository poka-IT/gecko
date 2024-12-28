import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class Certifications extends StatelessWidget {
  const Certifications({super.key, required this.address, required this.size, this.color = Colors.black});
  final String address;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubstrateSdk>(context, listen: true);

    // Si on a les données en cache, on les affiche directement
    final cachedCerts = sub.certsCounterCache[address];
    if (cachedCerts != null && cachedCerts.isNotEmpty) {
      return _buildContent(cachedCerts[0], cachedCerts[1]);
    }

    // Sinon on utilise un FutureBuilder pour charger les données
    return FutureBuilder(
      future: sub.getCertsCounter(address),
      builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildContent(snapshot.data![0], snapshot.data![1]);
      },
    );
  }

  Widget _buildContent(int receivedCount, int sentCount) {
    return Row(
      children: [
        Image.asset('assets/medal.png', color: color, height: scaleSize(18)),
        ScaledSizedBox(width: 1),
        Text(receivedCount.toString(), style: scaledTextStyle(fontSize: size, color: color)),
        ScaledSizedBox(width: 5),
        Text(
          "($sentCount)",
          style: scaledTextStyle(fontSize: size * 0.7, color: color),
        )
      ],
    );
  }
}
