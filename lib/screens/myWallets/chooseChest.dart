import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/home.dart';
import 'package:flutter/material.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ChooseChest extends StatelessWidget {
  TextEditingController tplController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    int currentChest = configBox.get('currentChest');
    return Scaffold(
        appBar: AppBar(
            title: SizedBox(
          height: 22,
          child: Text('Sélectionner mon coffre'),
        )),
        floatingActionButton: Container(
            height: 80.0,
            width: 80.0,
            child: FittedBox(
                child: FloatingActionButton(
              heroTag: "tplButton",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return HomeScreen();
                }),
              ),
              child: Container(
                height: 40.0,
                width: 40.0,
                child: Icon(Icons.home, color: Colors.grey[850]),
              ),
              backgroundColor:
                  floattingYellow, //smoothYellow, //Color.fromARGB(500, 204, 255, 255),
            ))),
        body: SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: 150),
            Center(
              child: Image.asset(
                'assets/chests/$currentChest.png',
              ),
            ),
            SizedBox(height: 20),
            Text(chestBox.get(currentChest).name),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: yellowC, // background
                  onPrimary: Colors.black, // foreground
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return HomeScreen();
                    }),
                  );
                },
                child: Text('Retour Accueil', style: TextStyle(fontSize: 20))),
            SizedBox(height: 20),
            GestureDetector(
                onTap: () {
                  Navigator.popUntil(
                    context,
                    ModalRoute.withName('/'),
                  );
                },
                child: Icon(Icons.home))
          ]),
        ));
  }
}
