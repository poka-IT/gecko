import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:intl/intl.dart';
import 'api.dart';
import "package:dio/dio.dart";
import 'ui/history_list_view.dart';

/// Integrates a list of articles with [ListPreferencesScreen].
class HistoryListScreen extends StatefulWidget {
  @override
  _HistoryListScreenState createState() => _HistoryListScreenState();
}


// class HistoryListScreen extends StatefulWidget {
//   // GeckoHome({Key key, this.title}) : super(key: key);
//   // final String title;

//   const HistoryListScreen({
//     @required this.repository,
// final String title,
//     Key key,
//   })  : assert(repository != null),
//         super(key: key);

//   final Repository repository;

//   @override
//   _GeckoHomeState createState() => _GeckoHomeState();
// }

class _HistoryListScreenState extends State<HistoryListScreen> {
  Uint8List bytes = Uint8List(0);
  TextEditingController _outputPubkey;
  TextEditingController _outputBalance;
  TextEditingController _outputHistory;

  @override
  initState() {
    super.initState();
    this._outputPubkey = new TextEditingController();
    this._outputBalance = new TextEditingController();
    this._outputHistory = new TextEditingController();
    // checkNode().then((result) {
    //   setState(() {
    //     _result = result;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            backgroundColor: Colors.grey[300],
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  SizedBox(height: 20),
                  TextField(
                      // enabled: false,
                      onChanged: (text) {
                        print("Clé tappé: $text");
                        isPubkey(text);
                      },
                      controller: this._outputPubkey,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Tappez/Collez une clé publique, ou scannez',
                        hintStyle: TextStyle(fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 7, vertical: 15),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
                  TextField(
                      // Affichage balance
                      enabled: false,
                      controller: this._outputBalance,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '',
                        hintStyle: TextStyle(fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 7, vertical: 15),
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      style: TextStyle(fontSize: 30.0, color: Colors.black)),
                  Expanded(
                      child: HistoryListView(
          repository: Provider.of<Repository>(context)
                          ))
                ],
              ),
            ),
            floatingActionButton: Container(
              height: 80.0,
              width: 80.0,
              child: FittedBox(
                child: FloatingActionButton(
                  onPressed: () => _scan(),
                  // label: Text('Scanner'),
                  child: Container(
                      height: 40.0,
                      width: 40.0,
                      child: Image.asset('images/scanner.png')),
                  backgroundColor: Color.fromARGB(500, 204, 255, 255),
                ),
              ),
            )));
  }

  Widget buildTranscationCard(Transaction transaction) {
    return Card(
      // 1
      elevation: 2.0,
      // 2
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      // 3
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        // 4
        child: Column(
          children: <Widget>[
            // 5
            SizedBox(
              height: 14.0,
            ),
            // 6
            Text(
              transaction.pubkey,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                fontFamily: "Palatino",
              ),
            ),
            Text(transaction.date,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  fontFamily: "Palatino",
                ))
          ],
        ),
      ),
    );
  }

  Future checkNode() async {
    final response = await Dio().post(graphqlEndpoint);
    showHistory(response);
    return response;
  }

  Future _scan() async {
    await Permission.camera.request();
    String barcode = await scanner.scan();
    // this._outputPubkey.text = "";
    if (barcode != null) {
      isPubkey(barcode);
    }
    return barcode;
  }

  Future isPubkey(pubkey) async {
    // final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
    RegExp regExp = new RegExp(
      r'^[a-zA-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(pubkey) == true &&
        pubkey.length > 42 &&
        pubkey.length < 45) {
      print("C'est une pubkey !!!");
      print(pubkey.length);
      showHistory(pubkey);
    }
  }

  Future showHistory(pubkey) async {
    // String pubkey = await _scan();
    if (pubkey == null) {
      print('nothing return.');
    } else {
      this._outputPubkey.text = "";
      this._outputBalance.text = "";
      this._outputHistory.text = "";
      // final udValue = await getUD();
      this._outputPubkey.text = pubkey;
      final myBalance = await getBalance(pubkey.toString());
      this._outputBalance.text = myBalance.toString() + " Ğ1";
    }
  }

  // Future _generateBarCode(String inputCode) async {
  //   if (inputCode != null && inputCode.isNotEmpty) {
  //     // print("Résultat du scan: " + inputCode);
  //     Uint8List result = await scanner.generateBarCode(inputCode);
  //     this.setState(() => this.bytes = result);
  //   } else {
  //     print("Veuillez renseigner une clé publique");
  //   }
  // }

}

class Transaction {
  String pubkey;
  String date;

  Transaction(this.pubkey, this.date);

  // TODO: Build this list !!!!
  // static List<Transaction> samples = List<Transaction> getHistory(pubkey.toString());

  Future buildHistory() async {
    final myHistory = await getHistory(pubkey.toString());
    if (myHistory == false) {
      return false;
    }

    String historyBC = "";
    for (var i in myHistory[0]) {
      var dateBrut = i[0];
      dateBrut = DateTime.fromMillisecondsSinceEpoch(dateBrut * 1000);
      final DateFormat formatter = DateFormat('dd-MM-yy - H:M');
      final String date = formatter.format(dateBrut);
      final issuer = i[1];
      final amount = i[2];
      // final amountUD = i[3];
      final comment = i[4];
      historyBC += date.toString() +
          " \n " +
          issuer.toString() +
          " \n " +
          amount.toString() +
          " Ğ1\n " +
          comment.toString() +
          "\n---\n";
    }

    String historyMP = "";
    for (var i in myHistory[1]) {
      if (i == null) {
        break;
      }
      var dateBrut = "Now";
      final issuer = i[1];
      final amount = i[2];
      // final amountUD = i[3];
      final comment = i[4];
      historyMP += dateBrut.toString() +
          " \n " +
          issuer.toString() +
          " \n " +
          amount.toString() +
          " Ğ1\n " +
          comment.toString() +
          "\n------------------\n";
    }

    var history;
    // print(historyMP.toString());
    if (historyMP == "") {
      history = historyBC;
    } else {
      history = "EN COURS DE TRAITEMENT\n" + historyMP + "VALIDÉ\n" + historyBC;
    }
    // this._outputHistory.text = history;

  List<Transaction> samples = List<Transaction> 

    return myHistory[0];
  }

  // static List<Transaction> samples = buildHistory();

  var list = json
      .decode(response.body)['results']
      .map((data) => Model.fromJson(data))
      .toList();

  // static List<Transaction> samples = [
  //   Transaction(
  //     "Spaghetti and Meatballs",
  //     "assets/2126711929_ef763de2b3_w.jpg",
  //   ),
  //   Transaction(
  //     "Tomato Soup",
  //     "assets/27729023535_a57606c1be.jpg",
  //   )
  // ];
}
