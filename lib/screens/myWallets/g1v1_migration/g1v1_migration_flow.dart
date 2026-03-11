import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/g1v1_migration.provider.dart';
import 'package:gecko/screens/myWallets/g1v1_migration/steps/step_intro.dart';
import 'package:gecko/screens/myWallets/g1v1_migration/steps/step_credentials.dart';
import 'package:gecko/screens/myWallets/g1v1_migration/steps/step_destination.dart';
import 'package:gecko/screens/myWallets/g1v1_migration/steps/step_confirmation.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class G1v1MigrationFlow extends ConsumerStatefulWidget {
  const G1v1MigrationFlow({super.key});

  @override
  ConsumerState<G1v1MigrationFlow> createState() => _G1v1MigrationFlowState();
}

class _G1v1MigrationFlowState extends ConsumerState<G1v1MigrationFlow> {
  final PageController _pageController = PageController();
  static const int _totalSteps = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(g1v1MigrationFlowProvider);

    // Sync PageView with provider state
    ref.listen<G1v1MigrationFlowState>(g1v1MigrationFlowProvider, (previous, next) {
      if (previous?.currentStep != next.currentStep) {
        _animateToPage(next.currentStep);
      }
    });

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        ref.read(csSaltControllerProvider).clear();
        ref.read(csPasswordControllerProvider).clear();
        ref.read(g1v1MigrationUiProvider.notifier).reset();
        ref.read(g1v1MigrationFlowProvider.notifier).reset();
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('importOldAccount'.tr()),
        body: SafeArea(
          child: ResponsiveCenter(
            maxWidth: 600,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      ref.read(g1v1MigrationFlowProvider.notifier).goToStep(index);
                    },
                    children: const [StepIntro(), StepCredentials(), StepDestination(), StepConfirmation()],
                  ),
                ),
                // Bottom dots indicator
                _buildDotsIndicator(context, flowState.currentStep),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDotsIndicator(BuildContext context, int currentStep) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(top: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.2), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: scaleSize(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isActive = index == currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: scaleSize(4)),
                width: scaleSize(isActive ? 10 : 8),
                height: scaleSize(isActive ? 10 : 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? context.colorScheme.primary : context.colorScheme.outline.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
