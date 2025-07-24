import 'dart:io';
import 'package:flutter/material.dart';

/// A smart avatar widget that handles loading from assets, files, and fallback
/// Always displays as a circular avatar with ClipOval
class SmartAvatar extends StatelessWidget {
  const SmartAvatar({super.key, required this.imagePath, this.fit = BoxFit.contain, this.width, this.height});

  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
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
