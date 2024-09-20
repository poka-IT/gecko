import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';

class GeckoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GeckoAppBar(this.text, {super.key});

  final String text;

  @override
  AppBar build(BuildContext context) {
    return AppBar(
      toolbarHeight: scaleSize(57),
      titleSpacing: 10,
      title: Text(
        text,
        style: scaledTextStyle(fontWeight: FontWeight.w600, fontSize: 17),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(scaleSize(57));
}
