import 'package:durt2/durt2.dart' as d show IdentitySuggestion, ConnectionStatus, IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus_search_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/name_source_badge.dart';

class SearchIdentityQuery extends ConsumerWidget {
  const SearchIdentityQuery({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if Squid is connected (required for identity search)
    final squidStatus = ref.watch(squidConnectionStatusProvider);
    final isNetworkAvailable = squidStatus == d.ConnectionStatus.connected;

    if (!isNetworkAvailable) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Loading(stroke: 3, size: 24),
              const SizedBox(height: 12),
              Text('connecting'.tr(), style: scaledTextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final searchResults = ref.watch(searchIdentityProvider(name));
    final cesiumPlusResultsAsync = name.trim().length >= 2
        ? ref.watch(cesiumPlusSearchProvider(name))
        : const AsyncValue<List<CesiumPlusSearchResult>>.data([]);

    return searchResults.when(
      data: (identities) {
        final cesiumPlusResults = cesiumPlusResultsAsync.asData?.value ?? [];
        final dedupedCesiumPlus = filterOutEmptyCesiumPlusResults(
          ref,
          deduplicateCesiumPlusResults(cesiumPlusResults, identities.map((i) => i.address).toSet()),
        );

        if (identities.isEmpty && dedupedCesiumPlus.isEmpty) {
          return Text('noResult'.tr());
        }

        const double avatarSize = 45;

        return Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                children: [
                  if (identities.isNotEmpty) ...[
                    SearchSectionHeader(title: 'verifiedIdentitiesSection'.tr(), tone: SearchSectionTone.verified),
                    ...identities.map(
                      (identity) =>
                          _buildIdentityTile(context: context, ref: ref, identity: identity, avatarSize: avatarSize),
                    ),
                  ],
                  if (dedupedCesiumPlus.isNotEmpty) ...[
                    if (identities.isNotEmpty) const SizedBox(height: 8),
                    SearchSectionHeader(title: 'selfDeclaredNamesSection'.tr(), tone: SearchSectionTone.warning),
                    ...dedupedCesiumPlus.map(
                      (result) => _buildCesiumPlusTile(context: context, result: result, avatarSize: avatarSize),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Text('loading'.tr()),
      error: (error, stackTrace) => Text('noResult'.tr()),
    );
  }

  Widget _buildIdentityTile({
    required BuildContext context,
    required WidgetRef ref,
    required d.IdentitySuggestion identity,
    required double avatarSize,
  }) {
    final idtyStatus = ref.watch(hybridIdtyStatusProvider(identity.address)).asData?.value;
    final source = idtyStatus == d.IdtyStatus.validated ? NameSource.identity : NameSource.pendingIdentity;
    return ListTile(
      key: keySearchResult(identity.address),
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.only(right: 2),
      leading: AspectRatio(
        aspectRatio: 1,
        child: DatapodAvatar(address: identity.address, size: avatarSize, name: identity.name),
      ),
      title: Row(
        children: <Widget>[
          Text(
            getShortPubkey(identity.address),
            style: scaledTextStyle(fontSize: 14, fontFamily: 'Monospace', fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      trailing: ScaledSizedBox(
        width: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Balance(address: identity.address, size: 14)],
            ),
          ],
        ),
      ),
      subtitle: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              identity.name,
              overflow: TextOverflow.ellipsis,
              style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(width: scaleSize(6)),
          NameSourceBadge(source: source),
        ],
      ),
      dense: !isTall,
      isThreeLine: false,
      onTap: () {
        NavigationService.openProfile(context, address: identity.address, username: identity.name);
      },
    );
  }

  Widget _buildCesiumPlusTile({
    required BuildContext context,
    required CesiumPlusSearchResult result,
    required double avatarSize,
  }) {
    return ListTile(
      key: keySearchResult(result.address),
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.only(right: 2),
      leading: AspectRatio(
        aspectRatio: 1,
        child: DatapodAvatar(address: result.address, size: avatarSize, name: result.title),
      ),
      title: Row(
        children: <Widget>[
          Text(
            getShortPubkey(result.address),
            style: scaledTextStyle(fontSize: 14, fontFamily: 'Monospace', fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      trailing: ScaledSizedBox(
        width: 120,
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
      subtitle: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              result.title,
              overflow: TextOverflow.ellipsis,
              style: scaledTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(width: scaleSize(6)),
          const NameSourceBadge(source: NameSource.cesiumPlus),
        ],
      ),
      dense: !isTall,
      isThreeLine: false,
      onTap: () {
        NavigationService.openProfile(context, address: result.address, username: result.title);
      },
    );
  }
}
