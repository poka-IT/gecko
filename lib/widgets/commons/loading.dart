import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

class Loading extends StatelessWidget {
  const Loading({
    Key? key,
    this.size = 15,
    this.stroke = 2,
  }) : super(key: key);

  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        color: orangeC,
        strokeWidth: stroke,
      ),
    );
  }
}
