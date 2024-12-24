import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';

class IconHomeSettings extends StatelessWidget {
  const IconHomeSettings({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const shadowColor = Colors.grey;
    const shadowBlurRadius = 0.8;
    return Builder(
      builder: (context) => IconButton(
        key: keyDrawerMenu,
        icon: Icon(
          Icons.menu,
          color: Colors.black,
          size: scaleSize(36),
          shadows: [
            const Shadow(
              color: shadowColor,
              blurRadius: shadowBlurRadius,
              offset: Offset(0.8, 0),
            ),
            const Shadow(
              color: shadowColor,
              blurRadius: shadowBlurRadius,
              offset: Offset(-0.8, 0),
            ),
            const Shadow(
              color: shadowColor,
              blurRadius: shadowBlurRadius,
              offset: Offset(0, 0.8),
            ),
            const Shadow(
              color: shadowColor,
              blurRadius: shadowBlurRadius,
              offset: Offset(0, -0.8),
            ),
          ],
        ),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }
}
