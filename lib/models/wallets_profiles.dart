import 'dart:io';

import 'package:durt/durt.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:truncate/truncate.dart';
import 'package:crypto/crypto.dart';
import 'package:fast_base58/fast_base58.dart';

class WalletsProfilesProvider with ChangeNotifier {
  WalletsProfilesProvider(this.pubkey);

  String? pubkey = '';
  String pubkeyShort = '';
  final TextEditingController outputPubkey = TextEditingController();
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

  Future scan(context) async {
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
    if (barcode != null && isPubkey(barcode)) {
      outputPubkey.text = barcode;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return WalletViewScreen(pubkey: pubkey);
        }),
      );
    } else {
      return 'false';
    }
    return barcode;
  }

  Future<String> pay(BuildContext context, String pinCode) async {
    MyWalletsProvider _myWalletModel = MyWalletsProvider();
    int? currentChest = configBox.get('currentChest');
    WalletData? defaultWallet = _myWalletModel.getDefaultWallet(currentChest);

    String dewif = chestBox.get(currentChest)!.dewif!;
    int? derivation;

    if (chestBox.get(currentChest)!.isCesium!) {
      derivation = -1;
    } else {
      derivation = defaultWallet!.derivation;
    }

    String result = await Gva(node: endPointGVA!).pay(
        recipient: pubkey!,
        amount: double.parse(payAmount.text),
        dewif: dewif,
        password: pinCode,
        comment: payComment.text,
        derivation: derivation);

    return result;
  }

  bool isPubkey(pubkey) {
    final RegExp regExp = RegExp(
      r'^[a-zA-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(pubkey) == true &&
        pubkey.length > 42 &&
        pubkey.length < 45) {
      log.d("C'est une pubkey !");

      this.pubkey = pubkey;
      // getShortPubkey(pubkey);

      // outputPubkey.text = pubkey;

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) {
      //     return const WalletViewScreen();
      //   }),
      // );
      // notifyListeners();

      return true;
    } else {
      return false;
    }
  }

  String getShortPubkey(String pubkey) {
    List<int> pubkeyByte = Base58Decode(pubkey);
    Digest pubkeyS256 = sha256.convert(sha256.convert(pubkeyByte).bytes);
    String pubkeyCheksum = Base58Encode(pubkeyS256.bytes);
    String pubkeyChecksumShort = truncate(pubkeyCheksum, 3,
        omission: "", position: TruncatePosition.end);

    pubkeyShort = truncate(pubkey, 5,
            omission: String.fromCharCode(0x2026),
            position: TruncatePosition.end) +
        truncate(pubkey, 4, omission: "", position: TruncatePosition.start) +
        ':$pubkeyChecksumShort';

    return pubkeyShort;
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
    outputPubkey.text = '';
    notifyListeners();
  }

  num removeDecimalZero(double n) {
    String result = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
    return num.parse(result);
  }

  snackCopyKey(context) {
    const snackBar = SnackBar(
        padding: EdgeInsets.all(20),
        content:
            Text("Cette clé publique a été copié dans votre presse-papier."),
        duration: Duration(seconds: 2));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void switchProfileView() {
    isHistoryScreen = !isHistoryScreen;
    if (isHistoryScreen) {
      historySwitchButtun = "Payer";
    } else {
      historySwitchButtun = "Voir l'historique";
    }
    notifyListeners();
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
}
