import 'package:flutter/material.dart';

class FaderTransition extends PageRouteBuilder {
  final Widget page;
  final bool isFast;

  FaderTransition({required this.page, required this.isFast})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              FadeTransition(
            opacity:
                Tween(begin: 0.0, end: isFast ? 3.0 : 1.0).animate(animation),
            child: child,
          ),
        );
}