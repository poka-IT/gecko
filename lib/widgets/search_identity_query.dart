import 'package:durt2/durt2.dart' as d show IdentitySuggestion, ConnectionStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers_deprecated/wallets_profiles.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:provider/provider.dart' as old_provider;

class SearchIdentityQuery extends ConsumerWidget {
  const SearchIdentityQuery({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsProfiles = old_provider.Provider.of<WalletsProfilesProvider>(context, listen: false);

    // Check if we have network connection
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isNetworkAvailable = connectionStatus == d.ConnectionStatus.connected;

    if (!isNetworkAvailable) {
      return Text('noResult'.tr());
    }

    final searchResults = ref.watch(searchIdentityProvider(name));

    return searchResults.when(
      data: (identities) {
        if (identities.isEmpty) {
          return Text('noResult'.tr());
        }
        const double avatarSize = 45;
        return Expanded(
          child: ListView(
            children: identities
                .map(
                  (identity) => _buildIdentityTile(
                    context: context,
                    identity: identity,
                    avatarSize: avatarSize,
                    walletsProfiles: walletsProfiles,
                  ),
                )
                .toList(),
          ),
        );
      },
      loading: () => Text('loading'.tr()),
      error: (error, stackTrace) => Text('noResult'.tr()),
    );
  }

  Widget _buildIdentityTile({
    required BuildContext context,
    required d.IdentitySuggestion identity,
    required double avatarSize,
    required WalletsProfilesProvider walletsProfiles,
  }) {
    return ListTile(
      key: keySearchResult(identity.address),
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.only(right: 2),
      leading: DatapodAvatar(address: identity.address, size: avatarSize, name: identity.name),
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
          Text(
            identity.name,
            style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      dense: !isTall,
      isThreeLine: false,
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return WalletViewScreen(address: identity.address, username: identity.name);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Smooth slide transition from right to left
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
    );
  }
}
