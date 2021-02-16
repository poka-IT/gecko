import 'package:gecko/globals.dart';
import 'package:gecko/models/history.dart';
import 'package:gecko/models/home.dart';
import 'package:gecko/screens/history.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:gecko/screens/myWallets/walletsHome.dart';
import 'package:gecko/screens/settings.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class HomeScreen extends StatelessWidget {
  var currentTab = [HistoryScreen(), WalletsHome()];

  @override
  Widget build(BuildContext context) {
    HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
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
        title: _homeProvider.appBarTitle,
        actions: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: IconButton(
                  icon: _homeProvider.searchIcon,
                  color: Colors.grey[850],
                  onPressed: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) {
                    //     return SearchList();
                    //   }),
                    // );

                    if (_homeProvider.searchIcon.icon == Icons.search) {
                      _homeProvider.searchIcon = Icon(
                        Icons.close,
                        color: Colors.grey[850],
                      );
                      _homeProvider.appBarTitle = TextField(
                        autofocus: true,
                        controller: _homeProvider.searchQuery,
                        onChanged: (text) {
                          print("Clé tappé: $text");
                          final String searchResult =
                              _historyProvider.isPubkey(text);
                          if (searchResult != '') {
                            _homeProvider.currentIndex = 0;
                          }
                        },
                        style: TextStyle(
                          color: Colors.grey[850],
                        ),
                        decoration: InputDecoration(
                            prefixIcon:
                                Icon(Icons.search, color: Colors.grey[850]),
                            hintText: "Rechercher ...",
                            hintStyle: TextStyle(color: Colors.grey[850])),
                      );
                      _homeProvider.handleSearchStart();
                    } else {
                      _homeProvider.handleSearchEnd();
                    }
                    _homeProvider.searchAction();
                  }))
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
