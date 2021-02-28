import 'package:bubble/bubble.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/8_stepEight.dart';

// ignore: must_be_immutable
class OnboardingStepSeven extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 33;

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
              child: RichText(
                  text: new TextSpan(
                // Note: Styles for TextSpans must be explicitly defined.
                // Child text spans will inherit styles from parent
                style: new TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  new TextSpan(text: "Munissez-vous d'"),
                  new TextSpan(
                      text: 'un papier et d’un crayon\n',
                      style: new TextStyle(fontWeight: FontWeight.bold)),
                  new TextSpan(
                      text:
                          "afin de pouvoir noter votre phrase de restauration."),
                ],
              )),
            ),
            Expanded(
                child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceAround,
                  mainAxisSize: MainAxisSize.min,
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // SizedBox(width: 50),
                    Container(
                        padding: const EdgeInsets.only(bottom: 90),
                        child: Bubble(
                          padding: BubbleEdges.all(15),
                          elevation: 5,
                          color: Colors.white,
                          margin: BubbleEdges.fromLTRB(15, 0, 0, 0),
                          // nip: BubbleNip.leftTop,
                          child: Text(
                            'Moi, j’ai déjà essayé de\nmémoriser une phrase de\nrestauration, mais je n’ai\npas une mémoire\nd’éléphant.',
                            style: TextStyle(color: Colors.black),
                          ),
                        )),

                    Image.asset(
                      'assets/onBoarding/chopp-gecko.png',
                      height: 200,
                    ),
                  ]),
            )),
            SizedBox(height: 50),
            SizedBox(
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
                      SmoothTransition(page: OnboardingStepEight()),
                    );
                  },
                  child: Text("J'ai de quoi noter",
                      style: TextStyle(fontSize: 20))),
            ),
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
