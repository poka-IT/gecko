import 'package:flutter/material.dart';
import 'package:gecko/utils/flower_power_colors.dart';
import 'package:gecko/services/image_cache_service.dart';

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
  final ImageCacheService _imageCache = ImageCacheService();

  @override
  void initState() {
    super.initState();

    // Animation for flower power colors (fast cycle)
    _colorController = AnimationController(duration: const Duration(milliseconds: 8159), vsync: this);

    // Animation for mirror flip (slower, smooth)
    _flipController = AnimationController(duration: const Duration(milliseconds: 2039), vsync: this);

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
                    // Original image using cached provider
                    Image(image: _imageCache.getImageProvider('assets/home/header.png'), height: widget.height),
                    // Flower power color with mask
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        FlowerPowerColors.getFlowerPowerColor(_colorAnimation.value),
                        BlendMode.srcATop,
                      ),
                      child: Image(
                        image: _imageCache.getImageProvider('assets/home/header.png'),
                        height: widget.height,
                      ),
                    ),
                  ],
                )
              : Image(image: _imageCache.getImageProvider('assets/home/header.png'), height: widget.height),
        );
      },
    );
  }
}
