import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/utils.dart';
import 'package:intl/intl.dart';

/// Holds aggregated transaction totals for a single contact.
class ContactAnalysisResult {
  /// The contact's blockchain address.
  final String address;

  /// The resolved human-readable name, if available.
  final String? username;

  /// Total amount sent to this contact (in centimes).
  final BigInt totalSent;

  /// Total amount received from this contact (in centimes).
  final BigInt totalReceived;

  /// Number of outgoing transactions to this contact.
  final int sentCount;

  /// Number of incoming transactions from this contact.
  final int receivedCount;

  ContactAnalysisResult({
    required this.address,
    this.username,
    BigInt? totalSent,
    BigInt? totalReceived,
    this.sentCount = 0,
    this.receivedCount = 0,
  }) : totalSent = totalSent ?? BigInt.zero,
       totalReceived = totalReceived ?? BigInt.zero;

  /// Total number of transactions (sent + received).
  int get transactionCount => sentCount + receivedCount;
}

/// Stateless service that performs transaction queries, aggregation, and
/// markdown report generation for the market analysis feature.
class MarketAnalysisService {
  /// Fetches all paginated transaction pages between [walletAddress] and
  /// [contactAddress] within the given date range.
  ///
  /// Returns an accumulated list of [TransactionDisplayItem] across all pages.
  /// Returns an empty list if the Squid indexer is offline.
  Future<List<TransactionDisplayItem>> fetchAllPages(
    String walletAddress,
    String contactAddress,
    DateTime startDate,
    DateTime endDate,
    DateTime genesisTime,
  ) async {
    final filters = d.TransactionFilters(
      addresses: [contactAddress],
      exactMatchAddress: true,
      startDate: startDate.toUtc(),
      endDate: endDate.toUtc(),
    );

    final allItems = <TransactionDisplayItem>[];
    String? cursor;

    while (true) {
      final result = await d.SquidService.client.getAccountHistoryFiltered(
        walletAddress,
        number: 50,
        cursor: cursor,
        filters: filters,
      );

      if (result == null) {
        // Squid offline -- return what we have so far (empty on first call).
        return allItems;
      }

      for (final node in result.items) {
        allItems.add(TransactionDisplayItem.fromFilteredGraphQLNode(node, walletAddress, genesisTime));
      }

      if (!result.hasNextPage) break;
      cursor = result.endCursor;
    }

    return allItems;
  }

  /// Aggregates a list of transaction items into sent/received totals for
  /// [contactAddress].
  ContactAnalysisResult aggregateTransactions(List<TransactionDisplayItem> items, String contactAddress) {
    var totalSent = BigInt.zero;
    var totalReceived = BigInt.zero;
    var sentCount = 0;
    var receivedCount = 0;
    String? username;

    for (final item in items) {
      if (item.isReceived) {
        totalReceived += item.amount;
        receivedCount++;
      } else {
        totalSent += item.amount;
        sentCount++;
      }
      if (username == null && item.username != null && item.username!.isNotEmpty) {
        username = item.username;
      }
    }

    return ContactAnalysisResult(
      address: contactAddress,
      username: username,
      totalSent: totalSent,
      totalReceived: totalReceived,
      sentCount: sentCount,
      receivedCount: receivedCount,
    );
  }

  /// Discovers addresses involved in [allItems] that are not the
  /// [walletAddress] or any of the [selectedAddresses].
  ///
  /// Returns a map from discovered address to its aggregated result.
  Map<String, ContactAnalysisResult> discoverOtherContacts(
    List<TransactionDisplayItem> allItems,
    String walletAddress,
    Set<String> selectedAddresses,
  ) {
    // Group items by the "other party" address field.
    final itemsByAddress = <String, List<TransactionDisplayItem>>{};

    for (final item in allItems) {
      final addr = item.address;
      if (addr.isEmpty || addr == walletAddress || selectedAddresses.contains(addr)) {
        continue;
      }
      itemsByAddress.putIfAbsent(addr, () => []).add(item);
    }

    final results = <String, ContactAnalysisResult>{};
    for (final entry in itemsByAddress.entries) {
      results[entry.key] = aggregateTransactions(entry.value, entry.key);
    }

    return results;
  }

  /// Generates a structured markdown report summarising the analysis.
  ///
  /// Amounts are converted from centimes to G1 with two decimal places for the
  /// text output only.
  String generateMarkdownReport({
    required String walletName,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, ContactAnalysisResult> contactResults,
    required Map<String, ContactAnalysisResult> otherContactResults,
  }) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    final buf = StringBuffer();

    buf.writeln('# Market Analysis');
    buf.writeln('**Wallet:** $walletName');
    buf.writeln('**Period:** ${dateFmt.format(startDate)} - ${dateFmt.format(endDate)}');
    buf.writeln();

    // Selected contacts table
    buf.writeln('## Summary');
    buf.writeln('| Contact | Sent | Received | Transactions |');
    buf.writeln('|---------|------|----------|-------------|');

    var grandSent = BigInt.zero;
    var grandReceived = BigInt.zero;
    var grandCount = 0;

    for (final r in contactResults.values) {
      final name = r.username ?? getShortPubkey(r.address);
      buf.writeln('| $name | ${_fmtAmount(r.totalSent)} | ${_fmtAmount(r.totalReceived)} | ${r.transactionCount} |');
      grandSent += r.totalSent;
      grandReceived += r.totalReceived;
      grandCount += r.transactionCount;
    }

    buf.writeln('| **Total** | **${_fmtAmount(grandSent)}** | **${_fmtAmount(grandReceived)}** | **$grandCount** |');

    // Other contacts section (only if non-empty)
    if (otherContactResults.isNotEmpty) {
      buf.writeln();
      buf.writeln('## Other Contacts');
      buf.writeln('| Contact | Sent | Received | Transactions |');
      buf.writeln('|---------|------|----------|-------------|');

      for (final r in otherContactResults.values) {
        final name = r.username ?? getShortPubkey(r.address);
        buf.writeln('| $name | ${_fmtAmount(r.totalSent)} | ${_fmtAmount(r.totalReceived)} | ${r.transactionCount} |');
      }
    }

    return buf.toString();
  }

  /// Formats a BigInt centimes amount as a G1 string with two decimal places.
  String _fmtAmount(BigInt centimes) {
    return (centimes.toDouble() / 100).toStringAsFixed(2);
  }
}

/// Provides the [MarketAnalysisService] singleton.
final marketAnalysisServiceProvider = Provider<MarketAnalysisService>((ref) {
  return MarketAnalysisService();
});
