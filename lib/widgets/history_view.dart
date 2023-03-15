import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/duniter_indexer.dart';
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
    int keyID = 0;
    const double avatarSize = 200;
    bool isMigrationPassed = false;
    List<String> pastDelimiters = [];

    return duniterIndexer.transBC == null
        ? Column(children: <Widget>[
            const SizedBox(height: 50),
            Text(
              "noTransactionToDisplay".tr(),
              style: const TextStyle(fontSize: 18),
            )
          ])
        : Column(children: <Widget>[
            Column(
                children: duniterIndexer.transBC!.map((repository) {
              final answer = computeHistoryView(repository, address);
              pastDelimiters.add(answer['dateDelimiter']);

              bool isMigrationTime = false;
              if (answer['isMigrationTime'] && !isMigrationPassed) {
                isMigrationPassed = true;
                isMigrationTime = true;
              }

              return Column(children: <Widget>[
                if (isMigrationTime)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Image(
                            image: AssetImage('assets/party.png'), height: 40),
                        const SizedBox(width: 40),
                        Text(
                          'blockchainStart'.tr(),
                          style: const TextStyle(
                              fontSize: 25,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 40),
                        const Image(
                            image: AssetImage('assets/party.png'), height: 40),
                      ],
                    ),
                  ),
                if (answer['isChangeOwnerkeyTime'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Image(
                            image: AssetImage('assets/party.png'), height: 40),
                        const SizedBox(width: 40),
                        Text(
                          'Identité migré !'.tr(),
                          style: const TextStyle(
                              fontSize: 25,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 40),
                        const Image(
                            image: AssetImage('assets/party.png'), height: 40),
                      ],
                    ),
                  ),
                if (pastDelimiters.length == 1 ||
                    pastDelimiters.length >= 2 &&
                        !(pastDelimiters[pastDelimiters.length - 2] ==
                            answer['dateDelimiter']))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      answer['dateDelimiter'],
                      style: const TextStyle(
                          fontSize: 23,
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
            if (result.isLoading && duniterIndexer.pageInfo!['hasPreviousPage'])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  CircularProgressIndicator(),
                ],
              ),
            if (!duniterIndexer.pageInfo!['hasNextPage'])
              Column(
                children: <Widget>[
                  const SizedBox(height: 15),
                  Text("historyStart".tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 15)
                ],
              )
          ]);
  }
}
