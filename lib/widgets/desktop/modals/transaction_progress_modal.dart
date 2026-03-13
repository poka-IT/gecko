import 'package:durt2/durt2.dart' hide Provider;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/transaction_status.dart';
import 'package:gecko/widgets/transaction_state_icon.dart';

/// Adaptive navigation: desktop modal or full-screen depending on layout.
/// Use this from any screen that needs to show transaction progress.
Future<void> navigateToTransactionProgress(
  BuildContext context, {
  required Stream<TransactionStatus> transactionStatus,
  String transType = 'pay',
  String? fromAddress,
  String? toAddress,
  String? toUsername,
}) {
  if (isDesktopLayout(context)) {
    return showDesktopTransactionProgressModal(
      context,
      transactionStatus: transactionStatus,
      transType: transType,
      fromAddress: fromAddress,
      toAddress: toAddress,
      toUsername: toUsername,
    );
  } else {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionInProgressScreen(
          transactionStatus: transactionStatus,
          transType: transType,
          fromAddress: fromAddress,
          toAddress: toAddress,
          toUsername: toUsername,
        ),
      ),
    );
  }
}

/// Shows a transaction-in-progress overlay as a desktop modal.
Future<void> showDesktopTransactionProgressModal(
  BuildContext context, {
  required Stream<TransactionStatus> transactionStatus,
  String transType = 'pay',
  String? fromAddress,
  String? toAddress,
  String? toUsername,
}) {
  return showDesktopModal(
    context: context,
    size: DesktopModalSize.small,
    barrierDismissible: false,
    showCloseButton: false,
    title: 'extrinsicInProgress'.tr(args: [actionMap[transType] ?? 'strangeTransaction'.tr()]),
    contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    builder: (context) => _TransactionProgressContent(
      transactionStatus: transactionStatus,
      transType: transType,
      fromAddress: fromAddress,
      toAddress: toAddress,
      toUsername: toUsername,
    ),
  );
}

class _TransactionProgressContent extends ConsumerStatefulWidget {
  final Stream<TransactionStatus> transactionStatus;
  final String transType;
  final String? fromAddress, toAddress, toUsername;

  const _TransactionProgressContent({
    required this.transactionStatus,
    required this.transType,
    this.fromAddress,
    this.toAddress,
    this.toUsername,
  });

  @override
  ConsumerState<_TransactionProgressContent> createState() => _TransactionProgressContentState();
}

class _TransactionProgressContentState extends ConsumerState<_TransactionProgressContent> {
  late String _fromAddress;
  late String _toAddress;
  TransactionState _lastState = TransactionState.none;

  bool get _canClose =>
      _lastState == TransactionState.inBlock ||
      _lastState == TransactionState.finalized ||
      _lastState == TransactionState.error ||
      _lastState == TransactionState.timeout;

  bool get _isSelfTransaction => _fromAddress.isNotEmpty && _toAddress.isNotEmpty && _fromAddress == _toAddress;

  @override
  void initState() {
    super.initState();
    final firstWallet = ref.read(firstWalletProvider);
    _fromAddress = widget.fromAddress ?? firstWallet?.address ?? '';
    _toAddress = widget.toAddress ?? '';
  }

  String _getDisplayName(String address, String? providedUsername, String? identityName, String? walletName) {
    if (identityName != null && identityName.isNotEmpty) return identityName;
    if (providedUsername != null && providedUsername.isNotEmpty) return providedUsername;
    final cachedUsername = g1WalletsBox.get(address)?.username;
    if (cachedUsername != null && cachedUsername.isNotEmpty) return cachedUsername;
    if (walletName != null && walletName.isNotEmpty) return WalletNameService.displayName(walletName);
    if (address.isNotEmpty) return getShortPubkey(address);
    return 'unknown'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final fromWalletData = ref.watch(walletByAddressProvider(_fromAddress));
    final toWalletData = ref.watch(walletByAddressProvider(_toAddress));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Participants
        _buildParticipants(context, fromWalletData, toWalletData),
        const SizedBox(height: 24),
        // Status stream
        _buildStatusSection(context),
        const SizedBox(height: 24),
        // Close button
        _buildCloseButton(context),
      ],
    );
  }

  Widget _buildParticipants(BuildContext context, WalletEntity? fromWallet, WalletEntity? toWallet) {
    if (_isSelfTransaction) {
      return _buildSelfParticipant(context, fromWallet);
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _buildParticipantRow(context, label: 'fromMinus'.tr(), address: _fromAddress, walletName: fromWallet?.name),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_downward_rounded, size: 14, color: context.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.08))),
              ],
            ),
          ),
          _buildParticipantRow(
            context,
            label: 'toMinus'.tr(),
            address: _toAddress,
            walletName: toWallet?.name,
            providedUsername: widget.toUsername,
          ),
        ],
      ),
    );
  }

  Widget _buildSelfParticipant(BuildContext context, WalletEntity? walletData) {
    final address = _fromAddress.isNotEmpty ? _fromAddress : _toAddress;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          DatapodAvatar(address: address, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionTypeLabel(),
                  style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 3),
                _buildIdentityName(context, address, null, walletData?.name),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(
    BuildContext context, {
    required String label,
    required String address,
    String? walletName,
    String? providedUsername,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          DatapodAvatar(address: address, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: scaledTextStyle(
                    fontSize: 10,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                _buildIdentityName(context, address, providedUsername, walletName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityName(BuildContext context, String address, String? providedUsername, String? walletName) {
    if (address.isEmpty) {
      return Text(
        _getDisplayName(address, providedUsername, null, walletName),
        style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final identityNameAsync = ref.watch(hybridIdentityNameProvider(address));
    return identityNameAsync.when(
      data: (identityName) => Text(
        _getDisplayName(address, providedUsername, identityName, walletName),
        style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      loading: () => Text(
        _getDisplayName(address, providedUsername, null, walletName),
        style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      error: (_, _) => Text(
        _getDisplayName(address, providedUsername, null, walletName),
        style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getTransactionTypeLabel() {
    return switch (widget.transType) {
      'renewMembership' => 'renewingMembership'.tr(),
      'revokeIdty' => 'revokeAdhesion'.tr(),
      'comfirmIdty' => 'identityConfirm'.tr(),
      'cert' => 'certification'.tr(),
      _ => 'wallet'.tr(),
    };
  }

  Widget _buildStatusSection(BuildContext context) {
    return StreamBuilder<TransactionStatus>(
      stream: widget.transactionStatus,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 100, child: Center(child: Loading(size: 28)));
        }

        final txStatus = snapshot.data!;

        if (txStatus.state != _lastState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _lastState = txStatus.state);
          });
        }

        final (resultText, statusColor) = _getStatusInfo(txStatus, context);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor.withValues(alpha: 0.1)),
              child: Center(child: TransactionStateIcon(txStatus.state, size: 32, stroke: 2.5)),
            ),
            if (txStatus.state != TransactionState.none) ...[
              const SizedBox(height: 16),
              Text(
                resultText,
                textAlign: TextAlign.center,
                style: scaledTextStyle(fontSize: 14, height: 1.5, color: context.colorScheme.onSurface),
              ),
            ],
          ],
        );
      },
    );
  }

  (String, Color) _getStatusInfo(TransactionStatus txStatus, BuildContext context) {
    if (txStatus.state == TransactionState.finalized) {
      if (widget.transType == 'renewMembership') {
        return ('membershipRenewalConfirmed'.tr(), Colors.green);
      }
      return ('extrinsicFinalized'.tr(args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()]), Colors.green);
    } else if (txStatus.state == TransactionState.error) {
      final errorParts = txStatus.errorMessage?.split('Exception: ');
      final error = errorParts != null && errorParts.length > 1 ? errorParts[1] : txStatus.errorMessage;
      return (lookupTransactionError(error) ?? '${'technicalError'.tr()}: $error', Colors.red);
    } else if (txStatus.state == TransactionState.inBlock) {
      return ('extrinsicValidated'.tr(args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()]), Colors.green);
    } else {
      final msg = switch (txStatus.state) {
        TransactionState.pending => 'sending'.tr(),
        TransactionState.retrying => 'retrying'.tr(),
        TransactionState.timeout => 'execTimeoutOver'.tr(),
        TransactionState.none => 'noTransaction'.tr(),
        _ => statusStatusMap[txStatus.state] ?? 'sending'.tr(),
      };
      return (msg, context.colorScheme.primary);
    }
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _canClose ? context.colorScheme.primary : context.colorScheme.surfaceContainerHigh,
          foregroundColor: _canClose ? Colors.white : context.colorScheme.onSurface.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _canClose ? () => Navigator.pop(context) : null,
        child: Text('close'.tr(), style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
