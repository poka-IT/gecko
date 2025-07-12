import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';

class AnimatedBackground extends StatefulWidget {
  final bool isEasterEggActive;
  final Widget child;

  const AnimatedBackground({super.key, required this.isEasterEggActive, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background normal (toujours présent)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                opacity: 0.8,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: context.colorScheme.brightness == Brightness.dark ? 0.8 : 0.4),
                  BlendMode.colorDodge,
                ),
                image: AssetImage("assets/home/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Background easter egg avec transition fade in/out
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: widget.isEasterEggActive ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 800),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  opacity: 0.8,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: context.colorScheme.brightness == Brightness.dark ? 0.8 : 0.4),
                    BlendMode.colorDodge,
                  ),
                  image: AssetImage("assets/background-easter/background-1.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),

        // Le contenu par-dessus
        widget.child,
      ],
    );
  }
}
