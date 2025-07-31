// ignore_for_file: file_names

import 'package:durt2/durt2.dart' show BidouilleLang;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallet_generation_providers.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/mnemonic_display.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart' as old_provider;

class OnboardingStepFive extends ConsumerStatefulWidget {
  const OnboardingStepFive({super.key, this.skipIntro = false});
  final bool skipIntro;

  @override
  ConsumerState<OnboardingStepFive> createState() {
    return _ChooseSafeState();
  }
}

// ignore: unused_element
class _ChooseSafeState extends ConsumerState<OnboardingStepFive> with TickerProviderStateMixin {
  List<String>? mnemonicList;
  bool isLoading = false;
  bool _hasInitialized = false;

  bool get _isMnemonicGenerated {
    final mnemonicState = ref.read(mnemonicStateProvider);
    return mnemonicState.mnemonicResult != null;
  }

  // Scroll detection variables
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;
  bool _isAtBottom = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize scroll detection
    _scrollController.addListener(_scrollListener);

    // Initialize animation
    _animationController = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _fadeAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Start pulsing animation
    _animationController.repeat(reverse: true);

    // Check if content is scrollable after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
    });

    // Don't call _generateMnemonicList() here as context.locale is not available yet
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call _generateMnemonicList() here when context is fully available
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Delay provider modification until after the widget tree is built
      Future(() => _generateMnemonicList());
      // Recheck scroll after mnemonic is generated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkScrollable();
      });
    }
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final bool isAtBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 10;

    if (_isAtBottom != isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
      });
    }
  }

  void _checkScrollable() {
    if (!_scrollController.hasClients) return;

    // Only show indicator if there's meaningful scroll content (more than 10 pixels)
    final bool isScrollable = _scrollController.position.maxScrollExtent > 10;
    if (_showScrollIndicator != isScrollable) {
      setState(() {
        _showScrollIndicator = isScrollable;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _generateMnemonicList() async {
    try {
      // Get user's preferred language
      final languageCode = context.locale.languageCode;
      final targetLanguage = BidouilleLang.fromLanguageCode(languageCode);

      // Generate mnemonic using new provider
      await ref
          .read(mnemonicStateProvider.notifier)
          .generateMnemonic(
            targetLanguage: targetLanguage,
            forceEnglish: configBox.get('generateMnemonicsInEnglish') ?? false,
          );

      final mnemonicState = ref.read(mnemonicStateProvider);
      if (mounted && mnemonicState.mnemonicResult != null) {
        setState(() {
          mnemonicList = mnemonicState.mnemonicResult!.displayWords;
          isLoading = false;
        });
        // Check scroll after the mnemonic is displayed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkScrollable();
        });
      }
    } catch (e) {
      log.e('Error generating mnemonic: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _regenerateMnemonic() async {
    setState(() {
      isLoading = true;
    });
    await _generateMnemonicList();
  }

  Widget sentenceArray() {
    if (mnemonicList == null) {
      return Center(child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 2));
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(12)),
      child: MnemonicDisplayWidget(
        mnemonicWords: mnemonicList!,
        isLoading: isLoading,
        useWordAsKey: false, // Use index as key for onboarding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('yourMnemonic'.tr()),
      bottomNavigationBar: Container(
        color: context.colorScheme.surface,
        padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).padding.bottom + 22, top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Secondary button
            ScaledSizedBox(
              width: 350,
              height: 55,
              child: ElevatedButton(
                key: keyGenerateMnemonic,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: const Color(0xffFFD58D),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: const Color(0xffFFD58D).withValues(alpha: 0.3),
                ),
                onPressed: () {
                  _regenerateMnemonic();
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "chooseAnotherMnemonic".tr(),
                    textAlign: TextAlign.center,
                    style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            // Main button
            nextButton(context, "iNotedMyMnemonic".tr(), false, widget.skipIntro),
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaledSizedBox(height: isTall ? 25 : 5),
                    const BuildProgressBar(pagePosition: 4),
                    ScaledSizedBox(height: isTall ? 25 : 5),
                    BuildText(text: 'geckoGeneratedYourMnemonicKeepItSecret'.tr()),
                    ScaledSizedBox(height: isTall ? 15 : 5),
                    sentenceArray(),
                    ScaledSizedBox(height: isTall ? 17 : 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaledSizedBox(
                          height: 40,
                          width: 132,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              backgroundColor: context.colorScheme.primary,
                              elevation: 1,
                            ),
                            onPressed: _isMnemonicGenerated
                                ? () {
                                    final mnemonicState = ref.read(mnemonicStateProvider);
                                    if (mnemonicState.mnemonicResult != null) {
                                      Clipboard.setData(
                                        ClipboardData(text: mnemonicState.mnemonicResult!.displayMnemonic),
                                      );
                                      SnackbarService.showMnemonicCopied(context);
                                    }
                                  }
                                : null,
                            child: Row(
                              children: <Widget>[
                                Image.asset('assets/walletOptions/copy-white.png', height: scaleSize(23)),
                                const Spacer(),
                                Text('copy'.tr(), style: scaledTextStyle(fontSize: 14, color: Colors.grey[50])),
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                        ScaledSizedBox(width: 70),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteNames.printWallet,
                              arguments: PrintWalletArguments(
                                sentence: ref.read(mnemonicStateProvider).mnemonicResult?.displayMnemonic ?? '',
                              ),
                            );
                          },
                          child: Image.asset(
                            'assets/printer.png',
                            height: scaleSize(42),
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTall ? 20 : 10), // Small bottom spacing
                  ],
                ),
              ),
            ),
          ),

          // Scroll indicator at bottom (above the buttons)
          if (_showScrollIndicator && !_isAtBottom)
            Positioned(
              bottom: 10, // Just above bottomNavigationBar
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: GestureDetector(
                        onTap: _scrollToBottom,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                'scrollToContinue'.tr(),
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget nextButton(BuildContext context, String text, bool isFast, bool skipIntro) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    return ScaledSizedBox(
      width: 350,
      height: 55,
      child: ElevatedButton(
        key: keyGoNext,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: context.colorScheme.primary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
        ),
        onPressed: _isMnemonicGenerated
            ? () {
                final mnemonicState = ref.read(mnemonicStateProvider);
                if (mnemonicState.mnemonicResult != null) {
                  // Store mnemonic in old provider for compatibility with next screen
                  myWalletProvider.mnemonic = mnemonicState.mnemonicResult!.displayMnemonic;

                  AppNavigator.pushWithFader(
                    context,
                    RouteNames.onboardingStepSix,
                    arguments: OnboardingStepSixArguments(
                      generatedMnemonic: mnemonicState.mnemonicResult!.displayMnemonic,
                      skipIntro: skipIntro,
                    ),
                  );
                }
              }
            : null,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
