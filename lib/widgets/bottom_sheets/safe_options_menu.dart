import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/screens/myWallets/safe_options.dart';
import 'package:gecko/screens/myWallets/migrate_g1v1_screen.dart';

/// Shows a bottom sheet with safe management options
void showSafeOptionsMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (BuildContext context) {
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      return Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Option 1: Manage safe
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(24), vertical: scaleSize(8)),
              leading: Image.asset('assets/safes/config.png', height: scaleSize(36)),
              title: Text('manageSafe'.tr(), style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SafeOptions()));
              },
            ),
            // Option 2: Import Cesium account
            ListTile(
              key: keyImportG1v1,
              contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(24), vertical: scaleSize(8)),
              leading: SvgPicture.asset('assets/cesium_bw2.svg', height: scaleSize(36)),
              title: Text(
                'importIdPasswordAccount'.tr(),
                style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MigrateG1v1()));
              },
            ),
            SizedBox(height: 24 + bottomPadding),
          ],
        ),
      );
    },
  );
}
