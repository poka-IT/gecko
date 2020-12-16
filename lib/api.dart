import 'dart:math';
import "package:dio/dio.dart" as dio;
import 'package:gql/language.dart' as gqlLang;
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:gql_exec/gql_exec.dart';
import "package:gql_link/gql_link.dart";

// Configure node
const graphqlEndpoint = "https://g1.librelois.fr/gva";

// // Check node connection
// Future getHttp() async {
//   try {
//     final client = await dio.Dio().get(graphqlEndpoint);
//     print(client);
//     return 0;
//   } catch (e) {
//     print(e);
//     return e;
//   }
// }

// Build queries
Future buildQ(query) async {
  var client;
  try {
    client = dio.Dio();
    print(client);
  } catch (e) {
    print(e);
  }
  // final client = dio.Dio();
  Link link;
  link = DioLink(
    graphqlEndpoint,
    client: client,
  );

  try {
    final res = await link
        .request(Request(
          operation: Operation(document: gqlLang.parseString(query)),
        ))
        .first;
    return res;
  } catch (e) {
    print("Erreur: Noeud injoingnable.");
    return 2;
  }
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
  var number = 3;
  var query = """{
        txsHistoryBc(
            pubkeyOrScript: "$pubkey"
            pagination: { pageSize: $number, ord: DESC }
        ) {
            both {
                pageInfo {
                    hasPreviousPage
                    hasNextPage
                }
                edges {
                    direction
                    node {
                        currency
                        issuers
                        outputs
                        comment
                        writtenTime
                    }
                }
            }
        }
        txsHistoryMp(pubkey: "$pubkey") {
            receiving {
                currency
                issuers
                comment
                outputs
                writtenTime
            }
            receiving {
                currency
                issuers
                comment
                outputs
                writtenTime
            }
        }
        currentUd {
          amount
          base
      }
    }""";

  final res = await buildQ(query);

  // Parse history
  var resBC, resMP;
  print(res.toString());
  try {
    resBC = res.data["txsHistoryBc"]['both']['edges'];
    resMP = res.data["txsHistoryMp"];
  } catch (e) {
    return false;
  }
  var i = 0;
  // String outPubkey;
  var transBC = [];
  final currentBase = res.data['currentUd']['base'];
  final currentUD = res.data['currentUd']['amount'] / 100;

  // Get tx received
  for (final trans in resBC) {
    // var direction = transBC[i]['direction'];
    print(trans);
    final transaction = trans['node'];
    var output = transaction['outputs'][0];
    // outPubkey = output.split("SIG(")[1].replaceAll(')', '');
    print("DEBUG1 " + transaction['writtenTime'].toString());
    transBC.add(i);
    transBC[i] = [];
    transBC[i].add(transaction['writtenTime']);
    transBC[i].add(transaction['issuers'][0]);
    var amountBrut = int.parse(output.split(':')[0]);
    final base = int.parse(output.split(':')[1]);
    final applyBase = base - currentBase;
    final amount = amountBrut * pow(10, applyBase) / 100;
    transBC[i].add(amount);
    final amountUD = amount / currentUD;
    transBC[i].add(amountUD.toStringAsFixed(2));
    transBC[i].add(transaction['comment']);
    transBC[i].add(base);

    i++;
  }

  // Get tx receving
  var transMP = [];
  i = 0;

  print('DEBUG2');
  print(resMP);

  for (var transaction in resMP['receiving']) {
    if (transMP == null) {
      print("DEBUG3 " + resMP.toString());
      break;
    }
    var output = transaction['outputs'][0];
    var outPubkey = output.split("SIG(")[1].replaceAll(')', '');
    transMP.add(i);
    transMP[i] = [];
    transMP[i].add(transaction['writtenTime']);
    transMP[i].add(transaction['issuers'][0]);
    var amountBrut = int.parse(output.split(':')[0]);
    final base = int.parse(output.split(':')[1]);
    final applyBase = base - currentBase;
    final amount = amountBrut * pow(10, applyBase) / 100;
    transMP[i].add(amount);
    final amountUD = amount / currentUD;
    transMP[i].add(amountUD.toStringAsFixed(2));
    transMP[i].add(transaction['comment']);
    transMP[i].add(base);
    transMP[i].add(outPubkey);

    i++;
  }

  // Order transactions by date
  transBC.sort((b, a) => Comparable.compare(a[0], b[0]));
  transMP.sort((b, a) => Comparable.compare(a[0], b[0]));

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
  return [transBC, transMP];
}
