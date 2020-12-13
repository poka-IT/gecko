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
  TextEditingController _outputAmount;

  @override
  initState() {
    super.initState();
    this._outputPubkey = new TextEditingController();
    this._outputAmount = new TextEditingController();
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
                          controller: this._outputPubkey,
                          maxLines: 2,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.wrap_text),
                            helperText: 'Clé publique scanné',
                            hintText: 'Clé publique scanné',
                            hintStyle: TextStyle(fontSize: 15),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 7, vertical: 15),
                          ),
                        ),
                        TextField(
                          controller: this._outputAmount,
                          maxLines: 2,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.wrap_text),
                            helperText: 'Solde du compte scanné',
                            hintText: 'Solde du compte scanné',
                            hintStyle: TextStyle(fontSize: 15),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 7, vertical: 15),
                          ),
                        ),
                        SizedBox(height: 20),
                        this._buttonGroup(),
                        SizedBox(height: 70),
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
      this._outputAmount.text = "";
      // final udValue = await getUD();
      final myBalance = await getBalance(barcode.toString());
      this._outputPubkey.text = barcode;
      print(myBalance.toString());
      this._outputAmount.text = myBalance.toString();
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
