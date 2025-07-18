import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gecko/widgets/commons/offline_info.dart';

/// Global overlay that displays offline information on top of all screens
/// Similar to VersionOverlay but for connection status
class GlobalOfflineOverlay extends StatefulWidget {
  const GlobalOfflineOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalOfflineOverlay> createState() => _GlobalOfflineOverlayState();
}

class _GlobalOfflineOverlayState extends State<GlobalOfflineOverlay> {
  bool _showOfflineInfo = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    // Wait 2 seconds before showing the offline banner to avoid initial flicker
    _delayTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showOfflineInfo = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          Positioned(top: 0, left: 0, right: 0, child: OfflineInfo(forceHide: !_showOfflineInfo)),
        ],
      ),
    );
  }
}
