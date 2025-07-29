import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/utils/debug_test_wallet.dart';
import 'package:durt2/durt2.dart' show Networks, Utils;

/// Test wallet button that only shows in debug mode when connected to local Duniter network
class TestWalletButton extends ConsumerWidget {
  const TestWalletButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch connection status to make this reactive
    ref.watch(duniterConnectionStatusProvider);

    if (!kDebugMode) return const SizedBox.shrink();

    // Check if current Duniter endpoint is local
    final currentEndpoint = Networks.duniterEndpoint;
    if (currentEndpoint.isEmpty) return const SizedBox.shrink();

    if (!Utils.isLocalEndpoint(currentEndpoint)) return const SizedBox.shrink();

    return Column(
      children: [
        ScaledSizedBox(height: scaleSize(17)),
        ScaledSizedBox(
          width: 330,
          height: 60,
          child: OutlinedButton(
            style:
                OutlinedButton.styleFrom(
                  side: BorderSide(width: scaleSize(2), color: Colors.orange),
                  padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                ).copyWith(
                  elevation: WidgetStateProperty.resolveWith<double>((Set<WidgetState> states) {
                    if (states.contains(WidgetState.pressed)) return 0;
                    return 4;
                  }),
                  shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.15)),
                ),
            onPressed: () => DebugTestWalletService.importTestWallet(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bug_report, color: Colors.orange, size: scaleSize(20)),
                ScaledSizedBox(width: 8),
                Text(
                  "Import Test Wallet (Dev Mode)",
                  style: scaledTextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
