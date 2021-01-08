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
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GlobalKey<HistoryScreenState> _keyHistory = GlobalKey();

  int _currentIndex = 0;
  Widget currentScreen;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Uint8List bytes = Uint8List(0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: <Widget>[
            HistoryScreen(
              keyHistory: _keyHistory,
            ),
            GenerateWalletScreen(),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 80.0,
        width: 80.0,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () => _keyHistory.currentState.scan(),
            child: Container(
                height: 40.0,
                width: 40.0,
                child: Image.asset('images/scanner.png')),
            backgroundColor: Color.fromARGB(500, 204, 255, 255),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.format_list_bulleted),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.settings),
            label: 'GENERATE WALLET',
          )
        ],
      ),
    ));
  }
}
