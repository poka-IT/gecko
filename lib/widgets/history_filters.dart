import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/widgets/unified_transaction_filters.dart';

/// Simple wrapper for the unified transaction filter widget
class TransactionFilter extends ConsumerWidget {
  const TransactionFilter({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UnifiedTransactionFilters(address: address);
  }
}
