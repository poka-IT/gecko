import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:provider/provider.dart';

class CesiumAvatar extends StatelessWidget {
  const CesiumAvatar({Key? key, required this.address, this.size = 15})
      : super(key: key);
  final String address;
  final double size;

  @override
  Widget build(BuildContext context) {
    final csProvider = Provider.of<CesiumPlusProvider>(context, listen: false);

    return ClipOval(
      child: FutureBuilder(
          future: csProvider.getAvatar(address, size),
          builder: ((context, AsyncSnapshot<Image> avatar) {
            if (avatar.hasError) {
              log.e(avatar.error);
              return (Icon(Icons.close_outlined,
                  color: Colors.red, size: size));
            } else if (avatar.connectionState != ConnectionState.done) {
              return SizedBox(
                  width: size,
                  height: size,
                  child: const FractionallySizedBox(
                      widthFactor: 0.6, heightFactor: 0.6, child: Loading()));
            }
            return avatar.data!;
          })),
    );
  }
}
