import 'package:durt2/durt2.dart' show IdtyStatus, CertStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/certify/cert_state.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/widgets/payment_popup.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/utils.dart';

const double buttonSize = 75;
const double buttonFontSize = 13;

class ProfileViewScreen extends ConsumerStatefulWidget {
  const ProfileViewScreen({
    required this.address,
    required this.username,
    this.fromAddress,
    this.autoOpenPayment = false,
    super.key,
  });
  final String address;
  final String? username;
  final String? fromAddress;
  final bool autoOpenPayment;

  @override
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  late String address;
  late String? username;
  late Future<WalletHeaderData> _headerDataFuture;

  @override
  void initState() {
    super.initState();
    address = widget.address;
    username = widget.username;
    _headerDataFuture = _loadWalletData();

    // Auto-open payment popup when navigating from a june:// URI with amount
    if (widget.autoOpenPayment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleTransfer(ref);
      });
    }
  }

  Future<WalletHeaderData> _loadWalletData() async {
    final profileData = await ref.read(storageServiceProvider).getProfileData(widget.address);

    final data = WalletHeaderData(
      hasIdentity: profileData.idtyStatus != IdtyStatus.none,
      isOwner: ref.read(isOwnerProvider(address)),
      walletName: ref.read(squidServiceProvider).walletNameIndexer[address],
      balance: profileData.balance.total,
      certsReceived: profileData.certData.receivedCount,
      certsSent: profileData.certData.sentCount,
    );

    await walletHeaderDataBox.put(address, data);

    return data;
  }

  @override
  Widget build(BuildContext context) {
    // Remove the provider assignment from build method to prevent rebuilds
    // It's now handled in initState

    return FutureBuilder<WalletHeaderData>(
      future: _headerDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(username == null ? 'seeAWallet'.tr() : 'memberAccountOf'.tr(args: [username ?? ''])),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(username == null ? 'seeAWallet'.tr() : 'memberAccountOf'.tr(args: [username ?? ''])),
            ),
            body: Center(child: Text('errorLoadingWalletData'.tr())),
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: WalletAppBar(
            address: address,
            titleBuilder: (uname) => uname == null ? 'seeAWallet'.tr() : 'memberAccountOf'.tr(args: [uname]),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final aspectRatio = constraints.maxHeight / constraints.maxWidth;
                final isCompact = aspectRatio < 1.3;
                final scaleFactor = isCompact ? (aspectRatio / 1.3).clamp(0.75, 1.0) : 1.0;
                final btnSize = buttonSize * scaleFactor;
                final gap = isCompact ? 6.0 : scaleSize(20);

                return Column(
                  children: [
                    if (isCompact)
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: constraints.maxWidth / scaleFactor,
                            child: WalletHeader(address: address),
                          ),
                        ),
                      )
                    else
                      WalletHeader(address: address),
                    SizedBox(height: gap),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildActionButton(
                                    context: context,
                                    key: keyViewActivity,
                                    icon: 'assets/walletOptions/clock.png',
                                    label: "displayNActivity".tr(),
                                    size: btnSize,
                                    onTap: () async {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                              ActivityScreen(address: address),
                                          transitionDuration: const Duration(milliseconds: 300),
                                          reverseTransitionDuration: const Duration(milliseconds: 300),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            const begin = Offset(1.0, 0.0);
                                            const end = Offset.zero;
                                            const curve = Curves.easeInOut;

                                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                            return SlideTransition(position: animation.drive(tween), child: child);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      ref.watch(blockHeightProvider);
                                      return _buildCertificationSection(ref, scaleFactor);
                                    },
                                  ),
                                  _buildActionButton(
                                    context: context,
                                    key: keyCopyAddress,
                                    icon: 'assets/copy_key.png',
                                    label: "copyAddress".tr(),
                                    size: btnSize,
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: address));
                                      SnackbarService.showAddressCopied(context);
                                    },
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  _buildTransferButton(ref, scaleFactor),
                                  SizedBox(height: isCompact ? 4 : scaleSize(isTall ? 40 : 7)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
    required Key key,
    double size = buttonSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: scaleSize(size),
          width: scaleSize(size),
          decoration: BoxDecoration(
            color: context.colorScheme.secondary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: key,
              borderRadius: BorderRadius.circular(size / 2),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(scaleSize(size * 0.2)),
                child: Image.asset(icon, color: context.colorScheme.onSurface),
              ),
            ),
          ),
        ),
        ScaledSizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTransferButton(WidgetRef ref, [double scaleFactor = 1.0]) {
    final btnSize = (buttonSize + 5) * scaleFactor;
    return Consumer(
      builder: (context, ref, _) {
        // Watch block height to trigger rebuilds when connection changes
        ref.watch(blockHeightProvider);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: scaleSize(btnSize),
              width: scaleSize(btnSize),
              decoration: BoxDecoration(
                color: context.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3)),
                ],
                border: Border.all(color: const Color(0xFF6c4204), width: 3),
              ),
              child: Opacity(
                opacity: ref.read(durtProvider).isConnected ? 1 : 0.5,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: keyPay,
                    borderRadius: BorderRadius.circular(btnSize / 2),
                    onTap: ref.read(durtProvider).isConnected ? () => _handleTransfer(ref) : null,
                    child: Padding(
                      padding: EdgeInsets.all(scaleSize(btnSize * 0.19)),
                      child: Image.asset('assets/vector_white.png', color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            ScaledSizedBox(height: 6),
            Text(
              'doATransfer'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: ref.read(durtProvider).isConnected ? context.colorScheme.onSurface : Colors.grey[500],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build the certification section with optional multi-account dropdown
  Widget _buildCertificationSection(WidgetRef ref, [double scaleFactor = 1.0]) {
    final certStateAsync = ref.watch(certStateProvider(address));

    return certStateAsync.when(
      data: (certState) {
        final shouldShowCertification = certState != null && certState.status != CertStatus.none;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeInOutCubic,
          tween: Tween<double>(begin: 0.0, end: shouldShowCertification ? 1.0 : 0.0),
          builder: (context, value, child) {
            // Clamp values to prevent errors
            final clampedValue = value.clamp(0.0, 1.0);

            final certBtnSize = buttonSize * scaleFactor;
            return SizedBox(
              width: scaleSize(certBtnSize + 20), // Extra width for certification text
              child: Opacity(
                opacity: clampedValue,
                child: Transform.scale(
                  scale: clampedValue,
                  child: IgnorePointer(
                    ignoring: clampedValue < 0.1,
                    child: shouldShowCertification
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCertificationWalletDropdown(ref),
                              CertStateWidget(certState: certState, address: address),
                            ],
                          )
                        : SizedBox(width: scaleSize(certBtnSize), height: scaleSize(certBtnSize + 20)),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => SizedBox(width: scaleSize(buttonSize), height: scaleSize(buttonSize + 20)),
      error: (error, stack) => SizedBox(width: scaleSize(buttonSize), height: scaleSize(buttonSize + 20)),
    );
  }

  /// Build the certification wallet dropdown for multi-account selection
  Widget _buildCertificationWalletDropdown(WidgetRef ref) {
    final identityWalletsAsync = ref.watch(identityWalletsAsyncProvider);
    final selectedAddress = ref.watch(selectedCertificationWalletProvider);

    return identityWalletsAsync.when(
      data: (identityWallets) {
        if (identityWallets.length <= 1) {
          return const SizedBox.shrink(); // No need for dropdown with only one wallet
        }

        // If no wallet is selected, default to the first one
        if (selectedAddress == null && identityWallets.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedCertificationWalletProvider.notifier).set(identityWallets.first.address);
          });
        }

        return Padding(
          padding: EdgeInsets.only(bottom: scaleSize(8)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(2)),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_circle, size: scaleSize(14), color: context.colorScheme.primary),
                ScaledSizedBox(width: 4),
                DropdownButton<String>(
                  value: selectedAddress ?? identityWallets.first.address,
                  isDense: true,
                  underline: Container(),
                  style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface),
                  dropdownColor: context.colorScheme.surfaceContainer,
                  items: identityWallets.map((wallet) {
                    return DropdownMenuItem<String>(
                      value: wallet.address,
                      child: Text(
                        WalletNameService.isDefault(wallet.name)
                            ? getShortPubkey(wallet.address)
                            : (wallet.name ?? getShortPubkey(wallet.address)),
                        style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                  onChanged: (newAddress) {
                    if (newAddress != null) {
                      ref.read(selectedCertificationWalletProvider.notifier).set(newAddress);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Future<void> _handleTransfer(WidgetRef ref) async {
    if (!await PinCodeService.askPinCode(context)) return;

    final fromWallet = widget.fromAddress != null ? ref.read(walletByAddressProvider(widget.fromAddress!)) : null;
    if (!mounted) return;
    paymentPopup(context, toAddress: address, username: username, fromWallet: fromWallet);
  }
}
