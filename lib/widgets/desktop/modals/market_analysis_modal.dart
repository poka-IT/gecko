import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/market_analysis_screen.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';

/// Shows the market analysis screen in a desktop modal.
Future<void> showDesktopMarketAnalysisModal(BuildContext context, {required String walletAddress}) {
  return showDesktopModal(
    context: context,
    size: DesktopModalSize.large,
    contentPadding: EdgeInsets.zero,
    showCloseButton: true,
    title: 'marketAnalysis'.tr(),
    builder: (context) => MarketAnalysisScreen(walletAddress: walletAddress, embeddedMode: true),
  );
}
