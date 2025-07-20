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
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Normal background (always present) - fixed to screen size
        Positioned(
          top: 0,
          left: 0,
          width: screenSize.width,
          height: screenSize.height,
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

        // Background easter egg with fade in/out transition - fixed to screen size
        Positioned(
          top: 0,
          left: 0,
          width: screenSize.width,
          height: screenSize.height,
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

        // Content on top
        widget.child,
      ],
    );
  }
}
