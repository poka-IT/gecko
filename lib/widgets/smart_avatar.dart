import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/avatar_providers.dart';

/// A smart avatar widget that handles loading from assets, files, Cesium+ and fallback
/// Always displays as a circular avatar with ClipOval
/// Priority: 1) Cesium+ avatar (if address provided), 2) Local file, 3) Asset, 4) Fallback
class SmartAvatar extends ConsumerWidget {
  const SmartAvatar({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.address,
  });

  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? address; // If provided, try to load Cesium+ avatar first

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If address is provided, try Cesium+ avatar first
    if (address != null && address!.isNotEmpty) {
      final avatarAsync = ref.watch(avatarProvider(address!));

      return avatarAsync.when(
        data: (cesiumAvatar) {
          // If Cesium+ avatar exists, use it
          if (cesiumAvatar != null) {
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: MemoryImage(cesiumAvatar), fit: fit),
              ),
            );
          }
          // Otherwise, fallback to local avatar
          return _buildLocalAvatar();
        },
        loading: () => _buildLocalAvatar(), // Show local while loading
        error: (_, _) => _buildLocalAvatar(), // Fallback to local on error
      );
    }

    // No address provided, use local avatar directly
    return _buildLocalAvatar();
  }

  Widget _buildLocalAvatar() {
    // Try to determine if it's an asset path or file path
    final isAssetPath = imagePath.startsWith('assets/');
    final fallbackAssetPath = 'assets/icon_user.png';

    if (isAssetPath) {
      // Load from assets
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: fit,
            onError: (exception, stackTrace) {
              // This will be handled by the fallback below
            },
          ),
        ),
      );
    } else {
      // For file paths, check if file exists synchronously
      final file = File(imagePath);
      DecorationImage decorationImage;

      if (file.existsSync()) {
        // File exists, use it
        decorationImage = DecorationImage(
          image: FileImage(file),
          fit: fit,
          onError: (exception, stackTrace) {
            // If error occurs, the image won't display properly but won't crash
          },
        );
      } else {
        // File doesn't exist, use fallback
        decorationImage = DecorationImage(image: AssetImage(fallbackAssetPath), fit: fit);
      }

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(shape: BoxShape.circle, image: decorationImage),
      );
    }
  }
}
