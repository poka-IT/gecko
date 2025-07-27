import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:durt2/durt2.dart' show Enum$IdentityStatusEnum;
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/identity_display_item.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/datapod_avatar.dart';

/// Tile widget for displaying identity activity
class IdentityTile extends StatelessWidget {
  const IdentityTile({super.key, required this.identity});

  final IdentityDisplayItem identity;

  @override
  Widget build(BuildContext context) {
    // Format the identity name for display
    final displayName = identity.name.isEmpty ? (identity.accountId ?? "Unknown").substring(0, 8) : identity.name;
    const double avatarSize = 45;

    return Container(
      margin: EdgeInsets.symmetric(vertical: scaleSize(4)),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(scaleSize(12)),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Material(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(scaleSize(12)),
        child: InkWell(
          onTap: identity.relevantAccountId != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WalletViewScreen(
                        address: identity.relevantAccountId!,
                        username: identity.name.isNotEmpty ? identity.name : null,
                      ),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(scaleSize(12)),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Row(
              children: [
                DatapodAvatar(
                  address: identity.relevantAccountId!,
                  size: avatarSize,
                  name: identity.name.isNotEmpty ? identity.name : null,
                ),
                ScaledSizedBox(width: 12),

                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Identity name and status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: scaledTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ScaledSizedBox(width: 8),
                          _buildStatusBadge(context),
                        ],
                      ),

                      ScaledSizedBox(height: 4),

                      // Address
                      if (identity.relevantAccountId != null) ...[
                        Text(
                          getShortPubkey(identity.relevantAccountId!),
                          style: scaledTextStyle(
                            fontSize: 13,
                            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontFamily: 'monospace',
                          ),
                        ),
                        ScaledSizedBox(height: 4),
                      ],

                      // Activity details
                      Row(
                        children: [
                          Icon(identity.getStatusIcon(), size: scaleSize(14), color: identity.getStatusColor()),
                          ScaledSizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getActivityDescription(context),
                              style: scaledTextStyle(
                                fontSize: 13,
                                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                ScaledSizedBox(width: 8),

                // Timestamp and block info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(identity.timestamp),
                      style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    if (identity.blockHeight != null) ...[
                      ScaledSizedBox(height: 2),
                      Text(
                        '#${identity.blockHeight}',
                        style: scaledTextStyle(
                          fontSize: 11,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(2)),
      decoration: BoxDecoration(
        color: identity.getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(scaleSize(12)),
        border: Border.all(color: identity.getStatusColor().withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        identity.displayStatus,
        style: scaledTextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: identity.getStatusColor()),
      ),
    );
  }

  String _getActivityDescription(BuildContext context) {
    switch (identity.status) {
      case Enum$IdentityStatusEnum.MEMBER:
        return 'identityIsMember'.tr();
      case Enum$IdentityStatusEnum.NOTMEMBER:
        return 'identityIsNotMember'.tr();
      case Enum$IdentityStatusEnum.REMOVED:
        return 'identityWasRemoved'.tr();
      case Enum$IdentityStatusEnum.REVOKED:
        return 'identityWasRevoked'.tr();
      case Enum$IdentityStatusEnum.UNCONFIRMED:
        return 'identityIsUnconfirmed'.tr();
      case Enum$IdentityStatusEnum.UNVALIDATED:
        return 'identityIsUnvalidated'.tr();
      case Enum$IdentityStatusEnum.$unknown:
        return 'identityStatusUnknown'.tr();
    }
  }
}
