import 'package:flutter/material.dart';

class PageNoTransit extends MaterialPageRoute {
  PageNoTransit({required super.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 0);
}
