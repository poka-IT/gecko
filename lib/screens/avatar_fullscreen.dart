import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class AvatarFullscreen extends StatelessWidget {
  TextEditingController tplController = TextEditingController();

  AvatarFullscreen(this.avatar, {Key key}) : super(key: key);
  final Image avatar;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.black,
          toolbarHeight: 60 * ratio,
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: orangeC),
              onPressed: () {
                Navigator.pop(context);
              }),
          title: SizedBox(
            height: 22,
            child: Text(
              'Photo de profil',
              style: TextStyle(color: orangeC),
            ),
          )),
      body: SafeArea(
        child: SizedBox.expand(
          child: Container(
            color: Colors.black,
            // alignment: Alignment.center,
            // height: MediaQuery.of(context).size.height,
            // width: MediaQuery.of(context).size.width,
            child: avatar,
          ),
        ),
      ),
    );
  }
}
