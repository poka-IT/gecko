import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';

import '7.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({Key? key}) : super(key: key);

  @override
  _OnBoardingPageState createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();
  bool isFreeze = false;

  void _onIntroEnd(context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HomePage()),
    );
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Container(
        padding: const EdgeInsets.all(0),
        width: 440,
        decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xffd2d4cf),
                Color(0xffeaeae7),
              ],
            ),
            border: Border.all(color: Colors.grey[900]!)),
        child: Image.asset('assets/onBoarding/$assetName', width: width));
  }

  Widget _buildText(String text, [double size = 20]) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: 440,
      decoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: Colors.grey[900]!)),
      child: Text(
        text,
        style: TextStyle(fontSize: size),
      ),
    );
  }

  Widget _nextButton() {
    return SizedBox(
      width: 410,
      height: 70,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          primary: orangeC, // background
          onPrimary: Colors.white, // foreground
        ),
        onPressed: () {
          introKey.currentState?.next();
        },
        child: const Text(
          'Continuer',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context, listen: false);
    const bodyStyle = TextStyle(fontSize: 19.0);
    var pageDecoration = PageDecoration(
      titleTextStyle:
          const TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      pageColor: backgroundColor,
      imagePadding: EdgeInsets.zero,
    );

    log.d(introKey.currentState?.controller.page);

    return IntroductionScreen(
      controlsPosition: const Position(left: 0, right: 0, bottom: 0),
      freeze: false,
      isProgressTap: false,
      isTopSafeArea: false,
      isBottomSafeArea: true,
      key: introKey,
      globalBackgroundColor: backgroundColor,
      globalFooter:
          SizedBox(width: double.infinity, height: 60, child: _nextButton()),
      pages: [
        PageViewModel(
          title: '',
          body: '',
          footer: Column(
            children: [
              _buildText(
                  'Gecko fabrique votre portefeuille à partir d’une phrase de restauration. Elle un peu le comme un plan qui permet de construire votre portefeuille.'),
              _buildImage('fabrication-de-portefeuille.png'),
              // const SizedBox(height: 40),
              // _nextButton()
            ],
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: '',
          body: '',
          footer: Column(
            children: [
              _buildText(
                  'Conservez cette phrase précieusement, car sans elle Gecko ne pourra pas reconstruire vos portefeuilles le jour où vous changez de téléphone.'),
              _buildImage(
                  'fabrication-de-portefeuille-impossible-sans-phrase.png')
            ],
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: '',
          body: '',
          footer: Column(
            children: [
              _buildText(
                  'Dans une blockchain, pas de procédure de récupération par mail. Seule votre phrase de restauration peut vous permettre de récupérer vos Ğ1 à tout moment.'),
              _buildImage('mot-de-passe-oublie.png')
            ],
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: '',
          body: '',
          footer: Column(
            children: [
              _buildText(
                  'Il est temps de vous munir d’un d’un papier et d’un crayon afin de pouvoir noter votre phrase de restauration.'),
              _buildImage('gecko-oublie-aussi.png')
            ],
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: '',
          body: '',
          footer: Column(
            children: [
              _buildText(
                  'Gecko a généré votre phrase de restauration ! Tâchez de la garder bien secrète, car elle permet à quiconque la connaît d’accéder à tous vos portefeuilles.'),
              const SizedBox(height: 40),
              sentanceArray(context),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return PrintWallet(
                          _generateWalletProvider.generatedMnemonic);
                    }),
                  );
                },
                child: Image.asset(
                  'assets/printer.png',
                  height: 35,
                ),
              ),
              const SizedBox(height: 40),
              // const Spacer(),
              SizedBox(
                width: 400,
                height: 62,
                child: ElevatedButton(
                    key: const Key('generateMnemonic'),
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      primary: const Color(0xffFFD58D),
                      onPrimary: Colors.black, // foreground
                    ),
                    onPressed: () {
                      _generateWalletProvider.reloadBuild();
                      // setState(() {});
                    },
                    child: const Text("Choisir une autre phrase",
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w600))),
              ),
              // const Spacer(),
            ],
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: '',
          body: '',
          footer: Column(
            children: [
              _buildText(
                  'Gecko fabrique votre portefeuille à partir d’une phrase de restauration. Elle un peu le comme un plan qui permet de construire votre portefeuille.'),
              _buildImage('fabrication-de-portefeuille.png'),
              const SizedBox(height: 25),
            ],
          ),
          decoration: pageDecoration,
        ),
        // PageViewModel(
        //   title: "Another title page",
        //   body: "Another beautiful body text for this example onboarding",
        //   image: _buildImage('keys-and-wallets-horizontal-plus-phrase.png'),
        //   footer: ElevatedButton(
        //     onPressed: () {
        //       introKey.currentState?.animateScroll(0);
        //     },
        //     child: const Text(
        //       'FooButton',
        //       style: TextStyle(color: Colors.white),
        //     ),
        //     style: ElevatedButton.styleFrom(
        //       primary: Colors.lightBlue,
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(8.0),
        //       ),
        //     ),
        //   ),
        //   decoration: pageDecoration,
        // ),
        // PageViewModel(
        //   title: "Title of last page - reversed",
        //   bodyWidget: Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: const [
        //       Text("Click on ", style: bodyStyle),
        //       Icon(Icons.edit),
        //       Text(" to edit a post", style: bodyStyle),
        //     ],
        //   ),
        //   decoration: pageDecoration.copyWith(
        //     bodyFlex: 2,
        //     imageFlex: 4,
        //     bodyAlignment: Alignment.bottomCenter,
        //     imageAlignment: Alignment.topCenter,
        //   ),
        //   image: _buildImage('keys-and-wallets-horizontal-plus-phrase.png'),
        //   reverse: true,
        // ),
      ],
      onDone: () => _onIntroEnd(context),
      onChange: (i) => setState(() {}),
      //onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: false,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
      showNextButton: false,
      // next: Icon(
      //   Icons.arrow_forward_ios,
      //   color: orangeC,
      //   size: 40,
      // ),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(0),
      controlsPadding: kIsWeb
          ? const EdgeInsets.all(12.0)
          : const EdgeInsets.fromLTRB(0, 0.0, 0.0, 50),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Colors.grey[400]!,
        activeColor: orangeC,
        activeSize: const Size(22.0, 10.0),
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text("This is the screen after Introduction")),
    );
  }
}
