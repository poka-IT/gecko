import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/services/image_cache_service.dart';

/// Optimized background widget with smooth loading and caching
class OptimizedBackground extends StatefulWidget {
  final bool isEasterEggActive;
  final Widget child;

  const OptimizedBackground({super.key, required this.isEasterEggActive, required this.child});

  @override
  State<OptimizedBackground> createState() => _OptimizedBackgroundState();
}

class _OptimizedBackgroundState extends State<OptimizedBackground> {
  final ImageCacheService _imageCache = ImageCacheService();

  @override
  Widget build(BuildContext context) {
    // Get the physical screen dimensions once, outside of any MediaQuery changes
    final view = View.of(context);
    final screenSize = view.physicalSize / view.devicePixelRatio;

    return SizedBox.expand(
      child: Stack(
        children: [
          // Fixed background that ignores keyboard changes
          Positioned(
            top: 0,
            left: 0,
            width: screenSize.width,
            height: screenSize.height,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [context.colorScheme.secondary.withValues(alpha: 0.9), context.colorScheme.secondary],
                ),
                image: DecorationImage(
                  opacity: 0.8,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: context.colorScheme.brightness == Brightness.dark ? 0.8 : 0.4),
                    BlendMode.colorDodge,
                  ),
                  image: _imageCache.getImageProvider('assets/home/background.jpg'),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    debugPrint('Background image failed to load: $exception');
                  },
                ),
              ),
            ),
          ),

          // Fixed easter egg background overlay
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
                    image: _imageCache.getImageProvider('assets/background-easter/background-1.jpg'),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      debugPrint('Easter egg background failed to load: $exception');
                    },
                  ),
                ),
              ),
            ),
          ),

          // Content on top - flexible
          widget.child,
        ],
      ),
    );
  }
}
