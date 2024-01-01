import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';

// import 'package:http/http.dart' as http;

class CesiumPlusProvider with ChangeNotifier {
  TextEditingController cesiumName = TextEditingController();

  CancelToken avatarCancelToken = CancelToken();

  final Map<String, String> _headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  // List _buildQueryGetAvatar(String pubkeyV1) {
  //   final queryGetAvatar = json.encode({
  //     "query": {
  //       "bool": {
  //         "should": [
  //           {
  //             "match": {
  //               '_id': {"query": pubkeyV1, "boost": 1}
  //             }
  //           },
  //           {
  //             "prefix": {'_id': pubkeyV1}
  //           }
  //         ]
  //       }
  //     },
  //     "_source": [
  //       "avatar",
  //       "avatar._content_type",
  //     ],
  //     "indices_boost": {"user": 1, "page": 1, "group": 0.01}
  //   });

  //   const requestUrl = "/user,page,group/profile,record/_search";
  //   final podRequest = cesiumPod + requestUrl;

  //   return [podRequest, queryGetAvatar];
  // }

  Future<List> _buildQuerySetAvatar(
      String pubkeyV1, String address, String avatar) async {
    int timeSent = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final queryGetAvatar = json.encode({
      "avatar": {"_content": avatar, "_content_type": "image/png"},
      "time": timeSent,
      "issuer": pubkeyV1,
      "version": 2,
      "tags": []
    });

    final requestUrl =
        "/user/profile?pubkey=$pubkeyV1/_update?pubkey=$pubkeyV1";
    final podRequest = cesiumPod + requestUrl;

    final signedDocument = await signDoc(queryGetAvatar, address);

    return [podRequest, signedDocument];
  }

  Future<String> signDoc(String document, String address) async {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
    final hashDocBytes = utf8.encode(document);
    final hashDoc = sha256.convert(hashDocBytes);
    final hashDocHex = hashDoc.toString().toUpperCase();

    // Generate signature of document
    final signature = await sub.signDatapod(hashDocHex, address);

    // Build final document
    final Map<String, dynamic> data = {
      'hash': hashDocHex,
      'signature': signature
    };
    final signJSON = jsonEncode(data);
    final Map<String, dynamic> finalJSON = {
      ...jsonDecode(signJSON),
      ...jsonDecode(document)
    };

    return jsonEncode(finalJSON);
  }
  // Future<String> getName(String address) async {
  //   String? name;

  //   if (g1WalletsBox.get(address)?.csName != null) {
  //     return g1WalletsBox.get(address)!.csName!;
  //   }

  //   List queryOptions = await _buildQueryName(address);

  //   var dio = Dio();
  //   late Response response;
  //   try {
  //     response = await dio.post(
  //       queryOptions[0],
  //       data: queryOptions[1],
  //       options: Options(
  //         headers: queryOptions[2],
  //         sendTimeout: const Duration(seconds: 3),
  //         receiveTimeout: const Duration(seconds: 5),
  //       ),
  //     );
  //     // response = await http.post((Uri.parse(queryOptions[0])),
  //     //     body: queryOptions[1], headers: queryOptions[2]);
  //   } catch (e) {
  //     log.e(e);
  //   }

  //   if (response.data['hits']['hits'].toString() == '[]') {
  //     return '';
  //   }
  //   final bool nameExist =
  //       response.data['hits']['hits'][0]['_source'].containsKey("title");
  //   if (!nameExist) {
  //     return '';
  //   }
  //   name = response.data['hits']['hits'][0]['_source']['title'];

  //   name ??= '';
  //   g1WalletsBox.get(address)!.csName = name;

  //   return name;
  // }

  Future<Image> getAvatar(String address, double size) async {
    return defaultAvatar(size);
    // final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
    // if (await isAvatarExist(address)) {
    //   return await getAvatarLocal(address, size);
    // }

    // final pubkeyV1 = await sub.addressToPubkeyB58(address);
    // var dio = Dio();

    // List queryOptions = _buildQueryGetAvatar(pubkeyV1);

    // late Response response;
    // try {
    //   response = await dio
    //       .post(queryOptions[0],
    //           data: queryOptions[1],
    //           options: Options(
    //             headers: _headers,
    //             sendTimeout: const Duration(seconds: 4),
    //             receiveTimeout: const Duration(seconds: 15),
    //           ),
    //           cancelToken: avatarCancelToken)
    //       .timeout(
    //         const Duration(seconds: 15),
    //       );
    // } catch (e) {
    //   log.e(e);
    // }

    // if (response.data['hits']['hits'].toString() == '[]' ||
    //     !response.data['hits']['hits'][0]['_source'].containsKey("avatar")) {
    //   return defaultAvatar(size);
    // }

    // final avatar =
    //     response.data['hits']['hits'][0]['_source']['avatar']['_content'];

    // final avatarFile = await saveAvatar(address, avatar);

    // final finalAvatar = Image.file(
    //   avatarFile,
    //   height: size,
    //   fit: BoxFit.fitWidth,
    // );

    // return finalAvatar;
  }

  Future<bool> setAvatar(String address, String avatarPath) async {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);

    final pubkeyV1 = await sub.addressToPubkeyB58(address);
    var dio = Dio();
    final Uint8List avatarBytes = await File(avatarPath).readAsBytes();
    final avatarString = base64Encode(avatarBytes);

    List queryOptions =
        await _buildQuerySetAvatar(pubkeyV1, address, avatarString);

    late Response response;
    try {
      response = await dio
          .post(queryOptions[0],
              data: queryOptions[1],
              options: Options(
                headers: _headers,
                sendTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 15),
              ),
              cancelToken: avatarCancelToken)
          .timeout(
            const Duration(seconds: 15),
          );
      return response.statusCode == 200;
    } catch (e) {
      log.e(e);
      return false;
    }
  }

  Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> saveAvatar(String address, String data) async {
    final path = await getLocalPath();
    final avatarFolder = Directory('$path/avatars/');
    if (!await avatarFolder.exists()) {
      await avatarFolder.create();
    }
    final file = File('$path/avatars/$address');
    return await file.writeAsBytes(base64.decode(data));
  }

  Future<Image> getAvatarLocal(String address, double size) async {
    final path = await getLocalPath();
    final avatarFile = File('$path/avatars/$address');
    return Image.file(
      avatarFile,
      height: size,
      fit: BoxFit.fitWidth,
    );
  }

  Future<bool> isAvatarExist(String address) async {
    final path = await getLocalPath();
    final avatarFile = File('$path/avatars/$address');
    return avatarFile.exists();
  }

  Future deleteAvatarFolder() async {
    final path = await getLocalPath();
    final avatarFolder = Directory('$path/avatars/');
    if (await avatarFolder.exists()) {
      await avatarFolder.delete(recursive: true);
    }
  }
}

Image defaultAvatar(double size) =>
    Image.asset(('assets/icon_user.png'), height: scaleSize(size));
