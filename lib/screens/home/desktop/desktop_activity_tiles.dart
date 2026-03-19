import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/certification_display_item.dart';
import 'package:gecko/models/identity_display_item.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/screens/home/desktop/desktop_shared.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/utils/identity_utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/datapod_avatar.dart';

Widget buildCompactTransactionTile(BuildContext context, TransactionDisplayItem tx) {
  final isReceived = tx.isReceived;
  final amount = isReceived ? tx.amount : tx.amount * BigInt.from(-1);
  final amountColor = isReceived ? context.colorScheme.primary : context.geckoColors.info;

  // Universal dividend tile
  if (tx.type == TransactionType.universalDividend) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.water_drop, size: 16, color: context.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tx.udCount > 1 ? 'universalDividendCompact'.tr(args: ['${tx.udCount}']) : 'universalDividend'.tr(),
              style: scaledTextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          BalanceDisplay(value: tx.udCount > 1 ? tx.amount : amount, size: 13, color: context.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            desktopRelativeTime(context, tx.transactionTime),
            style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  // Migration tile
  if (tx.type == TransactionType.identityMigrationFrom || tx.type == TransactionType.identityMigrationTo) {
    final isMigFrom = tx.type == TransactionType.identityMigrationFrom;
    return buildClickableProfile(
      context,
      address: tx.address,
      username: tx.username,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.swap_horiz,
              size: 16,
              color: isMigFrom ? context.colorScheme.secondary : context.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMigFrom ? 'identityMigratedFrom'.tr() : 'identityMigratedTo'.tr(),
                    style: scaledTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (tx.username != null && tx.username!.isNotEmpty)
                    Text(
                      tx.username!,
                      style: scaledTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              desktopRelativeTime(context, tx.transactionTime),
              style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }

  // Normal transfer tile
  final String? username = tx.username == '' ? null : tx.username;
  final fromAddress = tx.fromAddress ?? tx.address;
  final toAddress = tx.toAddress ?? tx.address;
  final fromLabel = (tx.fromUsername?.isNotEmpty == true) ? tx.fromUsername! : getShortPubkey(fromAddress);
  final toLabel = (tx.toUsername?.isNotEmpty == true) ? tx.toUsername! : getShortPubkey(toAddress);
  final hasNetworkEndpoints = tx.fromAddress != null || tx.toAddress != null;

  if (hasNetworkEndpoints) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          DatapodAvatar(address: fromAddress, size: 28, name: tx.fromUsername),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: buildClickableProfile(
                        context,
                        address: fromAddress,
                        username: tx.fromUsername,
                        child: buildCompactProfileLabel(
                          context,
                          text: fromLabel,
                          isAddressLabel: tx.fromUsername == null,
                          style: scaledTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                            fontFamily: tx.fromUsername == null ? 'monospace' : null,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 26,
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    DatapodAvatar(address: toAddress, size: 28, name: tx.toUsername),
                    const SizedBox(width: 6),
                    Expanded(
                      child: buildClickableProfile(
                        context,
                        address: toAddress,
                        username: tx.toUsername,
                        child: buildCompactProfileLabel(
                          context,
                          text: toLabel,
                          isAddressLabel: tx.toUsername == null,
                          style: scaledTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                            fontFamily: tx.toUsername == null ? 'monospace' : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (tx.comment != null && tx.comment!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      tx.comment!,
                      style: scaledTextStyle(
                        fontSize: 11,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BalanceDisplay(value: amount, size: 13, color: amountColor),
                const SizedBox(height: 2),
                Text(
                  desktopRelativeTime(context, tx.transactionTime),
                  style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  return buildClickableProfile(
    context,
    address: tx.address,
    username: username,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          DatapodAvatar(address: tx.address, size: 28, name: username),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildCompactProfileLabel(
                  context,
                  text: username ?? getShortPubkey(tx.address),
                  isAddressLabel: username == null,
                  style: scaledTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                    fontFamily: username == null ? 'monospace' : null,
                  ),
                ),
                if (tx.comment != null && tx.comment!.isNotEmpty)
                  Text(
                    tx.comment!,
                    style: scaledTextStyle(
                      fontSize: 11,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              BalanceDisplay(value: amount, size: 13, color: amountColor),
              const SizedBox(height: 2),
              Text(
                desktopRelativeTime(context, tx.transactionTime),
                style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget buildCompactIdentityTile(BuildContext context, IdentityDisplayItem identity) {
  final accountId = identity.relevantAccountId;
  if (accountId == null) return const SizedBox.shrink();

  final isCreated = IdentityUtils.isCreatedStatusString(identity.status);
  final displayName = identity.name.isEmpty
      ? getShortPubkey(accountId)
      : IdentityUtils.getDisplayNameFromString(identity.name, identity.status);

  return buildClickableProfile(
    context,
    address: accountId,
    username: identity.name.isNotEmpty ? identity.name : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Avatar
          DatapodAvatar(address: accountId, size: 28, name: identity.name.isNotEmpty ? identity.name : null),
          const SizedBox(width: 8),
          // Name + status description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildCompactProfileLabel(
                  context,
                  text: displayName,
                  isAddressLabel: identity.name.isEmpty,
                  style: scaledTextStyle(
                    fontSize: 13,
                    fontWeight: isCreated ? FontWeight.w500 : FontWeight.w600,
                    fontStyle: isCreated ? FontStyle.italic : FontStyle.normal,
                    color: isCreated ? context.colorScheme.onSurfaceVariant : context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(identity.getStatusIcon(), size: 12, color: identity.getStatusColor(context.geckoColors)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        identity.displayStatus,
                        style: scaledTextStyle(
                          fontSize: 11,
                          color: identity.getStatusColor(context.geckoColors),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time
          Text(
            desktopRelativeTime(context, identity.timestamp),
            style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    ),
  );
}

Widget buildCompactCertificationTile(BuildContext context, CertificationDisplayItem cert) {
  final statusColor = cert.getStatusColor(context.geckoColors);
  final issuerName = cert.issuerName ?? getShortPubkey(cert.issuerAccountId);
  final receiverName = cert.receiverName ?? getShortPubkey(cert.receiverAccountId);
  return LayoutBuilder(
    builder: (context, constraints) {
      final timeColumnWidth = (constraints.maxWidth * 0.22).clamp(112.0, 168.0);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: buildClickableProfile(
                      context,
                      address: cert.issuerAccountId,
                      username: cert.issuerName,
                      child: Row(
                        children: [
                          DatapodAvatar(address: cert.issuerAccountId, size: 20, name: issuerName),
                          const SizedBox(width: 10),
                          Expanded(
                            child: buildCompactProfileLabel(
                              context,
                              text: issuerName,
                              isAddressLabel: cert.issuerName == null,
                              style: scaledTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  Expanded(
                    child: buildClickableProfile(
                      context,
                      address: cert.receiverAccountId,
                      username: cert.receiverName,
                      child: Row(
                        children: [
                          DatapodAvatar(address: cert.receiverAccountId, size: 20, name: receiverName),
                          const SizedBox(width: 10),
                          Expanded(
                            child: buildCompactProfileLabel(
                              context,
                              text: receiverName,
                              isAddressLabel: cert.receiverName == null,
                              style: scaledTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: timeColumnWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    desktopRelativeTime(context, cert.timestamp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
                  if (cert.expirationText != null && !cert.isExpired)
                    Text(
                      cert.expirationText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: scaledTextStyle(fontSize: 10, color: context.geckoColors.warning),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
