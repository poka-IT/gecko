import 'package:durt2/durt2.dart' show Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/screens/home/test_wallet_button.dart';
import 'package:gecko/screens/onBoarding/import_choice_screen.dart';
import 'package:gecko/services/image_cache_service.dart';
import 'package:gecko/widgets/bubble_speak.dart';
import 'package:gecko/widgets/buttons/home_settings_button.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/desktop/modals/legacy_migration_modal.dart';
import 'package:gecko/widgets/desktop/modals/onboarding_modal.dart';
import 'package:gecko/widgets/desktop/modals/restore_modal.dart';
import 'package:gecko/widgets/desktop/modals/settings_modal.dart';

/// Welcome screen widget displayed when no wallets exist
class WelcomeHomeWidget extends ConsumerWidget {
  const WelcomeHomeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showImage = ref.watch(backgroundImageProvider);

    if (isDesktopLayout(context)) {
      return _DesktopWelcomeWidget(showBackgroundImage: showImage);
    }

    return _MobileWelcomeWidget(showBackgroundImage: showImage);
  }
}

// ─────────────────────────── Desktop Layout ───────────────────────────

class _DesktopWelcomeWidget extends StatelessWidget {
  final bool showBackgroundImage;

  const _DesktopWelcomeWidget({required this.showBackgroundImage});

  @override
  Widget build(BuildContext context) {
    final imageCache = ImageCacheService();
    final view = View.of(context);
    final screenSize = view.physicalSize / view.devicePixelRatio;

    return Stack(
      children: [
        // Background
        Positioned(
          top: 0,
          left: 0,
          width: screenSize.width,
          height: screenSize.height,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, -1),
                end: const Alignment(1, 1),
                colors: [
                  context.colorScheme.surface,
                  Color.lerp(context.colorScheme.surface, context.colorScheme.primary, 0.06)!,
                  context.colorScheme.surface,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              image: showBackgroundImage
                  ? DecorationImage(
                      opacity: 0.15,
                      image: imageCache.getImageProvider("assets/home/background.jpg"),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
        ),
        // Decorative glow
        Positioned(
          top: -100,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colorScheme.primary.withValues(alpha: 0.08),
                    context.colorScheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Column(
            children: [
              // Top bar: settings + network info
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.settings_rounded,
                        size: scaleSize(28),
                        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      tooltip: 'parameters'.tr(),
                      onPressed: () => showDesktopSettingsModal(context),
                    ),
                    const Spacer(),
                    _buildNetworkBadge(context),
                  ],
                ),
              ),

              // Main content — centered
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 740),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header + description
                          Image(image: imageCache.getImageProvider('assets/home/header.png'), height: 120),
                          const SizedBox(height: 8),
                          Text(
                            "fastAppDescription".tr(args: [Durt.i.network.symbol]),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Gecko mascot
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image(image: imageCache.getImageProvider('assets/home/gecko-bienvenue.png'), height: 120),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: BubbleSpeakWithTail(text: "noLizard".tr()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Action cards grid — 2x2
                          _buildActionCardsGrid(context),

                          const TestWalletButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Durt.i.network.symbol,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCardsGrid(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _ActionCard(
          key: keyOnboardingNewSafe,
          icon: Icons.add_circle_outline_rounded,
          title: 'createWallet'.tr(),
          isPrimary: true,
          onTap: () => showDesktopOnboardingModal(context),
        ),
        _ActionCard(
          key: keyRestoreSafe,
          icon: Icons.key_rounded,
          title: 'restoreWallet'.tr(),
          onTap: () => showDesktopRestoreModal(context),
        ),
        if (ImportChoiceScreen.enableLegacyLogin)
          _ActionCard(
            icon: Icons.swap_horiz_rounded,
            title: 'importLegacyAccount'.tr(),
            subtitle: 'importLegacyDescription'.tr(),
            onTap: () => showDesktopLegacyMigrationModal(context),
          ),
        _ActionCard(
          icon: Icons.public_rounded,
          title: 'exploreNetwork'.tr(),
          subtitle: 'exploreNetworkDescription'.tr(),
          onTap: () => Navigator.pushNamed(context, RouteNames.search),
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 220,
          padding: const EdgeInsets.all(24),
          // ignore: deprecated_member_use
          transform: _isHovered ? (Matrix4.identity()..translate(0.0, -3.0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, primary.withValues(alpha: 0.85)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colorScheme.surface.withValues(alpha: 0.92),
                      context.colorScheme.surfaceContainer.withValues(alpha: 0.68),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.white.withValues(alpha: 0.15)
                  : (_isHovered ? primary.withValues(alpha: 0.3) : context.colorScheme.outline.withValues(alpha: 0.08)),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isPrimary
                    ? primary.withValues(alpha: _isHovered ? 0.25 : 0.15)
                    : Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 24 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.isPrimary ? Colors.white.withValues(alpha: 0.18) : primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 28, color: widget.isPrimary ? Colors.white : primary),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.isPrimary ? Colors.white : context.colorScheme.onSurface,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isPrimary
                        ? Colors.white.withValues(alpha: 0.75)
                        : context.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Mobile Layout (original) ───────────────────────────

class _MobileWelcomeWidget extends StatelessWidget {
  final bool showBackgroundImage;

  const _MobileWelcomeWidget({required this.showBackgroundImage});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final imageCache = ImageCacheService();

    // Get fixed screen dimensions to avoid keyboard-related scaling
    final view = View.of(context);
    final screenSize = view.physicalSize / view.devicePixelRatio;

    return SizedBox.expand(
      child: Stack(
        children: [
          // Fixed background that ignores keyboard changes
          Positioned(
            top: 0,
            left: 0,
            width: screenSize.width,
            height: screenSize.height,
            child: Container(
              decoration: BoxDecoration(
                color: showBackgroundImage ? null : context.colorScheme.secondary,
                image: showBackgroundImage
                    ? DecorationImage(
                        image: imageCache.getImageProvider("assets/home/background.jpg"),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          ),

          // Content on top
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Positioned(top: statusBarHeight + scaleSize(10), left: scaleSize(15), child: IconHomeSettings()),
                  Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Image(
                        image: imageCache.getImageProvider('assets/home/header.png'),
                        height: scaleSize(165),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "fastAppDescription".tr(args: [Durt.i.network.symbol]),
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        style: scaledTextStyle(
                          color: Colors.white,
                          fontSize: isTall ? 19 : 17,
                          fontWeight: FontWeight.w700,
                          shadows: const <Shadow>[
                            Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.black),
                            Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: <Widget>[
                          const Spacer(flex: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: scaleSize(isTall ? 55 : 0)),
                                child: Image(
                                  image: imageCache.getImageProvider('assets/home/gecko-bienvenue.png'),
                                  height: scaleSize(isTall ? 180 : 160),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: BubbleSpeakWithTail(text: "noLizard".tr()),
                              ),
                            ],
                          ),
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
                              child: Column(
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 400, minHeight: scaleSize(60)),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        key: keyOnboardingNewSafe,
                                        style:
                                            ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor: context.colorScheme.primary,
                                              elevation: 0,
                                              padding: EdgeInsets.symmetric(
                                                vertical: scaleSize(12),
                                                horizontal: scaleSize(16),
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ).copyWith(
                                              elevation: WidgetStateProperty.resolveWith<double>((
                                                Set<WidgetState> states,
                                              ) {
                                                if (states.contains(WidgetState.pressed)) return 0;
                                                return 8;
                                              }),
                                              shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.2)),
                                            ),
                                        onPressed: () {
                                          Navigator.pushNamed(context, RouteNames.onboardingStepOne);
                                        },
                                        child: Text(
                                          'createWallet'.tr(),
                                          style: scaledTextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ScaledSizedBox(height: scaleSize(17)),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 400, minHeight: scaleSize(60)),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        key: keyRestoreSafe,
                                        style:
                                            OutlinedButton.styleFrom(
                                              side: BorderSide(width: scaleSize(4), color: context.colorScheme.primary),
                                              padding: EdgeInsets.symmetric(
                                                vertical: scaleSize(12),
                                                horizontal: scaleSize(16),
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                                            ).copyWith(
                                              elevation: WidgetStateProperty.resolveWith<double>((
                                                Set<WidgetState> states,
                                              ) {
                                                if (states.contains(WidgetState.pressed)) return 0;
                                                return 4;
                                              }),
                                              shadowColor: WidgetStateProperty.all(
                                                Colors.black.withValues(alpha: 0.15),
                                              ),
                                            ),
                                        onPressed: () {
                                          if (ImportChoiceScreen.enableLegacyLogin) {
                                            Navigator.pushNamed(context, RouteNames.importChoice);
                                          } else {
                                            Navigator.pushNamed(context, RouteNames.restoreSafe);
                                          }
                                        },
                                        child: Text(
                                          "restoreWallet".tr(),
                                          style: scaledTextStyle(
                                            fontSize: 20,
                                            color: context.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TestWalletButton(),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
