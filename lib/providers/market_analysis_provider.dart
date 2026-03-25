import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/market_analysis_service.dart';

/// Immutable state for the market analysis feature.
class MarketAnalysisState {
  /// Start of the analysis period.
  final DateTime? startDate;

  /// End of the analysis period.
  final DateTime? endDate;

  /// Addresses of contacts selected for analysis.
  final Set<String> selectedContactAddresses;

  /// Per-contact aggregated results (selected contacts).
  final Map<String, ContactAnalysisResult> contactResults;

  /// Discovered contacts not in the initial selection.
  final Map<String, ContactAnalysisResult> otherContactResults;

  /// Whether an analysis is currently running.
  final bool isAnalyzing;

  /// Number of contacts already processed in the current run.
  final int processedContacts;

  /// Total number of contacts to process in the current run.
  final int totalContacts;

  /// Human-readable error key, if the last operation failed.
  final String? error;

  const MarketAnalysisState({
    this.startDate,
    this.endDate,
    this.selectedContactAddresses = const {},
    this.contactResults = const {},
    this.otherContactResults = const {},
    this.isAnalyzing = false,
    this.processedContacts = 0,
    this.totalContacts = 0,
    this.error,
  });

  MarketAnalysisState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? selectedContactAddresses,
    Map<String, ContactAnalysisResult>? contactResults,
    Map<String, ContactAnalysisResult>? otherContactResults,
    bool? isAnalyzing,
    int? processedContacts,
    int? totalContacts,
    String? error,
    bool clearError = false,
  }) {
    return MarketAnalysisState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedContactAddresses: selectedContactAddresses ?? this.selectedContactAddresses,
      contactResults: contactResults ?? this.contactResults,
      otherContactResults: otherContactResults ?? this.otherContactResults,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      processedContacts: processedContacts ?? this.processedContacts,
      totalContacts: totalContacts ?? this.totalContacts,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Grand total amount sent across all selected contacts.
  BigInt get totalSent => contactResults.values.fold(BigInt.zero, (sum, r) => sum + r.totalSent);

  /// Grand total amount received across all selected contacts.
  BigInt get totalReceived => contactResults.values.fold(BigInt.zero, (sum, r) => sum + r.totalReceived);

  /// Grand total transaction count across all selected contacts.
  int get totalTransactionCount => contactResults.values.fold(0, (sum, r) => sum + r.transactionCount);

  /// Whether the analysis can be started (dates and contacts are set).
  bool get canAnalyze => startDate != null && endDate != null && selectedContactAddresses.isNotEmpty;

  /// Whether previous results are available.
  bool get hasResults => contactResults.isNotEmpty;
}

/// Notifier that orchestrates the market analysis workflow: date range
/// selection, contact toggling, sequential per-contact queries with
/// progressive state updates, and other-contacts discovery.
class MarketAnalysisNotifier extends Notifier<MarketAnalysisState> {
  @override
  MarketAnalysisState build() => const MarketAnalysisState();

  /// Sets the analysis date range.
  ///
  /// Validates that the range does not exceed 365 days (D-02). If exceeded,
  /// sets an error and leaves the dates unchanged.
  void setDateRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    if (days > 365) {
      state = state.copyWith(error: 'dateRangeExceeded');
      return;
    }
    state = state.copyWith(startDate: start, endDate: end, clearError: true);
  }

  /// Adds or removes [address] from the selected contacts set.
  void toggleContact(String address) {
    final current = Set<String>.from(state.selectedContactAddresses);
    if (current.contains(address)) {
      current.remove(address);
    } else {
      current.add(address);
    }
    state = state.copyWith(selectedContactAddresses: current);
  }

  /// Replaces the selection with all provided [addresses] (D-04 select all).
  void selectAllContacts(List<String> addresses) {
    state = state.copyWith(selectedContactAddresses: addresses.toSet());
  }

  /// Clears the contact selection (D-04 deselect all).
  void deselectAllContacts() {
    state = state.copyWith(selectedContactAddresses: {});
  }

  /// Runs the full analysis for [walletAddress].
  ///
  /// Loops through each selected contact sequentially, updates state
  /// progressively after each contact, then discovers other contacts from
  /// the collected transaction data.
  Future<void> runAnalysis(String walletAddress) async {
    // Pre-flight: check Squid connectivity.
    final squidStatus = ref.read(squidConnectionStatusProvider);
    if (squidStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(error: 'noNetworkConnection');
      return;
    }

    final addresses = state.selectedContactAddresses.toList();
    state = state.copyWith(
      isAnalyzing: true,
      contactResults: {},
      otherContactResults: {},
      processedContacts: 0,
      totalContacts: addresses.length,
      clearError: true,
    );

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);
      if (genesisTime == null) {
        state = state.copyWith(isAnalyzing: false, error: 'storageNotReady');
        return;
      }

      final service = ref.read(marketAnalysisServiceProvider);
      final squid = ref.read(squidServiceProvider);
      final allItems = <TransactionDisplayItem>[];
      final results = <String, ContactAnalysisResult>{};

      for (var i = 0; i < addresses.length; i++) {
        final contactAddress = addresses[i];

        // Fetch all pages for this contact.
        final items = await service.fetchAllPages(
          walletAddress,
          contactAddress,
          state.startDate!,
          state.endDate!,
          genesisTime,
        );

        allItems.addAll(items);

        // Aggregate.
        var result = service.aggregateTransactions(items, contactAddress);

        // Resolve username via Squid indexer if the transaction data had none.
        if (result.username == null) {
          final resolved = squid.walletNameIndexer[contactAddress];
          if (resolved != null) {
            result = ContactAnalysisResult(
              address: result.address,
              username: resolved,
              totalSent: result.totalSent,
              totalReceived: result.totalReceived,
              sentCount: result.sentCount,
              receivedCount: result.receivedCount,
            );
          }
        }

        results[contactAddress] = result;

        // Progressive state update.
        state = state.copyWith(
          contactResults: Map.unmodifiable(results),
          processedContacts: i + 1,
        );
      }

      // Discover other contacts.
      var otherResults = service.discoverOtherContacts(
        allItems,
        walletAddress,
        state.selectedContactAddresses,
      );

      // Resolve names for discovered contacts.
      final resolved = <String, ContactAnalysisResult>{};
      for (final entry in otherResults.entries) {
        final r = entry.value;
        if (r.username == null) {
          final name = squid.walletNameIndexer[entry.key];
          if (name != null) {
            resolved[entry.key] = ContactAnalysisResult(
              address: r.address,
              username: name,
              totalSent: r.totalSent,
              totalReceived: r.totalReceived,
              sentCount: r.sentCount,
              receivedCount: r.receivedCount,
            );
            continue;
          }
        }
        resolved[entry.key] = r;
      }

      state = state.copyWith(
        otherContactResults: Map.unmodifiable(resolved),
        isAnalyzing: false,
      );
    } catch (e, st) {
      log.e('Market analysis failed', error: e, stackTrace: st);
      state = state.copyWith(isAnalyzing: false, error: e.toString());
    }
  }

  /// Resets the notifier to its initial state.
  void reset() {
    state = const MarketAnalysisState();
  }
}

/// Provides the [MarketAnalysisNotifier] for the market analysis feature.
final marketAnalysisProvider = NotifierProvider<MarketAnalysisNotifier, MarketAnalysisState>(
  MarketAnalysisNotifier.new,
);
