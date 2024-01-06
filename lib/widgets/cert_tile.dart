import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/datapod_avatar.dart';

class CertTile extends StatelessWidget {
  const CertTile({
    Key? key,
    required this.listCerts,
  }) : super(key: key);

  final List listCerts;

  @override
  Widget build(BuildContext context) {
    int keyID = 0;
    const double avatarSize = 40;

    return Column(
        children: listCerts.map((repository) {
      return Column(children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 0),
          child: ListTile(
              key: keyTransaction(keyID++),
              contentPadding: EdgeInsets.only(
                  left: 10, right: 0, top: scaleSize(3), bottom: scaleSize(3)),
              leading: DatapodAvatar(
                              address: repository['address'], size: avatarSize),
              title: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  repository['name'],
                  style: scaledTextStyle(fontSize: 16),
                ),
              ),
              subtitle: RichText(
                text: TextSpan(
                  style: scaledTextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: repository['date'],
                      style: scaledTextStyle(fontSize: 15),
                    ),
                    if (repository[2] != '')
                      TextSpan(
                        text: '  ·  ',
                        style: scaledTextStyle(
                          fontSize: 19,
                          color: Colors.grey[550],
                        ),
                      ),
                    TextSpan(
                      text: getShortPubkey(repository['address']),
                      style: scaledTextStyle(
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Monospace',
                          color: Colors.grey[600],
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
              dense: !isTall,
              isThreeLine: false,
              onTap: () {
                Navigator.push(
                  homeContext,
                  MaterialPageRoute(builder: (context) {
                    return WalletViewScreen(
                      address: repository['address'],
                      username: repository['name'],
                    );
                  }),
                );
              }),
        ),
      ]);
    }).toList());
  }
}
