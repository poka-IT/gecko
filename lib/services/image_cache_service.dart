import 'package:flutter/material.dart';

/// Service to handle image preloading and caching for better performance
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Set<String> _preloadedImages = {};
  final Map<String, ImageProvider> _cachedProviders = {};

  /// Critical images that should be preloaded immediately
  static const List<String> criticalImages = [
    'assets/home/background.jpg',
    'assets/home/header.png',
    'assets/home/gecko-bienvenue.png',
    'assets/background-easter/background-1.jpg',
    'assets/home/loupe.png',
    'assets/home/wallet.png',
    'assets/home/qrcode.png',
  ];

  /// Preload critical images for the home screen
  Future<void> preloadCriticalImages(BuildContext context) async {
    final futures = criticalImages.map((imagePath) => preloadImage(context, imagePath));
    await Future.wait(futures);
  }

  /// Preload a specific image
  Future<void> preloadImage(BuildContext context, String imagePath) async {
    if (_preloadedImages.contains(imagePath)) {
      return; // Already preloaded
    }

    try {
      final imageProvider = AssetImage(imagePath);
      _cachedProviders[imagePath] = imageProvider;

      await precacheImage(imageProvider, context);
      _preloadedImages.add(imagePath);
    } catch (e) {
      debugPrint('Failed to preload image $imagePath: $e');
    }
  }

  /// Get a cached image provider or create a new one
  ImageProvider getImageProvider(String imagePath) {
    return _cachedProviders[imagePath] ?? AssetImage(imagePath);
  }
}
