import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/widgets/transaction_filters.dart';

/// Simple wrapper for the generic transaction filter widget in account mode
class TransactionFilter extends ConsumerWidget {
  const TransactionFilter({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TransactionFilters(mode: FilterMode.account, address: address);
  }
}
