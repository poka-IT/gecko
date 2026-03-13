import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/certification_display_item.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/widgets/datapod_avatar.dart';

/// Tile widget for displaying certification activity
class CertificationTile extends StatelessWidget {
  const CertificationTile({super.key, required this.certification});

  final CertificationDisplayItem certification;

  @override
  Widget build(BuildContext context) {
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
          onTap: () {
            NavigationService.openProfile(
              context,
              address: certification.issuerAccountId,
              username: certification.issuerName?.isNotEmpty == true ? certification.issuerName : null,
            );
          },
          borderRadius: BorderRadius.circular(scaleSize(12)),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with formatted status
                Row(
                  children: [
                    Icon(certification.getStatusIcon(), size: scaleSize(18), color: certification.getStatusColor()),
                    ScaledSizedBox(width: 8),
                    Expanded(
                      child: Text(
                        certification.displayStatus,
                        style: scaledTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: certification.getStatusColor(),
                        ),
                      ),
                    ),
                    // Show expiration badge only if certification is expired
                    if (certification.isExpired) _buildExpiredBadge(context),
                  ],
                ),

                ScaledSizedBox(height: 8),

                // Main certification relationship
                Row(
                  children: [
                    // Issuer
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'issuer'.tr(),
                            style: scaledTextStyle(
                              fontSize: 12,
                              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          ScaledSizedBox(height: 2),
                          Row(
                            children: [
                              DatapodAvatar(
                                address: certification.issuerAccountId,
                                size: 22,
                                name: certification.issuerDisplayName,
                              ),
                              ScaledSizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  certification.issuerDisplayName,
                                  style: scaledTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Fixed middle column keeps the arrow aligned across rows
                    SizedBox(
                      width: scaleSize(32),
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward,
                          size: scaleSize(16),
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),

                    // Receiver
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'receiver'.tr(),
                            style: scaledTextStyle(
                              fontSize: 12,
                              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          ScaledSizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  certification.receiverDisplayName,
                                  style: scaledTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              ScaledSizedBox(width: 6),
                              DatapodAvatar(
                                address: certification.receiverAccountId,
                                size: 22,
                                name: certification.receiverDisplayName,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                ScaledSizedBox(height: 8),

                // Bottom info row
                Row(
                  children: [
                    // Timestamp
                    Icon(
                      Icons.access_time,
                      size: scaleSize(14),
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    ScaledSizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(certification.timestamp),
                      style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),

                    ScaledSizedBox(width: 16),

                    // Expiration info if relevant (now only shows days remaining, not if expired)
                    if (certification.expirationText != null && !certification.isExpired) ...[
                      Icon(Icons.schedule, size: scaleSize(14), color: Colors.orange),
                      ScaledSizedBox(width: 4),
                      Text(certification.expirationText!, style: scaledTextStyle(fontSize: 12, color: Colors.orange)),
                    ],

                    const Spacer(),

                    // Block height
                    if (certification.updatedBlockHeight != null)
                      Text(
                        '#${certification.updatedBlockHeight}',
                        style: scaledTextStyle(
                          fontSize: 11,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpiredBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(6), vertical: scaleSize(2)),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(scaleSize(10)),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, size: scaleSize(12), color: Colors.red),
          ScaledSizedBox(width: 2),
          Text(
            'expired'.tr(),
            style: scaledTextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
