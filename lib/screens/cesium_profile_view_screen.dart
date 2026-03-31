import 'package:durt2/durt2.dart' show CesiumSocial;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/cesium_name_provider.dart';
import 'package:gecko/providers/cesium_profile_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/name_source_badge.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:url_launcher/url_launcher.dart';

class CesiumProfileViewScreen extends ConsumerWidget {
  const CesiumProfileViewScreen({required this.address, this.embeddedMode = false, super.key});
  final String address;
  final bool embeddedMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(cesiumProfileProvider(address));
    final identityNameAsync = ref.watch(hybridIdentityNameProvider(address));
    final displayName = identityNameAsync.hasValue ? identityNameAsync.value : null;

    // Determine if this is an identity name or CesiumPlus name
    final hasIdentityName = identityNameAsync.hasValue && identityNameAsync.value != null;

    // If no identity name, try CesiumPlus name from profile title
    final csNameAsync = ref.watch(cesiumNameProvider(address));
    final csName = csNameAsync.hasValue ? csNameAsync.value : null;
    final effectiveDisplayName = displayName ?? csName;

    // Check for CesiumPlus name conflicting with an on-chain identity
    final conflictAddress = (!hasIdentityName && csName != null)
        ? ref.watch(cesiumNameConflictProvider(address)).asData?.value
        : null;

    final content = ResponsiveCenter(
      maxWidth: 600,
      padding: EdgeInsets.zero,
      child: profileAsync.when(
        data: (profile) {
          if (profile == null) return _buildEmptyState(context);

          try {
            final description = profile['description']?.toString();
            final city = profile['city']?.toString();
            final socials = _parseSocials(profile['socials']);
            final tags = _parseTags(profile['tags']);

            final hasContent =
                (description != null && description.isNotEmpty) ||
                (city != null && city.isNotEmpty) ||
                socials.isNotEmpty ||
                tags.isNotEmpty;

            if (!hasContent) return _buildEmptyState(context);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(16)),
              child: Column(
                children: [
                  // Header: avatar + name
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: scaleSize(100),
                          height: scaleSize(100),
                          child: ClipOval(
                            child: DatapodAvatar(address: address, size: 100, name: effectiveDisplayName),
                          ),
                        ),
                        if (effectiveDisplayName != null && effectiveDisplayName.isNotEmpty) ...[
                          ScaledSizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  effectiveDisplayName,
                                  style: scaledTextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: hasIdentityName ? FontStyle.normal : FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              ScaledSizedBox(width: 6),
                              NameSourceBadge(source: hasIdentityName ? NameSource.identity : NameSource.cesiumPlus),
                            ],
                          ),
                        ],
                        if (!hasIdentityName && effectiveDisplayName != null) ...[
                          ScaledSizedBox(height: 4),
                          Text(
                            'selfDeclaredNameLabel'.tr(),
                            style: scaledTextStyle(
                              fontSize: 12,
                              color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        ScaledSizedBox(height: 4),
                        Text(
                          getShortPubkey(address),
                          style: scaledTextStyle(
                            fontSize: 14,
                            fontFamily: 'Monospace',
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (conflictAddress != null) ...[
                          ScaledSizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: scaleSize(10), vertical: scaleSize(6)),
                            decoration: BoxDecoration(
                              color: context.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: scaleSize(16), color: context.colorScheme.error),
                                ScaledSizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'nameConflictWarning'.tr(args: [csName!, getShortPubkey(conflictAddress)]),
                                    style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onErrorContainer),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ScaledSizedBox(height: 24),
                  // Description
                  if (description != null && description.isNotEmpty)
                    _buildSection(
                      context,
                      icon: Icons.description_outlined,
                      title: 'description'.tr(),
                      child: Text(description, style: scaledTextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                    ),
                  // City
                  if (city != null && city.isNotEmpty) ...[
                    ScaledSizedBox(height: 12),
                    _buildSection(
                      context,
                      icon: Icons.location_on_outlined,
                      title: 'city'.tr(),
                      child: Text(city, style: scaledTextStyle(fontSize: 14)),
                    ),
                  ],
                  // Tags
                  if (tags.isNotEmpty) ...[
                    ScaledSizedBox(height: 12),
                    _buildSection(
                      context,
                      icon: Icons.label_outline,
                      title: 'tags'.tr(),
                      child: Wrap(
                        spacing: scaleSize(6),
                        runSpacing: scaleSize(4),
                        children: tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag, style: scaledTextStyle(fontSize: 12)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.symmetric(horizontal: scaleSize(4)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  // Social links
                  if (socials.isNotEmpty) ...[
                    ScaledSizedBox(height: 12),
                    _buildSection(
                      context,
                      icon: Icons.share_outlined,
                      title: 'socialNetworks'.tr(),
                      child: Column(
                        children: socials.map((social) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _confirmAndLaunchUrl(context, social.url),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: scaleSize(6)),
                              child: Row(
                                children: [
                                  Icon(
                                    _getSocialIcon(social.type),
                                    size: scaleSize(20),
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(width: scaleSize(10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getSocialLabel(social.type),
                                          style: scaledTextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          social.url,
                                          style: scaledTextStyle(fontSize: 12, color: context.colorScheme.primary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.open_in_new,
                                    size: scaleSize(16),
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          } catch (_) {
            return _buildErrorState(context);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildErrorState(context),
      ),
    );

    if (embeddedMode) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text('viewProfile'.tr())),
      body: content,
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required Widget child}) {
    return Card(
      elevation: 0,
      color: context.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(scaleSize(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: scaleSize(18), color: context.colorScheme.onSurfaceVariant),
                SizedBox(width: scaleSize(8)),
                Text(
                  title,
                  style: scaledTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: scaleSize(10)),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: scaleSize(64),
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          ScaledSizedBox(height: 16),
          Text(
            'noProfileAvailable'.tr(),
            style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Text('profileLoadFailed'.tr(), style: scaledTextStyle(fontSize: 14, color: context.colorScheme.error)),
    );
  }

  List<CesiumSocial> _parseSocials(dynamic raw) {
    if (raw == null || raw is! List) return [];
    final result = <CesiumSocial>[];
    for (final s in raw) {
      if (s is! Map<String, dynamic>) continue;
      final url = s['url'] as String?;
      if (url == null || url.isEmpty) continue;
      final type = s['type'] as String? ?? 'web';
      result.add(CesiumSocial(type: type, url: url));
    }
    return result;
  }

  List<String> _parseTags(dynamic raw) {
    if (raw == null || raw is! List) return [];
    return raw.whereType<String>().where((t) => t.isNotEmpty).toList();
  }

  String _getSocialLabel(String type) {
    switch (type.toLowerCase()) {
      case 'twitter':
      case 'x':
        return 'X (Twitter)';
      case 'facebook':
        return 'Facebook';
      case 'diaspora':
        return 'Diaspora';
      case 'mastodon':
        return 'Mastodon';
      case 'github':
        return 'GitHub';
      case 'linkedin':
        return 'LinkedIn';
      case 'telegram':
        return 'Telegram';
      default:
        return type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : 'Link';
    }
  }

  IconData _getSocialIcon(String type) {
    switch (type.toLowerCase()) {
      case 'twitter':
      case 'x':
        return Icons.close;
      case 'facebook':
        return Icons.facebook;
      case 'diaspora':
      case 'mastodon':
        return Icons.public;
      case 'github':
        return Icons.code;
      case 'linkedin':
        return Icons.business;
      case 'telegram':
        return Icons.send;
      default:
        return Icons.link;
    }
  }

  Future<void> _confirmAndLaunchUrl(BuildContext context, String url) async {
    String safeUrl = url;
    if (!safeUrl.startsWith('http://') && !safeUrl.startsWith('https://')) {
      safeUrl = 'https://$safeUrl';
    }
    final uri = Uri.tryParse(safeUrl);
    if (uri == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.open_in_new, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('externalLinkTitle'.tr())),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('externalLinkWarning'.tr()),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                safeUrl,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Monospace',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('openLink'.tr())),
        ],
      ),
    );

    if (confirmed == true) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
