// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show IdtyStatus, WalletBalance;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers.dart';

import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/certifications.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/idty_status.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/models/transaction_display_item.dart';

class WalletHeader extends ConsumerWidget {
  const WalletHeader({
    super.key,
    required this.address,
    this.customImagePath,
    this.defaultImagePath,
    this.showUDToggle = false,
  });

  final String address;
  final String? customImagePath;
  final String? defaultImagePath;
  final bool showUDToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final isOwner = myWalletProvider.isOwner(address);

    // Use live subscriptions instead of cached data
    final idtyStatusStream = ref.watch(smartIdtyStatusStreamProvider(address));
    final balanceStream = ref.watch(smartBalanceStreamProvider(address));
    final identityNameAsync = ref.watch(identityNameStreamProvider(address));

    return Container(
      decoration: BoxDecoration(color: context.colorScheme.tertiary),
      child: Column(
        children: [
          // Status and subscription management
          WalletHeaderSubscriptionStatus(idtyStatusStream: idtyStatusStream, balanceStream: balanceStream),

          // Main content with live data
          WalletHeaderMainContent(
            address: address,
            isOwner: isOwner,
            idtyStatusStream: idtyStatusStream,
            balanceStream: balanceStream,
            identityNameAsync: identityNameAsync,
            customImagePath: customImagePath,
            defaultImagePath: defaultImagePath,
            showUDToggle: showUDToggle,
          ),
        ],
      ),
    );
  }
}

/// Subscription status indicator widget for debugging (can be removed in production)
class WalletHeaderSubscriptionStatus extends StatelessWidget {
  const WalletHeaderSubscriptionStatus({super.key, required this.idtyStatusStream, required this.balanceStream});

  final AsyncValue<IdtyStatus> idtyStatusStream;
  final AsyncValue<WalletBalance> balanceStream;

  @override
  Widget build(BuildContext context) {
    // Show subscription status for debugging (remove in production)
    final hasErrors = idtyStatusStream.hasError || balanceStream.hasError;
    final isLoading = idtyStatusStream.isLoading || balanceStream.isLoading;

    if (hasErrors || isLoading) {
      return Container(
        padding: EdgeInsets.all(scaleSize(4)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) Icon(Icons.sync, size: scaleSize(12), color: Colors.orange),
            if (hasErrors) Icon(Icons.error_outline, size: scaleSize(12), color: Colors.red),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Main content of the wallet header with live data
class WalletHeaderMainContent extends StatelessWidget {
  const WalletHeaderMainContent({
    super.key,
    required this.address,
    required this.isOwner,
    required this.idtyStatusStream,
    required this.balanceStream,
    required this.identityNameAsync,
    this.customImagePath,
    this.defaultImagePath,
    this.showUDToggle = false,
  });

  final String address;
  final bool isOwner;
  final AsyncValue<IdtyStatus> idtyStatusStream;
  final AsyncValue<WalletBalance> balanceStream;
  final AsyncValue<String?> identityNameAsync;
  final String? customImagePath;
  final String? defaultImagePath;
  final bool showUDToggle;

  @override
  Widget build(BuildContext context) {
    return balanceStream.when(
      data: (walletBalance) {
        final balance = walletBalance.transferableBalance;
        final isEmptyWallet = balance == BigInt.zero;

        return Container(
          decoration: BoxDecoration(color: isEmptyWallet ? context.colorScheme.error : context.colorScheme.tertiary),
          padding: EdgeInsets.only(left: scaleSize(16), right: scaleSize(16), bottom: scaleSize(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar section - back to original position
              WalletHeaderAvatar(
                address: address,
                isOwner: isOwner,
                customImagePath: customImagePath,
                defaultImagePath: defaultImagePath,
              ),
              ScaledSizedBox(width: 16),

              // Info section with live data
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address
                    WalletHeaderAddress(address: address),
                    ScaledSizedBox(height: 6),

                    // Balance
                    Balance(address: address, size: 18),
                    ScaledSizedBox(height: 6),

                    // Identity status and certifications with live data
                    WalletHeaderIdentitySection(
                      address: address,
                      idtyStatusStream: idtyStatusStream,
                      identityNameAsync: identityNameAsync,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const WalletHeaderLoading(),
      error: (error, stack) {
        log.e('❌ WalletHeader balance stream error for $address: $error');
        return const WalletHeaderError();
      },
    );
  }
}

/// Identity section with live status and certifications
class WalletHeaderIdentitySection extends StatelessWidget {
  const WalletHeaderIdentitySection({
    super.key,
    required this.address,
    required this.idtyStatusStream,
    required this.identityNameAsync,
  });

  final String address;
  final AsyncValue<IdtyStatus> idtyStatusStream;
  final AsyncValue<String?> identityNameAsync;

  @override
  Widget build(BuildContext context) {
    return idtyStatusStream.when(
      data: (idtyStatus) {
        final hasIdentity = idtyStatus != IdtyStatus.none;

        if (!hasIdentity) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: () => Navigator.push(
            context,
            PageNoTransit(
              builder: (context) => CertificationsScreen(address: address, username: identityNameAsync.value ?? ''),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.transparent),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Identity status with live updates
                Flexible(
                  child: IdentityStatus(address: address, color: context.colorScheme.primary),
                ),

                // Certifications with live updates
                Row(
                  children: [
                    Certifications(address: address, size: 13),
                    Icon(
                      Icons.chevron_right,
                      size: scaleSize(15),
                      color: context.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    ScaledSizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const WalletHeaderLoadingIdentity(),
      error: (error, stack) {
        log.e('❌ Identity status error for $address: $error');
        return const SizedBox.shrink();
      },
    );
  }
}

/// Avatar section with editing capability for owners
class WalletHeaderAvatar extends ConsumerStatefulWidget {
  const WalletHeaderAvatar({
    super.key,
    required this.address,
    required this.isOwner,
    this.customImagePath,
    this.defaultImagePath,
  });

  final String address;
  final bool isOwner;
  final String? customImagePath;
  final String? defaultImagePath;

  @override
  ConsumerState<WalletHeaderAvatar> createState() => _WalletHeaderAvatarState();
}

class _WalletHeaderAvatarState extends ConsumerState<WalletHeaderAvatar> {
  bool _isPickerOpen = false;
  String _newCustomImagePath = '';

  @override
  void initState() {
    super.initState();
    _newCustomImagePath = widget.customImagePath ?? '';
  }

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 90;

    return Container(
      width: scaleSize(avatarSize),
      height: scaleSize(avatarSize),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: old_provider.Consumer<WalletOptionsProvider>(
        builder: (context, walletOptionsProvider, child) {
          return Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isOwner && !_isPickerOpen
                      ? () async {
                          setState(() => _isPickerOpen = true);
                          walletOptionsProvider.reload();
                          final newPath = await walletOptionsProvider.changeAvatar();
                          setState(() {
                            _newCustomImagePath = newPath;
                            _isPickerOpen = false;
                          });
                          walletOptionsProvider.reload();
                        }
                      : null,
                  customBorder: const CircleBorder(),
                  child: ClipOval(
                    child: _newCustomImagePath.isEmpty
                        ? (widget.defaultImagePath != null
                              ? Image.asset(widget.defaultImagePath!, fit: BoxFit.cover)
                              : DatapodAvatar(address: widget.address, size: avatarSize))
                        : Image.asset(_newCustomImagePath, fit: BoxFit.cover),
                  ),
                ),
              ),
              if (widget.isOwner)
                Positioned(
                  right: scaleSize(5),
                  bottom: scaleSize(5),
                  child: Container(
                    padding: EdgeInsets.all(scaleSize(4)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt, size: scaleSize(12), color: Colors.black54),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Address section with copy functionality
class WalletHeaderAddress extends StatelessWidget {
  const WalletHeaderAddress({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: keyCopyAddress,
      onTap: () {
        Clipboard.setData(ClipboardData(text: address));
        snackCopyKey(context);
      },
      child: Row(
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                getShortPubkey(address),
                style: scaledTextStyle(
                  fontSize: 20,
                  fontFamily: 'Monospace',
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
          SizedBox(width: scaleSize(14)),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.copy, size: scaleSize(20), color: context.colorScheme.primary.withValues(alpha: 0.5)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: address));
              snackCopyKey(context);
            },
          ),
        ],
      ),
    );
  }
}

/// Loading state for the main header
class WalletHeaderLoading extends StatelessWidget {
  const WalletHeaderLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(scaleSize(16)),
      child: Row(
        children: [
          CircleAvatar(radius: scaleSize(45), backgroundColor: Colors.grey[300]),
          ScaledSizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: scaleSize(20),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                ),
                ScaledSizedBox(height: 8),
                Container(
                  height: scaleSize(16),
                  width: scaleSize(100),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state for the main header
class WalletHeaderError extends StatelessWidget {
  const WalletHeaderError({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(scaleSize(16)),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: scaleSize(40), color: Colors.red),
          ScaledSizedBox(width: 16),
          Text('errorLoadingWalletData'.tr(), style: scaledTextStyle(fontSize: 16, color: Colors.red)),
        ],
      ),
    );
  }
}

/// Loading state for the identity section
class WalletHeaderLoadingIdentity extends StatelessWidget {
  const WalletHeaderLoadingIdentity({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: scaleSize(20),
      width: scaleSize(80),
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
    );
  }
}

/// Compact Universal Dividends toggle for wallet header
class WalletHeaderUDToggle extends ConsumerStatefulWidget {
  const WalletHeaderUDToggle({super.key, required this.address});

  final String address;

  @override
  ConsumerState<WalletHeaderUDToggle> createState() => _WalletHeaderUDToggleState();
}

class _WalletHeaderUDToggleState extends ConsumerState<WalletHeaderUDToggle> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _hasCheckedForUDs = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(universalDividendsToggleProvider);

    // Check if UDs are available by looking at the combined provider
    final combinedState = ref.watch(combinedHistoryProvider(widget.address));
    final hasUDs = combinedState.transactions.any(
      (transaction) => transaction.type == TransactionType.universalDividend,
    );

    // Trigger fade-in animation when UDs are detected for the first time
    if (hasUDs && !_hasCheckedForUDs) {
      _hasCheckedForUDs = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    }

    // Hide toggle if no UDs are available
    if (!hasUDs) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.only(bottom: scaleSize(6)),
        child: GestureDetector(
          onTap: () {
            toggleUniversalDividends(ref, widget.address);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(4)),
            decoration: BoxDecoration(
              color: isEnabled ? context.colorScheme.primary.withValues(alpha: 0.1) : context.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEnabled
                    ? context.colorScheme.primary.withValues(alpha: 0.3)
                    : context.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop,
                  size: scaleSize(12),
                  color: isEnabled ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: scaleSize(4)),
                // Short text "UD" or "DU"
                Text(
                  'udShort'.tr(),
                  style: scaledTextStyle(
                    fontSize: 11,
                    color: isEnabled ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
