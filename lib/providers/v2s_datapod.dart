import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_datapod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class V2sDatapodProvider with ChangeNotifier {
  late GraphQLClient datapodClient;

  Future<Map<String, dynamic>> _setSignedVariables(String address, Map<String, dynamic> messageToSign) async {
    final myWalletProvider = Provider.of<MyWalletsProvider>(homeContext, listen: false);

    final hashDocBytes = utf8.encode(jsonEncode(messageToSign));
    final hashDoc = sha256.convert(hashDocBytes).toString().toUpperCase();
    if (!await myWalletProvider.askPinCode()) return {};

    // final signature = await sub.signDatapod(hashDoc, address);
    return <String, dynamic>{...messageToSign, 'hash': hashDoc, 'signature': 'signature'};
  }

  Future<QueryResult?> _execQuery(String query, Map<String, dynamic> variables) async {
    //TODO: Switch to IPFS Datapod
    return null;
    // final QueryOptions options =
    //     QueryOptions(document: gql(query), variables: variables);
    // return await datapodClient.query(options);
  }

  Future<bool> updateProfile(
      {required String address,
      String? title,
      String? description,
      String? avatar,
      String? city,
      List<Map<String, String>>? socials,
      Map<String, double>? geoloc}) async {
    final messageToSign = {
      'address': address,
      'description': description,
      'avatarBase64': avatar,
      'geoloc': geoloc,
      'title': title,
      'city': city,
      'socials': socials
    };
    final variables = await _setSignedVariables(address, messageToSign);
    if (variables.isEmpty) return false;

    final result = await _execQuery(updateProfileQ, variables);
    if (result?.hasException ?? true) {
      log.e(result?.exception.toString());
      return false;
    }
    log.d(result!.data!['updateProfile']['message']);
    return true;
  }

  Future<bool> deleteProfile({required String address}) async {
    final messageToSign = {'address': address};
    final variables = await _setSignedVariables(address, messageToSign);
    if (variables.isEmpty) return false;

    final result = await _execQuery(deleteProfileQ, variables);
    if (result?.hasException ?? true) {
      log.w(result?.exception.toString());
      return false;
    }
    log.d(result!.data!['deleteProfile']['message']);
    return true;
  }

  Future<bool> migrateProfile({required String addressOld, required String addressNew}) async {
    final messageToSign = {'addressOld': addressOld, 'addressNew': addressNew};
    final variables = await _setSignedVariables(addressOld, messageToSign);
    if (variables.isEmpty) return false;

    final result = await _execQuery(migrateProfileQ, variables);
    if (result?.hasException ?? true) {
      log.e(result?.exception.toString());
      return false;
    }
    log.d(result!.data!['migrateProfile']['message']);
    return true;
  }

  Future<bool> addTransactionComment({
    required String id,
    required String issuer,
    required String comment,
  }) async {
    final messageToSign = {
      'id': id,
      'address': issuer,
      'comment': comment,
    };
    final variables = await _setSignedVariables(issuer, messageToSign);
    if (variables.isEmpty) return false;

    final result = await _execQuery(addTransactionCommentQ, variables);
    if (result?.hasException ?? true) {
      log.e(result?.exception.toString());
      return false;
    }
    log.d(result!.data!['addTransaction']['message']);
    return true;
  }

  Future<bool> setAvatar(String address, String avatarPath) async {
    final avatarBytes = await File(avatarPath).readAsBytes();
    final avatarString = base64Encode(avatarBytes);
    return await updateProfile(address: address, avatar: avatarString);
  }

  Future<DateTime?> profileEditedAt(String address) async {
    final variables = <String, dynamic>{
      'address': address,
    };
    final result = await _execQuery(profileEditedAtQ, variables);
    if (result?.hasException ?? true) {
      // log.e(result?.exception.toString());
      return null;
    }
    final String? profileDateData = result!.data!['profiles_by_pk']?['updated_at'];
    final profileDate = profileDateData == null ? null : DateTime.tryParse(profileDateData);
    return profileDate;
  }

  Future<Image> getRemoteAvatar(String address, {double size = 20, String? uuid}) async {
    final variables = <String, dynamic>{
      'address': address,
    };
    final result = await _execQuery(getAvatarQ, variables);
    if (result?.hasException ?? true) {
      log.e(result?.exception.toString());
      return defaultAvatar(size);
    }
    final String? avatar64 = result!.data!['profiles_by_pk']?['avatar64'];

    if (avatar64 == null) {
      return defaultAvatar(size);
    }

    final sanitizedAvatar64 = avatar64.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');

    log.d('We save avatar for $address');
    await saveAvatar(address, sanitizedAvatar64, uuid);

    return Image.memory(
      base64.decode(sanitizedAvatar64),
      height: size,
      fit: BoxFit.fitWidth,
    );
  }

  Future<File> saveAvatar(String address, String data, String? uuid) async {
    uuid = uuid ?? const Uuid().v4();
    final file = File('${avatarsDirectory.path}/$address-$uuid');
    return await file.writeAsBytes(base64.decode(data));
  }

  Future<File> cacheAvatar(String address, String data) async {
    final uuid = const Uuid().v4();
    final tempFile = File('${avatarsCacheDirectory.path}/$uuid$address');
    final targetFile = File('${avatarsCacheDirectory.path}/$address');

    try {
      // Write to a temporary file first to prevent data race
      await tempFile.writeAsBytes(base64.decode(data));
      log.d('Caching avatar of $address');
      return await tempFile.rename(targetFile.path);
    } catch (e) {
      log.e("An error occurred while caching avatar: $e");
      rethrow;
    }
  }

  Image getAvatarLocal(String address) {
    final avatarFile = File('${avatarsCacheDirectory.path}/$address');
    return Image.file(
      avatarFile,
      fit: BoxFit.cover,
    );
  }

  Image defaultAvatar(double size) => Image.asset(('assets/icon_user.png'), height: scaleSize(size));

  Future deleteAvatarsCacheDirectory() async {
    if (await avatarsCacheDirectory.exists()) {
      await avatarsCacheDirectory.delete(recursive: true);
    }
  }

  Future deleteAvatarsDirectory() async {
    if (await avatarsDirectory.exists()) {
      await avatarsDirectory.delete(recursive: true);
    }
  }

  void reload() {
    notifyListeners();
  }
}
