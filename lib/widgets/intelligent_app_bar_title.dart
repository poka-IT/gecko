import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/datapod_avatar.dart';

class IntelligentAppBarTitle extends ConsumerWidget {
  const IntelligentAppBarTitle({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityNameAsync = ref.watch(identityNameStreamProvider(address));
    final idtyStatusAsync = ref.watch(hybridIdtyStatusProvider(address));
    final balanceAsync = ref.watch(smartBalanceStreamProvider(address));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        DatapodAvatar(address: address, size: 24),
        const SizedBox(width: 8),
        // Identity name or short address
        Expanded(child: _buildTitle(identityNameAsync, idtyStatusAsync)),
        const SizedBox(width: 8),
        // Balance
        if (balanceAsync.hasValue)
          BalanceDisplay(value: balanceAsync.value!.transferableBalance, size: 14, fontWeight: FontWeight.w500),
      ],
    );
  }

  Widget _buildTitle(AsyncValue identityNameAsync, AsyncValue idtyStatusAsync) {
    if (identityNameAsync.hasValue && idtyStatusAsync.hasValue) {
      final identityName = identityNameAsync.value;
      final idtyStatus = idtyStatusAsync.value!;

      if (idtyStatus != IdtyStatus.none &&
          idtyStatus != IdtyStatus.unknown &&
          identityName != null &&
          identityName.isNotEmpty) {
        return Text(
          identityName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    return Text(getShortPubkey(address), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
  }
}
