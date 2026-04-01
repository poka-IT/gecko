import 'package:durt2/durt2.dart' show WalletEntity, Durt, IdentitySuggestion, ConnectionStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus_search_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/search_provider.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/widgets/search_identity_query.dart';

class SearchResult extends ConsumerWidget {
  const SearchResult({super.key, required this.avatarSize});

  final double avatarSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchText = ref.watch(searchTextProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    return searchResultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return SearchIdentityQuery(name: searchText);
        } else {
          // When wallet address results are shown, also check for CesiumPlus results
          final cesiumPlusResultsAsync = searchText.trim().length >= 2
              ? ref.watch(cesiumPlusSearchProvider(searchText))
              : const AsyncValue<List<CesiumPlusSearchResult>>.data([]);

          final squidStatus = ref.watch(squidConnectionStatusProvider);
          final identityResultsAsync = squidStatus == ConnectionStatus.connected
              ? ref.watch(searchIdentityProvider(searchText))
              : const AsyncValue<List<IdentitySuggestion>>.data([]);

          final cesiumPlusResults = cesiumPlusResultsAsync.asData?.value ?? [];
          final identityResults = identityResultsAsync.asData?.value ?? [];

          // Deduplicate CesiumPlus results against both wallet and identity addresses
          final knownAddresses = <String>{...results.map((w) => w.address), ...identityResults.map((i) => i.address)};
          final dedupedCesiumPlus = deduplicateCesiumPlusResults(cesiumPlusResults, knownAddresses);

          return Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  children: <Widget>[
                    for (G1WalletsList g1Wallet in results) resultTileAddressSearch(g1Wallet, context),
                    if (dedupedCesiumPlus.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSectionHeader(context, 'selfDeclaredNamesSection'.tr()),
                      for (final result in dedupedCesiumPlus) _buildCesiumPlusTile(result, context),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
      },
      loading: () => const Center(child: Loading(stroke: 3, size: 30)),
      error: (error, stack) => SearchIdentityQuery(name: searchText),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
      child: Text(
        title,
        style: scaledTextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.42),
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  Widget resultTileAddressSearch(G1WalletsList g1Wallet, BuildContext context) {
    return ListTile(
      key: keySearchResult(g1Wallet.address),
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.all(5),
      leading: DatapodAvatar(address: g1Wallet.address, size: avatarSize, name: g1Wallet.username),
      title: Row(
        children: <Widget>[
          Text(
            getShortPubkey(g1Wallet.address),
            style: scaledTextStyle(fontSize: 14, fontFamily: 'Monospace', fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaledSizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Balance(address: g1Wallet.address, size: 14)],
                ),
              ],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: <Widget>[
          NameByAddress(
            wallet: WalletEntity.create(
              address: g1Wallet.address,
              name: g1Wallet.username,
              keyPairType: Durt.defaultKeyPairType,
            ),
            size: 14,
            showCesiumPlusName: true,
          ),
        ],
      ),
      dense: false,
      isThreeLine: false,
      onTap: () {
        NavigationService.openProfile(context, address: g1Wallet.address, username: g1Wallet.username);
      },
    );
  }

  Widget _buildCesiumPlusTile(CesiumPlusSearchResult result, BuildContext context) {
    return ListTile(
      key: keySearchResult(result.address),
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.all(5),
      leading: DatapodAvatar(address: result.address, size: avatarSize, name: result.title),
      title: Row(
        children: <Widget>[
          Text(
            getShortPubkey(result.address),
            style: scaledTextStyle(fontSize: 14, fontFamily: 'Monospace', fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaledSizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Balance(address: result.address, size: 14)],
                ),
              ],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: <Widget>[
          Text(
            result.title,
            style: scaledTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      dense: false,
      isThreeLine: false,
      onTap: () {
        NavigationService.openProfile(context, address: result.address, username: result.title);
      },
    );
  }
}
