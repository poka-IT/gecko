import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';

/// Indicates the source of a wallet name.
enum NameSource {
  /// Name verified by the web of trust (on-chain identity).
  identity,

  /// Self-declared name from CesiumPlus profile (not verified).
  cesiumPlus,
}

/// A small visual indicator showing whether a name comes from a verified
/// on-chain identity or a self-declared CesiumPlus profile.
///
/// - [NameSource.identity]: green verified icon with tooltip
/// - [NameSource.cesiumPlus]: italic muted text "self-declared" with tooltip
class NameSourceBadge extends StatelessWidget {
  const NameSourceBadge({super.key, required this.source});

  /// The source of the displayed name.
  final NameSource source;

  @override
  Widget build(BuildContext context) {
    return switch (source) {
      NameSource.identity => Tooltip(
        message: 'verifiedIdentity'.tr(),
        child: Icon(
          Icons.verified,
          size: scaleSize(16),
          color: context.geckoColors.statusMember,
        ),
      ),
      NameSource.cesiumPlus => Tooltip(
        message: 'selfDeclaredNameTooltip'.tr(),
        child: Text(
          'selfDeclaredName'.tr(),
          style: scaledTextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    };
  }
}
