import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';

/// Displays a warning card when the user's identity has been migrated
/// to another wallet from an external application (e.g. Cesium2).
class MigrationAlertCard extends ConsumerWidget {
  const MigrationAlertCard({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(isOwnerProvider(address));
    if (!isOwner) return const SizedBox.shrink();

    final isIgnored = ref.watch(ignoreMigrationWarningProvider(address));
    if (isIgnored) return const SizedBox.shrink();

    final migrationAsync = ref.watch(migrationFromDataProvider(address));
    final idtyStatusAsync = ref.watch(smartIdtyStatusStreamProvider(address));

    return migrationAsync.when(
      data: (migrationData) {
        if (migrationData == null) return const SizedBox.shrink();

        return idtyStatusAsync.when(
          data: (idtyStatus) {
            if (idtyStatus != IdtyStatus.none && idtyStatus != IdtyStatus.unknown) {
              return const SizedBox.shrink();
            }

            return _buildAlertCard(context, ref, migrationData.identityName ?? '?', migrationData.toAddress);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildAlertCard(BuildContext context, WidgetRef ref, String identityName, String newAddress) {
    final shortAddress = getShortPubkey(newAddress);

    return Container(
      margin: EdgeInsets.symmetric(vertical: scaleSize(8), horizontal: scaleSize(20)),
      padding: EdgeInsets.all(scaleSize(16)),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.orange.shade800, size: scaleSize(22)),
              ScaledSizedBox(width: 8),
              Expanded(
                child: Text(
                  'identityMigrated'.tr(),
                  style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                ),
              ),
            ],
          ),
          ScaledSizedBox(height: 12),
          TextMarkDown(
            'identityMigratedWarningMessage'.tr(args: [identityName, shortAddress]),
            style: scaledTextStyle(fontSize: 14, color: Colors.orange.shade900),
            textAlign: WrapAlignment.start,
          ),
          ScaledSizedBox(height: 8),
          Text(
            'identityMigratedWarningExplanation'.tr(),
            style: scaledTextStyle(fontSize: 13, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
          ),
          ScaledSizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.import_export, size: scaleSize(18)),
              label: Text(
                'forgetAndImportNewMnemonic'.tr(),
                style: scaledTextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: scaleSize(12), horizontal: scaleSize(16)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.restoreSafe);
              },
            ),
          ),
          ScaledSizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                ref.read(ignoreMigrationWarningProvider(address).notifier).ignore();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
              ),
              child: Text(
                'ignoreMigrationWarning'.tr(),
                style: scaledTextStyle(fontSize: 13, color: Colors.orange.shade800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
