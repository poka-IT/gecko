// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show CertStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/desktop/modals/activity_modal.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/certify/cert_state.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/widgets/payment_popup.dart';

/// Shows a profile view inside a desktop modal.
Future<void> showDesktopProfileModal(BuildContext context, {required String address, String? username}) {
  return showDesktopModal(
    context: context,
    size: DesktopModalSize.large,
    contentPadding: EdgeInsets.zero,
    showCloseButton: true,
    title: username != null ? 'memberAccountOf'.tr(args: [username]) : 'seeAWallet'.tr(),
    builder: (context) => _DesktopProfileContent(address: address, username: username),
  );
}

class _DesktopProfileContent extends ConsumerStatefulWidget {
  final String address;
  final String? username;

  const _DesktopProfileContent({required this.address, this.username});

  @override
  ConsumerState<_DesktopProfileContent> createState() => _DesktopProfileContentState();
}

class _DesktopProfileContentState extends ConsumerState<_DesktopProfileContent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Wallet header (avatar, name, address, balance, identity)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: WalletHeader(address: widget.address),
          ),
          const SizedBox(height: 24),
          // Action buttons
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _buildActions(context)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Primary actions row
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context,
                icon: Icons.history_rounded,
                label: 'displayNActivity'.tr(),
                onTap: () {
                  Navigator.of(context).pop(); // Close profile modal
                  showDesktopActivityModal(context, address: widget.address, username: widget.username);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                context,
                icon: Icons.copy_rounded,
                label: 'copyAddress'.tr(),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.address));
                  SnackbarService.showAddressCopied(context);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Certification section
        Consumer(
          builder: (context, ref, _) {
            ref.watch(blockHeightProvider);
            return _buildCertificationArea(context, ref);
          },
        ),
        const SizedBox(height: 16),
        // Transfer button
        _buildTransferButton(context),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: scaledTextStyle(
                    fontSize: 13,
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificationArea(BuildContext context, WidgetRef ref) {
    final certStateAsync = ref.watch(certStateProvider(widget.address));

    return certStateAsync.when(
      data: (certState) {
        if (certState == null || certState.status == CertStatus.none) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              _buildCertWalletDropdown(ref),
              CertStateWidget(certState: certState, address: widget.address),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCertWalletDropdown(WidgetRef ref) {
    final identityWalletsAsync = ref.watch(identityWalletsAsyncProvider);
    final selectedAddress = ref.watch(selectedCertificationWalletProvider);

    return identityWalletsAsync.when(
      data: (wallets) {
        if (wallets.length <= 1) return const SizedBox.shrink();

        if (selectedAddress == null && wallets.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedCertificationWalletProvider.notifier).set(wallets.first.address);
          });
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_circle, size: 16, color: context.colorScheme.primary),
                const SizedBox(width: 6),
                DropdownButton<String>(
                  value: selectedAddress ?? wallets.first.address,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface),
                  dropdownColor: context.colorScheme.surfaceContainer,
                  items: wallets.map((w) {
                    return DropdownMenuItem<String>(
                      value: w.address,
                      child: Text(
                        WalletNameService.isDefault(w.name)
                            ? getShortPubkey(w.address)
                            : (w.name ?? getShortPubkey(w.address)),
                        style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) ref.read(selectedCertificationWalletProvider.notifier).set(v);
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildTransferButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        ref.watch(blockHeightProvider);
        final isConnected = ref.read(durtProvider).isConnected;

        return SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isConnected ? () => _handleTransfer(ref) : null,
              child: Ink(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isConnected ? context.colorScheme.primary : context.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF6c4204) : context.colorScheme.outline.withValues(alpha: 0.1),
                    width: isConnected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/vector_white.png',
                      height: 24,
                      color: isConnected ? Colors.white : Colors.grey[400],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'doATransfer'.tr(),
                      style: scaledTextStyle(
                        fontSize: 15,
                        color: isConnected ? Colors.white : Colors.grey[500],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTransfer(WidgetRef ref) async {
    if (!await PinCodeService.askPinCode()) return;
    paymentPopup(toAddress: widget.address, username: widget.username);
  }
}
