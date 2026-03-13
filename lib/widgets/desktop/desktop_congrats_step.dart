import 'dart:math' show pi;

import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gif_view/gif_view.dart';

/// Shared congratulations step for desktop onboarding/restore/import modals.
///
/// Displays the gecko winking GIF, confetti cannons, a message, and an action button.
class DesktopCongratsStep extends StatefulWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onButtonPressed;

  const DesktopCongratsStep({
    super.key,
    required this.message,
    required this.buttonLabel,
    required this.onButtonPressed,
  });

  @override
  State<DesktopCongratsStep> createState() => _DesktopCongratsStepState();
}

class _DesktopCongratsStepState extends State<DesktopCongratsStep> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 500));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'allGood'.tr(),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              GifView(image: const AssetImage('assets/onBoarding/gecko-clin.gif'), height: 220),
              // Invisible preload to prevent gif loop glitch
              Image.asset('assets/onBoarding/gecko-clin.gif', height: 0),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onButtonPressed,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(widget.buttonLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        // Confetti cannons
        _buildConfettiCannon(Alignment.topLeft, pi * 0.15, 8),
        _buildConfettiCannon(Alignment.topRight, pi * 0.85, 8),
        _buildConfettiCannon(const Alignment(-0.3, -0.2), pi * 0.3, 6),
        _buildConfettiCannon(const Alignment(0.3, -0.2), pi * 0.7, 6),
      ],
    );
  }

  Widget _buildConfettiCannon(Alignment alignment, double blastDirection, int particles) {
    return Align(
      alignment: alignment,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirection: blastDirection,
        maxBlastForce: 15,
        minBlastForce: 3,
        emissionFrequency: 0.04,
        numberOfParticles: particles,
        shouldLoop: true,
        gravity: 0.15,
        particleDrag: 0.1,
        minimumSize: const Size(8, 8),
        maximumSize: const Size(12, 12),
      ),
    );
  }
}
