import 'package:durt2/durt2.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';

class Certifications extends StatefulWidget {
  const Certifications({super.key, required this.address, required this.size, this.color});
  final String address;
  final double size;
  final Color? color;

  @override
  State<Certifications> createState() => _CertificationsState();
}

class _CertificationsState extends State<Certifications> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Durt.i.storage.getCertsCounter(widget.address),
      builder: (context, certsCounter) {
        if (certsCounter.connectionState != ConnectionState.done || certsCounter.hasError || !certsCounter.hasData) {
          return const SizedBox.shrink();
        }
        return _buildContent(certsCounter.data!.receivedCount, certsCounter.data!.sentCount);
      },
    );
  }

  Widget _buildContent(int receivedCount, int sentCount) {
    final finalColor = widget.color ?? Theme.of(context).colorScheme.onSecondaryContainer;
    return Row(
      children: [
        Image.asset('assets/medal.png', color: finalColor, height: scaleSize(18)),
        ScaledSizedBox(width: 1),
        Text(
          receivedCount.toString(),
          style: scaledTextStyle(fontSize: widget.size, color: finalColor),
        ),
        ScaledSizedBox(width: 5),
        Text(
          "($sentCount)",
          style: scaledTextStyle(fontSize: widget.size * 0.7, color: finalColor),
        ),
      ],
    );
  }
}
