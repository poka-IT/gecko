import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/market_analysis_provider.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/market_analysis_service.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';
import 'package:gecko/widgets/market_analysis/analysis_results.dart';
import 'package:gecko/widgets/market_analysis/contact_selector.dart';
import 'package:gecko/widgets/market_analysis/date_range_selector.dart';

/// Main screen for the market analysis feature.
///
/// Provides a 3-step flow: date range selection, contact multi-selection,
/// and analysis results display with markdown export capability.
class MarketAnalysisScreen extends ConsumerStatefulWidget {
  const MarketAnalysisScreen({super.key, required this.walletAddress, this.embeddedMode = false});

  /// Address of the wallet to analyze.
  final String walletAddress;

  /// When true, omits the AppBar (used inside desktop modals).
  final bool embeddedMode;

  @override
  ConsumerState<MarketAnalysisScreen> createState() => _MarketAnalysisScreenState();
}

class _MarketAnalysisScreenState extends ConsumerState<MarketAnalysisScreen> {
  String get _walletName {
    final squid = ref.read(squidServiceProvider);
    return squid.walletNameIndexer[widget.walletAddress] ?? getShortPubkey(widget.walletAddress);
  }

  void _exportMarkdownReport() {
    final state = ref.read(marketAnalysisProvider);
    final service = ref.read(marketAnalysisServiceProvider);

    final markdown = service.generateMarkdownReport(
      walletName: _walletName,
      startDate: state.startDate!,
      endDate: state.endDate!,
      contactResults: state.contactResults,
      otherContactResults: state.otherContactResults,
    );

    Clipboard.setData(ClipboardData(text: markdown));
    SnackbarService.showMessage(context, message: 'copiedToClipboard'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketAnalysisProvider);
    final contacts = ref.watch(allContactsProvider);

    final body = SingleChildScrollView(
      padding: EdgeInsets.all(scaleSize(16)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Collapsible info banner
              const _MarketAnalysisInfoBanner(),
              ScaledSizedBox(height: 12),

              // Step 1: Date range selection
              DateRangeSelector(
                onDateRangeSelected: (start, end) {
                  ref.read(marketAnalysisProvider.notifier).setDateRange(start, end);
                },
                startDate: state.startDate,
                endDate: state.endDate,
              ),
              ScaledSizedBox(height: 20),

              // Step 2: Contact selection
              ContactSelector(
                contacts: contacts,
                selectedAddresses: state.selectedContactAddresses,
                onToggle: (addr) => ref.read(marketAnalysisProvider.notifier).toggleContact(addr),
                onSelectAll: () => ref
                    .read(marketAnalysisProvider.notifier)
                    .selectAllContacts(contacts.map((c) => c.address).toList()),
                onDeselectAll: () => ref.read(marketAnalysisProvider.notifier).deselectAllContacts(),
              ),
              ScaledSizedBox(height: 16),

              // Run Analysis button
              ElevatedButton(
                onPressed: state.canAnalyze && !state.isAnalyzing
                    ? () => ref.read(marketAnalysisProvider.notifier).runAnalysis(widget.walletAddress)
                    : null,
                child: Text('runAnalysis'.tr(), style: scaledTextStyle(fontSize: 15)),
              ),

              // Error display
              if (state.error != null) ...[
                ScaledSizedBox(height: 8),
                Text(
                  state.error!.tr(),
                  style: scaledTextStyle(fontSize: 13, color: context.geckoColors.danger),
                  textAlign: TextAlign.center,
                ),
              ],

              // Step 3: Results display
              if (state.hasResults || state.isAnalyzing)
                AnalysisResults(
                  state: state,
                  walletAddress: widget.walletAddress,
                  walletName: _walletName,
                  onExport: _exportMarkdownReport,
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.embeddedMode) return body;

    return Scaffold(
      appBar: AppBar(title: Text('marketAnalysis'.tr())),
      body: body,
    );
  }
}

/// Collapsible info banner explaining what market analysis does.
class _MarketAnalysisInfoBanner extends StatefulWidget {
  const _MarketAnalysisInfoBanner();

  @override
  State<_MarketAnalysisInfoBanner> createState() => _MarketAnalysisInfoBannerState();
}

class _MarketAnalysisInfoBannerState extends State<_MarketAnalysisInfoBanner> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.primary.withValues(alpha: 0.25);
    final bgColor = colorScheme.primary.withValues(alpha: 0.06);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header — always visible, tappable
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(14), vertical: scaleSize(12)),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: scaleSize(20), color: colorScheme.primary),
                  ScaledSizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'marketAnalysisInfoTitle'.tr(),
                      style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: scaleSize(20), color: colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),

          // Body — collapsible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(scaleSize(14), 0, scaleSize(14), scaleSize(14)),
              child: TextMarkDown(
                'marketAnalysisInfoBody'.tr(),
                style: scaledTextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
