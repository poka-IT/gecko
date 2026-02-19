// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/wallet_name_service.dart';

class AddNewDerivationButton extends ConsumerWidget {
  const AddNewDerivationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsState = ref.watch(walletsListProvider);
    final derivationState = ref.watch(derivationStateProvider);

    final lastWalletNumber = walletsState.wallets.isNotEmpty ? walletsState.wallets.last.number : -1;
    String newDerivationName = WalletNameService.defaultN(lastWalletNumber + 2);

    return Padding(
      padding: EdgeInsets.all(scaleSize(11)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: InkWell(
                key: keyAddDerivation,
                onTap: () async {
                  if (!derivationState.isLoading) {
                    if (!await PinCodeService.askPinCode()) return;

                    await ref.read(walletActionsProvider.notifier).generateNewDerivation(newDerivationName);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: derivationState.isLoading
                        ? ScaledSizedBox(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 6),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate an appropriate size based on container dimensions
                              // Use the smaller dimension and scale it up for better visibility
                              final double containerSize = constraints.biggest.shortestSide;
                              final double iconSize = (containerSize * 0.75).clamp(60.0, 120.0);

                              return Icon(
                                Icons.add,
                                size: iconSize,
                                color: const Color(0xFFFCB437),
                                weight: 900, // Maximum weight for boldness
                              );
                            },
                          ),
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
