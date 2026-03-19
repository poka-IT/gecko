import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Widget that caches avatar images to avoid flickering and improve performance
class CachedAvatarImage extends StatefulWidget {
  const CachedAvatarImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.isCircular = true,
    this.fallback,
    this.semanticLabel,
  });

  final String imagePath;
  final BoxFit fit;
  final bool isCircular;
  final Widget? fallback;

  /// Accessibility label for the avatar image.
  final String? semanticLabel;

  @override
  State<CachedAvatarImage> createState() => _CachedAvatarImageState();
}

class _CachedAvatarImageState extends State<CachedAvatarImage> {
  Uint8List? _cachedImageBytes;
  String? _cachedImagePath;

  @override
  void initState() {
    super.initState();
    _loadImage(); // fire-and-forget is OK here, mounted check inside
  }

  @override
  void didUpdateWidget(CachedAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _cachedImagePath = null;
      _cachedImageBytes = null;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imagePath == _cachedImagePath || widget.imagePath.isEmpty || widget.imagePath.startsWith('assets/')) {
      return;
    }

    try {
      final file = File(widget.imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _cachedImageBytes = bytes;
            _cachedImagePath = widget.imagePath;
          });
        }
      }
      // Don't set _cachedImagePath if file doesn't exist, so a retry is possible on rebuild
    } catch (e) {
      // Don't cache the path on error either, allow retry
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle asset images
    if (widget.imagePath.startsWith('assets/')) {
      final image = Image.asset(
        widget.imagePath,
        key: ValueKey(widget.imagePath),
        fit: widget.fit,
        semanticLabel: widget.semanticLabel,
      );
      return widget.isCircular
          ? Container(
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.hardEdge,
              child: image,
            )
          : image;
    }

    // Handle cached file images
    if (_cachedImageBytes != null) {
      final image = Image.memory(
        _cachedImageBytes!,
        key: ValueKey(widget.imagePath),
        fit: widget.fit,
        gaplessPlayback: true,
        semanticLabel: widget.semanticLabel,
      );
      return widget.isCircular
          ? Container(
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.hardEdge,
              child: image,
            )
          : image;
    }

    // Fallback while loading or on error
    return widget.fallback ?? const SizedBox();
  }
}
