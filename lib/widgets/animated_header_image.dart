import 'package:flutter/material.dart';

class AnimatedHeaderImage extends StatefulWidget {
  final bool isEasterEggActive;
  final double height;

  const AnimatedHeaderImage({super.key, required this.isEasterEggActive, required this.height});

  @override
  State<AnimatedHeaderImage> createState() => _AnimatedHeaderImageState();
}

class _AnimatedHeaderImageState extends State<AnimatedHeaderImage> with TickerProviderStateMixin {
  late AnimationController _colorController;
  late AnimationController _flipController;
  late Animation<double> _colorAnimation;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for disco colors (fast cycle)
    _colorController = AnimationController(duration: const Duration(seconds: 1), vsync: this);

    // Animation for mirror flip (slower, smooth)
    _flipController = AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_colorController);

    _flipAnimation = Tween<double>(
      begin: 1.0,
      end: -1.0,
    ).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AnimatedHeaderImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isEasterEggActive != oldWidget.isEasterEggActive) {
      if (widget.isEasterEggActive) {
        // Start animations
        _colorController.repeat();
        _flipController.repeat(reverse: true);
      } else {
        // Stop animations and return to normal
        _colorController.stop();
        _flipController.animateTo(0.0);
      }
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  Color _getDiscoColor(double value) {
    // Create smooth disco color transitions
    final hue = (value * 360) % 360;
    return HSVColor.fromAHSV(1.0, hue, 0.8, 1.0).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_colorAnimation, _flipAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scaleX: _flipAnimation.value,
          child: widget.isEasterEggActive
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // Image originale
                    Image(image: const AssetImage('assets/home/header.png'), height: widget.height),
                    // Couleur disco avec masque
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(_getDiscoColor(_colorAnimation.value), BlendMode.srcATop),
                      child: Image(image: const AssetImage('assets/home/header.png'), height: widget.height),
                    ),
                  ],
                )
              : Image(image: const AssetImage('assets/home/header.png'), height: widget.height),
        );
      },
    );
  }
}
