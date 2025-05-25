import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/wallet_name.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';

class NameByAddress extends StatelessWidget {
  const NameByAddress({super.key, required this.wallet, this.size = 20, this.color, this.fontWeight = FontWeight.w400, this.fontStyle = FontStyle.normal});
  final WalletData wallet;
  final Color? color;
  final double size;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final finalColor = color ?? Theme.of(context).colorScheme.onSurface;

    if (indexerEndpoint == '') {
      return WalletName(wallet: wallet, size: size, color: finalColor);
    }

    return GraphQLProvider(
      client: ValueNotifier(duniterIndexer.indexerClient),
      child: Query(
          options: QueryOptions(
            document: gql(getNameByAddressQ),
            variables: {
              'address': wallet.address,
            },
          ),
          builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
            if (kDebugMode) {
              if (result.hasException) {
                return Text(result.exception.toString());
              }
            }

            if (result.isLoading) {
              return const Loading();
            }

            final edges = result.data?['identityConnection']['edges'];
            final name = edges != null && edges.isNotEmpty ? edges[0]['node']['name'] : null;

            duniterIndexer.walletNameIndexer[wallet.address] = name;

            g1WalletsBox.put(wallet.address, G1WalletsList(address: wallet.address, username: duniterIndexer.walletNameIndexer[wallet.address]));

            if (duniterIndexer.walletNameIndexer[wallet.address] == null) {
              return WalletName(wallet: wallet, size: size, color: finalColor);
            }

            return Text(
              finalColor == homeContext.colorScheme.onSurfaceVariant
                  ? '(${duniterIndexer.walletNameIndexer[wallet.address]!})'
                  : truncate(duniterIndexer.walletNameIndexer[wallet.address]!, 19),
              style: scaledTextStyle(
                fontSize: size,
                color: finalColor,
                fontWeight: fontWeight,
                fontStyle: fontStyle,
              ),
            );
          }),
    );
  }
}
