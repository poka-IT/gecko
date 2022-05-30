import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'dart:math';
import 'package:intl/intl.dart';

class WalletsProfilesProvider with ChangeNotifier {
  WalletsProfilesProvider(this.address);

  String? address = '';
  String pubkeyShort = '';
  List? transBC;
  String? fetchMoreCursor;
  Map? pageInfo;
  bool isHistoryScreen = false;
  String historySwitchButtun = "Voir l'historique";
  String? rawSvg;
  TextEditingController payAmount = TextEditingController();
  TextEditingController payComment = TextEditingController();
  num? balance;
  int nRepositories = 20;
  int nPage = 1;

  Future<String> scan(context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Permission.camera.request();
    }
    String? barcode;
    try {
      barcode = await scanner.scan();
    } catch (e) {
      log.e(e);
      return 'false';
    }
    if (barcode != null && isAddress(barcode)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return WalletViewScreen(pubkey: barcode!);
        }),
      );
    } else {
      return 'false';
    }
    return barcode;
  }

  // Future<String> pay(BuildContext context, {int? derivation}) async {
  //   MyWalletsProvider _myWalletProvider =
  //       Provider.of<MyWalletsProvider>(context, listen: false);
  //   int? currentChest = configBox.get('currentChest');
  //   String result;

  //     derivation ??=
  //         _myWalletProvider.getDefaultWallet(currentChest)!.derivation!;
  //     result = await Gva(node: endPointGVA).pay(
  //         recipient: pubkey!,
  //         amount: double.parse(payAmount.text),
  //         mnemonic: _myWalletProvider.mnemonic,
  //         comment: payComment.text,
  //         derivation: derivation,
  //         lang: appLang);

  //   return result;
  // }

  bool isAddress(address) {
    final RegExp regExp = RegExp(
      r'^[a-zA-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(address) == true &&
        address.length > 45 &&
        address.length < 52) {
      log.d("C'est une adresse !");

      this.address = address;

      return true;
    } else {
      return false;
    }
  }

// poka: Do99s6wQR2JLfhirPdpAERSjNbmjjECzGxHNJMiNKT3P
// Pi: D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU         // For debug
// Boris: JE6mkuzSpT3ePciCPRTpuMT9fqPUVVLJz2618d33p7tn
// Matograine portefeuille: 9p5nHsES6xujFR7pw2yGy4PLKKHgWsMvsDHaHF64Uj25.
// Lion simone: 78jhpprYkMNF6i5kQPXfkAVBpd2aqcpieNsXTSW4c21f

  List parseHistory(txs, _pubkey) {
    var transBC = [];
    int i = 0;

    const currentBase = 0;
    double currentUD = 10.54;

    for (final trans in txs) {
      var direction = trans['direction'];
      final transaction = trans['node'];
      String? output;
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
      final int amountBrut = int.parse(output.split(':')[0]);
      final base = int.parse(output.split(':')[1]);
      final int applyBase = base - currentBase;
      final num amount =
          removeDecimalZero(amountBrut * pow(10, applyBase) / 100);
      num amountUD = amount / currentUD;
      if (direction == "RECEIVED") {
        transBC[i].add(transaction['issuers'][0]);
        transBC[i].add(getShortPubkey(transaction['issuers'][0]));
        transBC[i].add(amount.toString());
        transBC[i].add(amountUD.toStringAsFixed(2));
      } else if (direction == "SENT") {
        final outPubkey = output.split("SIG(")[1].replaceAll(')', '');
        transBC[i].add(outPubkey);
        transBC[i].add(getShortPubkey(outPubkey));
        transBC[i].add('- ' + amount.toString());
        transBC[i].add(amountUD.toStringAsFixed(2));
      }
      transBC[i].add(transaction['comment']);

      i++;
    }
    return transBC;
  }

  FetchMoreOptions? checkQueryResult(result, opts, _pubkey) {
    final List<dynamic>? blockchainTX =
        (result.data['txsHistoryBc']['both']['edges'] as List<dynamic>?);
    // final List<dynamic> mempoolTX =
    //     (result.data['txsHistoryMp']['receiving'] as List<dynamic>);

    pageInfo = result.data['txsHistoryBc']['both']['pageInfo'];
    fetchMoreCursor = pageInfo!['endCursor'];
    if (fetchMoreCursor == null) nPage = 1;

    if (nPage == 1) {
      nRepositories = 40;
    } else if (nPage == 2) {
      nRepositories = 100;
    }
    nPage++;

    if (fetchMoreCursor != null) {
      opts = FetchMoreOptions(
        variables: {'cursor': fetchMoreCursor, 'number': nRepositories},
        updateQuery: (previousResultData, fetchMoreResultData) {
          final List<dynamic> repos = [
            ...previousResultData!['txsHistoryBc']['both']['edges']
                as List<dynamic>,
            ...fetchMoreResultData!['txsHistoryBc']['both']['edges']
                as List<dynamic>
          ];

          fetchMoreResultData['txsHistoryBc']['both']['edges'] = repos;
          return fetchMoreResultData;
        },
      );
    }

    log.d(
        "###### DEBUG H Parse blockchainTX list. Cursor: $fetchMoreCursor ######");
    if (fetchMoreCursor != null) {
      transBC = parseHistory(blockchainTX, _pubkey);
    } else {
      log.i("###### DEBUG H - Début de l'historique");
    }

    return opts;
  }

  void resetdHistory() {
    notifyListeners();
  }

  num removeDecimalZero(double n) {
    String result = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
    return num.parse(result);
  }

  String generateIdenticon(String _pubkey) {
    return Jdenticon.toSvg(_pubkey);
  }

  // Future<num> getBalance(String _pubkey) async {
  //   final url = Uri.parse(
  //       '$endPointGVA?query={%20balance(script:%20%22$_pubkey%22)%20{%20amount%20base%20}%20}');
  //   final response = await http.get(url);
  //   final result = json.decode(response.body);

  //   if (result['data']['balance'] == null) {
  //     balance = 0.0;
  //   } else {
  //     balance = removeDecimalZero(result['data']['balance']['amount'] / 100);
  //   }

  //   return balance;
  // }

  Future<num?> getBalance(String? _pubkey) async {
    while (balance == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    return balance;
  }

  void reload() {
    notifyListeners();
  }
}

snackCopyKey(context) {
  const snackBar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text("Cette adresse a été copié dans votre presse-papier.",
          style: TextStyle(fontSize: 16)),
      duration: Duration(seconds: 2));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
