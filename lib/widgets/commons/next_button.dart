import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/routes.dart';

class NextButton extends StatelessWidget {
  const NextButton({
    super.key,
    required this.text,
    required this.nextScreen,
    required this.isFast,
    this.routeArguments,
  });

  final String text;
  final String nextScreen;
  final bool isFast;
  final RouteArguments? routeArguments;

  @override
  Widget build(BuildContext context) {
    return ScaledSizedBox(
      width: 340,
      height: 55,
      child: ElevatedButton(
        key: keyGoNext,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: context.colorScheme.primary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
        ),
        onPressed: () {
          AppNavigator.pushWithFader(context, nextScreen, arguments: routeArguments, isFast: isFast);
        },
        child: Text(
          text,
          style: scaledTextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}
