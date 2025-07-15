// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show IdtyStatus, WalletBalance, WalletEntity, Durt;
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
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/widgets/commons/animated_text.dart';

class WalletHeader extends ConsumerWidget {
  const WalletHeader({super.key, required this.address, this.customImagePath, this.defaultImagePath});

  final String address;
  final String? customImagePath;
  final String? defaultImagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final isOwner = myWalletProvider.isOwner(address);

    // Use hybrid provider to handle identity creation (solves closed stream issue)
    final idtyStatusAsync = ref.watch(hybridIdtyStatusProvider(address));
    final balanceAsync = ref.watch(smartBalanceStreamProvider(address));
    final identityNameAsync = ref.watch(identityNameStreamProvider(address));

    final hasError = idtyStatusAsync.hasError || balanceAsync.hasError || identityNameAsync.hasError;
    final isLoading = !idtyStatusAsync.hasValue || !balanceAsync.hasValue || !identityNameAsync.hasValue;

    // Use cached data if available, otherwise show loader
    final hasCachedData = idtyStatusAsync.hasValue || balanceAsync.hasValue || identityNameAsync.hasValue;

    Widget child;
    if (isLoading && !hasCachedData) {
      child = const WalletHeaderLoading();
    } else if (hasError && !hasCachedData) {
      if (balanceAsync.hasError) log.e('❌ WalletHeader balance stream error for $address: ${balanceAsync.error}');
      if (idtyStatusAsync.hasError) log.e('❌ Identity status error for $address: ${idtyStatusAsync.error}');
      if (identityNameAsync.hasError) log.e('❌ Identity name error for $address: ${identityNameAsync.error}');
      child = const WalletHeaderError();
    } else {
      child = WalletHeaderContent(
        address: address,
        isOwner: isOwner,
        // Provide data if available, otherwise it will be handled gracefully
        idtyStatus: idtyStatusAsync.hasValue ? idtyStatusAsync.value! : IdtyStatus.none,
        walletBalance: balanceAsync.value,
        identityName: identityNameAsync.value,
        customImagePath: customImagePath,
        defaultImagePath: defaultImagePath,
      );
    }

    return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: child);
  }
}

class WalletHeaderContent extends StatelessWidget {
  const WalletHeaderContent({
    super.key,
    required this.address,
    required this.isOwner,
    required this.idtyStatus,
    required this.walletBalance,
    this.identityName,
    this.customImagePath,
    this.defaultImagePath,
  });

  final String address;
  final bool isOwner;
  final IdtyStatus idtyStatus;
  final WalletBalance? walletBalance;
  final String? identityName;
  final String? customImagePath;
  final String? defaultImagePath;

  @override
  Widget build(BuildContext context) {
    final balance = walletBalance?.transferableBalance;
    final isEmptyWallet = balance == null || balance == BigInt.zero;

    return Container(
      decoration: BoxDecoration(color: isEmptyWallet ? context.colorScheme.error : context.colorScheme.tertiary),
      padding: EdgeInsets.only(left: scaleSize(16), right: scaleSize(16), bottom: scaleSize(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          WalletHeaderAvatar(
            address: address,
            isOwner: isOwner,
            customImagePath: customImagePath,
            defaultImagePath: defaultImagePath,
          ),
          ScaledSizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WalletHeaderAddress(address: address),
                ScaledSizedBox(height: 6),
                // Use a placeholder if balance is not yet available
                if (walletBalance != null)
                  Balance(address: address, size: 18)
                else
                  Container(
                    height: scaleSize(22),
                    width: scaleSize(120),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ScaledSizedBox(height: 6),
                WalletHeaderIdentitySection(address: address, idtyStatus: idtyStatus, identityName: identityName ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Identity section with live status and certifications
class WalletHeaderIdentitySection extends StatelessWidget {
  const WalletHeaderIdentitySection({
    super.key,
    required this.address,
    required this.idtyStatus,
    required this.identityName,
  });

  final String address;
  final IdtyStatus idtyStatus;
  final String identityName;

  @override
  Widget build(BuildContext context) {
    final hasIdentity = idtyStatus != IdtyStatus.none;

    if (!hasIdentity) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        PageNoTransit(
          builder: (context) => CertificationsScreen(address: address, username: identityName),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.transparent),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Identity status with live updates - pass the current status to display
            Flexible(
              child: _IdentityStatusDisplay(
                address: address,
                currentStatus: idtyStatus,
                color: context.colorScheme.primary,
              ),
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
  }
}

/// Internal identity status display widget that shows current status without database access
class _IdentityStatusDisplay extends StatelessWidget {
  const _IdentityStatusDisplay({required this.address, required this.currentStatus, required this.color});

  final String address;
  final IdtyStatus currentStatus;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Create a minimal wallet entity for display purposes only
    final displayWallet = WalletEntity.create(address: address, keyPairType: Durt.defaultKeyPairType);

    final nameByAddress = currentStatus == IdtyStatus.validated
        ? NameByAddress(
            wallet: displayWallet,
            size: 18,
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
          )
        : NameByAddress(
            wallet: displayWallet,
            size: 16,
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          );

    final Map<IdtyStatus, String> statusText = {
      IdtyStatus.none: '',
      IdtyStatus.created: 'identityCreated'.tr(),
      IdtyStatus.confirmed: 'identityConfirmed'.tr(),
      IdtyStatus.validated: 'memberValidated'.tr(),
      IdtyStatus.expired: 'identityExpired'.tr(),
      IdtyStatus.revoked: 'identityRevoked'.tr(),
      IdtyStatus.unknown: '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FittedBox only for the name to scale down when too long
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: nameByAddress),
        AnimatedFadeOutIn<String>(
          data: statusText[currentStatus]!,
          duration: const Duration(milliseconds: 150),
          builder: (value) => Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: scaleSize(15),
              color: color,
              fontWeight: currentStatus == IdtyStatus.validated ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ],
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
      decoration: BoxDecoration(color: context.colorScheme.tertiary),
      height: scaleSize(122),
      padding: EdgeInsets.only(left: scaleSize(16), right: scaleSize(16), bottom: scaleSize(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: scaleSize(90),
            height: scaleSize(90),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 25)),
          ),
          ScaledSizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: scaleSize(24),
                  width: scaleSize(180),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                ScaledSizedBox(height: 8),
                Container(
                  height: scaleSize(22),
                  width: scaleSize(120),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
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
      height: scaleSize(122),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: scaleSize(40), color: Colors.red),
          ScaledSizedBox(width: 16),
          Text('errorLoadingWalletData'.tr(), style: scaledTextStyle(fontSize: 16, color: Colors.red)),
        ],
      ),
    );
  }
}
