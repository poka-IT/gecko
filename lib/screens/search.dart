import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
// import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/search_result.dart';
import 'package:provider/provider.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SearchProvider _searchProvider = Provider.of<SearchProvider>(context);
    final double screenHeight = MediaQuery.of(context).size.height;
    // HomeProvider _homeProvider =
    //     Provider.of<HomeProvider>(context, listen: false);

    return WillPopScope(
        onWillPop: () {
          _searchProvider.searchController.text = '';
          return Future<bool>.value(true);
        },
        child: Scaffold(
          backgroundColor: backgroundColor,

          appBar: AppBar(
            elevation: 1,
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Rechercher'),
            ),
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  _searchProvider.searchController.text = '';
                  Navigator.of(context).pop();
                }),
          ),
          // bottomNavigationBar: _homeProvider.bottomAppBar(context),
          body: SafeArea(
            child: Column(children: <Widget>[
              CommonElements().offlineInfo(context),
              SizedBox(height: isTall ? 200 : 100),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: TextField(
                  controller: _searchProvider.searchController,
                  autofocus: true,
                  maxLines: 1,
                  textAlign: TextAlign.left,
                  onChanged: (v) => _searchProvider.rebuildWidget(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIconConstraints: const BoxConstraints(
                      minHeight: 32,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 17),
                      child: Image(
                          image: AssetImage('assets/loupe-noire.png'),
                          height: 35),
                    ),
                    border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.grey[500]!, width: 2),
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.grey[500]!, width: 2.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Spacer(flex: 1),
              SizedBox(
                width: 410,
                height: 70,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    primary: orangeC, // background
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: _searchProvider.searchController.text.length >= 2
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return const SearchResultScreen();
                            }),
                          );
                        }
                      : null,
                  child: const Text(
                    'Rechercher',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Spacer(flex: screenHeight <= 800 ? 1 : 2),
            ]),
          ),
        ));
  }
}
