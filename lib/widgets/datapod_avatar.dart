import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/avatar_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:gecko/widgets/commons/shimmer_avatar.dart';

class DatapodAvatar extends ConsumerWidget {
  const DatapodAvatar({super.key, required this.address, this.size = 15, this.name});

  final String address;
  final double size;
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocalWallet = ref.watch(isOwnerProvider(address));

    return ScaledSizedBox(
      width: size,
      height: size,
      child: isLocalWallet ? _buildLocalWalletAvatar(context, ref) : _buildRemoteAvatar(context, ref),
    );
  }

  Widget _buildLocalWalletAvatar(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletByAddressProvider(address));

    final walletNumber = wallet?.number ?? 0;
    final defaultAvatar = CachedAvatarImage(
      imagePath: 'assets/avatars/${walletNumber % 4}.png',
      fit: BoxFit.cover,
      isCircular: true,
    );

    // 1. Explicit local image (camera pick) takes precedence.
    if (wallet?.imagePath != null && wallet!.imagePath!.isNotEmpty) {
      return CachedAvatarImage(
        key: ValueKey(wallet.imagePath),
        imagePath: wallet.imagePath!,
        fit: BoxFit.cover,
        isCircular: true,
        fallback: defaultAvatar,
      );
    }

    // 2. No local image: try CesiumPlus so the photo set on mobile is
    //    visible on desktop (and vice-versa). Falls back to the default
    //    safe avatar if nothing is available remotely.
    return _buildRemoteAvatar(context, ref, defaultAvatar: defaultAvatar);
  }

  /// Renders the avatar using the CesiumPlus cache.
  ///
  /// [defaultAvatar] is only provided for local wallets: when no remote avatar
  /// is available (or while it's still loading, or if the cached bytes are
  /// corrupt) we want to fall back to the numbered safe avatar instead of the
  /// generic "unknown person" icon / shimmer used for external addresses.
  /// This avoids a visible regression where a local wallet briefly shows a
  /// shimmer before settling on its safe avatar.
  Widget _buildRemoteAvatar(BuildContext context, WidgetRef ref, {Widget? defaultAvatar}) {
    final pixelSize = (scaleSize(size) * MediaQuery.devicePixelRatioOf(context)).toInt();

    // First check synchronous cache - if avatar is already in memory, show it immediately
    final cachedAvatar = ref.watch(avatarSyncProvider(address));
    if (cachedAvatar != null) {
      return ClipOval(child: _buildFadeInImage(cachedAvatar, pixelSize, defaultAvatar: defaultAvatar));
    }

    // Otherwise, use async provider which will trigger loading
    final avatarAsync = ref.watch(avatarProvider(address));

    return ClipOval(
      child: avatarAsync.when(
        data: (avatarBytes) {
          if (avatarBytes != null) {
            return _buildFadeInImage(avatarBytes, pixelSize, defaultAvatar: defaultAvatar);
          } else {
            return defaultAvatar ?? _buildDefaultAvatar(context);
          }
        },
        loading: () => defaultAvatar ?? ShimmerAvatar(size: scaleSize(size)),
        error: (error, stackTrace) => defaultAvatar ?? _buildDefaultAvatar(context),
      ),
    );
  }

  /// Build image with smooth fade-in during decode.
  ///
  /// [defaultAvatar] is propagated to the [Image.memory] errorBuilder so that
  /// corrupt cached bytes for a local wallet still fall back to its numbered
  /// safe avatar instead of the generic "unknown person" icon.
  Widget _buildFadeInImage(Uint8List avatarBytes, int pixelSize, {Widget? defaultAvatar}) {
    return Image.memory(
      avatarBytes,
      key: ValueKey('avatar_$address'),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: pixelSize,
      cacheHeight: pixelSize,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) => defaultAvatar ?? _buildDefaultAvatar(context),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    if (name != null && name!.isNotEmpty) {
      return Container(
        key: ValueKey('avatar_default_name_$address'),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
        alignment: Alignment.center,
        child: Text(
          name![0].toUpperCase(),
          style: scaledTextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    return Image.asset('assets/icon_user.png', key: ValueKey('avatar_default_icon_$address'), fit: BoxFit.cover);
  }
}
