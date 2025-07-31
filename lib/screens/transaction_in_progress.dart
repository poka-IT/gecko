import 'package:durt2/durt2.dart' hide Provider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/transaction_status.dart';
import 'package:gecko/widgets/transaction_state_icon.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:easy_localization/easy_localization.dart';

class TransactionInProgressScreen extends StatefulWidget {
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
  State<TransactionInProgressScreen> createState() => _TransactionInProgressScreenState();
}

class _TransactionInProgressScreenState extends State<TransactionInProgressScreen> {
  late String fromAddressFormat;
  late String toAddressFormat;
  late String toUsernameFormat;

  @override
  void initState() {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(homeContext, listen: false);

    String defaultWalletAddress = myWalletProvider.getDefaultWallet().address;
    String defaultWalletName = myWalletProvider.getDefaultWallet().name ?? '';
    String? walletDataName = myWalletProvider.getWalletDataByAddress(widget.toAddress ?? '')?.name;

    fromAddressFormat = widget.fromAddress ?? g1WalletsBox.get(defaultWalletAddress)?.username ?? defaultWalletName;
    toAddressFormat = widget.toAddress ?? ''; // No fallback - should not happen in normal flow
    toUsernameFormat =
        widget.toUsername ??
        walletDataName ??
        (toAddressFormat.isNotEmpty ? getShortPubkey(toAddressFormat) : 'Unknown');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.colorScheme.tertiary,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'extrinsicInProgress'.tr(args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()]),
          style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface, fontWeight: FontWeight.w500),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: context.colorScheme.tertiary,
              padding: EdgeInsets.symmetric(horizontal: scaleSize(24), vertical: scaleSize(16)),
              child: Column(
                children: [
                  Text('fromMinus'.tr(), style: scaledTextStyle(fontSize: 13, color: Colors.black54)),
                  ScaledSizedBox(height: 4),
                  Text(fromAddressFormat, style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  if (fromAddressFormat != toAddressFormat) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                      child: Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    Text('toMinus'.tr(), style: scaledTextStyle(fontSize: 13, color: Colors.black54)),
                    ScaledSizedBox(height: 4),
                    // Use reactive identity name if toAddress is available, otherwise fallback to static
                    widget.toAddress != null
                        ? Consumer(
                            builder: (context, ref, child) {
                              final identityNameAsync = ref.watch(identityNameProvider(widget.toAddress!));

                              return identityNameAsync.when(
                                data: (identityName) {
                                  // If we have an identity name, use it; otherwise fallback to static
                                  final displayName = (identityName != null && identityName.isNotEmpty)
                                      ? identityName
                                      : toUsernameFormat;
                                  return Text(
                                    displayName,
                                    style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                  );
                                },
                                loading: () => Text(
                                  toUsernameFormat,
                                  style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                error: (_, _) => Text(
                                  toUsernameFormat,
                                  style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                              );
                            },
                          )
                        : Text(toUsernameFormat, style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<TransactionStatus>(
                stream: widget.transactionStatus,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: Loading(size: 30));
                  }

                  final txStatus = snapshot.data!;
                  String resultText;

                  if (txStatus.state == TransactionState.finalized) {
                    if (widget.transType == 'renewMembership') {
                      resultText = 'membershipRenewalConfirmed'.tr();
                    } else {
                      resultText = 'extrinsicValidated'.tr(
                        args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()],
                      );
                    }
                  } else if (txStatus.state == TransactionState.error) {
                    final errorParts = txStatus.errorMessage?.split('Exception: ');
                    final error = errorParts != null && errorParts.length > 1 ? errorParts[1] : txStatus.errorMessage;
                    resultText = errorTransactionMap[error] ?? error!;
                  } else {
                    resultText = statusStatusMap[txStatus.state] ?? 'Unknown status: ${txStatus.state}';
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: scaleSize(52),
                        height: scaleSize(52),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 1),
                        ),
                        child: Center(child: TransactionStateIcon(txStatus.state)),
                      ),
                      if (txStatus.state != TransactionState.none) ...[
                        ScaledSizedBox(height: 24),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaleSize(32)),
                          child: Text(
                            resultText,
                            textAlign: TextAlign.center,
                            style: scaledTextStyle(fontSize: 15, height: 1.4, color: context.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(scaleSize(24)),
              child: SizedBox(
                width: double.infinity,
                height: scaleSize(48),
                child: ElevatedButton(
                  key: keyCloseTransactionScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'close'.tr(),
                    style: scaledTextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
