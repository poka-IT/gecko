import 'dart:async';

import 'package:durt2/durt2.dart' as d show ConnectionStatus, Durt, IdentitySuggestion, WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/global_search_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/search_provider.dart';
import 'package:gecko/providers/cesium_plus_search_provider.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/name_by_address.dart';

class GlobalSearchOverlay extends ConsumerStatefulWidget {
  const GlobalSearchOverlay({super.key});

  @override
  ConsumerState<GlobalSearchOverlay> createState() => _GlobalSearchOverlayState();
}

class _GlobalSearchOverlayState extends ConsumerState<GlobalSearchOverlay> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode(debugLabel: 'global_search_overlay');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayOpen = ref.watch(globalSearchProvider.select((state) => state.isOverlayOpen));

    ref.listen(globalSearchProvider.select((state) => state.isOverlayOpen), (_, next) {
      if (next) {
        final searchText = ref.read(searchTextProvider);
        if (_controller.text != searchText) {
          _controller.text = searchText;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _focusNode.requestFocus();
          _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
        });
      }
    });

    return IgnorePointer(
      ignoring: !overlayOpen,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        opacity: overlayOpen ? 1 : 0,
        child: Material(
          type: MaterialType.transparency,
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.42),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeOverlay,
              child: SafeArea(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: overlayOpen ? 0.96 : 0.98, end: overlayOpen ? 1 : 0.98),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Transform.scale(scale: value, child: child),
                    child: GestureDetector(
                      onTap: () {},
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                context.colorScheme.surface.withValues(alpha: 0.98),
                                context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 48,
                                offset: const Offset(0, 26),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(context),
                                const SizedBox(height: 14),
                                _buildSearchField(context),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: context.colorScheme.surface.withValues(alpha: 0.72),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.05)),
                                    ),
                                    child: const _GlobalSearchResults(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'search'.tr(),
                style: scaledTextStyle(fontSize: 18, color: context.colorScheme.onSurface, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '⌘K',
                style: scaledTextStyle(
                  fontSize: 11,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _closeOverlay,
          style: IconButton.styleFrom(
            backgroundColor: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
            foregroundColor: context.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          ref.read(searchTextProvider.notifier).set(value);
          setState(() {});
        },
        onSubmitted: (_) => _openFirstResult(),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'desktopSearchIdentityPlaceholder'.tr(),
          hintStyle: scaledTextStyle(
            fontSize: 15,
            color: context.colorScheme.onSurface.withValues(alpha: 0.36),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: context.colorScheme.primary, size: 22),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchTextProvider.notifier).clear();
                    _focusNode.requestFocus();
                    setState(() {});
                  },
                  icon: Icon(Icons.close_rounded, color: context.colorScheme.onSurface.withValues(alpha: 0.56)),
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
        style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _openFirstResult() async {
    final query = _controller.text.trim();
    if (query.length < 2) return;

    final walletResults = await ref.read(searchResultsProvider.future);
    if (walletResults.isNotEmpty) {
      final first = walletResults.first;
      _openProfile(address: first.address, username: first.username);
      return;
    }

    final squidStatus = ref.read(squidConnectionStatusProvider);
    if (squidStatus != d.ConnectionStatus.connected) return;

    final identities = await ref.read(searchIdentityProvider(query).future);
    if (identities.isNotEmpty) {
      final first = identities.first;
      _openProfile(address: first.address, username: first.name);
      return;
    }

    final cesiumPlusResults = await ref.read(cesiumPlusSearchProvider(query).future);
    if (cesiumPlusResults.isNotEmpty) {
      final first = cesiumPlusResults.first;
      _openProfile(address: first.address, username: first.title);
      return;
    }
  }

  void _openProfile({required String address, String? username}) {
    _closeOverlay(clearSearch: false);
    NavigationService.openProfile(context, address: address, username: username);
  }

  void _closeOverlay({bool clearSearch = true}) {
    ref.read(globalSearchProvider.notifier).closeOverlay();
    if (clearSearch) {
      _controller.clear();
      ref.read(searchTextProvider.notifier).clear();
      if (mounted) {
        setState(() {});
      }
    }
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 10), () {
        if (mounted) {
          _focusNode.unfocus();
        }
      }),
    );
  }
}

class _GlobalSearchResults extends ConsumerWidget {
  const _GlobalSearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchTextProvider).trim();

    if (query.length < 2) {
      return _SearchOverlayHint(query: query);
    }

    final squidStatus = ref.watch(squidConnectionStatusProvider);
    final walletResultsAsync = ref.watch(searchResultsProvider);
    final identityResultsAsync = squidStatus == d.ConnectionStatus.connected
        ? ref.watch(searchIdentityProvider(query))
        : const AsyncValue<List<d.IdentitySuggestion>>.data([]);

    final cesiumPlusResultsAsync = query.length >= 2
        ? ref.watch(cesiumPlusSearchProvider(query))
        : const AsyncValue<List<CesiumPlusSearchResult>>.data([]);

    final walletResults = walletResultsAsync.asData?.value ?? const <G1WalletsList>[];
    final identityResults = identityResultsAsync.asData?.value ?? const <d.IdentitySuggestion>[];
    final cesiumPlusResults = cesiumPlusResultsAsync.asData?.value ?? const <CesiumPlusSearchResult>[];
    final isLoading = walletResultsAsync.isLoading || identityResultsAsync.isLoading;

    final knownAddresses = <String>{
      ...walletResults.map((w) => w.address),
      ...identityResults.map((i) => i.address),
    };
    final dedupedCesiumPlus = deduplicateCesiumPlusResults(cesiumPlusResults, knownAddresses);

    if (isLoading) {
      return const Center(child: Loading(stroke: 3, size: 28));
    }

    if (walletResults.isEmpty && identityResults.isEmpty && dedupedCesiumPlus.isEmpty) {
      return Center(
        child: Text(
          'noResult'.tr(),
          style: scaledTextStyle(
            fontSize: 14,
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (walletResults.isNotEmpty) ...[
          _ResultsSectionTitle(title: 'desktopWalletShortLabel'.tr()),
          const SizedBox(height: 8),
          ...walletResults.map((wallet) => _WalletResultTile(wallet: wallet)),
        ],
        if (identityResults.isNotEmpty) ...[
          if (walletResults.isNotEmpty) const SizedBox(height: 12),
          _ResultsSectionTitle(title: 'verifiedIdentitiesSection'.tr()),
          const SizedBox(height: 8),
          ...identityResults.map((identity) => _IdentityResultTile(identity: identity)),
        ],
        if (dedupedCesiumPlus.isNotEmpty) ...[
          if (walletResults.isNotEmpty || identityResults.isNotEmpty) const SizedBox(height: 12),
          _ResultsSectionTitle(title: 'selfDeclaredNamesSection'.tr()),
          const SizedBox(height: 8),
          ...dedupedCesiumPlus.map((cs) => _CesiumPlusResultTile(result: cs)),
        ],
      ],
    );
  }
}

class _SearchOverlayHint extends StatelessWidget {
  const _SearchOverlayHint({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded, size: 34, color: context.colorScheme.onSurface.withValues(alpha: 0.28)),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'desktopSearchIdentityPlaceholder'.tr() : 'search'.tr(),
              textAlign: TextAlign.center,
              style: scaledTextStyle(
                fontSize: 14,
                color: context.colorScheme.onSurface.withValues(alpha: 0.48),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsSectionTitle extends StatelessWidget {
  const _ResultsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: scaledTextStyle(
          fontSize: 11,
          color: context.colorScheme.onSurface.withValues(alpha: 0.42),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _WalletResultTile extends ConsumerWidget {
  const _WalletResultTile({required this.wallet});

  final G1WalletsList wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SearchResultTileShell(
      address: wallet.address,
      title: getShortPubkey(wallet.address),
      subtitle: NameByAddress(
        wallet: d.WalletEntity.create(
          address: wallet.address,
          name: wallet.username,
          keyPairType: d.Durt.defaultKeyPairType,
        ),
        size: 13,
        showCesiumPlusName: true,
      ),
      username: wallet.username,
      onTap: () {
        ref.read(globalSearchProvider.notifier).closeOverlay();
        ref.read(searchTextProvider.notifier).clear();
        NavigationService.openProfile(context, address: wallet.address, username: wallet.username);
      },
    );
  }
}

class _IdentityResultTile extends ConsumerWidget {
  const _IdentityResultTile({required this.identity});

  final d.IdentitySuggestion identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SearchResultTileShell(
      address: identity.address,
      title: getShortPubkey(identity.address),
      subtitle: Text(
        identity.name,
        overflow: TextOverflow.ellipsis,
        style: scaledTextStyle(
          fontSize: 13,
          color: context.colorScheme.onSurface.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
        ),
      ),
      username: identity.name,
      onTap: () {
        ref.read(globalSearchProvider.notifier).closeOverlay();
        ref.read(searchTextProvider.notifier).clear();
        NavigationService.openProfile(context, address: identity.address, username: identity.name);
      },
    );
  }
}

class _CesiumPlusResultTile extends ConsumerWidget {
  const _CesiumPlusResultTile({required this.result});

  final CesiumPlusSearchResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SearchResultTileShell(
      address: result.address,
      title: getShortPubkey(result.address),
      subtitle: Text(
        result.title,
        overflow: TextOverflow.ellipsis,
        style: scaledTextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: context.colorScheme.onSurface.withValues(alpha: 0.58),
          fontWeight: FontWeight.w600,
        ),
      ),
      username: result.title,
      onTap: () {
        ref.read(globalSearchProvider.notifier).closeOverlay();
        ref.read(searchTextProvider.notifier).clear();
        NavigationService.openProfile(context, address: result.address, username: result.title);
      },
    );
  }
}

class _SearchResultTileShell extends StatelessWidget {
  const _SearchResultTileShell({
    required this.address,
    required this.title,
    required this.subtitle,
    required this.username,
    required this.onTap,
  });

  final String address;
  final String title;
  final Widget subtitle;
  final String? username;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                DatapodAvatar(address: address, size: 42, name: username),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: scaledTextStyle(
                          fontSize: 13,
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      subtitle,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Balance(address: address, size: 12, color: context.colorScheme.onSurface),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
