import 'package:gecko/ui/historyScreen.dart';
import 'package:gecko/ui/generateWallets.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui';

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
          ],
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
            icon: new Icon(Icons
                .format_list_bulleted), //Icons.person_add_alt_1_rounded //Icons.lock
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.lock),
            label: 'Mes portefeuilles',
          )
        ],
      ),
    );
  }
}
