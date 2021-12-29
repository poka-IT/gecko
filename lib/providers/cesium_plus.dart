import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;

class CesiumPlusProvider with ChangeNotifier {
  TextEditingController cesiumName = TextEditingController();
  Image defaultAvatar(double? size) =>
      Image.asset(('assets/icon_user.png'), height: size);

  CancelToken avatarCancelToken = CancelToken();

  Future<List> _buildQuery(_pubkey) async {
    var queryGetAvatar = json.encode({
      "query": {
        "bool": {
          "should": [
            {
              "match": {
                '_id': {"query": _pubkey, "boost": 2}
              }
            },
            {
              "prefix": {'_id': _pubkey}
            }
          ]
        }
      },
      "highlight": {
        "fields": {"title": {}, "tags": {}}
      },
      "from": 0,
      "size": 100,
      "_source": [
        "title",
        "avatar",
        "avatar._content_type",
        "description",
        "city",
        "address",
        "socials.url",
        "creationTime",
        "membersCount",
        "type"
      ],
      "indices_boost": {"user": 100, "page": 1, "group": 0.01}
    });

    String requestUrl = "/user,page,group/profile,record/_search";
    String podRequest = cesiumPod + requestUrl;

    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

    return [podRequest, queryGetAvatar, headers];
  }

  Future<String> getName(String? _pubkey) async {
    String? _name;

    if (g1WalletsBox.get(_pubkey)!.csName != null) {
      return g1WalletsBox.get(_pubkey)!.csName!;
    }

    List queryOptions = await _buildQuery(_pubkey);

    var dio = Dio();
    late Response response;
    try {
      response = await dio.post(
        queryOptions[0],
        data: queryOptions[1],
        options: Options(
          headers: queryOptions[2],
          sendTimeout: 3000,
          receiveTimeout: 5000,
        ),
      );
      // response = await http.post((Uri.parse(queryOptions[0])),
      //     body: queryOptions[1], headers: queryOptions[2]);
    } catch (e) {
      log.e(e);
    }

    if (response.data['hits']['hits'].toString() == '[]') {
      return '';
    }
    final bool _nameExist =
        response.data['hits']['hits'][0]['_source'].containsKey("title");
    if (!_nameExist) {
      return '';
    }
    _name = response.data['hits']['hits'][0]['_source']['title'];

    _name ??= '';
    g1WalletsBox.get(_pubkey)!.csName = _name;

    return _name;
  }

  Future<Image?> getAvatar(String? _pubkey, double size) async {
    if (g1WalletsBox.get(_pubkey)?.avatar != null) {
      return g1WalletsBox.get(_pubkey)!.avatar;
    }
    var dio = Dio();

    // log.d(_pubkey);

    List queryOptions = await _buildQuery(_pubkey);

    late Response response;
    try {
      response = await dio
          .post(queryOptions[0],
              data: queryOptions[1],
              options: Options(
                headers: queryOptions[2],
                sendTimeout: 4000,
                receiveTimeout: 15000,
              ),
              cancelToken: avatarCancelToken)
          .timeout(
            const Duration(seconds: 15),
          );
      // response = await http.post((Uri.parse(queryOptions[0])),
      //     body: queryOptions[1], headers: queryOptions[2]);
    } catch (e) {
      log.e(e);
    }

    if (response.data['hits']['hits'].toString() == '[]' ||
        !response.data['hits']['hits'][0]['_source'].containsKey("avatar")) {
      return defaultAvatar(size);
    }

    final _avatar =
        response.data['hits']['hits'][0]['_source']['avatar']['_content'];

    var avatarFile =
        File('${(await getTemporaryDirectory()).path}/avatar_$_pubkey.png');
    await avatarFile.writeAsBytes(base64.decode(_avatar));

    final finalAvatar = Image.file(
      avatarFile,
      height: size,
      fit: BoxFit.fitWidth,
    );

    g1WalletsBox.get(_pubkey)!.avatar = finalAvatar;

    return finalAvatar;
  }
}
