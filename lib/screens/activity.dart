// ignore_for_file: must_be_immutable

import 'package:durt2/durt2.dart' show IdtyStatusExtension;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers.dart';

import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';
import 'package:gecko/widgets/history_query.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/widgets/compact_wallet_header.dart';
import 'package:gecko/widgets/intelligent_app_bar_title.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/transaction_in_progress_data.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({required this.address, this.username, this.transactionData}) : super(key: keyActivityScreen);

  final String address;
  final String? username;
  final TransactionInProgressData? transactionData;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> with TickerProviderStateMixin {
  late Future<WalletHeaderData> _headerDataFuture;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  static const double _expandedHeaderHeight = 100.0;
  static const double _collapsedHeaderHeight = 60.0;
  static const double _scrollThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    ref.read(storageServiceProvider).getOldOwnerKey(widget.address);
    _headerDataFuture = _loadWalletData();

    // Initialize animation controller
    _headerAnimationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final offset = notification.metrics.pixels;

      if (offset > _scrollThreshold) {
        // Scroll down - collapse header
        if (_headerAnimationController.value < 1.0) {
          _headerAnimationController.forward();
        }
      } else {
        // Scroll up - expand header
        if (_headerAnimationController.value > 0.0) {
          _headerAnimationController.reverse();
        }
      }
    }
    return false;
  }

  Future<WalletHeaderData> _loadWalletData() async {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    final (idtyStatusValue, balanceResult, certData) = await (
      ref.read(storageServiceProvider).getIdtyStatus(widget.address),
      ref.read(storageServiceProvider).getBalance(widget.address),
      ref.read(storageServiceProvider).getCertsCounter(widget.address),
    ).wait;

    final data = WalletHeaderData(
      hasIdentity: idtyStatusValue.hasIdentity,
      isOwner: myWalletProvider.isOwner(widget.address),
      walletName: ref.read(squidServiceProvider).walletNameIndexer[widget.address],
      balance: balanceResult.transferableBalance,
      certsReceived: certData.receivedCount,
      certsSent: certData.sentCount,
    );

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WalletHeaderData>(
      future: _headerDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: WalletAppBar(address: widget.address, title: 'accountActivity'.tr()),
            body: const Center(child: CircularProgressIndicator()),
            bottomNavigationBar: const GeckoBottomAppBar(),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: WalletAppBar(address: widget.address, title: 'accountActivity'.tr()),
            body: Center(child: Text('errorLoadingWalletData'.tr())),
            bottomNavigationBar: const GeckoBottomAppBar(),
          );
        }

        return _buildScaffold(snapshot.data!);
      },
    );
  }

  Widget _buildScaffold(WalletHeaderData headerData) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [_buildCollapsibleHeader()];
          },
          body: Stack(
            children: [
              HistoryQuery(address: widget.address, transactionData: widget.transactionData),
              const OfflineInfo(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const GeckoBottomAppBar(),
    );
  }

  Widget _buildCollapsibleHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        // Watch balance to determine if wallet is empty
        final balanceAsync = ref.watch(smartBalanceStreamProvider(widget.address));
        final balance = balanceAsync.hasValue ? balanceAsync.value?.transferableBalance : null;
        final isEmptyWallet = balance == null || balance == BigInt.zero;

        // Calculate dynamic heights based on animation
        final currentExpandedHeight = _expandedHeaderHeight - (_headerAnimation.value * 40);
        final currentCollapsedHeight = _collapsedHeaderHeight;

        // Determine background color based on wallet state
        final backgroundColor = isEmptyWallet
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.tertiary;

        return SliverAppBar(
          expandedHeight: currentExpandedHeight,
          collapsedHeight: currentCollapsedHeight,
          pinned: true,
          stretch: true,
          backgroundColor: backgroundColor,
          elevation: _headerAnimation.value * 4,
          surfaceTintColor: backgroundColor,
          shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
          title: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _headerAnimation.value > 0.3 ? 1.0 : 0.0,
            child: IntelligentAppBarTitle(address: widget.address),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.only(top: kToolbarHeight + 4),
              child: Transform.translate(
                offset: Offset(0, 15 * _headerAnimation.value),
                child: Opacity(
                  opacity: 1.0 - _headerAnimation.value,
                  child: CompactWalletHeader(address: widget.address),
                ),
              ),
            ),
            stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
          ),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        );
      },
    );
  }
}
