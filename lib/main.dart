import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:intl/intl.dart';
// import 'package:flutter_html_view';
import 'api.dart';
import "package:dio/dio.dart";

List<String> litems = ["1", "2", "Third", "4"];

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
            body: Builder(
              builder: (BuildContext context) {
                return ListView(
                  children: <Widget>[
                    Container(
                      color: Colors.white,
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
                                hintText:
                                    'Tappez/Collez une clé publique, ou scannez',
                                hintStyle: TextStyle(fontSize: 15),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 15),
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
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 15),
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                              ),
                              style: TextStyle(
                                  fontSize: 30.0, color: Colors.black)),

                          TextField(

                              // Affichage history
                              enabled: false,
                              controller: this._outputHistory,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.wrap_text),
                                hintText: '',
                                hintStyle: TextStyle(fontSize: 15),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 15),
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                              ),
                              style: TextStyle(
                                  fontSize: 13.0,
                                  height: 1.5,
                                  color: Colors.black)),
                          SizedBox(height: 20),
                          SizedBox(height: 70),
                          // Expanded(
                          //     child: ListView.builder(
                          //         padding: const EdgeInsets.all(8),
                          //         itemCount: names.length,
                          //         itemBuilder: (BuildContext context, int index) {
                          //           return Container(
                          //             height: 50,
                          //             margin: EdgeInsets.all(2),
                          //             child: Center(
                          //                 child: Text(
                          //               '${names[index]} (${msgCount[index]})',
                          //               style: TextStyle(fontSize: 18),
                          //             )),
                          //           );
                          //         }))
                        ],
                      ),
                    ),
                    // new ListView.builder(
                    //     itemCount: litems.length,
                    //     itemBuilder: (BuildContext ctxt, int index) {
                    //       return new Text(litems[index]);
                    //     })
                  ],
                );
              },
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
        history =
            "EN COURS DE TRAITEMENT\n" + historyMP + "VALIDÉ\n" + historyBC;
      }
      this._outputHistory.text = history;
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
