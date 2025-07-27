import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
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

    final shouldAddSpace =
        transaction.comment != null &&
        transaction.comment!.isNotEmpty &&
        transaction.comment!.length > 14 &&
        username != null;

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
                builder: (context) => WalletViewScreen(address: transaction.address, username: username),
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
                  child: Stack(
                    clipBehavior: Clip.none, // Allow overflow if needed
                    children: [
                      Column(
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

                          // Add space for comment when present (more space if there's also a username and comment is long)
                          if (shouldAddSpace) ScaledSizedBox(height: 25),
                        ],
                      ),

                      // Direction arrow always visible at the same position
                      Positioned(
                        left: 0,
                        top: username != null
                            ? scaleSize(48) // Lowered from 46 to 48
                            : scaleSize(30), // Lowered from 28 to 30
                        child: Icon(
                          transaction.isReceived ? Icons.call_received : Icons.call_made,
                          size: scaleSize(14),
                          color: transaction.isReceived ? context.colorScheme.primary : Colors.blue,
                        ),
                      ),

                      // Comment positioned as overlay to use maximum available space
                      if (transaction.comment != null && transaction.comment!.isNotEmpty)
                        Positioned(
                          left: scaleSize(20), // Start after the arrow
                          right: scaleSize(55), // Leave space for amount/date column
                          top: username != null
                              ? scaleSize(48) // Same as arrow position (lowered from 46)
                              : scaleSize(30), // Same as arrow position (lowered from 28)
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
            ),
          ),
        ),
      ),
    );
  }

  /// Build smart address with truncation from the beginning when needed
  Widget _buildSmartAddress(BuildContext context, double maxWidth) {
    final String? username = transaction.username == '' ? null : transaction.username;
    final address = getShortPubkey(transaction.address);
    final style = scaledTextStyle(
      fontSize: username != null ? 13 : 16,
      color: context.colorScheme.onSurface.withValues(alpha: username != null ? 0.6 : 1.0),
      fontFamily: 'monospace',
      fontWeight: username != null ? FontWeight.normal : FontWeight.w600,
    );

    // Measure if full address fits
    final fullTextPainter = TextPainter(
      text: TextSpan(text: address, style: style),
      textDirection: ui.TextDirection.ltr,
    );
    fullTextPainter.layout();

    // Add safety margin for spacing
    final safeMaxWidth = maxWidth - 16.0;

    if (fullTextPainter.width <= safeMaxWidth) {
      // Full address fits
      return Text(address, style: style, maxLines: 1, overflow: TextOverflow.clip);
    }

    // Need to truncate from the beginning
    final ellipsisPainter = TextPainter(
      text: TextSpan(text: '…', style: style),
      textDirection: ui.TextDirection.ltr,
    );
    ellipsisPainter.layout();
    final ellipsisWidth = ellipsisPainter.width;

    final availableForText = safeMaxWidth - ellipsisWidth;

    // Find how many chars from the END we can keep
    String bestText = '…';
    for (int i = 1; i <= address.length; i++) {
      final testSuffix = address.substring(address.length - i);
      final testPainter = TextPainter(
        text: TextSpan(text: testSuffix, style: style),
        textDirection: ui.TextDirection.ltr,
      );
      testPainter.layout();

      if (testPainter.width <= availableForText) {
        bestText = '…$testSuffix';
      } else {
        break;
      }
    }

    return Text(bestText, style: style, maxLines: 1, overflow: TextOverflow.clip);
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
                    ScaledSizedBox(height: 2),
                    Text(
                      'automaticIncome'.tr(),
                      style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
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
                builder: (context) => WalletViewScreen(address: transaction.address, username: transaction.username),
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
                builder: (context) => WalletViewScreen(address: transaction.address, username: transaction.username),
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
