import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';

class GeckoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GeckoAppBar(this.text, {super.key, this.bottom});

  final String text;
  final PreferredSizeWidget? bottom;

  @override
  AppBar build(BuildContext context) {
    return AppBar(
      backgroundColor: context.colorScheme.tertiary,
      toolbarHeight: scaleSize(57),
      titleSpacing: 10,
      title: Text(
        text,
        style: scaledTextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: context.colorScheme.onSecondaryContainer,
        ),
      ),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(scaleSize(57) + (bottom?.preferredSize.height ?? 0));
}
