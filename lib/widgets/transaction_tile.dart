import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/screens/profile_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.keyID,
    required this.avatarSize,
    required this.transaction,
    required this.context,
    this.viewingAddress,
  });

  final int keyID;
  final double avatarSize;
  final TransactionDisplayItem transaction;
  final BuildContext context;
  final String? viewingAddress;

  @override
  Widget build(BuildContext context) {
    final newKey = keyID + 1;
    final String? username = transaction.username == '' ? null : transaction.username;
    final BigInt finalAmount = transaction.isReceived ? transaction.amount : transaction.amount * BigInt.from(-1);

    // Different UI for Universal Dividends
    if (transaction.type == TransactionType.universalDividend) {
      return _buildUniversalDividendTile(context, newKey, finalAmount);
    }

    // Different UI for Identity Migration "From" events
    if (transaction.type == TransactionType.identityMigrationFrom) {
      return _buildIdentityMigrationFromTile(context, newKey);
    }

    // Different UI for Identity Migration "To" events
    if (transaction.type == TransactionType.identityMigrationTo) {
      return _buildIdentityMigrationToTile(context, newKey);
    }

    // Modern transaction tile with optimized layout
    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(4)),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(scaleSize(12)),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Material(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(scaleSize(12)),
        child: InkWell(
          key: keyTransaction(newKey),
          onTap: () {
            Navigator.push(
              context,
              PageNoTransit(
                builder: (context) =>
                    ProfileViewScreen(address: transaction.address, username: username, fromAddress: viewingAddress),
              ),
            );
          },
          borderRadius: BorderRadius.circular(scaleSize(12)),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Row(
              children: [
                // Avatar
                DatapodAvatar(address: transaction.address, size: avatarSize, name: username),

                ScaledSizedBox(width: 12),

                // Main content area - flexible to handle address truncation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top row: Name/Address and Amount/Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Name and address with smart truncation
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name or address with truncation logic
                                if (username != null) ...[
                                  Text(
                                    username,
                                    style: scaledTextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: context.colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  ScaledSizedBox(height: 2),
                                ],
                                // Address with smart truncation (always present)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return _buildSmartAddress(context, constraints.maxWidth);
                                  },
                                ),
                                // Comment with arrow - inline after address
                                if (transaction.comment != null && transaction.comment!.isNotEmpty) ...[
                                  ScaledSizedBox(height: 4),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _showCommentDialog(context, transaction.comment!),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Direction arrow
                                        Icon(
                                          transaction.isReceived ? Icons.call_received : Icons.call_made,
                                          size: scaleSize(14),
                                          color: transaction.isReceived ? context.colorScheme.primary : Colors.blue,
                                        ),
                                        ScaledSizedBox(width: 6),
                                        // Comment text
                                        Expanded(
                                          child: Text(
                                            transaction.comment!,
                                            style: scaledTextStyle(
                                              fontSize: 13,
                                              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          ScaledSizedBox(width: 12),

                          // Right: Amount and date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Amount
                              BalanceDisplay(
                                value: finalAmount,
                                size: 16,
                                color: transaction.isReceived ? context.colorScheme.primary : Colors.blue,
                              ),
                              ScaledSizedBox(height: 4),

                              // Date
                              Text(
                                DateFormat.MMMd(
                                  Localizations.localeOf(context).languageCode,
                                ).format(transaction.transactionTime),
                                style: scaledTextStyle(
                                  fontSize: 11,
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              ScaledSizedBox(height: 2),

                              // Time
                              Text(
                                DateFormat.Hm().format(transaction.transactionTime),
                                style: scaledTextStyle(
                                  fontSize: 10,
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCommentDialog(BuildContext context, String comment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(scaleSize(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.comment_outlined, size: scaleSize(20), color: context.colorScheme.primary),
                  ScaledSizedBox(width: 8),
                  Text('comment'.tr(), style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              ScaledSizedBox(height: 16),
              SelectableText(
                comment,
                style: scaledTextStyle(
                  fontSize: 15,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build smart address using the centralized utility function
  Widget _buildSmartAddress(BuildContext context, double maxWidth) {
    final String? username = transaction.username == '' ? null : transaction.username;
    final style = scaledTextStyle(
      fontSize: username != null ? 13 : 16,
      color: context.colorScheme.onSurface.withValues(alpha: username != null ? 0.6 : 1.0),
      fontFamily: 'monospace',
      fontWeight: username != null ? FontWeight.normal : FontWeight.w600,
    );

    return buildSmartAddressText(address: transaction.address, maxWidth: maxWidth, style: style);
  }

  /// Build a modern tile for Universal Dividends
  Widget _buildUniversalDividendTile(BuildContext context, int newKey, BigInt finalAmount) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(4)),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(scaleSize(12)),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Material(
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(scaleSize(12)),
        child: Padding(
          padding: EdgeInsets.all(scaleSize(12)),
          child: Row(
            children: [
              // Modern icon container
              Container(
                width: scaleSize(40),
                height: scaleSize(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorScheme.primary.withValues(alpha: 0.1),
                  border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.3), width: 1),
                ),
                child: Icon(Icons.water_drop, size: scaleSize(20), color: context.colorScheme.primary),
              ),

              ScaledSizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'universalDividend'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount and date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BalanceDisplay(value: finalAmount, size: 16, color: context.colorScheme.primary),
                  ScaledSizedBox(height: 4),
                  Text(
                    DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(transaction.transactionTime),
                    style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a modern tile for Identity Migration "From" events
  Widget _buildIdentityMigrationFromTile(BuildContext context, int newKey) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(4)),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(scaleSize(12)),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Material(
        color: context.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(scaleSize(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageNoTransit(
                builder: (context) => ProfileViewScreen(
                  address: transaction.address,
                  username: transaction.username,
                  fromAddress: viewingAddress,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(scaleSize(12)),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Row(
              children: [
                // Migration icon
                Container(
                  width: scaleSize(40),
                  height: scaleSize(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colorScheme.secondary.withValues(alpha: 0.1),
                    border: Border.all(color: context.colorScheme.secondary.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Icon(Icons.swap_horiz, size: scaleSize(20), color: context.colorScheme.secondary),
                ),

                ScaledSizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'identityMigratedFrom'.tr(),
                        style: scaledTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      ScaledSizedBox(height: 2),
                      if (transaction.username != null && transaction.username!.isNotEmpty) ...[
                        Text(
                          transaction.username!,
                          style: scaledTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        ScaledSizedBox(height: 2),
                      ],
                      Text(
                        getShortPubkey(transaction.address),
                        style: scaledTextStyle(
                          fontSize: 13,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                // Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(transaction.transactionTime),
                      style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    ScaledSizedBox(height: 2),
                    Text(
                      DateFormat.Hm().format(transaction.transactionTime),
                      style: scaledTextStyle(fontSize: 10, color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
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

  /// Build a modern tile for Identity Migration "To" events
  Widget _buildIdentityMigrationToTile(BuildContext context, int newKey) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(4)),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(scaleSize(12)),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Material(
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(scaleSize(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageNoTransit(
                builder: (context) => ProfileViewScreen(
                  address: transaction.address,
                  username: transaction.username,
                  fromAddress: viewingAddress,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(scaleSize(12)),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Row(
              children: [
                // Migration icon
                Container(
                  width: scaleSize(40),
                  height: scaleSize(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Icon(Icons.swap_horiz, size: scaleSize(20), color: context.colorScheme.primary),
                ),

                ScaledSizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'identityMigratedTo'.tr(),
                        style: scaledTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      ScaledSizedBox(height: 2),
                      if (transaction.username != null && transaction.username!.isNotEmpty) ...[
                        Text(
                          transaction.username!,
                          style: scaledTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        ScaledSizedBox(height: 2),
                      ],
                      Text(
                        getShortPubkey(transaction.address),
                        style: scaledTextStyle(
                          fontSize: 13,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                // Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(transaction.transactionTime),
                      style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    ScaledSizedBox(height: 2),
                    Text(
                      DateFormat.Hm().format(transaction.transactionTime),
                      style: scaledTextStyle(fontSize: 10, color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
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
}
