import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/v2s_datapod.dart';
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

    return ScaledSizedBox(
        width: size, child: ClipOval(child: datapod.defaultAvatar(size)));
  }
}
