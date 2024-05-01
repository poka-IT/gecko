import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:gecko/widgets/transaction_tile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({
    Key? key,
    required this.result,
    required this.address,
  }) : super(key: key);
  final QueryResult result;
  final String address;

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);

    int keyID = 0;
    const double avatarSize = 50;
    bool isMigrationPassed = false;
    List<String> pastDelimiters = [];

    return duniterIndexer.transBC == null
        ? Column(children: <Widget>[
            ScaledSizedBox(height: 50),
            Text(
              "noTransactionToDisplay".tr(),
              style: scaledTextStyle(fontSize: 16),
            )
          ])
        : Column(children: <Widget>[
            Column(
                children: duniterIndexer.transBC!.map((repository) {
              final answer =
                  duniterIndexer.computeHistoryView(repository, address);
              pastDelimiters.add(answer['dateDelimiter']);

              bool isMigrationTime = false;
              if (answer['isMigrationTime'] && !isMigrationPassed) {
                isMigrationPassed = true;
                isMigrationTime = true;
              }

              return Column(children: <Widget>[
                if (isMigrationTime)
                  Padding(
                    padding: EdgeInsets.only(
                        top: scaleSize(25), bottom: scaleSize(15)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image(
                            image: const AssetImage('assets/party.png'),
                            height: scaleSize(31)),
                        Text(
                          'blockchainStart'.tr(),
                          style: scaledTextStyle(
                              fontSize: 19,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w400),
                        ),
                        Image(
                            image: const AssetImage('assets/party.png'),
                            height: scaleSize(31)),
                      ],
                    ),
                  ),
                if (pastDelimiters.length == 1 ||
                    pastDelimiters.length >= 2 &&
                        !(pastDelimiters[pastDelimiters.length - 2] ==
                            answer['dateDelimiter']))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      answer['dateDelimiter'],
                      style: scaledTextStyle(
                          fontSize: 19,
                          color: orangeC,
                          fontWeight: FontWeight.w300),
                    ),
                  ),
                TransactionTile(
                    keyID: keyID,
                    avatarSize: avatarSize,
                    repository: repository,
                    dateForm: answer['dateForm'],
                    finalAmount: answer['finalAmount'],
                    duniterIndexer: duniterIndexer,
                    context: context),
              ]);
            }).toList()),
            if (result.isLoading && duniterIndexer.pageInfo!['hasNextPage'])
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Loading(size: 30, stroke: 3),
                ],
              ),
            if (!duniterIndexer.pageInfo!['hasNextPage'] &&
                sub.oldOwnerKeys[address]?[0] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    PageNoTransit(builder: (context) {
                      return WalletViewScreen(
                        address: sub.oldOwnerKeys[address]![0],
                        username: null,
                      );
                    }),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 40,
                        color: Colors.green[700],
                      ),
                      Column(children: [
                        Text(
                          'identityMigrated'.tr(),
                          style: scaledTextStyle(
                              fontSize: 19,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'from'.tr(args: [
                            ' ${getShortPubkey(sub.oldOwnerKeys[address]![0])}'
                          ]),
                          style: scaledTextStyle(fontSize: 16),
                        ),
                      ]),
                      Icon(
                        Icons.account_circle,
                        size: scaleSize(32),
                        color: Colors.green[700],
                      ),
                    ],
                  ),
                ),
              ),
            if (!duniterIndexer.pageInfo!['hasNextPage'])
              Column(
                children: <Widget>[
                  ScaledSizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.blur_on_outlined, size: scaleSize(31)),
                      Text("historyStart".tr(),
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(
                              fontSize: 19, fontWeight: FontWeight.w300)),
                      Icon(Icons.blur_on_outlined, size: scaleSize(31)),
                    ],
                  ),
                  ScaledSizedBox(height: 30)
                ],
              )
          ]);
  }
}
