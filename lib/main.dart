import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'api.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    // final List<String> names = <String>[
    //   'Aby',
    //   'Aish',
    //   'Ayan',
    //   'Ben',
    //   'Bob',
    //   'Charlie',
    //   'Cook',
    //   'Carline'
    // ];
    // final List<int> msgCount = <int>[2, 0, 10, 6, 52, 4, 0, 2];
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
                            enabled: false,
                            controller: this._outputPubkey,
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Clé publique scanné',
                              hintStyle: TextStyle(fontSize: 15),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 15),
                            ),
                            style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                        TextField(
                            enabled: false,
                            controller: this._outputBalance,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Solde du compte scanné',
                              hintStyle: TextStyle(fontSize: 15),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 15),
                            ),
                            style:
                                TextStyle(fontSize: 18.0, color: Colors.black)),
                        TextField(
                            enabled: false,
                            controller: this._outputHistory,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.wrap_text),
                              hintText: 'Historique du compte scanné',
                              hintStyle: TextStyle(fontSize: 15),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 15),
                            ),
                            style: TextStyle(
                                fontSize: 14.0,
                                height: 1.5,
                                color: Colors.black)),
                        SizedBox(height: 20),
                        this._buttonGroup(),
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
                ],
              );
            },
          )
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () => _scanBytes(),
          //   tooltip: 'Prennez une photo',
          //   child: const Icon(Icons.camera_alt),
          // ),
          ),
    );
  }

  Widget _buttonGroup() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 120,
            child: InkWell(
              onTap: _scan,
              child: Card(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Image.asset('images/scanner.png'),
                    ),
                    Divider(height: 20),
                    Expanded(flex: 1, child: Text("Scanner")),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future _scan() async {
    await Permission.camera.request();
    String barcode = await scanner.scan();
    if (barcode == null) {
      print('nothing return.');
    } else {
      print("Debug: " + barcode);
      this._outputPubkey.text = "";
      this._outputBalance.text = "";
      this._outputHistory.text = "";
      // final udValue = await getUD();
      final myBalance = await getBalance(barcode.toString());
      final myHistory = await getHistory(barcode.toString());
      this._outputPubkey.text = barcode;
      this._outputBalance.text = myBalance.toString() + " Ḡ1";

      String historyBloc = "";
      var j = 0;
      for (var i in myHistory) {
        print(i);
        var date = i[0];
        date = DateTime.fromMillisecondsSinceEpoch(date * 1000);
        final issuer = i[1];
        final amount = i[2];
        // final amountUD = i[3];
        final comment = i[4];
        historyBloc += date.toString() +
            " | " +
            issuer.toString() +
            " | " +
            amount.toString() +
            " | " +
            comment.toString() +
            "\n---\n";
        j++;
        if (j >= 10) {
          break;
        }
      }
      this._outputHistory.text = historyBloc;
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
