import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/datapod_avatar.dart';

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

  void _openProfile(BuildContext context, {required String address, String? username}) {
    NavigationService.openProfile(context, address: address, username: username, fromAddress: viewingAddress);
  }

  @override
  Widget build(BuildContext context) {
    final newKey = keyID + 1;
    final String? username = transaction.username == '' ? null : transaction.username;
    final BigInt finalAmount = transaction.isReceived ? transaction.amount : transaction.amount * BigInt.from(-1);

    // Different UI for Universal Dividends
    if (transaction.type == TransactionType.universalDividend) {
      if (transaction.udCount > 1) {
        return ExpandableUdTile(transaction: transaction, keyID: newKey);
      }
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
          onTap: () => _openProfile(context, address: transaction.address, username: username),
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
                                  safeLocale(Localizations.localeOf(context).languageCode),
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
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

  /// Build a modern tile for a single Universal Dividend
  Widget _buildUniversalDividendTile(BuildContext context, int newKey, BigInt finalAmount) {
    final locale = safeLocale(Localizations.localeOf(context).languageCode);

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
              Expanded(
                child: Text(
                  'universalDividend'.tr(),
                  style: scaledTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BalanceDisplay(value: finalAmount, size: 16, color: context.colorScheme.primary),
                  ScaledSizedBox(height: 4),
                  Text(
                    DateFormat.MMMd(locale).format(transaction.transactionTime),
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
          onTap: () => _openProfile(context, address: transaction.address, username: transaction.username),
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
                      DateFormat.MMMd(
                        safeLocale(Localizations.localeOf(context).languageCode),
                      ).format(transaction.transactionTime),
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
          onTap: () => _openProfile(context, address: transaction.address, username: transaction.username),
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
                      DateFormat.MMMd(
                        safeLocale(Localizations.localeOf(context).languageCode),
                      ).format(transaction.transactionTime),
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

/// Expandable tile for merged consecutive Universal Dividends.
/// Tapping the header toggles inline expansion of individual UDs.
class ExpandableUdTile extends StatefulWidget {
  const ExpandableUdTile({super.key, required this.transaction, required this.keyID});

  final TransactionDisplayItem transaction;
  final int keyID;

  @override
  State<ExpandableUdTile> createState() => _ExpandableUdTileState();
}

class _ExpandableUdTileState extends State<ExpandableUdTile> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final locale = safeLocale(Localizations.localeOf(context).languageCode);
    final udItems = tx.udItems ?? [];

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
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header tile (tappable)
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(scaleSize(12)),
              child: Padding(
                padding: EdgeInsets.all(scaleSize(12)),
                child: Row(
                  children: [
                    // Icon with count badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
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
                        Positioned(
                          right: scaleSize(-4),
                          top: scaleSize(-4),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: scaleSize(5), vertical: scaleSize(1)),
                            decoration: BoxDecoration(
                              color: context.colorScheme.primary,
                              borderRadius: BorderRadius.circular(scaleSize(10)),
                            ),
                            child: Text(
                              '×${tx.udCount}',
                              style: scaledTextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    ScaledSizedBox(width: 12),

                    // Label + date range
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'universalDividendCompact'.tr(args: ['${tx.udCount}']),
                                  style: scaledTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              ScaledSizedBox(width: 4),
                              RotationTransition(
                                turns: _rotationAnimation,
                                child: Icon(
                                  Icons.chevron_right,
                                  size: scaleSize(18),
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          ScaledSizedBox(height: 2),
                          Text(
                            _formatUdDateRange(udItems, locale),
                            style: scaledTextStyle(
                              fontSize: 12,
                              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Total amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        BalanceDisplay(value: tx.amount, size: 16, color: context.colorScheme.primary),
                        ScaledSizedBox(height: 4),
                        Text(
                          'total'.tr(),
                          style: scaledTextStyle(
                            fontSize: 11,
                            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expandable individual UDs
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(
                    height: 1,
                    indent: scaleSize(16),
                    endIndent: scaleSize(16),
                    color: context.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  ...udItems.map(
                    (ud) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(3)),
                      child: Row(
                        children: [
                          ScaledSizedBox(width: 16),
                          Container(
                            width: scaleSize(6),
                            height: scaleSize(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          ScaledSizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat.yMMMd(locale).format(ud.transactionTime),
                              style: scaledTextStyle(
                                fontSize: 13,
                                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          BalanceDisplay(value: ud.amount, size: 13, color: context.colorScheme.primary),
                          ScaledSizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                  ScaledSizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatUdDateRange(List<TransactionDisplayItem> udItems, String locale) {
    if (udItems.isEmpty) return '';
    final oldest = udItems.last.transactionTime;
    final newest = udItems.first.transactionTime;
    final dateFormat = DateFormat.MMMd(locale);
    return '${dateFormat.format(oldest)} — ${dateFormat.format(newest)}';
  }
}
