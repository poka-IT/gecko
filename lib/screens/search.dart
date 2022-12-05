import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/widgets_keys.dart';
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
    final searchProvider = Provider.of<SearchProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    String callback() => 'tata';
    // final _homeProvider =
    //     Provider.of<HomeProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () {
        searchProvider.searchController.text = '';
        return Future<bool>.value(true);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: AppBar(
          elevation: 1,
          toolbarHeight: 60 * ratio,
          title: SizedBox(
            height: 22,
            child: Text('search'.tr()),
          ),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                searchProvider.searchController.text = '';
                Navigator.of(context).pop();
              }),
        ),
        // bottomNavigationBar: _homeProvider.bottomAppBar(context),
        body: SafeArea(
          child: Stack(children: [
            Column(children: <Widget>[
              SizedBox(height: isTall ? 200 : 100),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: TextField(
                  onSubmitted: searchProvider.searchController.text.length >= 2
                      ? (_) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return const SearchResultScreen();
                            }),
                          );
                        }
                      : (value) {},
                  textInputAction: TextInputAction.search,
                  key: keySearchField,
                  controller: searchProvider.searchController,
                  autofocus: true,
                  maxLines: 1,
                  textAlign: TextAlign.left,
                  onChanged: (v) => searchProvider.reload(),
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
                width: 320,
                height: 90,
                child: ElevatedButton(
                  key: keyConfirmSearch,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, elevation: 4,
                    backgroundColor: orangeC, // foreground
                  ),
                  onPressed: searchProvider.searchController.text.length >= 2
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return const SearchResultScreen();
                            }),
                          );
                        }
                      : null,
                  child: Text(
                    'search'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Spacer(flex: screenHeight <= 800 ? 1 : 2),
            ]),
            CommonElements().offlineInfo(context),
          ]),
        ),
      ),
    );
  }
}
