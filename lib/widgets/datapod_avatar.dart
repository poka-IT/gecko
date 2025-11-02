import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/avatar_providers.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:provider/provider.dart' as old_provider;

class DatapodAvatar extends ConsumerWidget {
  const DatapodAvatar({super.key, required this.address, this.size = 15, this.name});

  final String address;
  final double size;
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context); // listen: true by default
    final isLocalWallet = myWalletProvider.isOwner(address);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.colorScheme.onSecondaryContainer, width: 0.2),
      ),
      child: ScaledSizedBox(
        width: size,
        height: size,
        child: isLocalWallet ? _buildLocalWalletAvatar(context) : _buildRemoteAvatar(ref),
      ),
    );
  }

  Widget _buildLocalWalletAvatar(BuildContext context) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context); // listen: true
    final wallet = myWalletProvider.getWalletDataByAddress(address);

    if (wallet?.imagePath != null && wallet!.imagePath!.isNotEmpty) {
      // For local wallets, ALWAYS show local file (not Cesium+)
      // Use CachedAvatarImage for optimal performance
      return CachedAvatarImage(
        key: ValueKey(wallet.imagePath),
        imagePath: wallet.imagePath!,
        fit: BoxFit.cover,
        isCircular: true,
      );
    } else {
      // Use default avatar based on wallet number
      final walletNumber = wallet?.number ?? 0;
      return CachedAvatarImage(
        imagePath: 'assets/avatars/${walletNumber % 4}.png',
        fit: BoxFit.cover,
        isCircular: true,
      );
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
    // If a name is provided, show name circle instead of icon_user.png
    if (name != null && name!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Theme.of(homeContext).colorScheme.primary.withValues(alpha: 0.1),
        child: Text(
          name![0].toUpperCase(),
          style: scaledTextStyle(
            fontSize: size * 0.4, // Scale font size based on avatar size
            fontWeight: FontWeight.w600,
            color: Theme.of(homeContext).colorScheme.primary,
          ),
        ),
      );
    }
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
