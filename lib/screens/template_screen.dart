import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/home.dart';
import 'package:flutter/material.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class TemplateScreen extends StatelessWidget {
  TextEditingController tplController = TextEditingController();

  TemplateScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    return Scaffold(
        appBar: AppBar(
            title: const SizedBox(
          height: 22,
          child: Text('Template screen'),
        )),
        floatingActionButton: SizedBox(
            height: 80.0,
            width: 80.0,
            child: FittedBox(
                child: FloatingActionButton(
              heroTag: "tplButton",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return const HomeScreen();
                }),
              ),
              child: SizedBox(
                height: 40.0,
                width: 40.0,
                child: Icon(Icons.home, color: Colors.grey[850]),
              ),
              backgroundColor:
                  floattingYellow, //smoothYellow, //Color.fromARGB(500, 204, 255, 255),
            ))),
        body: SafeArea(
          child: Column(children: <Widget>[
            const SizedBox(height: 20),
            TextField(
                enabled: true,
                controller: tplController,
                maxLines: 1,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(15.0),
                ),
                style: const TextStyle(
                    fontSize: 22.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 20),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: yellowC, // background
                  onPrimary: Colors.black, // foreground
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return const HomeScreen();
                    }),
                  );
                },
                child: const Text('Retour Accueil',
                    style: TextStyle(fontSize: 20))),
            const SizedBox(height: 20),
            GestureDetector(
                onTap: () {
                  Navigator.popUntil(
                    context,
                    ModalRoute.withName('/'),
                  );
                },
                child: const Icon(Icons.home))
          ]),
        ));
  }
}
