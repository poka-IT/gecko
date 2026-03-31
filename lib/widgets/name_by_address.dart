import 'package:durt2/durt2.dart' as d show WalletEntity, ConnectionStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/cesium_name_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/utils/identity_utils.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/wallet_name.dart';
import 'package:truncate/truncate.dart';

class NameByAddress extends ConsumerWidget {
  const NameByAddress({
    super.key,
    required this.wallet,
    this.size = 20,
    this.color,
    this.fontWeight = FontWeight.w400,
    this.fontStyle = FontStyle.normal,
    this.showCesiumPlusName = false,
  });

  final d.WalletEntity wallet;
  final Color? color;
  final double size;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final bool showCesiumPlusName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finalColor = color ?? Theme.of(context).colorScheme.onSurface;

    // Check if we have network connection
    final connectionStatus = ref.watch(connectionStatusProvider);

    final isNetworkAvailable = connectionStatus == d.ConnectionStatus.connected;

    if (!isNetworkAvailable) {
      // Check Hive cache for CesiumPlus name when offline
      if (showCesiumPlusName) {
        final cached = g1WalletsBox.get(wallet.address);
        if (cached?.username != null) {
          // Identity name takes priority even offline
          return Text(
            truncate(cached!.username!, 22),
            style: scaledTextStyle(fontSize: size, color: finalColor, fontWeight: fontWeight, fontStyle: fontStyle),
          );
        }
        if (cached?.csName != null) {
          return Text(
            truncate(cached!.csName!, 22),
            style: scaledTextStyle(
              fontSize: size,
              color: finalColor.withValues(alpha: 0.8),
              fontWeight: fontWeight,
              fontStyle: FontStyle.italic,
            ),
          );
        }
      }
      return WalletName(wallet: wallet, size: size, color: finalColor);
    }

    final identityNameAsync = ref.watch(hybridIdentityNameProvider(wallet.address));
    final idtyStatusAsync = ref.watch(hybridIdtyStatusProvider(wallet.address));
    final idtyStatus = idtyStatusAsync.hasValue ? idtyStatusAsync.value : null;

    return identityNameAsync.when(
      data: (name) {
        // Store the real name in G1 wallets list for compatibility (not the placeholder)
        if (name != null) {
          g1WalletsBox.put(wallet.address, G1WalletsList(address: wallet.address, username: name));
        }

        // If no identity name found, try CesiumPlus fallback
        if (name == null) {
          // CesiumPlus fallback: only when explicitly opted in
          if (showCesiumPlusName) {
            final csNameAsync = ref.watch(cesiumNameProvider(wallet.address));
            return csNameAsync.when(
              data: (csName) {
                if (csName != null) {
                  // Persist to Hive for offline fallback (DISP-04)
                  final existing = g1WalletsBox.get(wallet.address);
                  if (existing != null) {
                    if (existing.csName != csName) {
                      existing.csName = csName;
                      g1WalletsBox.put(wallet.address, existing);
                    }
                  } else {
                    g1WalletsBox.put(wallet.address, G1WalletsList(address: wallet.address, csName: csName));
                  }
                  // Display CesiumPlus name with italic style (visually distinct from identity names)
                  return Text(
                    truncate(csName, 22),
                    style: scaledTextStyle(
                      fontSize: size,
                      color: finalColor.withValues(alpha: 0.8),
                      fontWeight: fontWeight,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
                // No CesiumPlus name either -- check Hive offline cache, then fall through
                final cached = g1WalletsBox.get(wallet.address);
                if (cached?.csName != null) {
                  return Text(
                    truncate(cached!.csName!, 22),
                    style: scaledTextStyle(
                      fontSize: size,
                      color: finalColor.withValues(alpha: 0.8),
                      fontWeight: fontWeight,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
                if (wallet.name == null) return SizedBox.shrink();
                return WalletName(wallet: wallet, size: size, color: finalColor);
              },
              loading: () {
                // While loading CesiumPlus, check Hive cache first, then show local name
                final cached = g1WalletsBox.get(wallet.address);
                if (cached?.csName != null) {
                  return Text(
                    truncate(cached!.csName!, 22),
                    style: scaledTextStyle(
                      fontSize: size,
                      color: finalColor.withValues(alpha: 0.8),
                      fontWeight: fontWeight,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
                if (wallet.name == null) return SizedBox.shrink();
                return WalletName(wallet: wallet, size: size, color: finalColor);
              },
              error: (_, _) {
                // On error, check Hive cache, then fall through to wallet name
                final cached = g1WalletsBox.get(wallet.address);
                if (cached?.csName != null) {
                  return Text(
                    truncate(cached!.csName!, 22),
                    style: scaledTextStyle(
                      fontSize: size,
                      color: finalColor.withValues(alpha: 0.8),
                      fontWeight: fontWeight,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
                if (wallet.name == null) return SizedBox.shrink();
                return WalletName(wallet: wallet, size: size, color: finalColor);
              },
            );
          }
          // Default: no CesiumPlus fallback
          if (wallet.name == null) return SizedBox.shrink();
          return WalletName(wallet: wallet, size: size, color: finalColor);
        }

        // Substitute display name when status is created
        final isCreated = IdentityUtils.isCreatedStatus(idtyStatus);
        final displayName = IdentityUtils.getDisplayName(name, idtyStatus) ?? name;
        final displayColor = isCreated ? Theme.of(context).colorScheme.onSurfaceVariant : finalColor;
        final displayFontStyle = isCreated ? FontStyle.italic : fontStyle;

        // Show identity name
        return Text(
          truncate(displayName, 22),
          style: scaledTextStyle(
            fontSize: size,
            color: displayColor,
            fontWeight: fontWeight,
            fontStyle: displayFontStyle,
          ),
        );
      },
      loading: () => const Loading(),
      error: (error, stackTrace) {
        // On error, fall back to wallet name
        return WalletName(wallet: wallet, size: size, color: finalColor);
      },
    );
  }
}
