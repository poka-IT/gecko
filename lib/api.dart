import "package:dio/dio.dart" as dio;
import 'package:gql/language.dart' as gqlLang;
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:gql_exec/gql_exec.dart';
import "package:gql_link/gql_link.dart";

const graphqlEndpoint = "https://g1.librelois.fr/gva";

const QcurrentUD = """{
    currentUd {
      amount
      base
}
}""";

Future getBalance(String pubkey) async {
  var qBalance = """{
    balance(script: "$pubkey") {
      amount
      base
    }
  }""";

  final client = dio.Dio();
  final Link link = DioLink(
    graphqlEndpoint,
    client: client,
  );

  final res = await link
      .request(Request(
        operation: Operation(document: gqlLang.parseString(qBalance)),
      ))
      .first;

  final balance = res.data["balance"]["amount"] / 100;
  return balance;
}

Future getHistory(String pubkey) async {
  print(pubkey);
  var qHistory = """{
        transactionsHistory(pubkey: "$pubkey") {
            received {
                writtenTime
                issuers
                outputs
                comment
            }
        }
    }""";

  final client = dio.Dio();
  final Link link = DioLink(
    graphqlEndpoint,
    client: client,
  );

  final res = await link
      .request(Request(
        operation: Operation(document: gqlLang.parseString(qHistory)),
      ))
      .first;

  var result = res.data["transactionsHistory"]["received"];
  String outPubkey;
  for (var bloc in result) {
    var output = bloc['outputs'][0];
    outPubkey = output.split("SIG(")[1].replaceAll(')', '');
    print(outPubkey);
  }

  final history = outPubkey;
  return history;
}
