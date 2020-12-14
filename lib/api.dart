import 'dart:math';
import "package:dio/dio.dart" as dio;
import 'package:gql/language.dart' as gqlLang;
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:gql_exec/gql_exec.dart';
import "package:gql_link/gql_link.dart";

// Configure node
const graphqlEndpoint = "https://g1.librelois.fr/gva";

// Build queries
Future buildQ(query) async {
  final client = dio.Dio();
  final Link link = DioLink(
    graphqlEndpoint,
    client: client,
  );

  final res = await link
      .request(Request(
        operation: Operation(document: gqlLang.parseString(query)),
      ))
      .first;

  return res;
}

/* Requests functions */

// Get current UD
Future getUD() async {
  const query = """{
      currentUd {
        amount
        base
  }
  }""";

  final result = await buildQ(query);
  return result.data["currentUd"]["amount"];
}

// Get balance
Future getBalance(String pubkey) async {
  var query = """{
    balance(script: "$pubkey") {
      amount
      base
    }
  }""";

  final result = await buildQ(query);
  return result.data["balance"]["amount"] / 100;
}

// Get history
Future getHistory(String pubkey) async {
  print(pubkey);
  var query = """{
        txsHistoryBc(pubkeyOrScript: "$pubkey") {
            received {
                writtenTime
                issuers
                outputs
                comment
            }
        }
        currentUd {
          amount
          base
      }
    }""";

  final res = await buildQ(query);

  // Parse history
  var result;
  try {
    result = res.data["txsHistoryBc"]["received"];
  } catch (e) {
    print("DEBUG: " + e.toString());
    print(res.data);
    return false;
  }
  var i = 0;
  // String outPubkey;
  var trans = [];
  final currentBase = res.data['currentUd']['base'];
  final currentUD = res.data['currentUd']['amount'] / 100;

  for (var bloc in result) {
    var output = bloc['outputs'][0];
    // outPubkey = output.split("SIG(")[1].replaceAll(')', '');
    trans.add(i);
    trans[i] = [];
    trans[i].add(bloc['writtenTime']);
    trans[i].add(bloc['issuers'][0]);
    var amountBrut = int.parse(output.split(':')[0]);
    final base = int.parse(output.split(':')[1]);
    final applyBase = base - currentBase;
    final amount = amountBrut * pow(10, applyBase) / 100;
    trans[i].add(amount);
    final amountUD = amount / currentUD;
    trans[i].add(amountUD.toStringAsFixed(2));
    trans[i].add(bloc['comment']);
    trans[i].add(base);

    i++;
  }

  // Order transactions by date
  trans.sort((b, a) => Comparable.compare(a[0], b[0]));

  // // Keep only base if there is base change
  // var lastBase = 0;
  // for (i in trans) {
  //     if (i[5] == lastBase){
  //       i[6] = null;
  //     }
  //     else {
  //       lastBase = i[6];
  //     }

  // print(trans);
  return trans;
}
