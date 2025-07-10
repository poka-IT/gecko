import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/certs_list.dart';

class CertTile extends StatelessWidget {
  const CertTile({super.key, required this.listCerts});

  final List<CertDisplayItem> listCerts;

  @override
  Widget build(BuildContext context) {
    int keyID = 0;
    const double avatarSize = 40;

    return Column(
      children: listCerts.map((repository) {
        final String dateString = DateFormat.yMd(Localizations.localeOf(context).languageCode).format(repository.date);
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 0),
              child: ListTile(
                key: keyTransaction(keyID++),
                contentPadding: EdgeInsets.only(left: 10, right: 0, top: scaleSize(3), bottom: scaleSize(3)),
                leading: DatapodAvatar(address: repository.address, size: avatarSize),
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    repository.name,
                    style: scaledTextStyle(fontSize: 15, color: context.colorScheme.onSecondaryContainer),
                  ),
                ),
                subtitle: RichText(
                  text: TextSpan(
                    style: scaledTextStyle(fontSize: 14, color: homeContext.colorScheme.onSurfaceVariant),
                    children: <TextSpan>[
                      TextSpan(text: dateString, style: scaledTextStyle(fontSize: 14)),
                      if (repository.name.isNotEmpty)
                        TextSpan(
                          text: '  ·  ',
                          style: scaledTextStyle(fontSize: 18, color: Colors.grey[550]),
                        ),
                      TextSpan(
                        text: getShortPubkey(repository.address),
                        style: scaledTextStyle(
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Monospace',
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                dense: !isTall,
                isThreeLine: false,
                onTap: repository.address.isNotEmpty
                    ? () {
                        Navigator.push(
                          homeContext,
                          MaterialPageRoute(
                            builder: (context) {
                              return WalletViewScreen(address: repository.address, username: repository.name);
                            },
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
