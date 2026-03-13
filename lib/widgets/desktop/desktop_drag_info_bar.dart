import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/wallet_name_service.dart';

/// Floating info bar shown at the bottom of the desktop home during drag & drop.
/// Displays live transfer preview: source wallet -> target wallet.
class DesktopDragInfoBar extends ConsumerWidget {
  const DesktopDragInfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragState = ref.watch(dragDropProvider);

    if (!dragState.isDragging) return const SizedBox.shrink();

    final source = dragState.dragAddress!;
    final target = dragState.lastFlyBy;
    final isSameAddress = target != null && target.address == source.address;

    final squid = ref.read(squidServiceProvider);
    final sourceName = squid.walletNameIndexer[source.address] ?? WalletNameService.displayName(source.name);
    final targetName = target != null
        ? (squid.walletNameIndexer[target.address] ?? WalletNameService.displayName(target.name))
        : null;

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: ClipRRect(
            key: ValueKey(target?.address ?? 'no_target'),
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: target != null && !isSameAddress
                        ? context.colorScheme.primary.withValues(alpha: 0.4)
                        : context.colorScheme.outline.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Transfer icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: target != null && !isSameAddress
                            ? context.colorScheme.primary.withValues(alpha: 0.14)
                            : context.colorScheme.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        size: 20,
                        color: target != null && !isSameAddress
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info text
                    Flexible(
                      child: target == null
                          ? _buildWaitingState(context, sourceName)
                          : isSameAddress
                          ? _buildSameWalletState(context, sourceName)
                          : _buildReadyState(context, sourceName, targetName!),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingState(BuildContext context, String sourceName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'executeATransfer'.tr(),
          style: scaledTextStyle(
            fontSize: 11,
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'from'.tr(args: [''])} ',
              style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            Flexible(
              child: Text(
                sourceName,
                style: scaledTextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '  →  ',
              style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
            Text(
              'chooseATargetWallet'.tr(),
              style: scaledTextStyle(
                fontSize: 12,
                color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSameWalletState(BuildContext context, String sourceName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'executeATransfer'.tr(),
          style: scaledTextStyle(
            fontSize: 11,
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'from'.tr(args: [''])} ',
              style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            Flexible(
              child: Text(
                sourceName,
                style: scaledTextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '  →  ',
              style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
            Text(
              'chooseATargetWallet'.tr(),
              style: scaledTextStyle(
                fontSize: 12,
                color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadyState(BuildContext context, String sourceName, String targetName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'executeATransfer'.tr(),
          style: scaledTextStyle(
            fontSize: 11,
            color: context.colorScheme.primary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'from'.tr(args: [''])} ',
              style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            Flexible(
              child: Text(
                sourceName,
                style: scaledTextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '  →  ',
              style: scaledTextStyle(fontSize: 13, color: context.colorScheme.primary.withValues(alpha: 0.6)),
            ),
            Flexible(
              child: Text(
                targetName,
                style: scaledTextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colorScheme.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
