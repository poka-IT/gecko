import 'package:durt2/durt2.dart' show CertStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
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
Future<void> showDesktopProfileModal(
  BuildContext context, {
  required String address,
  String? username,
  VoidCallback? onBack,
}) {
  return showDesktopModal(
    context: context,
    size: DesktopModalSize.large,
    contentPadding: EdgeInsets.zero,
    showCloseButton: true,
    title: username != null ? 'memberAccountOf'.tr(args: [username]) : 'seeAWallet'.tr(),
    onBack: onBack,
    builder: (context) => _DesktopProfileContent(address: address, username: username, onBack: onBack),
  );
}

class _DesktopProfileContent extends ConsumerStatefulWidget {
  final String address;
  final String? username;
  final VoidCallback? onBack;

  const _DesktopProfileContent({required this.address, this.username, this.onBack});

  @override
  ConsumerState<_DesktopProfileContent> createState() => _DesktopProfileContentState();
}

class _DesktopProfileContentState extends ConsumerState<_DesktopProfileContent> {
  /// Once cert content has been shown, never go back to placeholder
  bool _certContentShown = false;

  /// Cache last successfully built cert widget to avoid flicker during provider reloads
  Widget? _lastCertContent;

  @override
  void initState() {
    super.initState();
    // Reset selected certification wallet when opening a new profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedCertificationWalletProvider.notifier).set(null);
    });
  }

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
                  Navigator.of(context).pop();
                  showDesktopActivityModal(
                    context,
                    address: widget.address,
                    username: widget.username,
                    onBack: () => showDesktopProfileModal(
                      context,
                      address: widget.address,
                      username: widget.username,
                      onBack: widget.onBack,
                    ),
                  );
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
            const SizedBox(width: 12),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final isContact = ref.watch(isContactProvider(widget.address));
                  return _buildActionTile(
                    context,
                    icon: isContact ? Icons.add_reaction_rounded : Icons.add_reaction_outlined,
                    label: isContact ? 'removeContact'.tr() : 'addContact'.tr(),
                    onTap: () async {
                      G1WalletsList? existing;
                      g1WalletsBox.toMap().forEach((key, value) {
                        if (key == widget.address) existing = value;
                      });
                      final toggleContact = ref.read(toggleContactProvider);
                      await toggleContact(existing ?? G1WalletsList(address: widget.address), context);
                    },
                  );
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
    // On desktop, use all-safes provider to find member wallets across all safes.
    // Auto-select first member wallet so certStateProvider sees it.
    final allMemberWalletsAsync = ref.watch(allSafesIdentityWalletsProvider);
    final selectedAddress = ref.watch(selectedCertificationWalletProvider);

    // Auto-select first member wallet if none is selected yet
    allMemberWalletsAsync.whenData((wallets) {
      if (wallets.isNotEmpty && selectedAddress == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedCertificationWalletProvider.notifier).set(wallets.first.address);
        });
      }
    });

    // No cert area if we have no member wallets
    final memberWallets = allMemberWalletsAsync.asData?.value;
    final hasMemberWallet = memberWallets != null && memberWallets.isNotEmpty;

    if (!hasMemberWallet) {
      return const SizedBox.shrink();
    }

    final certStateAsync = ref.watch(certStateProvider(widget.address));
    final certState = certStateAsync.asData?.value;
    final isNone = certState != null && certState.status == CertStatus.none;

    // Determine what to show
    Widget child;
    if (isNone || certStateAsync.hasError) {
      // Definitive: no cert area needed
      _certContentShown = false;
      _lastCertContent = null;
      child = const SizedBox.shrink();
    } else if (certState != null) {
      // We have real data — build and cache the content
      _certContentShown = true;
      _lastCertContent = Container(
        key: const ValueKey('cert_content'),
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
      child = _lastCertContent!;
    } else if (_certContentShown && _lastCertContent != null) {
      // Loading but we've shown content before — keep showing cached content
      child = _lastCertContent!;
    } else {
      // First load, never shown content — show placeholder
      child = _buildCertPlaceholder(context);
    }

    // AnimatedSize smoothly handles height transitions (nothing→content)
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  Widget _buildCertPlaceholder(BuildContext context) {
    return Container(
      key: const ValueKey('cert_loading'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertWalletDropdown(WidgetRef ref) {
    // Desktop: show member wallets from ALL safes
    final identityWalletsAsync = ref.watch(allSafesIdentityWalletsProvider);
    final selectedAddress = ref.watch(selectedCertificationWalletProvider);

    // Keep last known wallets to avoid flicker during refresh
    final wallets = identityWalletsAsync.asData?.value;
    if (wallets == null || wallets.length <= 1) return const SizedBox.shrink();

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
  }

  Widget _buildTransferButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        ref.watch(blockHeightProvider);
        final isConnected = ref.read(durtProvider).isConnected;
        final hasWallets = ref.watch(isWalletsExistsProvider);
        final isEnabled = isConnected && hasWallets;

        return SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isEnabled ? () => _handleTransfer(ref) : null,
              child: Ink(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isEnabled ? context.colorScheme.primary : context.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isEnabled ? const Color(0xFF6c4204) : context.colorScheme.outline.withValues(alpha: 0.1),
                    width: isEnabled ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/vector_white.png',
                      height: 24,
                      color: isEnabled ? Colors.white : Colors.grey[400],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'doATransfer'.tr(),
                      style: scaledTextStyle(
                        fontSize: 15,
                        color: isEnabled ? Colors.white : Colors.grey[500],
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
    if (!await PinCodeService.askPinCode(context)) return;
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    paymentPopup(context, toAddress: widget.address, username: widget.username);
  }
}
