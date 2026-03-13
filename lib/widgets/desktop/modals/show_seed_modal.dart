import 'package:durt2/durt2.dart' show Durt, BidouilleLang;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/security_providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/commons/mnemonic_display.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';

/// Shows the mnemonic seed inside a desktop modal.
Future<void> showDesktopShowSeedModal(BuildContext context, {required String walletName}) {
  return showDesktopModal(
    context: context,
    title: 'myMnemonic'.tr(),
    size: DesktopModalSize.medium,
    contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    builder: (context) => const _ShowSeedContent(),
  );
}

class _ShowSeedContent extends ConsumerWidget {
  const _ShowSeedContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstWallet = ref.watch(firstWalletProvider);

    if (firstWallet == null) {
      return Center(child: Text('noWalletFound'.tr()));
    }

    return SingleChildScrollView(
      child: ref
          .watch(seedDisplayProvider((address: firstWallet.address, pin: PinCodeService.pinCode)))
          .when(
            loading: () => Center(
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 80), child: Loading(stroke: 4, size: 40)),
            ),
            error: (error, stack) {
              log.e('Seed display error: $error');
              final errorMessage = error is PinExpiredException ? 'pinExpired'.tr() : error.toString();
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: context.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'errorRetrievingSeed'.tr(),
                        style: scaledTextStyle(fontSize: 16, color: context.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        style: scaledTextStyle(
                          fontSize: 14,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text('retry'.tr()),
                        onPressed: () {
                          ref.invalidate(
                            seedDisplayProvider((address: firstWallet.address, pin: PinCodeService.pinCode)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            data: (seedData) {
              final englishMnemonic = seedData.englishMnemonic;
              final displayMnemonic = seedData.displayMnemonic;
              final mnemonicWords = displayMnemonic.trim().split(RegExp(r'\s+'));
              if (mnemonicWords.length != 12 || mnemonicWords.any((word) => word.isEmpty)) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: context.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          'invalidMnemonicFormat'.tr(),
                          style: scaledTextStyle(fontSize: 16, color: context.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final safeLanguage = Durt.i.wallets.getSafeMnemonicLanguage(firstWallet.safe.target?.number);
              final isEnglish = safeLanguage == BidouilleLang.english;

              return Column(
                children: [
                  BuildText(text: 'keepYourMnemonicSecret'.tr(), size: 15),
                  const SizedBox(height: 24),
                  MnemonicDisplayWidget(mnemonicWords: mnemonicWords, isLoading: false, useWordAsKey: true),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: context.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        onPressed: () => SnackbarService.copyMnemonicToClipboard(context, displayMnemonic),
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text('copy'.tr(), style: scaledTextStyle(fontSize: 13, color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: context.colorScheme.onSurface,
                          backgroundColor: context.colorScheme.surfaceContainerHigh,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        onPressed: () {
                          final navigator = Navigator.of(context);
                          navigator.pop(); // Close the seed modal first
                          navigator.pushNamed(
                            RouteNames.printWallet,
                            arguments: PrintWalletArguments(sentence: displayMnemonic),
                          );
                        },
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: Text('print'.tr(), style: scaledTextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  if (!isEnglish) ...[
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.1)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          leading: Icon(Icons.translate, size: 20, color: context.colorScheme.primary),
                          title: Text(
                            'compatibility'.tr(),
                            style: scaledTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                          children: [
                            Text(
                              'compatibilityExplanation'.tr(),
                              style: scaledTextStyle(
                                fontSize: 13,
                                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: context.colorScheme.onSurface,
                                  backgroundColor: context.colorScheme.secondary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () => SnackbarService.copyMnemonicToClipboard(context, englishMnemonic),
                                icon: Icon(Icons.copy, size: 18),
                                label: Text('copyEnglishVersion'.tr(), style: scaledTextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
    );
  }
}
