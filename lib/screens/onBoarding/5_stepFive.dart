import 'package:bubble/bubble.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/6_stepSix.dart';

// ignore: must_be_immutable
class OnboardingStepFive extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 25;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            Stack(children: [
              Container(height: 100),
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: GeckoSpeechAppBar('Ma phrase de restauration')),
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset(
                  'assets/onBoarding/gecko_bar.png',
                ),
              ),
              Positioned(
                top: 70,
                left: 50,
                child: Image.asset(
                  'assets/onBoarding/progress_bar/total.png',
                ),
              ),
              Positioned(
                top: 70,
                left: 50,
                child: Image.asset(
                  'assets/onBoarding/progress_bar/$progress.png',
                ),
              ),
              Positioned(
                top: 66,
                right: 45,
                child: Text('$progress%',
                    style: TextStyle(fontSize: 12, color: Colors.black)),
              ),
            ]),
            Bubble(
              padding: BubbleEdges.all(15),
              elevation: 5,
              color: Colors.white,
              margin: BubbleEdges.fromLTRB(10, 0, 20, 10),
              // nip: BubbleNip.leftTop,
              child: Text(
                "Par contre, attention :\n\nDans une blockchain, il n’y a pas de procédure de récupération de trousseau.\n\nSi vous perdez votre phrase de restauration, je ne pourrai pas vous la communiquer, et vous ne pourrez donc plus jamais accéder à votre compte.",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: 10),
            // Row(children: <Widget>[
            // Align(
            //     alignment: Alignment.centerRight,
            //     child:
            Image.asset(
              'assets/onBoarding/maison-qui-brule.png',
              height: 200,
            ),
            // ]),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 350,
                      height: 55,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: Color(0xffD28928),
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              SmoothTransition(page: OnboardingStepSix()),
                            );
                          },
                          child: Text("J'ai compris",
                              style: TextStyle(fontSize: 20))),
                    ))),
            SizedBox(height: 80),
          ]),
        ));
  }
}

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
