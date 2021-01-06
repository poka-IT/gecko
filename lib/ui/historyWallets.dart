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

class HistoryListView extends StatelessWidget {
  const HistoryListView(
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
                    truncate(repository[2].toString(), 17,
                        omission: "...", position: TruncatePosition.end)),
                subtitle: Text(repository[5].toString()),
                dense: true,
                // enabled: _act == 2,
                onTap: () {/* TODO: Load this history */}),
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
