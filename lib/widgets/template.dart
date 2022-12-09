import 'package:flutter/material.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemplateWidget extends ConsumerWidget {
  const TemplateWidget(
      {Key? key, required this.address, this.color = Colors.black})
      : super(key: key);
  final String address;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return const Text('Hello Widget');
    });
  }
}
