import 'package:flutter/material.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class TemplateWidget extends StatelessWidget {
  const TemplateWidget(
      {super.key, required this.address, this.color = Colors.black});
  final String address;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return const Text('Hello Widget');
    });
  }
}
