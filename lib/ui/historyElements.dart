import 'package:flutter/material.dart';
import 'package:truncate/truncate.dart';

// class HistoryListScreen extends StatefulWidget {
//   @override
//   _HistoryListScreen createState() => _HistoryListScreen();
// }

// class _HistoryListScreen extends State<HistoryListScreen> {
//   @override
//   Widget build(BuildContext context) {
//     print('Coucou page 2');

//     return MaterialApp(
//         home: Scaffold(
//             backgroundColor: Colors.grey[300],
//             body: SafeArea(child: Text('Hello !'))));
//   }
// }

class HistoryElements extends StatelessWidget {
  // const String({this.isPubkey});
  // final PubkeyCallBack isPubkey;
  // GlobalKey<MyState> _myKey = GlobalKey();

  const HistoryElements(
      {Key key,
      @required ScrollController scrollController,
      @required this.transBC,
      @required this.historyData})
      : _scrollController = scrollController,
        super(key: key);

  final ScrollController _scrollController;
  final List transBC;
  final historyData;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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

      // child: new NotificationListener(
      child: new ListView(
        controller: _scrollController,
        children: <Widget>[
          for (var repository in transBC)
            ListTile(
                contentPadding: const EdgeInsets.all(5.0),
                leading: Text(repository[3].toString()),
                title: Text(repository[1].toString() +
                    '\n' +
                    truncate(repository[2], 17,
                        omission: "...", position: TruncatePosition.end)),
                subtitle: Text(repository[5]),
                dense: true,
                // enabled: _act == 2,
                onTap: () {/* TODO: Load this history: repository[2] */}),
          if (historyData.isLoading)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
              ],
            ),
        ],
      ),
      // onNotification: (t) {
      //   if (t is ScrollEndNotification) {
      //     // fetchMore(opts);
      //     print(_scrollController.position.pixels);
      //   }
      //   return t;
      // },
    );
  }
}

// typedef PubkeyCallBack = void Function(String pubkey);