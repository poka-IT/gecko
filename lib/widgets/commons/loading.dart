import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';

class Loading extends StatelessWidget {
  const Loading({super.key, this.size = 15, this.stroke = 2});

  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return ScaledSizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: stroke),
    );
  }
}
