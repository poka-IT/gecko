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
  });

  final String imagePath;
  final BoxFit fit;
  final bool isCircular;
  final Widget? fallback;

  @override
  State<CachedAvatarImage> createState() => _CachedAvatarImageState();
}

class _CachedAvatarImageState extends State<CachedAvatarImage> {
  Uint8List? _cachedImageBytes;
  String? _cachedImagePath;

  @override
  void initState() {
    super.initState();
    _loadImageSync();
  }

  @override
  void didUpdateWidget(CachedAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _cachedImagePath = null;
      _cachedImageBytes = null;
      _loadImageSync();
      // Trigger rebuild when image path changes
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _loadImageSync() {
    if (widget.imagePath == _cachedImagePath || widget.imagePath.isEmpty || widget.imagePath.startsWith('assets/')) {
      return;
    }

    _cachedImagePath = widget.imagePath;

    try {
      final file = File(widget.imagePath);
      if (file.existsSync()) {
        _cachedImageBytes = file.readAsBytesSync();
        // Don't call setState in initState - image is already loaded for first build
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle asset images
    if (widget.imagePath.startsWith('assets/')) {
      final image = Image.asset(widget.imagePath, key: ValueKey(widget.imagePath), fit: widget.fit);
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
        gaplessPlayback: false,
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
