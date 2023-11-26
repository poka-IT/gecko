import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/wallet_view.dart';

class CertTile extends StatelessWidget {
  const CertTile({
    Key? key,
    required this.listCerts,
  }) : super(key: key);

  final List listCerts;

  @override
  Widget build(BuildContext context) {
    int keyID = 0;
    const double avatarSize = 200;

    return Column(
        children: listCerts.map((repository) {
      return Column(children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 0),
          child: ListTile(
              key: keyTransaction(keyID++),
              contentPadding: const EdgeInsets.only(
                  left: 20, right: 30, top: 15, bottom: 15),
              leading: ClipOval(
                child: defaultAvatar(avatarSize),
              ),
              title: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(repository['name'],
                    style: const TextStyle(fontSize: 22)),
              ),
              subtitle: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: repository['date'],
                    ),
                    if (repository[2] != '')
                      TextSpan(
                        text: '  ·  ',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[550],
                        ),
                      ),
                    TextSpan(
                      text: getShortPubkey(repository['address']),
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                          fontSize: 18),
                    ),
                  ],
                ),
              ),
              dense: false,
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
