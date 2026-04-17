import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';

/// Indicates the source (and trust level) of a wallet name.
enum NameSource {
  /// On-chain identity fully validated by the web of trust (full member).
  identity,

  /// On-chain identity that exists but is not yet a validated member
  /// (created / confirmed / expired / revoked). Must NOT look the same as
  /// [identity], otherwise a non-member reads as a trusted member.
  pendingIdentity,

  /// Self-declared name from a CesiumPlus profile (never verified).
  cesiumPlus,
}

/// A small visual indicator showing whether a name comes from a verified
/// on-chain identity or a self-declared CesiumPlus profile.
///
/// - [NameSource.identity]: green verified icon with tooltip
/// - [NameSource.cesiumPlus]: amber warning pill with "self-declared" label and tooltip
class NameSourceBadge extends StatelessWidget {
  const NameSourceBadge({super.key, required this.source});

  /// The source of the displayed name.
  final NameSource source;

  @override
  Widget build(BuildContext context) {
    return switch (source) {
      NameSource.identity => Tooltip(
        message: 'verifiedIdentity'.tr(),
        child: Icon(Icons.verified, size: scaleSize(16), color: context.geckoColors.statusMember),
      ),
      NameSource.pendingIdentity => Tooltip(
        message: 'pendingIdentityTooltip'.tr(),
        child: Icon(Icons.schedule, size: scaleSize(15), color: context.geckoColors.statusCreated),
      ),
      NameSource.cesiumPlus => Tooltip(
        message: 'selfDeclaredNameTooltip'.tr(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(6), vertical: scaleSize(2)),
          decoration: BoxDecoration(
            color: context.geckoColors.warning.withValues(alpha: 0.18),
            border: Border.all(color: context.geckoColors.warning.withValues(alpha: 0.7), width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: scaleSize(12), color: context.geckoColors.warning),
              SizedBox(width: scaleSize(3)),
              Text(
                'selfDeclaredName'.tr(),
                style: scaledTextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: context.geckoColors.warning,
                ),
              ),
            ],
          ),
        ),
      ),
    };
  }
}

/// Visual tone for [SearchSectionHeader].
enum SearchSectionTone {
  /// No semantic color, neutral muted grey (default for non-semantic groupings).
  neutral,

  /// Green verified tone — reassures the user that names below come from the
  /// on-chain web of trust.
  verified,

  /// Amber warning tone — signals that names below are self-declared and not
  /// verified by the web of trust.
  warning,
}

/// Shared section header for search result lists.
///
/// Use [tone] to pick a color and leading icon so the verified / unverified
/// sections read at a glance. All search widgets should route through this
/// widget so the visual language stays consistent.
class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({super.key, required this.title, this.tone = SearchSectionTone.neutral, this.padding});

  final String title;
  final SearchSectionTone tone;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (tone) {
      SearchSectionTone.verified => (context.geckoColors.statusMember, Icons.verified_rounded),
      SearchSectionTone.warning => (context.geckoColors.warning, Icons.warning_amber_rounded),
      SearchSectionTone.neutral => (context.colorScheme.onSurface.withValues(alpha: 0.42), null),
    };
    return Padding(
      padding: padding ?? const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: scaleSize(14), color: color), SizedBox(width: scaleSize(6))],
          Text(
            title,
            style: scaledTextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.9),
          ),
        ],
      ),
    );
  }
}
