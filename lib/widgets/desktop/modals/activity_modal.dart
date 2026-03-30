import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/widgets/compact_wallet_header.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/history_query.dart';

/// Shows the activity/transaction history in a desktop modal.
Future<void> showDesktopActivityModal(BuildContext context, {required String address, String? username}) {
  return showDesktopModal(
    context: context,
    size: DesktopModalSize.large,
    contentPadding: EdgeInsets.zero,
    showCloseButton: true,
    title: 'displayNActivity'.tr(),
    builder: (context) => _DesktopActivityContent(address: address, username: username),
  );
}

class _DesktopActivityContent extends ConsumerStatefulWidget {
  final String address;
  final String? username;

  const _DesktopActivityContent({required this.address, this.username});

  @override
  ConsumerState<_DesktopActivityContent> createState() => _DesktopActivityContentState();
}

class _DesktopActivityContentState extends ConsumerState<_DesktopActivityContent> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(transactionFiltersProvider.notifier).reset();
    });
    if (ref.read(storageStateProvider) == StorageState.onlineMode) {
      ref.read(storageServiceProvider).getOldOwnerKey(widget.address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCompactHeader(context),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: HistoryQuery(address: widget.address),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    final balanceAsync = ref.watch(smartBalanceStreamProvider(widget.address));

    final Color backgroundColor;
    if (balanceAsync.isLoading && !balanceAsync.hasValue) {
      backgroundColor = context.colorScheme.tertiary;
    } else {
      final balance = balanceAsync.value?.transferableBalance;
      final isEmptyWallet = balance == null || balance == BigInt.zero;
      backgroundColor = isEmptyWallet ? context.colorScheme.error : context.colorScheme.tertiary;
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      child: Container(
        color: backgroundColor,
        child: CompactWalletHeader(address: widget.address, showBackButton: false),
      ),
    );
  }
}
