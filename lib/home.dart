import 'package:flutter/material.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:gecko/ui/generateWallets.dart';
import 'package:gecko/ui/historyWallets.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'parsingGVA.dart';
import 'query.dart';
import 'package:sentry/sentry.dart' as sentry;

// method to call from widget to fetchmore queries
typedef FetchMore = dynamic Function(FetchMoreOptions options);

typedef Refetch = Future<QueryResult> Function();

typedef QueryBuilder = Widget Function(
  QueryResult result, {
  Refetch refetch,
  FetchMore fetchMore,
});

//ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  // const HistoryListScreen({
  //   final Key key,
  //   @required this.options,
  //   @required this.builder,
  // }) : super(key: key);

  // final QueryOptions options;
  // final QueryBuilder builder;

  HomeScreen({this.screens});

  static const Tag = "HistoryListScreen";
  final List<Widget> screens;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Widget currentScreen;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Uint8List bytes = Uint8List(0);

  final TextEditingController _outputPubkey = new TextEditingController();

  final nRepositories = 20;

  // String pubkey = 'D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU'; // For debug
  String pubkey = '';
  bool isBuilding = true;
  ScrollController _scrollController = new ScrollController();

  _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
        print("reach the bottom");
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // _scrollController
    //   ..addListener(() {
    //     if (_scrollController.position.pixels ==
    //         _scrollController.position.maxScrollExtent) {
    //       // print(
    //       //     "DEBUG H fetchMoreCursor in scrollController: $fetchMoreCursor");
    //       fetchMore(opts);
    //     }
    //   });
  }

  @override
  Widget build(BuildContext context) {
    print('Build pubkey : ' + pubkey);
    print('Build this.pubkey : ' + this.pubkey);
    print('isBuilding: ' + isBuilding.toString());
    return MaterialApp(
        home: Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: <Widget>[
            historyScreen(),
            GenerateWalletScreen(),
            //  FriendsScreen()
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 80.0,
        width: 80.0,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () => _scan(),
            child: Container(
                height: 40.0,
                width: 40.0,
                child: Image.asset('images/scanner.png')),
            backgroundColor: Color.fromARGB(500, 204, 255, 255),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.format_list_bulleted),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.settings),
            label: 'GENERATE WALLET',
          )
        ],
      ),
    ));
  }

  Widget historyScreen() {
    return Column(children: <Widget>[
      TextField(
          onChanged: (text) {
            print("Clé tappxé: $text");
            this.pubkey = text;
            isPubkey(text);
          },
          controller: this._outputPubkey,
          maxLines: 1,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Tappez/Collez une clé publique, ou scannez',
            hintStyle: TextStyle(fontSize: 15),
            contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 15),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
          style: TextStyle(
              fontSize: 15.0,
              color: Colors.black,
              fontWeight: FontWeight.bold)),
      historyQuery(),
    ]);
  }

  Expanded historyQuery() {
    return Expanded(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Query(
          options: QueryOptions(
            document: gql(getHistory),
            variables: <String, dynamic>{
              'pubkey': this.pubkey,
              'number': nRepositories,
              // set cursor to null so as to start at the beginning
              'cursor': null
            },
          ),
          builder: (QueryResult result, {refetch, FetchMore fetchMore}) {
            if (result.isLoading && result.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (result.hasException) {
              return Text('\nErrors: \n  ' + result.exception.toString());
            }

            if (result.data == null && result.exception.toString() == null) {
              return const Text('Both data and errors are null');
            }

            final List<dynamic> blockchainTX =
                (result.data['txsHistoryBc']['both']['edges'] as List<dynamic>);

            final Map pageInfo =
                result.data['txsHistoryBc']['both']['pageInfo'];

            final String fetchMoreCursor = pageInfo['endCursor'];

            FetchMoreOptions opts = FetchMoreOptions(
              variables: {'cursor': fetchMoreCursor},
              updateQuery: (previousResultData, fetchMoreResultData) {
                final List<dynamic> repos = [
                  ...previousResultData['txsHistoryBc']['both']['edges']
                      as List<dynamic>,
                  ...fetchMoreResultData['txsHistoryBc']['both']['edges']
                      as List<dynamic>
                ];

                fetchMoreResultData['txsHistoryBc']['both']['edges'] = repos;
                return fetchMoreResultData;
              },
            );

            // _scrollController
            //   ..addListener(() {
            //     if (_scrollController.position.pixels ==
            //         _scrollController.position.maxScrollExtent) {
            //       if (!result.isLoading) {
            //         print(
            //             "DEBUG H fetchMoreCursor in scrollController: $fetchMoreCursor");
            //         fetchMore(opts);
            //       }
            //     }
            //   });

            // s/o : https://stackoverflow.com/questions/54065354/how-to-detect-scroll-position-of-listview-in-flutter/54188385#54188385
            // new NotificationListener(
            //   child: new ListView(
            //     controller: _scrollController,
            //   ),
            //   onNotification: (t) {
            //     if (t is ScrollEndNotification) {
            //       fetchMore(opts);
            //     }
            //   },
            // );

            // fetchMore(opts);

            print(
                "###### DEBUG H Parse blockchainTX list. Cursor: $fetchMoreCursor ######");
            List _transBC = parseHistory(blockchainTX);

            return Expanded(
              child: HistoryListView(
                  scrollController: _scrollController,
                  transBC: _transBC,
                  historyData: result),
            );
          },
        ),
      ],
    ));
  }

  Future _scan() async {
    await Permission.camera.request();
    String barcode;
    try {
      barcode = await scanner.scan();
    } catch (e, stack) {
      print(e);
      await sentry.Sentry.captureException(
        e,
        stackTrace: stack,
      );
    }
    // this._outputPubkey.text = "";
    if (barcode != null) {
      this._outputPubkey.text = barcode;
      isPubkey(barcode);
      onTabTapped(0);
    }
    return barcode;
  }

  String isPubkey(pubkey) {
    // final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
    RegExp regExp = new RegExp(
      r'^[a-zA-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(pubkey) == true &&
        pubkey.length > 42 &&
        pubkey.length < 45) {
      print("C'est une pubkey !!!");

      setState(() {
        this.pubkey = pubkey;
      });

      return pubkey;
    }

    return '';
  }
}
