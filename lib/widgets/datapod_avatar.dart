import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/widgets/smart_avatar.dart';
import 'package:provider/provider.dart' as old_provider;

class DatapodAvatar extends ConsumerWidget {
  const DatapodAvatar({super.key, required this.address, this.size = 15});

  final String address;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final isLocalWallet = myWalletProvider.isOwner(address);

    return ScaledSizedBox(
      width: size,
      height: size,
      child: isLocalWallet ? _buildLocalWalletAvatar() : _buildRemoteAvatar(ref),
    );
  }

  Widget _buildLocalWalletAvatar() {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(homeContext, listen: false);
    final wallet = myWalletProvider.getWalletDataByAddress(address);

    if (wallet?.imagePath != null && wallet!.imagePath!.isNotEmpty) {
      return SmartAvatar(imagePath: wallet.imagePath!, width: size, height: size);
    } else {
      // Use default avatar based on wallet number
      final walletNumber = wallet?.number ?? 0;
      return SmartAvatar(imagePath: 'assets/avatars/${walletNumber % 4}.png', width: size, height: size);
    }
  }

  Widget _buildRemoteAvatar(WidgetRef ref) {
    final avatarAsync = ref.watch(avatarProvider(address));

    return ClipOval(
      child: avatarAsync.when(
        data: (avatarBytes) {
          if (avatarBytes != null) {
            return Image.memory(
              avatarBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // If image loading fails, show default avatar
                return _buildDefaultAvatar();
              },
            );
          } else {
            // No avatar found, show default
            return _buildDefaultAvatar();
          }
        },
        loading: () => _buildLoadingAvatar(),
        error: (error, stackTrace) {
          // Error occurred, show default avatar
          return _buildDefaultAvatar();
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Image.asset('assets/icon_user.png', height: size, fit: BoxFit.fill);
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[300]),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
          ),
        ),
      ),
    );
  }
}
