import 'package:gecko/globals.dart';
import 'package:gecko/models/home.dart';
import 'package:gecko/ui/historyScreen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:gecko/ui/myWallets/walletsHome.dart';
import 'package:gecko/ui/settingsScreen.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class HomeScreen extends StatelessWidget {
  var currentTab = [HistoryScreen(), WalletsHome()];

  @override
  Widget build(BuildContext context) {
    var _homeProvider = Provider.of<HomeProvider>(context);
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Expanded(
                child: ListView(padding: EdgeInsets.zero, children: <Widget>[
              DrawerHeader(
                child: Column(children: <Widget>[
                  SizedBox(height: 0),
                  Image(
                      image: AssetImage('assets/icon/gecko_final.png'),
                      height: 130),
                ]),
                decoration: BoxDecoration(
                  color: Color(0xffD28928),
                ),
              ),
              ListTile(
                title: Text('Paramètres'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return SettingsScreen();
                    }),
                  );
                },
              ),
              ListTile(
                title: Text('A propos'),
                onTap: () {
                  // Update the state of the app.
                  // ...
                },
              ),
            ])),
            Container(
                child: Align(
                    alignment: FractionalOffset.bottomCenter,
                    child: Text('Ğecko v$appVersion'))),
            SizedBox(height: 20)
          ],
        ),
      ),
      appBar: AppBar(
        leading: Builder(
            builder: (context) => IconButton(
                  icon: new Icon(Icons.menu, color: Colors.grey[850]),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )),
        title: Text('Ğecko', style: TextStyle(color: Colors.grey[850])),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.search, color: Colors.grey[850]),
          ),
        ],
        backgroundColor: Color(0xffFFD58D),
      ),
      backgroundColor: Color(0xffF9F9F1),
      body: currentTab[_homeProvider.currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xffFFD58D),
        fixedColor: Colors.grey[850],
        unselectedItemColor: Color(0xffBD935C),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          _homeProvider.currentIndex = index;
        },
        currentIndex: _homeProvider.currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.format_list_bulleted),
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
