import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/widgets/compact_wallet_header.dart';
import 'package:gecko/main.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/history_query.dart';
import 'package:gecko/widgets/wallet_header.dart';

/// Shows the activity/transaction history in a desktop modal.
Future<void> showDesktopActivityModal(
  BuildContext context, {
  required String address,
  String? username,
  VoidCallback? onBack,
}) {
  return showDesktopModal(
    context: context,
    size: DesktopModalSize.large,
    contentPadding: EdgeInsets.zero,
    showCloseButton: true,
    title: 'displayNActivity'.tr(),
    onBack: onBack,
    headerBackgroundColorBuilder: (context, ref) => walletHeaderSurfaceColor(context, ref, address),
    builder: (modalContext) => DesktopModalScope(
      reopenCurrentModal: () =>
          showDesktopActivityModal(Gecko.navigatorContext!, address: address, username: username, onBack: onBack),
      child: _DesktopActivityContent(address: address, username: username),
    ),
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
    // Same tint as the modal title bar above, so the header reads as one
    // continuous surface (rounded only at the bottom, where it meets the list).
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      child: Container(
        color: walletHeaderSurfaceColor(context, ref, widget.address),
        child: CompactWalletHeader(address: widget.address, showBackButton: false),
      ),
    );
  }
}
