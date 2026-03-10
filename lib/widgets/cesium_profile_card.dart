import 'dart:ui' as ui;

import 'package:durt2/durt2.dart' show CesiumSocial;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/cesium_profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CesiumProfileCard extends ConsumerWidget {
  const CesiumProfileCard({required this.address, super.key});
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(cesiumProfileProvider(address));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

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

          if (!hasContent) return const SizedBox.shrink();

          return _buildCard(context, description: description, city: city, socials: socials, tags: tags);
        } catch (_) {
          return _buildErrorCard(context);
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _buildErrorCard(context),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    String? description,
    String? city,
    required List<CesiumSocial> socials,
    required List<String> tags,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: 1.0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(scaleSize(14)),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null && description.isNotEmpty) _ExpandableDescription(description: description),
                if (city != null && city.isNotEmpty) ...[
                  if (description != null && description.isNotEmpty) SizedBox(height: scaleSize(10)),
                  _CityRow(city: city),
                ],
                if (tags.isNotEmpty) ...[SizedBox(height: scaleSize(10)), _TagsWrap(tags: tags)],
                if (socials.isNotEmpty) ...[SizedBox(height: scaleSize(10)), _SocialList(socials: socials)],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
      child: Text(
        'profileLoadFailed'.tr(),
        style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurfaceVariant),
      ),
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
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.description});
  final String description;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Text(
            widget.description,
            style: scaledTextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(widget.description, style: scaledTextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
        ),
        if (_needsExpansion(context))
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.only(top: scaleSize(4)),
              child: Text(
                _expanded ? 'showLess'.tr() : 'showMore'.tr(),
                style: scaledTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colorScheme.primary),
              ),
            ),
          ),
      ],
    );
  }

  bool _needsExpansion(BuildContext context) {
    final span = TextSpan(
      text: widget.description,
      style: scaledTextStyle(fontSize: 13, fontStyle: FontStyle.italic),
    );
    final tp = TextPainter(text: span, maxLines: 3, textDirection: ui.TextDirection.ltr);
    // Use available width minus card padding (14*2) and screen margin (16*2)
    final maxWidth = MediaQuery.of(context).size.width - scaleSize(60);
    tp.layout(maxWidth: maxWidth);
    return tp.didExceedMaxLines;
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({required this.city});
  final String city;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: scaleSize(16), color: context.colorScheme.onSurfaceVariant),
        SizedBox(width: scaleSize(6)),
        Flexible(
          child: Text(
            city,
            style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TagsWrap extends StatelessWidget {
  const _TagsWrap({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: scaleSize(6),
      runSpacing: scaleSize(4),
      children: tags
          .map(
            (tag) => Chip(
              label: Text(tag, style: scaledTextStyle(fontSize: 11)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.symmetric(horizontal: scaleSize(4)),
            ),
          )
          .toList(),
    );
  }
}

class _SocialList extends StatelessWidget {
  const _SocialList({required this.socials});
  final List<CesiumSocial> socials;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: socials.map((social) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _launchUrl(social.url),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: scaleSize(4)),
            child: Row(
              children: [
                Icon(_getSocialIcon(social.type), size: scaleSize(18), color: context.colorScheme.onSurfaceVariant),
                SizedBox(width: scaleSize(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSocialLabel(social.type),
                        style: scaledTextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        social.url,
                        style: scaledTextStyle(fontSize: 11, color: context.colorScheme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new, size: scaleSize(14), color: context.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        );
      }).toList(),
    );
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

  Future<void> _launchUrl(String url) async {
    String safeUrl = url;
    if (!safeUrl.startsWith('http://') && !safeUrl.startsWith('https://')) {
      safeUrl = 'https://$safeUrl';
    }
    final uri = Uri.tryParse(safeUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
