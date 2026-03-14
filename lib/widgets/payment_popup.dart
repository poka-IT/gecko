// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:durt2/durt2.dart'
    show
        TransactionStatus,
        WalletEntity,
        Durt,
        DuniterService,
        WalletService,
        SquidService,
        AccountPaymentStatus,
        ConnectionStatus,
        SquidAccountQueries;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/text_input_formaters.dart';
import 'package:gecko/models/transaction_in_progress_data.dart';
import 'package:gecko/models/widgets_keys.dart';

import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/trm_data_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/desktop/modals/transaction_progress_modal.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/commons/async_elevated_button.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:url_launcher/url_launcher.dart';

// Simple function to show the payment popup - no longer depends on external ref
void paymentPopup({required String toAddress, required String? username, WalletEntity? fromWallet}) {
  showModalBottomSheet<void>(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(topRight: Radius.circular(16), topLeft: Radius.circular(16)),
    ),
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 600),
    context: homeContext,
    builder: (BuildContext context) {
      return PaymentPopupWidget(toAddress: toAddress, username: username, fromWallet: fromWallet);
    },
  );
}

// Payment popup as a proper ConsumerStatefulWidget with its own ref lifecycle
class PaymentPopupWidget extends ConsumerStatefulWidget {
  final String toAddress;
  final String? username;
  final WalletEntity? fromWallet;

  const PaymentPopupWidget({super.key, required this.toAddress, required this.username, this.fromWallet});

  @override
  ConsumerState<PaymentPopupWidget> createState() => _PaymentPopupWidgetState();
}

class _PaymentPopupWidgetState extends ConsumerState<PaymentPopupWidget> {
  double fees = 0;
  static const double shapeSize = 16;
  WalletEntity? _fromWallet;
  bool canValidate = false;
  final amountFocus = FocusNode();
  final commentFocus = FocusNode();

  // Balance validation state
  BigInt? defaultWalletSpendable;
  BigInt? toAddressBalance;
  bool balancesLoaded = false;

  /// All wallets across all safes, for the dropdown list.
  List<WalletEntity> get _allWallets {
    final groups = ref.read(safeWalletGroupsProvider);
    return groups.expand((g) => g.wallets).toList();
  }

  WalletEntity get fromWallet {
    final all = _allWallets;
    if (_fromWallet != null && all.any((w) => w.address == _fromWallet!.address)) {
      return _fromWallet!;
    }
    final lastAddress = ref.read(lastPaymentWalletAddressProvider);
    if (lastAddress != null) {
      final match = all.where((w) => w.address == lastAddress).firstOrNull;
      if (match != null) return match;
    }
    if (all.isNotEmpty) return all.first;
    final first = ref.read(firstWalletProvider);
    if (first != null) return first;
    return _fromWallet ?? widget.fromWallet ?? all.first;
  }

  set fromWallet(WalletEntity value) => _fromWallet = value;

  @override
  void initState() {
    super.initState();

    // Initialize fromWallet immediately so the first build has the correct value
    if (widget.fromWallet != null) {
      _fromWallet = widget.fromWallet;
    }

    // Schedule reset state and wallet loading after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Reset state after build is complete to avoid setState during build
        resetState();

        // Load wallets and load balances after ready
        ref.read(walletsListProvider.notifier).loadWallets().then((_) {
          if (mounted) {
            // Load balances after wallets are ready
            loadBalances();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    amountFocus.dispose();
    commentFocus.dispose();
    super.dispose();
  }

  void resetState() {
    // Reset form data for the target address
    ref.read(profileViewProvider(widget.toAddress).notifier).clearForm();

    // Reset controllers to match the state
    final amountController = ref.read(payAmountControllerProvider(widget.toAddress));
    amountController.clear();

    final commentController = ref.read(payCommentControllerProvider(widget.toAddress));
    commentController.clear();
  }

  // Load balances asynchronously with proper widget lifecycle management
  Future<void> loadBalances() async {
    if (!mounted) return;

    try {
      final storageService = ref.read(storageServiceProvider);
      final (defaultBalance, toBalance) = await (
        storageService.getBalance(fromWallet.address),
        storageService.getBalance(widget.toAddress),
      ).wait;

      if (!mounted) return;

      setState(() {
        defaultWalletSpendable = defaultBalance.spendable;
        toAddressBalance = toBalance.transferableBalance;
        balancesLoaded = true;
      });
    } catch (e) {
      log.e('Error loading balances for payment validation: $e');
      if (mounted) {
        setState(() {
          // Set conservative defaults on error
          defaultWalletSpendable = BigInt.zero;
          toAddressBalance = BigInt.zero;
          balancesLoaded = true;
        });
      }
    }
  }

  Future<dynamic> deriveKeypairWithYield(String address, String pinCode, WalletService walletService) async {
    // This function yields control to the UI periodically during the derivation
    // By wrapping the heavy operation and giving the UI a chance to update

    // Yield to UI before starting
    await Future.microtask(() {});

    // Execute the derivation
    final keypair = await walletService.getKeyPairFromAddress(address: address, pinCode: pinCode);

    // Yield to UI after completion
    await Future.microtask(() {});

    return keypair;
  }

  void executeTransactionInBackground(
    WalletEntity capturedFromWallet,
    StreamController<TransactionStatus> statusController,
    String payAmount,
    String payComment,
    CurrencyDisplayMode displayMode,
    AsyncValue trmDataAsync,
    DuniterService duniterService,
    WalletService walletService,
  ) async {
    try {
      // Give UI a chance to update before heavy operations
      await Future.microtask(() {});

      // Heavy operation 1: Derive keypair (cryptographic operation)
      // Break this into smaller chunks to avoid blocking UI
      final keypair = await deriveKeypairWithYield(capturedFromWallet.address, PinCodeService.pinCode, walletService);

      // Give UI another chance to update
      await Future.microtask(() {});

      final isUdUnit = displayMode == CurrencyDisplayMode.du;
      final inputAmount = double.parse(payAmount);

      // Convert amount based on display mode
      double amountInG1;
      switch (displayMode) {
        case CurrencyDisplayMode.g1:
          amountInG1 = inputAmount; // No conversion needed
          break;
        case CurrencyDisplayMode.du:
          amountInG1 = inputAmount; // DU conversion is handled by isUd flag
          break;
        case CurrencyDisplayMode.moneyOverMembers:
          // Convert mM/N to G1: mM/N * moneyOverMembersRatio / 1000
          final trmData = trmDataAsync.maybeWhen(data: (data) => data, orElse: () => null);
          if (trmData != null) {
            amountInG1 = inputAmount * trmData.moneyOverMembersRatio / 1000.0;
          } else {
            throw Exception('TRM data not available for M/N conversion');
          }
          break;
      }

      // Execute transaction (crypto + network)
      final transactionStatus = duniterService.pay(
        keypair: keypair,
        destAddress: widget.toAddress,
        amount: amountInG1,
        comment: payComment,
        isUd: isUdUnit,
      );

      // Forward the actual transaction status to our controller
      transactionStatus.listen(
        (status) => statusController.add(status),
        onError: (error) => statusController.addError(error),
        onDone: () => statusController.close(),
      );
    } catch (e) {
      // Handle errors
      log.e('Transaction failed: $e');
      statusController.addError(e);
      statusController.close();
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final days = difference.inDays;

    if (days >= 365) {
      final years = (days / 365).floor();
      return 'timeAgoYears'.tr(args: [years.toString()]);
    } else if (days >= 30) {
      final months = (days / 30).floor();
      return 'timeAgoMonths'.tr(args: [months.toString()]);
    } else {
      return 'timeAgoDays'.tr(args: [days.toString()]);
    }
  }

  Future executeTransfert() async {
    // Capture fromWallet first, before any async operations that might dispose the widget
    // This avoids accessing ref after the widget is unmounted
    final capturedFromWallet = fromWallet;

    // Remember this wallet for next payment in this session
    ref.read(lastPaymentWalletAddressProvider.notifier).set(capturedFromWallet.address);

    // Capture all required data before any async operations that might dispose the widget
    final payAmount = ref.read(profileViewProvider(widget.toAddress)).payAmount;
    final payComment = ref.read(profileViewProvider(widget.toAddress)).payComment;
    final displayMode = ref.read(currencyDisplayModeProvider);
    final trmDataAsync = ref.read(trmDataProvider);
    final duniterService = ref.read(duniterServiceProvider);
    final walletService = ref.read(walletServiceProvider);

    // Check account status before payment (fail-open: skip if Squid unavailable)
    final squidStatus = ref.read(squidConnectionStatusProvider);
    if (squidStatus == ConnectionStatus.connected) {
      try {
        final accountStatus = await SquidService.client.getAccountPaymentStatus(widget.toAddress);
        if (accountStatus != null && accountStatus.status != AccountPaymentStatus.active) {
          final symbol = Durt.i.network.symbol;
          final (String, String) warning = switch (accountStatus.status) {
            AccountPaymentStatus.neverExisted => (
              'paymentWarningNonExistentTitle'.tr(),
              'paymentWarningNonExistentMessage'.tr(args: [symbol]),
            ),
            AccountPaymentStatus.emptied => (
              'paymentWarningEmptiedTitle'.tr(),
              'paymentWarningEmptiedMessage'.tr(
                args: [
                  symbol,
                  accountStatus.lastActivityTime != null ? _formatTimeAgo(accountStatus.lastActivityTime!) : '?',
                ],
              ),
            ),
            AccountPaymentStatus.inactive => (
              'paymentWarningInactiveTitle'.tr(),
              'paymentWarningInactiveMessage'.tr(
                args: [
                  symbol,
                  accountStatus.lastActivityTime != null ? _formatTimeAgo(accountStatus.lastActivityTime!) : '?',
                ],
              ),
            ),
            AccountPaymentStatus.active => ('', ''),
          };

          final confirmed = await showConfirmationDialog(
            context: context,
            title: warning.$1,
            message: warning.$2,
            type: ConfirmationDialogType.warning,
          );
          if (!confirmed) return;
        }
      } catch (e) {
        // Fail-open: ignore errors and proceed with payment
        log.d('Account status check failed (proceeding anyway): $e');
      }
    }

    // Close popup immediately to avoid blocking UI
    Navigator.pop(context);

    // Get PIN code first (this is usually fast)
    if (!await PinCodeService.askPinCode(wallet: fromWallet)) return;

    // Create a StreamController to control the transaction status
    final statusController = StreamController<TransactionStatus>();

    // Create a transaction data with the captured data
    final transactionData = TransactionInProgressData(
      status: statusController.stream.asBroadcastStream(),
      toAddress: widget.toAddress,
      amount: double.parse(payAmount),
      comment: payComment,
    );

    // Navigate to transaction progress view
    if (isDesktopLayout(homeContext)) {
      // Desktop: compact modal showing transaction progress
      showDesktopTransactionProgressModal(
        homeContext,
        transactionStatus: transactionData.status,
        transType: 'pay',
        fromAddress: capturedFromWallet.address,
        toAddress: widget.toAddress,
        toUsername: widget.username,
      );
    } else {
      // Mobile: full activity screen with transaction data
      Navigator.push(
        homeContext,
        MaterialPageRoute(
          builder: (context) {
            return ActivityScreen(address: capturedFromWallet.address, transactionData: transactionData);
          },
        ),
      );
    }

    // Execute heavy operations asynchronously in background
    executeTransactionInBackground(
      capturedFromWallet,
      statusController,
      payAmount,
      payComment,
      displayMode,
      trmDataAsync,
      duniterService,
      walletService,
    );
  }

  /// Returns validation error message or null if valid
  String? getValidationError() {
    if (!mounted) return null;

    final payAmount = ref.read(profileViewProvider(widget.toAddress)).payAmount;
    if (payAmount.isEmpty) return null; // No error message when empty

    if (!balancesLoaded || defaultWalletSpendable == null || toAddressBalance == null) {
      return null; // Still loading
    }

    try {
      final ratio = ref.watch(balanceRatioProvider);
      final BigInt payAmountValue = BigInt.from((double.parse(payAmount) * ratio.toDouble()).round());
      final existentialDeposit = ref.read(storageServiceProvider).currencyConstants.existentialDeposit;

      // Check each condition and return appropriate error
      if (payAmountValue <= BigInt.zero) {
        return 'invalidAmount'.tr();
      }

      if (widget.toAddress == fromWallet.address) {
        return 'cannotSendToYourself'.tr();
      }

      // spendable = max sendable with keep_alive (excludes ED and reserved).
      // Allow sending full displayed balance (spendable + ED) as transferAll.
      final displayedBalance = defaultWalletSpendable! + existentialDeposit;
      if (payAmountValue > defaultWalletSpendable! && payAmountValue != displayedBalance) {
        return 'insufficientBalance'.tr();
      }

      if (toAddressBalance! <= BigInt.zero && payAmountValue < existentialDeposit) {
        // Convert existential deposit to display units
        final displayAmount = (existentialDeposit.toDouble() / ratio.toDouble()).toStringAsFixed(2);
        return 'minimumAmountRequired'.tr(args: [displayAmount]);
      }

      return null; // All validations passed
    } catch (e) {
      return null;
    }
  }

  bool canValidatePayment() {
    return getValidationError() == null &&
        ref.read(profileViewProvider(widget.toAddress)).payAmount.isNotEmpty &&
        balancesLoaded;
  }

  @override
  Widget build(BuildContext context) {
    // Calcul de la hauteur à utiliser : on se base sur scaleSize(380)
    // Si l'écran est trop petit, on utilisera 90% de sa hauteur.
    final screenHeight = MediaQuery.of(context).size.height;
    final double desiredHeight = scaleSize(380);
    final double bottomSheetHeight = screenHeight < desiredHeight ? screenHeight * 0.9 : desiredHeight;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        // Load balances on first build and when wallet changes
        if (!balancesLoaded) {
          loadBalances().then((_) {
            if (context.mounted) {
              setState(() {
                // Trigger rebuild after balances are loaded
              });
            }
          });
        }

        canValidate = canValidatePayment();
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              // On fixe la hauteur maximale du bottom sheet
              height: bottomSheetHeight,
              decoration: ShapeDecoration(
                color: context.colorScheme.tertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(shapeSize),
                    topLeft: Radius.circular(shapeSize),
                  ),
                ),
              ),
              // Ce container contient un SingleChildScrollView pour autoriser le scroll
              // et un ConstrainedBox avec une contrainte minimale égale à la hauteur fixée.
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: bottomSheetHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: scaleSize(12),
                        bottom: scaleSize(16),
                        left: scaleSize(16),
                        right: scaleSize(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'executeATransfer'.tr(),
                                style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                key: keyPopButton,
                                iconSize: scaleSize(28),
                                icon: const Icon(Icons.cancel_outlined),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                          ScaledSizedBox(height: 4),
                          Text(
                            'from'.tr(args: ['']),
                            style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                          ),
                          ScaledSizedBox(height: 4),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blueAccent.shade200, width: 1.5),
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(0),
                            child: DropdownButton<String>(
                              dropdownColor: context.colorScheme.tertiary,
                              elevation: 12,
                              key: keyDropdownWallets,
                              value: fromWallet.address,
                              menuMaxHeight: scaleSize(270),
                              onTap: () {
                                FocusScope.of(context).requestFocus(amountFocus);
                              },
                              selectedItemBuilder: (context) {
                                return _allWallets.map((wallet) {
                                  return Container(
                                    width: scaleSize(isTall ? 315 : 310),
                                    padding: EdgeInsets.all(scaleSize(7)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        NameByAddress(wallet: wallet, fontStyle: FontStyle.normal, size: 16),
                                        const Spacer(),
                                        Balance(address: wallet.address, size: 16),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                              onChanged: (String? newSelectedWalletAddress) async {
                                if (newSelectedWalletAddress == null) return;

                                final newSelectedWallet = _allWallets.firstWhere(
                                  (wallet) => wallet.address == newSelectedWalletAddress,
                                );

                                setState(() {
                                  fromWallet = newSelectedWallet;
                                  balancesLoaded = false;
                                  defaultWalletSpendable = null;
                                  toAddressBalance = null;
                                });

                                amountFocus.requestFocus();
                              },
                              items: _allWallets.map((WalletEntity wallet) {
                                return DropdownMenuItem<String>(
                                  value: wallet.address,
                                  key: keySelectThisWallet(wallet.address),
                                  child: Container(
                                    color: context.colorScheme.tertiary,
                                    width: scaleSize(isTall ? 315 : 310),
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        NameByAddress(wallet: wallet, fontStyle: FontStyle.normal, size: 16),
                                        const Spacer(),
                                        Balance(address: wallet.address, size: 16),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          ScaledSizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'to'.tr(args: ['']),
                                style: scaledTextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              ScaledSizedBox(width: 10),
                              Text(
                                widget.username ?? getShortPubkey(widget.toAddress),
                                style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          ScaledSizedBox(height: 7),
                          Row(
                            children: [
                              Text(
                                'amount'.tr(),
                                style: scaledTextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              if (fees > 0)
                                InkWell(
                                  onTap: () => infoFeesPopup(context),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outlined,
                                        color: context.colorScheme.primary,
                                        size: scaleSize(21),
                                      ),
                                      ScaledSizedBox(width: 5),
                                      Text(
                                        'fees'.tr(args: [fees.toString(), Durt.i.network.symbol]),
                                        style: scaledTextStyle(
                                          color: context.colorScheme.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ScaledSizedBox(width: 10),
                            ],
                          ),
                          ScaledSizedBox(height: 10),
                          Focus(
                            onFocusChange: (focused) {
                              if (!commentFocus.hasFocus) {
                                setState(() {
                                  FocusScope.of(context).requestFocus(amountFocus);
                                });
                              }
                            },
                            child: TextField(
                              textInputAction: TextInputAction.done,
                              onEditingComplete: () async {
                                final isCommentVisible = ref
                                    .read(profileViewProvider(widget.toAddress))
                                    .isCommentVisible;
                                if (isCommentVisible) {
                                  commentFocus.requestFocus();
                                } else if (canValidate) {
                                  await executeTransfert();
                                }
                              },
                              key: keyAmountField,
                              controller: ref.read(payAmountControllerProvider(widget.toAddress)),
                              autofocus: true,
                              focusNode: amountFocus,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              autocorrect: false,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) async {
                                // Update Riverpod state
                                ref.read(profileViewProvider(widget.toAddress).notifier).setPayAmount(value);
                                setState(() {});
                              },
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.deny(',', replacementString: '.'),
                                FilteringTextInputFormatter.allow(RegExp(r'(^\d+\.?\d{0,2})')),
                              ],
                              decoration: InputDecoration(
                                hintText: '0.00',
                                suffix: Consumer(
                                  builder: (context, ref, _) {
                                    final displayMode = ref.watch(currencyDisplayModeProvider);

                                    String suffixText;
                                    switch (displayMode) {
                                      case CurrencyDisplayMode.g1:
                                        suffixText = Durt.i.network.symbol;
                                        break;
                                      case CurrencyDisplayMode.du:
                                        suffixText = 'ud'.tr(args: ['']);
                                        break;
                                      case CurrencyDisplayMode.moneyOverMembers:
                                        suffixText = 'M/N';
                                        break;
                                    }

                                    return GestureDetector(
                                      onTap: () {
                                        _showCurrencyModeMenu(context, ref, setState);
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(suffixText, style: const TextStyle(fontSize: 14)),
                                          ScaledSizedBox(width: 4),
                                          Icon(Icons.arrow_drop_down, size: scaleSize(16), color: Colors.grey[600]),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[500]!, width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.all(scaleSize(6)),
                              ),
                              style: scaledTextStyle(
                                fontSize: 22,
                                color: context.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Error message display
                          Builder(
                            builder: (context) {
                              final errorMessage = getValidationError();
                              return AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 150),
                                  opacity: errorMessage != null ? 1.0 : 0.0,
                                  child: errorMessage != null
                                      ? Padding(
                                          padding: EdgeInsets.only(top: scaleSize(6)),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.info_outline, size: scaleSize(14), color: Colors.orange[700]),
                                              ScaledSizedBox(width: 4),
                                              Text(
                                                errorMessage,
                                                style: scaledTextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              );
                            },
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final isCommentVisible = ref
                                  .watch(profileViewProvider(widget.toAddress))
                                  .isCommentVisible;
                              return Column(
                                children: [
                                  if (isCommentVisible) const SizedBox(height: 8),
                                  AnimatedCrossFade(
                                    duration: const Duration(milliseconds: 200),
                                    crossFadeState: isCommentVisible
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    firstChild: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: scaleSize(4), vertical: scaleSize(2)),
                                      ),
                                      icon: Icon(
                                        Icons.add_comment_outlined,
                                        size: scaleSize(18),
                                        color: Colors.grey[600],
                                      ),
                                      label: Text(
                                        'addComment'.tr(),
                                        style: scaledTextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(profileViewProvider(widget.toAddress).notifier)
                                            .toggleCommentVisibility();
                                        Future.delayed(const Duration(milliseconds: 250), () {
                                          if (context.mounted) {
                                            amountFocus.unfocus();
                                            commentFocus.requestFocus();
                                          }
                                        });
                                      },
                                    ),
                                    secondChild: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: ref.read(payCommentControllerProvider(widget.toAddress)),
                                          focusNode: commentFocus,
                                          onChanged: (value) => ref
                                              .read(profileViewProvider(widget.toAddress).notifier)
                                              .setPayComment(value),
                                          inputFormatters: [Utf8LengthLimitingTextInputFormatter(146)],
                                          textInputAction: TextInputAction.done,
                                          onEditingComplete: () async {
                                            if (canValidate) {
                                              await executeTransfert();
                                            }
                                          },
                                          maxLines: 1,
                                          style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface),
                                          decoration: InputDecoration(
                                            hintText: 'optionalComment'.tr(),
                                            hintStyle: TextStyle(color: context.colorScheme.onSurfaceVariant),
                                            filled: true,
                                            fillColor: context.colorScheme.surfaceContainer,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: scaleSize(8),
                                              vertical: scaleSize(4),
                                            ),
                                            counterText: '',
                                            suffixIcon: IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: Icon(
                                                Icons.close,
                                                size: scaleSize(16),
                                                color: context.colorScheme.onSurfaceVariant,
                                              ),
                                              onPressed: () {
                                                ref
                                                    .read(profileViewProvider(widget.toAddress).notifier)
                                                    .setPayComment('');
                                                ref
                                                    .read(profileViewProvider(widget.toAddress).notifier)
                                                    .toggleCommentVisibility();
                                                commentFocus.unfocus();
                                                amountFocus.requestFocus();
                                              },
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: context.colorScheme.outline, width: 1),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: context.colorScheme.primary, width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: AsyncElevatedButton(
                              key: keyConfirmPayment,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                elevation: 4,
                                backgroundColor: context.colorScheme.primary,
                              ),
                              onPressed: canValidate
                                  ? () async {
                                      await executeTransfert();
                                    }
                                  : null,
                              child: Text(
                                'executeTheTransfer'.tr(),
                                style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCurrencyModeMenu(BuildContext context, WidgetRef ref, StateSetter setState) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<CurrencyDisplayMode>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<CurrencyDisplayMode>(
          value: CurrencyDisplayMode.g1,
          child: Row(
            children: [
              Icon(Icons.straighten, size: scaleSize(20), color: Theme.of(context).colorScheme.primary),
              ScaledSizedBox(width: 12),
              Text(
                Durt.i.network.symbol,
                style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ],
          ),
        ),
        PopupMenuItem<CurrencyDisplayMode>(
          value: CurrencyDisplayMode.du,
          child: Row(
            children: [
              Icon(Icons.water_drop_rounded, size: scaleSize(20), color: Theme.of(context).colorScheme.primary),
              ScaledSizedBox(width: 12),
              Text('DU', style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
            ],
          ),
        ),
        PopupMenuItem<CurrencyDisplayMode>(
          value: CurrencyDisplayMode.moneyOverMembers,
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded, size: scaleSize(20), color: Theme.of(context).colorScheme.primary),
              ScaledSizedBox(width: 12),
              Text('M/N', style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
            ],
          ),
        ),
      ],
    ).then((CurrencyDisplayMode? selectedMode) {
      if (selectedMode != null) {
        // Change the currency display mode
        ref.read(currencyDisplayModeProvider.notifier).setDisplayMode(selectedMode);

        // Trigger a rebuild of the popup
        setState(() {
          // The Consumer widget will automatically update with the new mode
        });
      }
    });
  }

  Future<void> infoFeesPopup(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.colorScheme.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outlined, color: context.colorScheme.primary, size: 40),
              ScaledSizedBox(height: 20),
              Text(
                'feesExplanation'.tr(),
                textAlign: TextAlign.center,
                style: scaledTextStyle(fontSize: 19, fontWeight: FontWeight.w500),
              ),
              ScaledSizedBox(height: 30),
              Text(
                'feesExplanationDetails'.tr(),
                textAlign: TextAlign.center,
                style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w300),
              ),
              ScaledSizedBox(height: 5),
              InkWell(
                onTap: () async => await _launchUrl('https://duniter.org'),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 2),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.blueAccent, width: 1)),
                  ),
                  child: Text(
                    'moreInfo'.tr(),
                    textAlign: TextAlign.center,
                    style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  key: keyInfoPopup,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('gotit'.tr(), style: scaledTextStyle(fontSize: 20, color: const Color(0xffD80000))),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}
