import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_datapod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/v2s_datapod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class DatapodAvatar extends StatelessWidget {
  const DatapodAvatar({Key? key, required this.address, this.size = 15})
      : super(key: key);
  final String address;
  final double size;

  @override
  Widget build(BuildContext context) {
    final datapod = Provider.of<V2sDatapodProvider>(context, listen: false);

    final cachedImage = File('${avatarsCacheDirectory.path}/$address');
    if (cachedImage.existsSync()) {
      return ScaledSizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: datapod.getAvatarLocal(address),
        ),
      );
    }

    final httpLink = HttpLink(
      '$datapodEndpoint/v1/graphql',
    );

    final client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(),
        link: httpLink,
      ),
    );

    return ScaledSizedBox(
      width: size,
      child: GraphQLProvider(
        client: client,
        child: Query(
            options: QueryOptions(
              document: gql(getAvatarQ),
              variables: <String, dynamic>{
                'address': address,
              },
            ),
            builder: (QueryResult result, {fetchMore, refetch}) {
              if (result.isLoading) {
                return Center(
                  child: ClipOval(child: datapod.defaultAvatar(size)),
                );
              }
              final String? avatar64 =
                  result.data!['profiles_by_pk']?['avatar64'];

              if (avatar64 == null || result.data == null) {
                return ClipOval(child: datapod.defaultAvatar(size));
              }

              final sanitizedAvatar64 = avatar64
                  .replaceAll('\n', '')
                  .replaceAll('\r', '')
                  .replaceAll(' ', '');

              datapod.cacheAvatar(address, sanitizedAvatar64);

              return ClipOval(
                child: Image.memory(
                  base64.decode(sanitizedAvatar64),
                  fit: BoxFit.cover,
                ),
              );
            }),
      ),
    );
  }
}
