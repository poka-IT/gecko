import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/certs_list.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';

class CertTile extends StatelessWidget {
  const CertTile({super.key, required this.listCerts});

  final List<CertDisplayItem> listCerts;

  @override
  Widget build(BuildContext context) {
    int keyID = 0;
    const double avatarSize = 40;

    return Column(
      children: listCerts.map((cert) {
        final newKey = keyID++;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: scaleSize(4), vertical: scaleSize(3)),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(scaleSize(12)),
            border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.1), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: InkWell(
            key: keyTransaction(newKey),
            onTap: cert.address.isNotEmpty
                ? () {
                    Navigator.push(
                      context,
                      PageNoTransit(
                        builder: (context) =>
                            WalletViewScreen(address: cert.address, username: cert.name.isNotEmpty ? cert.name : null),
                      ),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(scaleSize(12)),
            child: Padding(
              padding: EdgeInsets.all(scaleSize(12)),
              child: Row(
                children: [
                  // Avatar
                  DatapodAvatar(address: cert.address, size: avatarSize, name: cert.name.isNotEmpty ? cert.name : null),

                  ScaledSizedBox(width: 12),

                  // Main content area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name (if available)
                        if (cert.name.isNotEmpty) ...[
                          Text(
                            cert.name,
                            style: scaledTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          ScaledSizedBox(height: 2),
                        ],

                        // Address
                        Text(
                          getShortPubkey(cert.address),
                          style: scaledTextStyle(
                            fontSize: cert.name.isNotEmpty ? 13 : 16,
                            color: context.colorScheme.onSurface.withValues(alpha: cert.name.isNotEmpty ? 0.6 : 1.0),
                            fontFamily: 'monospace',
                            fontWeight: cert.name.isNotEmpty ? FontWeight.normal : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  ScaledSizedBox(width: 12),

                  // Date column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Certification icon
                      Container(
                        padding: EdgeInsets.all(scaleSize(6)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colorScheme.primary.withValues(alpha: 0.1),
                          border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Icon(Icons.verified_user, size: scaleSize(16), color: context.colorScheme.primary),
                      ),

                      ScaledSizedBox(height: 8),

                      // Date
                      Text(
                        cert.date.year == DateTime.now().year
                            ? DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(cert.date)
                            : DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(cert.date),
                        style: scaledTextStyle(
                          fontSize: 11,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      ScaledSizedBox(height: 2),

                      // Time
                      Text(
                        DateFormat.Hm().format(cert.date),
                        style: scaledTextStyle(
                          fontSize: 10,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
