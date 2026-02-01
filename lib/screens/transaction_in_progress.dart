import 'package:durt2/durt2.dart' hide Provider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/transaction_status.dart';
import 'package:gecko/widgets/transaction_state_icon.dart';
import 'package:easy_localization/easy_localization.dart';

class TransactionInProgressScreen extends ConsumerStatefulWidget {
  final Stream<TransactionStatus> transactionStatus;
  final String transType;
  final String? fromAddress, toAddress, toUsername;

  const TransactionInProgressScreen({
    super.key,
    required this.transactionStatus,
    this.transType = 'pay',
    this.fromAddress,
    this.toAddress,
    this.toUsername,
  });

  @override
  ConsumerState<TransactionInProgressScreen> createState() => _TransactionInProgressScreenState();
}

class _TransactionInProgressScreenState extends ConsumerState<TransactionInProgressScreen> {
  late String _fromAddress;
  late String _toAddress;

  bool get _isSelfTransaction =>
      _fromAddress.isNotEmpty &&
      _toAddress.isNotEmpty &&
      _normalizeAddress(_fromAddress) == _normalizeAddress(_toAddress);

  String _normalizeAddress(String address) {
    if (address.length > 8) return address;
    return address;
  }

  @override
  void initState() {
    super.initState();

    final firstWallet = ref.read(firstWalletProvider);

    _fromAddress = widget.fromAddress ?? firstWallet.address;
    _toAddress = widget.toAddress ?? '';
  }

  String _getDisplayName(String address, String? providedUsername, String? identityName, String? walletName) {
    if (identityName != null && identityName.isNotEmpty) return identityName;
    if (providedUsername != null && providedUsername.isNotEmpty) return providedUsername;
    final cachedUsername = g1WalletsBox.get(address)?.username;
    if (cachedUsername != null && cachedUsername.isNotEmpty) return cachedUsername;
    if (walletName != null && walletName.isNotEmpty) return walletName;
    if (address.isNotEmpty) return getShortPubkey(address);
    return 'unknown'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final fromWalletData = ref.watch(walletByAddressProvider(_fromAddress));
    final toWalletData = ref.watch(walletByAddressProvider(_toAddress));

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'extrinsicInProgress'.tr(args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()]),
          style: scaledTextStyle(fontSize: 17, color: context.colorScheme.onSurface, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ScaledSizedBox(height: 16),
            _buildTransactionHeader(context, fromWalletData, toWalletData),
            Expanded(child: _buildStatusSection(context)),
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHeader(BuildContext context, WalletEntity? fromWalletData, WalletEntity? toWalletData) {
    if (_isSelfTransaction) {
      return _buildSelfTransactionHeader(context, fromWalletData);
    }
    return _buildTransferHeader(context, fromWalletData, toWalletData);
  }

  Widget _buildSelfTransactionHeader(BuildContext context, WalletEntity? walletData) {
    final effectiveAddress = _fromAddress.isNotEmpty ? _fromAddress : _toAddress;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16)),
      padding: EdgeInsets.all(scaleSize(16)),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(scaleSize(16)),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          DatapodAvatar(address: effectiveAddress, size: scaleSize(48)),
          ScaledSizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionTypeLabel(),
                  style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                ScaledSizedBox(height: 4),
                _buildIdentityName(
                  context,
                  effectiveAddress,
                  null,
                  walletData?.name,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferHeader(BuildContext context, WalletEntity? fromWalletData, WalletEntity? toWalletData) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16)),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(scaleSize(16)),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        children: [
          _buildParticipantRow(
            context,
            label: 'fromMinus'.tr(),
            address: _fromAddress,
            walletName: fromWalletData?.name,
            providedUsername: null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
            child: Row(
              children: [
                ScaledSizedBox(width: 20),
                Container(
                  padding: EdgeInsets.all(scaleSize(6)),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_downward_rounded, size: scaleSize(14), color: context.colorScheme.primary),
                ),
                ScaledSizedBox(width: 16),
                Expanded(child: Container(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.1))),
              ],
            ),
          ),
          _buildParticipantRow(
            context,
            label: 'toMinus'.tr(),
            address: _toAddress,
            walletName: toWalletData?.name,
            providedUsername: widget.toUsername,
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
      padding: EdgeInsets.all(scaleSize(16)),
      child: Row(
        children: [
          DatapodAvatar(address: address, size: scaleSize(48)),
          ScaledSizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: scaledTextStyle(
                    fontSize: 11,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                ScaledSizedBox(height: 4),
                _buildIdentityName(
                  context,
                  address,
                  providedUsername,
                  walletName,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityName(
    BuildContext context,
    String address,
    String? providedUsername,
    String? walletName, {
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    if (address.isEmpty) {
      return Text(
        _getDisplayName(address, providedUsername, null, walletName),
        style: scaledTextStyle(fontSize: fontSize, fontWeight: fontWeight),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final identityNameAsync = ref.watch(hybridIdentityNameProvider(address));

    return identityNameAsync.when(
      data: (identityName) {
        final displayName = _getDisplayName(address, providedUsername, identityName, walletName);
        return Text(
          displayName,
          style: scaledTextStyle(fontSize: fontSize, fontWeight: fontWeight),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
      loading: () {
        final displayName = _getDisplayName(address, providedUsername, null, walletName);
        return Text(
          displayName,
          style: scaledTextStyle(fontSize: fontSize, fontWeight: fontWeight),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
      error: (_, _) {
        final displayName = _getDisplayName(address, providedUsername, null, walletName);
        return Text(
          displayName,
          style: scaledTextStyle(fontSize: fontSize, fontWeight: fontWeight),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
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
          return const Center(child: Loading(size: 30));
        }

        final txStatus = snapshot.data!;

        // Note: Certification cache updates are handled by CertificationTransactionHelper
        // which listens to the stream independently of this widget

        final (resultText, statusColor) = _getStatusInfo(txStatus);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusIcon(context, txStatus, statusColor),
            if (txStatus.state != TransactionState.none) ...[
              ScaledSizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(32)),
                child: Text(
                  resultText,
                  textAlign: TextAlign.center,
                  style: scaledTextStyle(fontSize: 15, height: 1.5, color: context.colorScheme.onSurface),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatusIcon(BuildContext context, TransactionStatus txStatus, Color statusColor) {
    return Container(
      width: scaleSize(72),
      height: scaleSize(72),
      decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor.withValues(alpha: 0.1)),
      child: Center(child: TransactionStateIcon(txStatus.state, size: 36, stroke: 3)),
    );
  }

  (String, Color) _getStatusInfo(TransactionStatus txStatus) {
    String resultText;
    Color statusColor;

    if (txStatus.state == TransactionState.finalized) {
      if (widget.transType == 'renewMembership') {
        resultText = 'membershipRenewalConfirmed'.tr();
      } else {
        resultText = 'extrinsicValidated'.tr(args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()]);
      }
      statusColor = Colors.green;
    } else if (txStatus.state == TransactionState.error) {
      final errorParts = txStatus.errorMessage?.split('Exception: ');
      final error = errorParts != null && errorParts.length > 1 ? errorParts[1] : txStatus.errorMessage;
      resultText = errorTransactionMap[error] ?? error ?? 'unknownError'.tr();
      statusColor = Colors.red;
    } else if (txStatus.state == TransactionState.inBlock) {
      resultText = 'extrinsicValidated'.tr(args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()]);
      statusColor = Colors.green;
    } else {
      resultText = _getStatusMessage(txStatus.state);
      statusColor = context.colorScheme.primary;
    }

    return (resultText, statusColor);
  }

  String _getStatusMessage(TransactionState state) {
    return switch (state) {
      TransactionState.pending => 'sending'.tr(),
      TransactionState.retrying => 'retrying'.tr(),
      TransactionState.timeout => 'execTimeoutOver'.tr(),
      TransactionState.none => 'noTransaction'.tr(),
      _ => statusStatusMap[state] ?? 'sending'.tr(),
    };
  }

  Widget _buildCloseButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(scaleSize(24)),
      child: SizedBox(
        width: double.infinity,
        height: scaleSize(52),
        child: ElevatedButton(
          key: keyCloseTransactionScreen,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleSize(12))),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            'close'.tr(),
            style: scaledTextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
