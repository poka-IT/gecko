import 'package:bubble/bubble.dart';
import 'package:flutter/services.dart';
import 'package:gecko/screens/home.dart';
import 'package:flutter/material.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class NoKeyChainScreen extends StatelessWidget {
  TextEditingController tplController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    return Scaffold(
        extendBodyBehindAppBar: true,
        // backgroundColor: Colors.white,
        // appBar: GeckoSpeechAppBar('Mes portefeuilles'),
        body: SafeArea(
          child: Column(children: <Widget>[
            Stack(children: [
              Container(height: 100),
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: GeckoSpeechAppBar('Mes portefeuilles')),
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset(
                  'assets/onBoarding/gecko_bar.png',
                ),
              ),
            ]),
            Bubble(
              padding: BubbleEdges.all(15),
              elevation: 5,
              color: Colors.white,
              margin: BubbleEdges.fromLTRB(10, 0, 20, 10),
              // nip: BubbleNip.leftTop,
              child: Text(
                "Je ne connais pour l’instant aucun de vos portefeuilles.\n\nVous pouvez en créer un nouveau, ou bien importer un portefeuille Cesium existant.",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: 70),
            Container(
              child: ClipOval(
                child: Material(
                  color: Color(0xffFFD58D), // button color
                  child: InkWell(
                      splashColor: Color(0xffD28928), // inkwell color
                      child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Image(
                              image: AssetImage('assets/onBoarding/wallet.png'),
                              height: 75)),
                      onTap: () {}),
                ),
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4.0,
                      offset: Offset(2.0, 2.5),
                      spreadRadius: 0.5)
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Créer un nouveau\nportefeuille",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 70),
            Container(
              child: ClipOval(
                child: Material(
                  color: Color(0xffFFD58D), // button color
                  child: InkWell(
                      splashColor: Color(0xffD28928), // inkwell color
                      child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Image(
                              image: AssetImage('assets/onBoarding/cesium.png'),
                              height: 50)),
                      onTap: () {}),
                ),
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4.0,
                      offset: Offset(2.0, 2.5),
                      spreadRadius: 0.5)
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Importer un\nportefeuille Cesium",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 10),
            )
          ]),
        ));
  }
}

// class GeckoSpeechAppBar extends StatelessWidget with PreferredSizeWidget {

//   }
//   // Widget build(BuildContext context) {
//   //   return AppBar(
//   //       leading: IconButton(
//   //         icon: Container(
//   //             height: 100,
//   //             child: Image.asset('assets/onBoarding/gecko_bar.png')),
//   //         onPressed: () => Navigator.popUntil(
//   //           context,
//   //           ModalRoute.withName('/'),
//   //         ),
//   //       ),
//   //       title: SizedBox(
//   //         height: 22,
//   //         child: Text('Mes portefeuilles'),
//   //       ));
//   // }
// }

class GeckoSpeechAppBar extends StatelessWidget with PreferredSizeWidget {
  @override
  final Size preferredSize;
  final String title;

  GeckoSpeechAppBar(
    this.title, {
    Key key,
  })  : preferredSize = Size.fromHeight(105.4),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    // return PreferredSize(
    //   preferredSize: Size(MediaQuery.of(context).size.width, 200),
    //   child: Container(
    //     child: Stack(
    //       alignment: Alignment.topLeft,
    //       children: <Widget>[
    //         Container(
    //           color: Color(0xffFFD68E),
    //           width: MediaQuery.of(context).size.width,
    //           height: 100,
    //         ),
    //         Container(
    //           // width: 100,
    //           height: 200,
    //           child: Column(children: <Widget>[
    //             SizedBox(height: 61.5),
    //             Image.asset('assets/onBoarding/gecko_bar.png')
    //           ]),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
    return AppBar(
        leading: IconButton(
          icon: Container(
              height: 30,
              child: Image.asset('assets/onBoarding/gecko_bar.png')),
          onPressed: () => Navigator.popUntil(
            context,
            ModalRoute.withName('/'),
          ),
        ),
        title: SizedBox(
          height: 25,
          child: Text(title),
        ));
  }
}
