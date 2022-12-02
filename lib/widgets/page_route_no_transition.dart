import 'package:flutter/material.dart';

class PageNoTransit extends MaterialPageRoute {
  PageNoTransit({builder}) : super(builder: builder);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 0);
}
