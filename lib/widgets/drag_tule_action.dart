// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/payment_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';

class DragTuleAction extends ConsumerWidget {
  const DragTuleAction({
    super.key,
    required this.wallet,
    this.child,
    this.desktopMode = false,
    this.desktopChildBuilder,
  });

  final WalletEntity wallet;
  final Widget? child;
  final bool desktopMode;
  final Widget Function(Widget dragHandle)? desktopChildBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;
    final dragDropNotifier = ref.read(dragDropProvider.notifier);
    final dragState = ref.watch(dragDropProvider);
    final lastFlyBy = dragState.lastFlyBy;
    final isHoveredTarget = lastFlyBy?.address == wallet.address && dragState.dragAddress?.address != wallet.address;

    final feedback = desktopMode ? _buildDesktopFeedback(context) : _buildMobileFeedback(context);

    Widget buildDesktopHandle() {
      return Draggable<String>(
        key: ValueKey('drag_${wallet.address}_safe$currentSafe'),
        data: wallet.address,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => dragDropNotifier.setDragAddress(wallet),
        onDragEnd: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            dragDropNotifier.clearDrag();
          });
        },
        feedback: feedback,
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: MouseRegion(
            cursor: SystemMouseCursors.grabbing,
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: context.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Tooltip(
            message: 'desktopDragToPayTooltip'.tr(),
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: context.colorScheme.onSurface.withValues(alpha: 0.24),
            ),
          ),
        ),
      );
    }

    final dragTarget = DragTarget<String>(
      onAcceptWithDetails: (senderAddress) async {
        final walletData = ref.read(walletByAddressProvider(senderAddress.data));
        paymentPopup(
          toAddress: wallet.address,
          username: g1WalletsBox.get(wallet.address)?.username ?? WalletNameService.displayName(wallet.name),
          fromWallet: walletData,
        );
      },
      onLeave: (_) {
        if (lastFlyBy?.address == wallet.address) {
          dragDropNotifier.setLastFlyBy(null);
        }
      },
      onMove: (details) {
        if (wallet.address != lastFlyBy?.address) {
          dragDropNotifier.setLastFlyBy(wallet);
        }
      },
      onWillAcceptWithDetails: (senderAddress) => senderAddress.data != wallet.address,
      builder: (BuildContext context, List<dynamic> accepted, List<dynamic> rejected) {
        final content = desktopMode
            ? desktopChildBuilder?.call(buildDesktopHandle()) ?? child ?? const SizedBox.shrink()
            : child ?? const SizedBox.shrink();
        return AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: isHoveredTarget ? 1.015 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(desktopMode ? 18 : 12),
              boxShadow: isHoveredTarget
                  ? [
                      BoxShadow(
                        color: context.colorScheme.primary.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: IntrinsicHeight(child: content),
          ),
        );
      },
    );

    if (desktopMode) return dragTarget;

    return LongPressDraggable<String>(
      key: ValueKey('drag_${wallet.address}_safe$currentSafe'),
      delay: const Duration(milliseconds: 200),
      data: wallet.address,
      dragAnchorStrategy: (Draggable<Object> _, BuildContext _, Offset _) => const Offset(55, 55),
      onDragStarted: () => dragDropNotifier.setDragAddress(wallet),
      onDragEnd: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          dragDropNotifier.clearDrag();
        });
      },
      feedback: feedback,
      child: dragTarget,
    );
  }

  Widget _buildMobileFeedback(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colorScheme.primary,
        shape: const CircleBorder(),
        padding: EdgeInsets.all(scaleSize(14)),
      ),
      child: SizedBox(
        height: scaleSize(33),
        child: const Image(image: AssetImage('assets/vector_white.png')),
      ),
    );
  }

  Widget _buildDesktopFeedback(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 14)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.send_rounded, color: context.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                WalletNameService.displayName(wallet.name),
                overflow: TextOverflow.ellipsis,
                style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
