import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/onBoarding/1.dart';

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
        body: SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: 190),
            Center(
              child: Image.asset(
                'assets/chests/$currentChest.png',
              ),
            ),
            SizedBox(height: 40),
            Text(
              chestBox.get(currentChest).name,
              style: TextStyle(fontSize: 21),
            ),
            SizedBox(height: 15),
            Image.asset('assets/chests/vector.png'),
            SizedBox(height: 15),
            Text(
              'Choisir un autre\ncoffre',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 80),
            SizedBox(
              width: 400,
              height: 70,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: orangeC, // background
                  onPrimary: Colors.black, // foreground
                ),
                onPressed: () {
                  configBox.put('currentChest', 0);
                  Navigator.popUntil(
                    context,
                    ModalRoute.withName('/mywallets'),
                  );
                },
                child: Text(
                  'Ouvrir ce coffre',
                  style: TextStyle(
                      fontSize: 22,
                      color: backgroundColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(height: 20),
            InkWell(
                key: Key('createNewChest'),
                onTap: () {
                  Navigator.push(
                    context,
                    FaderTransition(page: OnboardingStepOne(), isFast: false),
                  );
                },
                child: SizedBox(
                  width: 400,
                  height: 70,
                  child: Center(
                      child: Text('Créer un nouveau coffre',
                          style: TextStyle(
                              fontSize: 22,
                              color: orangeC,
                              fontWeight: FontWeight.w600))),
                )),
            SizedBox(height: 10),
          ]),
        ));
  }
}
