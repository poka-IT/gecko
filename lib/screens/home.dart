import 'package:gecko/globals.dart';
import 'package:gecko/models/history.dart';
import 'package:gecko/models/home.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/walletsHome.dart';
import 'dart:ui';
import 'package:gecko/screens/settings.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    // _historyProvider.snackNode(context);

    return Scaffold(
        resizeToAvoidBottomInset: false,
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
                                _historyProvider.isPubkey(context, text);
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
                    }))
          ],
          backgroundColor: Color(0xffFFD58D),
        ),
        backgroundColor: Color(0xffF9F9F1),
        body: // _homeProvider.currentTab[_homeProvider.currentIndex],
            Builder(
          builder: (context) => Column(children: <Widget>[
            // _historyProvider.snackNode(context),
            // SnackBar(content: Text('tataaa')),

            Padding(
                padding: EdgeInsets.only(top: 22),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image(
                          image: AssetImage('assets/icon/gecko_final.png'),
                          height: 180),
                    ])),
            Padding(
                padding: EdgeInsets.only(top: 15),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "L’application de paiement Ğ1\nplus mobile qu’un lésard du Vietnam",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black, fontSize: 15),
                      )
                    ])),
            Padding(
                padding: EdgeInsets.only(top: 60),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Column(children: <Widget>[
                        ClipOval(
                          child: Material(
                            color: Color(0xffFFD58D), // button color
                            child: Padding(
                                padding: EdgeInsets.all(17),
                                child: InkWell(
                                  splashColor: Colors.black, // inkwell color
                                  child: Image(
                                      image:
                                          AssetImage('assets/qrcode-scan.png'),
                                      height: 58),
                                  onTap: () async {
                                    await _historyProvider.scan(context);
                                  },
                                )),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Payer par QR-Code",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 13),
                        )
                      ])
                    ])),
            Padding(
                padding: EdgeInsets.only(top: 60),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Column(children: <Widget>[
                        ClipOval(
                          child: Material(
                            color: Color(0xffFFD58D), // button color
                            child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                                child: InkWell(
                                  splashColor: Colors.black, // inkwell color
                                  child: Image(
                                      image:
                                          AssetImage('assets/blockchain.png'),
                                      height: 65),
                                  onTap: () {},
                                )),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Explorer\n",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 13),
                        )
                      ]),
                      SizedBox(width: 140),
                      Column(children: <Widget>[
                        ClipOval(
                          child: Material(
                            color: Color(0xffFFD58D), // button color
                            child: Padding(
                                padding: EdgeInsets.all(20),
                                child: InkWell(
                                  splashColor: Colors.black, // inkwell color
                                  child: Image(
                                      image: AssetImage('assets/lock.png'),
                                      height: 50),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) {
                                        return WalletsHome();
                                      }),
                                    );
                                  },
                                )),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Gérer mes\nportefeuilles",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 13),
                        )
                      ])
                    ]))
          ]),
          // bottomNavigationBar: BottomNavigationBar(
          //   backgroundColor: Color(0xffFFD58D),
          //   fixedColor: Colors.grey[850],
          //   unselectedItemColor: Color(0xffBD935C),
          //   type: BottomNavigationBarType.fixed,
          //   onTap: (index) {
          //     _homeProvider.currentIndex = index;
          //   },
          //   currentIndex: _homeProvider.currentIndex,
          //   items: [
          //     BottomNavigationBarItem(
          //       icon: Image.asset('assets/block-space-disabled.png', height: 26),
          //       activeIcon: Image.asset('assets/blockchain.png', height: 26),
          //       label: 'Explorateur',
          //     ),
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.lock),
          //       label: 'Mes portefeuilles',
          //     ),
          //   ],
          // ),
        ));
  }
}
