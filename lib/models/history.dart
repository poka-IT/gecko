import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry/sentry.dart' as sentry;
import 'package:qrscan/qrscan.dart' as scanner;
import 'dart:math';
import 'package:intl/intl.dart';

class HistoryProvider with ChangeNotifier {
  String pubkey = '';
  HistoryProvider(this.pubkey);
  final TextEditingController outputPubkey = new TextEditingController();
  bool isTheEnd = false;
  List transBC;
  bool isFirstBuild = true;

  Future scan() async {
    await Permission.camera.request();
    String barcode;
    try {
      barcode = await scanner.scan();
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
      return 'false';
    }
    if (barcode != null) {
      this.outputPubkey.text = barcode;
      isPubkey(barcode);
    } else {
      return 'false';
    }
    return barcode;
  }

  String isPubkey(pubkey) {
    final RegExp regExp = new RegExp(
      r'^[a-zA-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(pubkey) == true &&
        pubkey.length > 42 &&
        pubkey.length < 45) {
      print("C'est une pubkey !!!");

      this.pubkey = pubkey;
      this.outputPubkey.text = pubkey;
      notifyListeners();

      return pubkey;
    }

    return '';
  }

// Pi: D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU         // For debug
// Boris: JE6mkuzSpT3ePciCPRTpuMT9fqPUVVLJz2618d33p7tn
// Matograine portefeuille: 9p5nHsES6xujFR7pw2yGy4PLKKHgWsMvsDHaHF64Uj25.
// Lion simone: 78jhpprYkMNF6i5kQPXfkAVBpd2aqcpieNsXTSW4c21f

  List parseHistory(txs, _pubkey) {
    // print(txs);
    var transBC = [];
    int i = 0;

    final currentBase = 0;
    double currentUD = 10.54;

    for (final trans in txs) {
      var direction = trans['direction'];
      final transaction = trans['node'];
      var output;
      if (direction == "RECEIVED") {
        for (String line in transaction['outputs']) {
          if (line.contains(_pubkey)) {
            output = line;
          }
        }
      } else {
        output = transaction['outputs'][0];
      }
      if (output == null) {
        continue;
      }

      transBC.add(i);
      transBC[i] = [];
      final dateBrut = DateTime.fromMillisecondsSinceEpoch(
          transaction['writtenTime'] * 1000);
      final DateFormat formatter = DateFormat('dd-MM-yy\nHH:mm');
      final date = formatter.format(dateBrut);
      transBC[i].add(transaction['writtenTime']);
      transBC[i].add(date);
      // print(
      //     "DEBUG date et comment: ${date.toString()} -- ${transaction['comment'].toString()}");
      int amountBrut = int.parse(output.split(':')[0]);
      final base = int.parse(output.split(':')[1]);
      final int applyBase = base - currentBase;
      final num amount =
          removeDecimalZero(amountBrut * pow(10, applyBase) / 100);
      num amountUD = amount / currentUD;
      if (direction == "RECEIVED") {
        transBC[i].add(transaction['issuers'][0]);
        transBC[i].add(amount.toString());
        transBC[i].add(amountUD.toStringAsFixed(2));
      } else if (direction == "SENT") {
        final outPubkey = output.split("SIG(")[1].replaceAll(')', '');
        transBC[i].add(outPubkey);
        transBC[i].add('- ' + amount.toString());
        transBC[i].add(amountUD.toStringAsFixed(2));
      }
      transBC[i].add(transaction['comment']);

      i++;
    }
    return transBC;
  }

  FetchMoreOptions checkQueryResult(result, opts, _pubkey) {
    final List<dynamic> blockchainTX =
        (result.data['txsHistoryBc']['both']['edges'] as List<dynamic>);

    final Map pageInfo = result.data['txsHistoryBc']['both']['pageInfo'];

    final String fetchMoreCursor = pageInfo['endCursor'];

    if (fetchMoreCursor != null) {
      opts = FetchMoreOptions(
        variables: {'cursor': fetchMoreCursor},
        updateQuery: (previousResultData, fetchMoreResultData) {
          final List<dynamic> repos = [
            ...previousResultData['txsHistoryBc']['both']['edges']
                as List<dynamic>,
            ...fetchMoreResultData['txsHistoryBc']['both']['edges']
                as List<dynamic>
          ];

          fetchMoreResultData['txsHistoryBc']['both']['edges'] = repos;
          return fetchMoreResultData;
        },
      );
    }

    print(
        "###### DEBUG H Parse blockchainTX list. Cursor: $fetchMoreCursor ######");
    if (fetchMoreCursor != null) {
      transBC = parseHistory(blockchainTX, _pubkey);
      isTheEnd = false;
    } else {
      print("###### DEBUG H - Début de l'historique");
      isTheEnd = true;
    }

    return opts;
  }

  void snackNode(context) {
    if (isFirstBuild) {
      String _message;
      if (endPointGVA == 'HS') {
        _message =
            "Aucun noeud Duniter disponible, veuillez réessayer ultérieurement";
      } else {
        _message = "Vous êtes connecté au noeud\n${endPointGVA.split('/')[2]}";
      }
      final snackBar =
          SnackBar(content: Text(_message), duration: Duration(seconds: 2));
      Scaffold.of(context).showSnackBar(snackBar);
      isFirstBuild = false;
    }
  }

  void resetdHistory() {
    this.outputPubkey.text = '';
    notifyListeners();
  }

  num removeDecimalZero(double n) {
    String result = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
    return num.parse(result);
  }

  // num getBalance(_pubkey) {
  //   getBalance(_pubkey);
  // }
}
