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
import 'package:gecko/widgets/market_analysis/analysis_results.dart';
import 'package:gecko/widgets/market_analysis/contact_selector.dart';
import 'package:gecko/widgets/market_analysis/date_range_selector.dart';

/// Main screen for the market analysis feature.
///
/// Provides a 3-step flow: date range selection, contact multi-selection,
/// and analysis results display with markdown export capability.
class MarketAnalysisScreen extends ConsumerStatefulWidget {
  const MarketAnalysisScreen({super.key, required this.walletAddress});

  /// Address of the wallet to analyze.
  final String walletAddress;

  @override
  ConsumerState<MarketAnalysisScreen> createState() => _MarketAnalysisScreenState();
}

class _MarketAnalysisScreenState extends ConsumerState<MarketAnalysisScreen> {
  late final MarketAnalysisNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(marketAnalysisProvider.notifier);
  }

  @override
  void dispose() {
    _notifier.reset();
    super.dispose();
  }

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

    return Scaffold(
      appBar: AppBar(title: Text('marketAnalysis'.tr())),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(scaleSize(16)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    state.error!,
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
      ),
    );
  }
}
