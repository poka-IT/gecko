import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gecko/services/karaoke_service.dart';
import 'package:gecko/providers_deprecated/home.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/globals.dart';

enum TapSide { left, right }

class TapEvent {
  final DateTime time;
  final TapSide side;

  TapEvent(this.time, this.side);
}

class EasterEggDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onEasterEggTriggered;
  final ValueChanged<bool> onPlayingStateChanged;

  const EasterEggDetector({
    super.key,
    required this.child,
    this.onEasterEggTriggered,
    required this.onPlayingStateChanged,
  });

  @override
  State<EasterEggDetector> createState() => _EasterEggDetectorState();
}

class _EasterEggDetectorState extends State<EasterEggDetector> {
  static const int tapTimeout = 3000; // 3 seconds timeout
  static const double cornerSize = 120; // Size of each corner area

  // Pattern: 2 left taps then 3 right taps
  static const List<TapSide> requiredPattern = [
    TapSide.left,
    TapSide.left,
    TapSide.right,
    TapSide.right,
    TapSide.right,
  ];

  final List<TapEvent> _tapEvents = [];
  bool _isPlaying = false;
  AudioPlayer? _audioPlayer;
  final KaraokeService _karaokeService = KaraokeService();
  String? _originalMessage;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _karaokeService.loadLyrics();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _karaokeService.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details, Size screenSize) {
    final tapSide = _getTapSide(details.globalPosition, screenSize);
    if (tapSide != null) {
      _handleCornerTap(tapSide);
    }
  }

  TapSide? _getTapSide(Offset position, Size screenSize) {
    // Check if tap is in bottom corners only
    bool isInBottomLeft = position.dx <= cornerSize && position.dy >= screenSize.height - cornerSize;
    bool isInBottomRight =
        position.dx >= screenSize.width - cornerSize && position.dy >= screenSize.height - cornerSize;

    if (isInBottomLeft) return TapSide.left;
    if (isInBottomRight) return TapSide.right;
    return null;
  }

  void _handleCornerTap(TapSide side) {
    final now = DateTime.now();

    // Remove old taps (older than timeout)
    _tapEvents.removeWhere((event) => now.difference(event.time).inMilliseconds > tapTimeout);

    // Add current tap
    _tapEvents.add(TapEvent(now, side));

    // Check if we have the correct pattern
    if (_checkPattern()) {
      _triggerEasterEgg();
      _tapEvents.clear(); // Reset after triggering
    } else if (_tapEvents.length >= requiredPattern.length) {
      // Reset if we have too many taps without correct pattern
      _tapEvents.clear();
    }
  }

  bool _checkPattern() {
    if (_tapEvents.length != requiredPattern.length) {
      return false;
    }

    // Check if the sequence matches the required pattern
    for (int i = 0; i < requiredPattern.length; i++) {
      if (_tapEvents[i].side != requiredPattern[i]) {
        return false;
      }
    }

    return true;
  }

  void _triggerEasterEgg() {
    if (_isPlaying) {
      // Stop the sound if it's already playing
      _stopSound();
    } else {
      // Start playing the sound
      _playSound();
    }

    widget.onEasterEggTriggered?.call();
  }

  void _playSound() async {
    try {
      setState(() {
        _isPlaying = true;
      });
      widget.onPlayingStateChanged(true);

      // Sauvegarder le message original du homeProvider
      final homeProvider = old_provider.Provider.of<HomeProvider>(context, listen: false);
      _originalMessage = homeProvider.homeMessage;

      await _audioPlayer?.play(AssetSource('sounds/gecko.mp3'));

      // Démarrer le karaoké
      _karaokeService.startKaraoke((text) {
        if (mounted) {
          homeProvider.changeMessage(text.isEmpty ? '♪ ♫ ♪' : text);
        }
      });

      // Listen for completion
      _audioPlayer?.onPlayerComplete.listen((event) {
        if (mounted) {
          _stopKaraoke();
          setState(() {
            _isPlaying = false;
          });
          widget.onPlayingStateChanged(false);
        }
      });
    } catch (e) {
      log.e('Error playing sound: $e');
      _stopKaraoke();
      setState(() {
        _isPlaying = false;
      });
      widget.onPlayingStateChanged(false);
    }
  }

  void _stopSound() async {
    try {
      await _audioPlayer?.stop();
      _stopKaraoke();
      setState(() {
        _isPlaying = false;
      });
      widget.onPlayingStateChanged(false);
    } catch (e) {
      log.e('Error stopping sound: $e');
    }
  }

  void _stopKaraoke() {
    _karaokeService.stopKaraoke();

    // Restaurer le message original
    if (mounted && _originalMessage != null) {
      final homeProvider = old_provider.Provider.of<HomeProvider>(context, listen: false);
      homeProvider.changeMessage(_originalMessage!, true);
      _originalMessage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(onTapDown: (details) => _onTapDown(details, screenSize), child: widget.child);
      },
    );
  }
}
