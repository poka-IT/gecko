import 'package:gecko/ui/historyScreen.dart';
import 'package:gecko/ui/generateWallets.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui';

import 'myWallets.dart';

//ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  HomeScreen({this.screens});
  final List<Widget> screens;

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  GlobalKey<HistoryScreenState> _keyHistory = GlobalKey();

  int currentIndex = 0;
  Widget currentScreen;

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Uint8List bytes = Uint8List(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF9F9F1),
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: <Widget>[
            HistoryScreen(
              keyHistory: _keyHistory,
            ),
            GenerateWalletScreen(),
            MyWalletsScreen(),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 80.0,
        width: 80.0,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () async {
              final resultScan = await _keyHistory.currentState.scan();
              print(resultScan);
              if (resultScan != 'false') {
                onTabTapped(0);
              }
            },
            child: Container(
                height: 40.0,
                width: 40.0,
                child: Image.asset('images/scanner.png')),
            backgroundColor: Color(
                0xffEFEFBF), //Color(0xffFFD68E), //Color.fromARGB(500, 204, 255, 255),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xffFFD68E),
        fixedColor: Color(0xff855F2D),
        unselectedItemColor: Color(0xffBD935C),
        type: BottomNavigationBarType.fixed,
        onTap: onTabTapped,
        currentIndex: currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.format_list_bulleted),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.person_add_alt_1_rounded),
            label: 'Générer un wallet',
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.lock),
            label: 'Mes wallets',
          )
        ],
      ),
    );
  }
}
