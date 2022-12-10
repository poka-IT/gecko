import 'package:flutter/material.dart';

class SmoothTransition extends PageRouteBuilder {
  final Widget page;
  SmoothTransition({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              TweenAnimationBuilder(
            duration: const Duration(seconds: 5),
            tween: Tween(begin: 200, end: 200),
            builder: (BuildContext context, dynamic value, Widget? child) {
              return page;
            },
          ),
        );
}
