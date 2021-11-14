import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CesiumPlusProvider with ChangeNotifier {
  TextEditingController cesiumName = TextEditingController();
  int iAvatar = 0;
  bool isComplete = false;

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

  Future<String> getName(String _pubkey) async {
    String _name;

    List queryOptions = await _buildQuery(_pubkey);
    final response = await http.post((Uri.parse(queryOptions[0])),
        body: queryOptions[1], headers: queryOptions[2]);
    final responseJson = json.decode(response.body);
    if (responseJson['hits']['hits'].toString() == '[]') {
      return '';
    }
    final bool _nameExist =
        responseJson['hits']['hits'][0]['_source'].containsKey("title");
    if (!_nameExist) {
      return '';
    }
    _name = responseJson['hits']['hits'][0]['_source']['title'];

    return _name;
  }

  Future<List> getAvatar(String _pubkey) async {
    List queryOptions = await _buildQuery(_pubkey);
    final response = await http.post((Uri.parse(queryOptions[0])),
        body: queryOptions[1], headers: queryOptions[2]);
    final responseJson = json.decode(response.body);
    if (responseJson['hits']['hits'].toString() == '[]') {
      return [File(appPath.path + '/default_avatar.png')];
    }
    final bool avatarExist =
        responseJson['hits']['hits'][0]['_source'].containsKey("avatar");
    if (!avatarExist) {
      return [File(appPath.path + '/default_avatar.png')];
    }
    final _avatar =
        responseJson['hits']['hits'][0]['_source']['avatar']['_content'];

    var avatarFile =
        File('${(await getTemporaryDirectory()).path}/avatar$iAvatar.png');
    await avatarFile.writeAsBytes(base64.decode(_avatar));
    iAvatar++;
    isComplete = true;

    return [avatarFile];
  }
}
