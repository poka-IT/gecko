import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/widgets/wallet_name.dart';
import 'package:gecko/widgets/wallet_name_controller.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';

class NameByAddress extends StatelessWidget {
  const NameByAddress(
      {Key? key,
      required this.address,
      required this.wallet,
      this.size = 20,
      this.canEdit = false,
      this.color = Colors.black,
      this.fontWeight = FontWeight.w400,
      this.fontStyle = FontStyle.italic})
      : super(key: key);
  final String address;
  final WalletData wallet;
  final Color color;
  final double size;
  final bool canEdit;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    if (indexerEndpoint == '') {
      if (canEdit) {
        return WalletNameController(wallet: wallet, size: size);
      } else {
        return WalletName(wallet: wallet, size: size, color: color);
      }
    }
    final httpLink = HttpLink(
      '$indexerEndpoint/v1/graphql',
    );

    final client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(store: HiveStore()),
        link: httpLink,
      ),
    );
    return GraphQLProvider(
      client: client,
      child: Query(
          options: QueryOptions(
            document: gql(
                getNameByAddressQ), // this is the query string you just created
            variables: {
              'address': address,
            },
            // pollInterval: const Duration(seconds: 10),
          ),
          builder: (QueryResult result,
              {VoidCallback? refetch, FetchMore? fetchMore}) {
            if (result.hasException) {
              return Text(result.exception.toString());
            }

            if (result.isLoading) {
              return const Text('Loading');
            }

            duniterIndexer.walletNameIndexer[address] =
                result.data?['account_by_pk']?['identity']?['name'];

            g1WalletsBox.put(
                address,
                G1WalletsList(
                    address: address,
                    username: duniterIndexer.walletNameIndexer[address]));

            // log.d(g1WalletsBox.toMap().values.first.username);

            if (duniterIndexer.walletNameIndexer[address] == null) {
              if (canEdit) {
                return WalletNameController(wallet: wallet, size: size);
              } else {
                return WalletName(wallet: wallet, size: size, color: color);
              }
            }

            return Text(
              color == Colors.grey[700]!
                  ? '(${duniterIndexer.walletNameIndexer[address]!})'
                  : truncate(duniterIndexer.walletNameIndexer[address]!, 20),
              style: TextStyle(
                fontSize: size,
                color: color,
                fontWeight: fontWeight,
                fontStyle: fontStyle,
              ),
            );
          }),
    );
  }
}
