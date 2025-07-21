import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/screens/wallet_view.dart';
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
  });

  final int keyID;
  final double avatarSize;
  final TransactionDisplayItem transaction;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final newKey = keyID + 1;
    final String? username = transaction.username == '' ? null : transaction.username;
    final BigInt finalAmount = transaction.isReceived ? transaction.amount : transaction.amount * BigInt.from(-1);
    final String dateString = DateFormat.yMd(
      Localizations.localeOf(context).languageCode,
    ).add_Hm().format(transaction.transactionTime);

    // Different UI for Universal Dividends
    if (transaction.type == TransactionType.universalDividend) {
      return _buildUniversalDividendTile(context, newKey, finalAmount, dateString);
    }

    // Different UI for Identity Migration "From" events
    if (transaction.type == TransactionType.identityMigrationFrom) {
      return _buildIdentityMigrationFromTile(context, newKey, dateString);
    }

    // Different UI for Identity Migration "To" events
    if (transaction.type == TransactionType.identityMigrationTo) {
      return _buildIdentityMigrationToTile(context, newKey, dateString);
    }

    // Standard transaction tile with improved layout
    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(4)),
      decoration: BoxDecoration(color: context.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        key: keyTransaction(newKey),
        onTap: () {
          Navigator.push(
            context,
            PageNoTransit(
              builder: (context) => WalletViewScreen(address: transaction.address, username: username),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colorScheme.onSecondaryContainer, width: 1),
                ),
                child: DatapodAvatar(address: transaction.address, size: avatarSize),
              ),

              ScaledSizedBox(width: 12),

              // Main content - flexible to adapt to balance width
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: Address and Balance
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address - truncated at START when needed
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final address = getShortPubkey(transaction.address);
                              final style = scaledTextStyle(fontSize: 16, fontFamily: 'Monospace');

                              // Measure if full address fits
                              final fullTextPainter = TextPainter(
                                text: TextSpan(text: address, style: style),
                                textDirection: ui.TextDirection.ltr,
                              );
                              fullTextPainter.layout();

                              // Add safety margin to account for padding/spacing differences
                              final safeMaxWidth = constraints.maxWidth - 16.0;

                              if (fullTextPainter.width <= safeMaxWidth) {
                                // Full address fits with safety margin
                                return Text(address, style: style, maxLines: 1, overflow: TextOverflow.clip);
                              }

                              // Need to truncate - measure ellipsis width
                              final ellipsisPainter = TextPainter(
                                text: TextSpan(text: '...', style: style),
                                textDirection: ui.TextDirection.ltr,
                              );
                              ellipsisPainter.layout();
                              final ellipsisWidth = ellipsisPainter.width;

                              final availableForText = constraints.maxWidth - ellipsisWidth;

                              // Find how many chars from the END we can keep
                              String bestText = '...';
                              for (int i = 1; i <= address.length; i++) {
                                final testSuffix = address.substring(address.length - i);
                                final testPainter = TextPainter(
                                  text: TextSpan(text: testSuffix, style: style),
                                  textDirection: ui.TextDirection.ltr,
                                );
                                testPainter.layout();

                                if (testPainter.width <= availableForText) {
                                  bestText = '${String.fromCharCode(0x2026)}$testSuffix';
                                } else {
                                  break;
                                }
                              }

                              return Text(bestText, style: style, maxLines: 1, overflow: TextOverflow.clip);
                            },
                          ),
                        ),

                        ScaledSizedBox(width: 8),

                        // Balance - flexible width based on content
                        BalanceDisplay(
                          value: finalAmount,
                          size: 16,
                          color: transaction.isReceived ? greenColor : blueColor,
                        ),
                      ],
                    ),

                    ScaledSizedBox(height: 6),

                    // Bottom section: Username, comment, and date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (username != null) ...[
                          Text(
                            username,
                            style: scaledTextStyle(fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          ScaledSizedBox(height: 3),
                        ],
                        if (transaction.comment != null && transaction.comment!.isNotEmpty) ...[
                          Text(
                            transaction.comment!,
                            style: scaledTextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          ScaledSizedBox(height: 3),
                        ],
                        Text(dateString, style: scaledTextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a specialized tile for Universal Dividends
  Widget _buildUniversalDividendTile(BuildContext context, int newKey, BigInt finalAmount, String dateString) {
    // Adaptive colors based on theme
    final bool isDark = context.isDarkTheme;

    final Color tileBackgroundColor = isDark ? Colors.teal.shade900.withValues(alpha: 0.15) : Colors.cyan.shade50;

    final Color tileBorderColor = isDark ? Colors.teal.shade700.withValues(alpha: 0.4) : Colors.cyan.shade200;

    final Color iconBackgroundColor = isDark ? Colors.teal.shade800.withValues(alpha: 0.3) : Colors.teal.shade100;

    final Color iconBorderColor = isDark ? Colors.teal.shade600.withValues(alpha: 0.6) : Colors.teal.shade300;

    final Color iconColor = isDark ? Colors.teal.shade300 : Colors.teal.shade700;

    final Color titleColor = isDark ? Colors.teal.shade200 : Colors.teal.shade800;

    final Color dateColor = isDark ? Colors.teal.shade300 : Colors.teal.shade600;

    final Color balanceColor = isDark ? Colors.cyan.shade300 : Colors.cyan.shade700;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(4)),
      decoration: BoxDecoration(
        color: tileBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tileBorderColor, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(12)),
        child: Row(
          children: [
            // Icon container - much smaller
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackgroundColor,
                border: Border.all(color: iconBorderColor, width: 1),
              ),
              child: Center(child: Icon(Icons.water_drop, size: 16, color: iconColor)),
            ),

            ScaledSizedBox(width: 10),

            // Content - title and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'universalDividend'.tr(),
                    style: scaledTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  ScaledSizedBox(height: 1),
                  Text(dateString, style: scaledTextStyle(fontSize: 10, color: dateColor)),
                ],
              ),
            ),

            // Balance - right aligned
            BalanceDisplay(value: finalAmount, size: 13, color: balanceColor),
          ],
        ),
      ),
    );
  }

  /// Build a specialized event display for Identity Migration "From" events
  Widget _buildIdentityMigrationFromTile(BuildContext context, int newKey, String dateString) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleSize(25), horizontal: scaleSize(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageNoTransit(
              builder: (context) => WalletViewScreen(address: transaction.address, username: transaction.username),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.account_circle, size: scaleSize(40), color: greenColor),
                Column(
                  children: [
                    Text(
                      'identityMigratedFrom'.tr(),
                      style: scaledTextStyle(fontSize: 19, color: greenColor, fontWeight: FontWeight.w500),
                    ),
                    if (transaction.username != null && transaction.username!.isNotEmpty) ...[
                      Text(transaction.username!, style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ScaledSizedBox(height: 2),
                    ],
                    Text(
                      'from'.tr(args: [' ${getShortPubkey(transaction.address)}']),
                      style: scaledTextStyle(fontSize: 16),
                    ),
                    ScaledSizedBox(height: 4),
                    Text(dateString, style: scaledTextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
                Icon(Icons.account_circle, size: scaleSize(32), color: greenColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a specialized event display for Identity Migration "To" events
  Widget _buildIdentityMigrationToTile(BuildContext context, int newKey, String dateString) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleSize(25), horizontal: scaleSize(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageNoTransit(
              builder: (context) => WalletViewScreen(address: transaction.address, username: transaction.username),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.account_circle, size: scaleSize(32), color: blueColor),
                Column(
                  children: [
                    Text(
                      'identityMigratedTo'.tr(),
                      style: scaledTextStyle(fontSize: 19, color: blueColor, fontWeight: FontWeight.w500),
                    ),
                    if (transaction.username != null && transaction.username!.isNotEmpty) ...[
                      Text(transaction.username!, style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ScaledSizedBox(height: 2),
                    ],
                    Text(
                      'to'.tr(args: [' ${getShortPubkey(transaction.address)}']),
                      style: scaledTextStyle(fontSize: 16),
                    ),
                    ScaledSizedBox(height: 4),
                    Text(dateString, style: scaledTextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
                Icon(Icons.account_circle, size: scaleSize(40), color: blueColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
