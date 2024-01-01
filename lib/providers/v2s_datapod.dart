import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_datapod.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class V2sDatapodProvider with ChangeNotifier {
  Future<QueryResult> _execQuery(
      String query, Map<String, dynamic> variables) async {
    final httpLink = HttpLink(
      // 'http://10.0.2.2:8080/v1/graphql',
      'https://gdev-datapod.p2p.legal/v1/graphql',
    );

    final GraphQLClient client = GraphQLClient(
      cache: GraphQLCache(),
      link: httpLink,
    );

    final QueryOptions options =
        QueryOptions(document: gql(query), variables: variables);

    return await client.query(options);
  }

  Future<bool> updateProfile(
      {required String address,
      String? title,
      String? description,
      String? avatar,
      String? city,
      List<Map<String, String>>? socials,
      Map<String, double>? geoloc}) async {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);

    final messageToSign = jsonEncode({
      'address': address,
      'description': description,
      'avatarBase64': avatar,
      'geoloc': geoloc,
      'title': title,
      'city': city,
      'socials': socials
    });
    final hashDocBytes = utf8.encode(messageToSign);
    final hashDoc = sha256.convert(hashDocBytes).toString().toUpperCase();
    final signature = await sub.signDatapod(hashDoc, address);

    final variables = <String, dynamic>{
      'address': address,
      'hash': hashDoc,
      'signature': signature,
      'title': title,
      'description': description,
      'avatar': avatar,
      'city': city,
      'socials': socials,
      'geoloc': geoloc,
    };
    final result = await _execQuery(updateProfileQ, variables);
    if (result.hasException) {
      log.e(result.exception.toString());
      return false;
    }
    log.d(result.data!['updateProfile']['message']);
    return true;
  }

  Future<bool> deleteProfile({required String address}) async {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);

    final messageToSign = jsonEncode({'address': address});
    final hashDocBytes = utf8.encode(messageToSign);
    final hashDoc = sha256.convert(hashDocBytes).toString().toUpperCase();
    final signature = await sub.signDatapod(hashDoc, address);

    final variables = <String, dynamic>{
      'address': address,
      'hash': hashDoc,
      'signature': signature
    };
    final result = await _execQuery(deleteProfileQ, variables);
    if (result.hasException) {
      log.e(result.exception.toString());
      return false;
    }
    log.d(result.data!['deleteProfile']['message']);
    return true;
  }

  Future<bool> migrateProfile(
      {required String addressOld, required String addressNew}) async {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);

    final messageToSign =
        jsonEncode({'addressOld': addressOld, 'addressNew': addressNew});
    final hashDocBytes = utf8.encode(messageToSign);
    final hashDoc = sha256.convert(hashDocBytes).toString().toUpperCase();
    final signature = await sub.signDatapod(hashDoc, addressOld);

    final variables = <String, dynamic>{
      'addressOld': addressOld,
      'addressNew': addressNew,
      'hash': hashDoc,
      'signature': signature
    };
    final result = await _execQuery(migrateProfileQ, variables);
    if (result.hasException) {
      log.e(result.exception.toString());
      return false;
    }
    log.d(result.data!['migrateProfile']['message']);
    return true;
  }

  Future<bool> setAvatar(String address, String avatarPath) async {
    final avatarBytes = await File(avatarPath).readAsBytes();
    final avatarString = base64Encode(avatarBytes);
    return await updateProfile(address: address, avatar: avatarString);
  }
}
