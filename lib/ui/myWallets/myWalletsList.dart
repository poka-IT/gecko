// import 'package:gecko/ui/generateWallets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/ui/myWallets/walletOptions.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MyWalletsList extends StatefulWidget {
  const MyWalletsList({Key keyMyWallets}) : super(key: keyMyWallets);
  @override
  MyWalletListState createState() => MyWalletListState();
}

class MyWalletListState extends State<MyWalletsList> {
  Directory walletsDirectory;
  List _listWallets = [];

  void initState() {
    super.initState();
    initAppDirectory();
  }

  void initAppDirectory() async {
    Directory _appPath = await getApplicationDocumentsDirectory();
    walletsDirectory = Directory('${_appPath.path}/wallets');
    _listWallets = getAllWalletsNames();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(children: <Widget>[
      SizedBox(height: 8),
      for (var repository in this._listWallets)
        ListTile(
          contentPadding: const EdgeInsets.all(5.0),
          leading: Text(repository, style: TextStyle(fontSize: 14.0)),
          title: Text(repository, style: TextStyle(fontSize: 14.0)),
          subtitle: Text(repository, style: TextStyle(fontSize: 14.0)),
          dense: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return WalletOptions(walletName: repository);
              }),
            ).then((value) => setState(() {
                  initAppDirectory();
                }));
          },
        ),
      SizedBox(height: 20),
      SizedBox(
          width: 75.0,
          height: 25.0,
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 2,
                primary: Color(0xffFFD68E), //Color(0xffFFD68E), // background
                onPrimary: Colors.black, // foreground
              ),
              onPressed: () {
                initAppDirectory();
                setState(() {});
              },
              child: Text('(Refresh)', style: TextStyle(fontSize: 10)))),
    ]));
  }

  List getAllWalletsNames() {
    this._listWallets.clear();
    print(this.walletsDirectory.path);

    this
        .walletsDirectory
        .listSync(recursive: false, followLinks: false)
        .forEach((wallet) {
      String _name = wallet.path.split('/').last;
      print(_name);
      this._listWallets.add(_name);
    });
    //     .listen((FileSystemEntity entity) {
    //   print(entity.path.split('/').last);
    //   this._listWallets.add(entity.path.split('/').last);
    // });

    return _listWallets;

    // final _local = await _appPath.path.list().toList();
  }
}
