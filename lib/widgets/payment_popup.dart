// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:durt2/durt2.dart' show TransactionStatus, WalletEntity, Durt;
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
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/providers_deprecated/wallets_profiles.dart';
import 'package:gecko/screens/activity.dart';

import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:url_launcher/url_launcher.dart';

// Simple function to show the payment popup - no longer depends on external ref
void paymentPopup({required String toAddress, required String? username}) {
  showModalBottomSheet<void>(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(topRight: Radius.circular(16), topLeft: Radius.circular(16)),
    ),
    isScrollControlled: true,
    context: homeContext,
    builder: (BuildContext context) {
      return PaymentPopupWidget(toAddress: toAddress, username: username);
    },
  );
}

// Payment popup as a proper ConsumerStatefulWidget with its own ref lifecycle
class PaymentPopupWidget extends ConsumerStatefulWidget {
  final String toAddress;
  final String? username;

  const PaymentPopupWidget({super.key, required this.toAddress, required this.username});

  @override
  ConsumerState<PaymentPopupWidget> createState() => _PaymentPopupWidgetState();
}

class _PaymentPopupWidgetState extends ConsumerState<PaymentPopupWidget> {
  double fees = 0;
  static const double shapeSize = 16;
  late WalletEntity defaultWallet;
  bool canValidate = false;
  final amountFocus = FocusNode();
  final commentFocus = FocusNode();

  // Balance validation state
  BigInt? defaultWalletBalance;
  BigInt? toAddressBalance;
  bool balancesLoaded = false;

  late WalletsProfilesProvider walletViewProvider;
  late MyWalletsProvider myWalletProvider;

  @override
  void initState() {
    super.initState();

    // Initialize providers
    walletViewProvider = old_provider.Provider.of<WalletsProfilesProvider>(context, listen: false);
    myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    // Initialize default wallet
    defaultWallet = myWalletProvider.getDefaultWallet();

    // Schedule reset state and wallet loading after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Reset state after build is complete to avoid setState during build
        resetState();

        // Load wallets and sort them
        myWalletProvider.readAllWallets().then((value) {
          if (mounted) {
            myWalletProvider.listWallets.sort((a, b) => (a.derivation ?? -1).compareTo(b.derivation ?? -1));
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
    walletViewProvider.payAmount.text = '';
    walletViewProvider.isCommentVisible = false;
    walletViewProvider.comment = '';
    walletViewProvider.payComment.text = '';
  }

  // Load balances asynchronously with proper widget lifecycle management
  Future<void> loadBalances() async {
    if (!mounted) return;

    try {
      final storageService = ref.read(storageServiceProvider);
      final defaultBalance = await storageService.getBalance(defaultWallet.address);

      if (!mounted) return;

      final toBalance = await storageService.getBalance(widget.toAddress);

      if (!mounted) return;

      setState(() {
        defaultWalletBalance = defaultBalance.transferableBalance;
        toAddressBalance = toBalance.transferableBalance;
        balancesLoaded = true;
      });
    } catch (e) {
      log.e('Error loading balances for payment validation: $e');
      if (mounted) {
        setState(() {
          // Set conservative defaults on error
          defaultWalletBalance = BigInt.zero;
          toAddressBalance = BigInt.zero;
          balancesLoaded = true;
        });
      }
    }
  }

  Future<dynamic> deriveKeypairWithYield(String address, String pinCode) async {
    // This function yields control to the UI periodically during the derivation
    // By wrapping the heavy operation and giving the UI a chance to update

    // Yield to UI before starting
    await Future.microtask(() {});

    // Execute the derivation
    final keypair = await ref.read(walletServiceProvider).getKeyPairFromAddress(address: address, pinCode: pinCode);

    // Yield to UI after completion
    await Future.microtask(() {});

    return keypair;
  }

  void executeTransactionInBackground(StreamController<TransactionStatus> statusController) async {
    try {
      // Give UI a chance to update before heavy operations
      await Future.microtask(() {});

      // Heavy operation 1: Derive keypair (cryptographic operation)
      // Break this into smaller chunks to avoid blocking UI
      final keypair = await deriveKeypairWithYield(defaultWallet.address, myWalletProvider.pinCode);

      // Give UI another chance to update
      await Future.microtask(() {});

      final displayMode = ref.read(currencyDisplayModeProvider);
      final isUdUnit = displayMode == CurrencyDisplayMode.du;
      final inputAmount = double.parse(walletViewProvider.payAmount.text);

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
          final trmDataAsync = ref.read(trmDataProvider);
          final trmData = trmDataAsync.maybeWhen(data: (data) => data, orElse: () => null);
          if (trmData != null) {
            amountInG1 = inputAmount * trmData.moneyOverMembersRatio / 1000.0;
          } else {
            throw Exception('TRM data not available for M/N conversion');
          }
          break;
      }

      // Execute transaction (crypto + network)
      final transactionStatus = ref
          .read(duniterServiceProvider)
          .pay(
            keypair: keypair,
            destAddress: widget.toAddress,
            amount: amountInG1,
            comment: walletViewProvider.comment,
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

  Future executeTransfert() async {
    // Close popup immediately to avoid blocking UI
    Navigator.pop(context);

    // Get PIN code first (this is usually fast)
    if (!await myWalletProvider.askPinCode()) return;

    // Create a StreamController to control the transaction status
    final statusController = StreamController<TransactionStatus>();

    // Create a transaction data with the controlled stream (as broadcast to allow multiple listeners)
    final transactionData = TransactionInProgressData(
      status: statusController.stream.asBroadcastStream(),
      toAddress: widget.toAddress,
      amount: double.parse(walletViewProvider.payAmount.text),
      comment: walletViewProvider.comment,
    );

    // Navigate immediately to activity screen with loading state
    Navigator.push(
      homeContext,
      MaterialPageRoute(
        builder: (context) {
          return ActivityScreen(address: defaultWallet.address, transactionData: transactionData);
        },
      ),
    );

    // Execute heavy operations asynchronously in background
    executeTransactionInBackground(statusController);
  }

  bool canValidatePayment() {
    if (!mounted) return false;

    // Vérification du montant saisi
    final payAmount = walletViewProvider.payAmount.text;
    if (payAmount.isEmpty) return false;

    // Wait for balances to be loaded before validating
    if (!balancesLoaded || defaultWalletBalance == null || toAddressBalance == null) {
      return false; // Cannot validate without balance data
    }

    try {
      // Get balance ratio using the provider
      final ratio = ref.watch(balanceRatioProvider);

      // Calculate amount value in base units
      final BigInt payAmountValue = BigInt.from((double.parse(payAmount) * ratio.toDouble()).round());

      final existentialDeposit = ref.read(storageServiceProvider).currencyConstants.existentialDeposit;

      // Vérifications de validité avec les vraies balances
      final bool isAmountValid = payAmountValue > BigInt.zero;
      final bool isNotSendingToSelf = widget.toAddress != defaultWallet.address;
      final BigInt transferableBalance = defaultWalletBalance! - existentialDeposit;
      final bool hasEnoughBalance = (payAmountValue <= transferableBalance) || defaultWalletBalance == payAmountValue;
      final bool respectsExistentialDeposit = toAddressBalance! > BigInt.zero || payAmountValue >= existentialDeposit;

      return isAmountValid && isNotSendingToSelf && hasEnoughBalance && respectsExistentialDeposit;
    } catch (e) {
      // If ref is disposed or any error occurs, return false for safety
      log.e('Error in canValidatePayment: $e');
      return false;
    }
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
        return Padding(
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
                            // The dropdown's value is the ADDRESS of the default wallet.
                            value: defaultWallet.address,
                            menuMaxHeight: scaleSize(270),
                            onTap: () {
                              FocusScope.of(context).requestFocus(amountFocus);
                            },
                            // This builds the widget that's visible when the dropdown is closed.
                            selectedItemBuilder: (context) {
                              return myWalletProvider.listWallets.map((wallet) {
                                return Container(
                                  // The dropdown automatically selects the correct widget to show.
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
                            // This is called when the user selects a new item.
                            onChanged: (String? newSelectedWalletAddress) async {
                              if (newSelectedWalletAddress == null) return;

                              // Find the full WalletEntity object that corresponds to the selected address.
                              final newSelectedWallet = myWalletProvider.listWallets.firstWhere(
                                (wallet) => wallet.address == newSelectedWalletAddress,
                              );

                              // Update your local state and trigger a rebuild.
                              setState(() {
                                defaultWallet = newSelectedWallet;
                                // Reset balance loading state when wallet changes
                                balancesLoaded = false;
                                defaultWalletBalance = null;
                                toAddressBalance = null;
                              });

                              // Execute your original logic.
                              await ref.read(walletServiceProvider).setDefaultAddress(newSelectedWallet.address);
                              amountFocus.requestFocus();
                            },
                            // This builds the list of choices the user sees when the dropdown is open.
                            items: myWalletProvider.listWallets.map((WalletEntity wallet) {
                              return DropdownMenuItem<String>(
                                // Each item's value is its unique ADDRESS string.
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
                                    Icon(Icons.info_outlined, color: context.colorScheme.primary, size: scaleSize(21)),
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
                              if (walletViewProvider.isCommentVisible) {
                                commentFocus.requestFocus();
                              } else if (canValidate) {
                                await executeTransfert();
                              }
                            },
                            key: keyAmountField,
                            controller: walletViewProvider.payAmount,
                            autofocus: true,
                            focusNode: amountFocus,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            autocorrect: false,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) async {
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
                        if (walletViewProvider.isCommentVisible) const SizedBox(height: 8),
                        old_provider.Consumer<WalletsProfilesProvider>(
                          builder: (context, profileProvider, _) {
                            return AnimatedCrossFade(
                              duration: const Duration(milliseconds: 200),
                              crossFadeState: profileProvider.isCommentVisible
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: scaleSize(4), vertical: scaleSize(2)),
                                ),
                                icon: Icon(Icons.add_comment_outlined, size: scaleSize(18), color: Colors.grey[600]),
                                label: Text(
                                  'addComment'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onPressed: () {
                                  profileProvider.toggleCommentVisibility();
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
                                    controller: profileProvider.payComment,
                                    focusNode: commentFocus,
                                    onChanged: (value) => profileProvider.comment = value,
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
                                      hintStyle: TextStyle(color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.white.withAlpha(128),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: scaleSize(8),
                                        vertical: scaleSize(4),
                                      ),
                                      counterText: '',
                                      suffixIcon: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(Icons.close, size: scaleSize(16), color: Colors.grey[600]),
                                        onPressed: () {
                                          profileProvider.comment = '';
                                          profileProvider.toggleCommentVisibility();
                                          commentFocus.unfocus();
                                          amountFocus.requestFocus();
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
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
