// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/network_activity_provider.dart';
import 'package:gecko/providers/network_certifications_provider.dart';
import 'package:gecko/providers/network_identities_provider.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/providers/safe_data_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/screens/profile_view.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/animated_header_image.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/buttons/home_settings_button.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/easter_egg_detector.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/widgets/transaction_tile.dart';
import 'package:gecko/widgets/network_activity/identity_tile.dart';
import 'package:gecko/widgets/network_activity/certification_tile.dart';

/// Desktop home layout for wide screens (>= 900px)
/// Two-panel layout: branding + activity on left, dashboard on right
class DesktopHomeWidget extends ConsumerStatefulWidget {
  final bool isEasterEggActive;
  final ValueChanged<bool> onEasterEggStateChange;

  const DesktopHomeWidget({super.key, required this.isEasterEggActive, required this.onEasterEggStateChange});

  @override
  ConsumerState<DesktopHomeWidget> createState() => _DesktopHomeWidgetState();
}

class _DesktopHomeWidgetState extends ConsumerState<DesktopHomeWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<ScrollController> _scrollControllers;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollControllers = List.generate(3, (_) => ScrollController());
    for (final sc in _scrollControllers) {
      sc.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    for (final sc in _scrollControllers) {
      sc.removeListener(_onScroll);
      sc.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final sc = _scrollControllers[_tabController.index];
    if (!sc.hasClients) return;
    if (sc.position.pixels < sc.position.maxScrollExtent * 0.7) return;

    switch (_tabController.index) {
      case 0:
        loadMoreNetworkTransactions(ref);
        break;
      case 1:
        loadMoreNetworkIdentities(ref);
        break;
      case 2:
        loadMoreNetworkCertifications(ref);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return EasterEggDetector(
      onPlayingStateChanged: widget.onEasterEggStateChange,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.5),
            radius: 1.8,
            colors: [
              context.colorScheme.primary.withValues(alpha: 0.12),
              context.colorScheme.surface,
              context.colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Left panel: Branding + Actions + Wallets + Network status
              Expanded(flex: 3, child: _buildLeftPanel(context, ref)),
              // Right panel: Network activity (full height)
              Expanded(flex: 2, child: _buildActivityPanel(context, ref)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Left Panel ───────────────────────────

  Widget _buildLeftPanel(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Settings button + Gecko mascot at the very top
          Stack(
            children: [
              Positioned(top: scaleSize(10), left: 0, child: IconHomeSettings()),
              Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: AnimatedHeaderImage(isEasterEggActive: widget.isEasterEggActive, height: scaleSize(120)),
                ),
              ),
            ],
          ),
          // Message just below gecko
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
            child: DefaultTextStyle(
              textAlign: TextAlign.center,
              style: scaledTextStyle(color: context.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
              child: Consumer(
                builder: (context, ref, _) {
                  final homeMessage = ref.watch(homeMessageProvider);
                  final homeMessageNotifier = ref.read(homeMessageProvider.notifier);
                  return GestureDetector(
                    onTap: () {
                      if (homeMessage == "noLizard".tr()) {
                        homeMessageNotifier.showWisdomOfTheDay(context);
                      }
                    },
                    child: AnimatedFadeOutIn<String>(
                      data: homeMessage,
                      duration: const Duration(milliseconds: 200),
                      builder: (value) => Text(value),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Horizontal action buttons
          _buildHorizontalButtons(context, ref),
          const SizedBox(height: 20),
          // Total balance
          _buildTotalBalanceCard(context, ref),
          const SizedBox(height: 10),
          // Wallet list (flexible, adapts to content)
          Flexible(child: _buildWalletOverview(context, ref)),
          const SizedBox(height: 10),
          // Network status
          _buildNetworkStatusCard(context, ref),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ─── Activity Panel (right, full height) ───

  Widget _buildActivityPanel(BuildContext context, WidgetRef ref) {
    return Padding(padding: const EdgeInsets.fromLTRB(0, 12, 16, 12), child: _buildNetworkActivityFeed(context, ref));
  }

  Widget _buildHorizontalButtons(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(
          context: context,
          icon: 'assets/home/loupe.png',
          label: 'searchWallet'.tr(),
          onTap: () => Navigator.pushNamed(context, RouteNames.search),
        ),
        ScaledSizedBox(width: 30),
        _buildCircleButton(
          context: context,
          icon: 'assets/home/wallet.png',
          label: 'manageWallets'.tr(),
          onTap: () async {
            if (!await PinCodeService.askPinCode(canSwitch: true)) return;
            Navigator.pushNamed(context, RouteNames.myWallets);
          },
        ),
        ScaledSizedBox(width: 30),
        _buildCircleButton(
          context: context,
          icon: 'assets/home/qrcode.png',
          label: 'scanQRCode'.tr(),
          onTap: () async {
            final scanQr = ref.read(qrScanProvider);
            await scanQr(context);
          },
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final size = scaleSize(60);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(padding: EdgeInsets.all(scaleSize(14)), child: Image.asset(icon)),
            ),
          ),
        ),
        ScaledSizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: scaledTextStyle(
            color: context.colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Network Activity Feed ───

  Widget _buildNetworkActivityFeed(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkProvider);
    final networkLabel = network.name.toUpperCase();

    return _buildGlassCard(
      context,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Network label header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Icon(Icons.public, size: 16, color: context.colorScheme.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  'networkActivity'.tr(),
                  style: scaledTextStyle(
                    fontSize: 13,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    networkLabel,
                    style: scaledTextStyle(
                      fontSize: 10,
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Tab bar
          TabBar(
            controller: _tabController,
            indicatorColor: context.colorScheme.primary,
            labelColor: context.colorScheme.primary,
            unselectedLabelColor: context.colorScheme.onSurface.withValues(alpha: 0.5),
            labelStyle: scaledTextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: scaledTextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0.5,
            dividerColor: context.colorScheme.outline.withValues(alpha: 0.1),
            tabs: [
              Tab(
                height: 42,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.swap_horiz, size: 16), const SizedBox(width: 4), Text('transactions'.tr())],
                ),
              ),
              Tab(
                height: 42,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.person, size: 16), const SizedBox(width: 4), Text('identities'.tr())],
                ),
              ),
              Tab(
                height: 42,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.verified, size: 16), const SizedBox(width: 4), Text('certifications'.tr())],
                ),
              ),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsTab(context, ref),
                _buildIdentitiesTab(context, ref),
                _buildCertificationsTab(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(networkActivityProvider);

    if (activityState.transactions.isEmpty) {
      if (activityState.isLoading) {
        return Center(child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 2));
      }
      return _buildEmptyState(context, Icons.swap_horiz, 'noNetworkActivity'.tr());
    }

    return ListView.builder(
      controller: _scrollControllers[0],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: activityState.transactions.length,
      itemBuilder: (context, index) {
        final transaction = activityState.transactions[index];
        return TransactionTile(
          key: Key("desktop_tx_$index"),
          keyID: index,
          avatarSize: scaleSize(32),
          transaction: transaction,
          context: context,
        );
      },
    );
  }

  Widget _buildIdentitiesTab(BuildContext context, WidgetRef ref) {
    final identitiesState = ref.watch(networkIdentitiesProvider);

    if (identitiesState.identities.isEmpty) {
      if (identitiesState.isLoading) {
        return Center(child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 2));
      }
      return _buildEmptyState(context, Icons.person_outline, 'noIdentityActivity'.tr());
    }

    return ListView.builder(
      controller: _scrollControllers[1],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: identitiesState.identities.length,
      itemBuilder: (context, index) {
        return IdentityTile(key: Key("desktop_idty_$index"), identity: identitiesState.identities[index]);
      },
    );
  }

  Widget _buildCertificationsTab(BuildContext context, WidgetRef ref) {
    final certsState = ref.watch(networkCertificationsProvider);

    if (certsState.certifications.isEmpty) {
      if (certsState.isLoading) {
        return Center(child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 2));
      }
      return _buildEmptyState(context, Icons.verified_outlined, 'noCertificationActivity'.tr());
    }

    return ListView.builder(
      controller: _scrollControllers[2],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: certsState.certifications.length,
      itemBuilder: (context, index) {
        return CertificationTile(key: Key("desktop_cert_$index"), certification: certsState.certifications[index]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: context.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Text(
            message,
            style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  // ─── Total Balance Card ───

  Widget _buildTotalBalanceCard(BuildContext context, WidgetRef ref) {
    final currentSafe = ref.watch(currentSafeNumberProvider);
    final safeData = ref.watch(safeOnChainDataProvider(currentSafe));

    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: safeData.when(
        data: (data) {
          var total = BigInt.zero;
          for (final balance in data.balances.values) {
            total += balance.transferableBalance;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'soldeTotal'.tr(),
                style: scaledTextStyle(
                  fontSize: 12,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: BalanceDisplay(
                  value: total,
                  size: 20,
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
        loading: () => SizedBox(
          height: 24,
          child: Center(
            child: CircularProgressIndicator(
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, _) =>
            Text('errorLoadingWalletData'.tr(), style: scaledTextStyle(fontSize: 12, color: Colors.red[300]!)),
      ),
    );
  }

  // ─── Wallet Overview Card ───

  Widget _buildWalletOverview(BuildContext context, WidgetRef ref) {
    final walletsState = ref.watch(walletsListProvider);

    return _buildGlassCard(
      context,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: scaleSize(14),
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'myWalletsTitle'.tr(),
                style: scaledTextStyle(
                  fontSize: 12,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${walletsState.wallets.length}',
                style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (walletsState.wallets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'noWalletFound'.tr(),
                  style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: walletsState.wallets.length,
                separatorBuilder: (_, _) =>
                    Divider(color: context.colorScheme.outline.withValues(alpha: 0.06), height: 1),
                itemBuilder: (context, index) {
                  final wallet = walletsState.wallets[index];
                  return _buildWalletRow(context, ref, wallet);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletRow(BuildContext context, WidgetRef ref, d.WalletEntity wallet) {
    final idtyStatus = ref.watch(safeWalletIdtyStatusProvider(wallet.address));

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileViewScreen(address: wallet.address, username: wallet.name),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: scaleSize(28),
              height: scaleSize(28),
              child: ClipOval(
                child:
                    wallet.imagePath != null && wallet.imagePath!.isNotEmpty && !wallet.imagePath!.startsWith('assets/')
                    ? CachedAvatarImage(imagePath: wallet.imagePath!, fit: BoxFit.cover, isCircular: false)
                    : Image.asset('assets/avatars/${wallet.number % 4}.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NameByAddress(
                    wallet: wallet,
                    size: 12,
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  Row(
                    children: [
                      if (idtyStatus != null && idtyStatus != d.IdtyStatus.none)
                        Padding(padding: const EdgeInsets.only(right: 4), child: _buildIdtyStatusDot(idtyStatus)),
                      Text(
                        getShortPubkey(wallet.address),
                        style: scaledTextStyle(
                          fontSize: 9,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                          fontFamily: 'Monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Balance(address: wallet.address, size: 12, color: context.colorScheme.onSurface),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildIdtyStatusDot(d.IdtyStatus status) {
    final color = switch (status) {
      d.IdtyStatus.validated => Colors.green,
      d.IdtyStatus.confirmed => Colors.orange,
      d.IdtyStatus.created => Colors.blue,
      d.IdtyStatus.expired => Colors.red,
      d.IdtyStatus.revoked => Colors.grey,
      _ => Colors.grey,
    };

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 3, spreadRadius: 1)],
      ),
    );
  }

  Widget _buildStatusDot(bool isConnected) {
    final color = isConnected ? Colors.green : Colors.orange;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)],
      ),
    );
  }

  // ─── Network Status Card ───

  Widget _buildNetworkStatusCard(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final squidStatus = ref.watch(squidConnectionStatusProvider);
    final blockHeight = ref.watch(blockHeightProvider);
    final isDuniterConnected = connectionStatus == d.ConnectionStatus.connected;
    final isSquidConnected = squidStatus == d.ConnectionStatus.connected;

    String duniterDisplay = '';
    String squidDisplay = '';
    if (isDuniterConnected) {
      try {
        duniterDisplay = d.Networks.duniterEndpoint.replaceFirst('wss://', '').replaceFirst('ws://', '');
      } catch (_) {}
    }
    if (isSquidConnected) {
      try {
        squidDisplay = d.Networks.squidEndpoint.replaceFirst('https://', '').replaceFirst('http://', '');
      } catch (_) {}
    }

    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Node info (left side)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Duniter node row
                Row(
                  children: [
                    _buildStatusDot(isDuniterConnected),
                    const SizedBox(width: 6),
                    Text(
                      'Duniter',
                      style: scaledTextStyle(
                        fontSize: 10,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isDuniterConnected ? duniterDisplay : 'connecting'.tr(),
                        style: scaledTextStyle(
                          fontSize: 10,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Squid indexer row
                Row(
                  children: [
                    _buildStatusDot(isSquidConnected),
                    const SizedBox(width: 6),
                    Text(
                      'Indexer',
                      style: scaledTextStyle(
                        fontSize: 10,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isSquidConnected ? squidDisplay : 'connecting'.tr(),
                        style: scaledTextStyle(
                          fontSize: 10,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Block height (right side, vertically centered)
          if (isDuniterConnected && blockHeight > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '#$blockHeight',
                style: scaledTextStyle(
                  fontSize: 12,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
