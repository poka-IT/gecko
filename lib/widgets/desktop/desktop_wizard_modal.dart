import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';

/// A single step in a desktop wizard modal.
class WizardStep {
  final String title;
  final WidgetBuilder builder;

  /// Whether the "Next" button should be enabled.
  /// If null, always enabled.
  final ValueNotifier<bool>? canProceed;

  const WizardStep({required this.title, required this.builder, this.canProceed});
}

/// Shows a wizard-style modal for multi-step flows (onboarding, migration, etc.)
///
/// Returns the value passed to [WizardModalState.complete], or null if dismissed.
Future<T?> showDesktopWizardModal<T>({
  required BuildContext context,
  required List<WizardStep> steps,
  double width = 700,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.03, 0), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return _WizardModalShell<T>(steps: steps, width: width);
    },
  );
}

class _WizardModalShell<T> extends StatefulWidget {
  final List<WizardStep> steps;
  final double width;

  const _WizardModalShell({required this.steps, required this.width});

  @override
  State<_WizardModalShell<T>> createState() => _WizardModalShellState<T>();
}

class _WizardModalShellState<T> extends State<_WizardModalShell<T>> {
  int _currentStep = 0;

  void _next() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  /// Call this from step builders to complete the wizard with a result.
  void complete([T? result]) {
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == widget.steps.length - 1;

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop()},
      child: Focus(
        autofocus: true,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.width, maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: Material(
                type: MaterialType.transparency,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.colorScheme.surface.withValues(alpha: 0.95),
                            context.colorScheme.surfaceContainer.withValues(alpha: 0.88),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(context, step),
                          _buildProgressBar(context),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: WizardStepScope(
                                onComplete: ([result]) => complete(result as T?),
                                onNext: _next,
                                onBack: _back,
                                currentStep: _currentStep,
                                totalSteps: widget.steps.length,
                                child: step.builder(context),
                              ),
                            ),
                          ),
                          _buildFooter(context, step, isFirst, isLast),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WizardStep step) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: List.generate(widget.steps.length, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < widget.steps.length - 1 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive ? context.colorScheme.primary : context.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WizardStep step, bool isFirst, bool isLast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isFirst)
            TextButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(MaterialLocalizations.of(context).backButtonTooltip),
            )
          else
            const SizedBox.shrink(),
          if (!isLast) _buildNextButton(context, step) else const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, WizardStep step) {
    if (step.canProceed != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: step.canProceed!,
        builder: (context, canProceed, _) {
          return FilledButton.icon(
            onPressed: canProceed ? _next : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text('continue'.tr()),
          );
        },
      );
    }
    return FilledButton.icon(
      onPressed: _next,
      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
      label: Text('continue'.tr()),
    );
  }
}

/// Inherited widget that gives step builders access to wizard navigation.
class WizardStepScope extends InheritedWidget {
  final void Function([dynamic result]) onComplete;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  const WizardStepScope({
    super.key,
    required this.onComplete,
    required this.onNext,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
    required super.child,
  });

  static WizardStepScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WizardStepScope>()!;
  }

  static WizardStepScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WizardStepScope>();
  }

  @override
  bool updateShouldNotify(WizardStepScope oldWidget) {
    return currentStep != oldWidget.currentStep || totalSteps != oldWidget.totalSteps;
  }
}
