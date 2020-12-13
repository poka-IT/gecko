import "package:dio/dio.dart" as dio;
import 'package:gql/language.dart' as gqlLang;
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:gql_exec/gql_exec.dart';
import "package:gql_link/gql_link.dart";

// Configure node
const graphqlEndpoint = "https://g1.librelois.fr/gva";

// Build query
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
        transactionsHistory(pubkey: "$pubkey") {
            received {
                writtenTime
                issuers
                outputs
                comment
            }
        }
    }""";

  final res = await buildQ(query);

  // Parse history
  var result = res.data["transactionsHistory"]["received"];
  String outPubkey;
  for (var bloc in result) {
    var output = bloc['outputs'][0];
    outPubkey = output.split("SIG(")[1].replaceAll(')', '');
    print(outPubkey);
  }

  return outPubkey;
}
