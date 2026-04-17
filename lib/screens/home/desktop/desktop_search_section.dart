import 'dart:io' show Platform;

import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/cesium_plus_search_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/search_provider.dart';
import 'package:gecko/screens/home/desktop/desktop_shared.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/datapod_avatar.dart';

class DesktopSearchSection extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ScrollController searchScrollController;
  final VoidCallback onFocusDesktopHomeShell;
  final VoidCallback onToggleContactsPanel;
  final VoidCallback onToggleActivityPanel;
  final bool isContactsPanelOpen;
  final bool isActivityPanelOpen;

  const DesktopSearchSection({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchScrollController,
    required this.onFocusDesktopHomeShell,
    required this.onToggleContactsPanel,
    required this.onToggleActivityPanel,
    required this.isContactsPanelOpen,
    required this.isActivityPanelOpen,
  });

  @override
  ConsumerState<DesktopSearchSection> createState() => _DesktopSearchSectionState();
}

class _DesktopSearchSectionState extends ConsumerState<DesktopSearchSection> {
  int _highlightedSearchIndex = -1;

  String get _searchShortcutLabel {
    if (!kIsWeb && Platform.isMacOS) {
      return '\u2318K';
    }
    return 'Ctrl+K';
  }

  List<DesktopSearchSuggestion> _buildSearchSuggestions({
    required List<d.IdentitySuggestion> identities,
    required List<d.WalletEntity> addresses,
    required List<CesiumPlusSearchResult> cesiumPlusResults,
  }) {
    final seen = <String>{};
    final suggestions = <DesktopSearchSuggestion>[];

    for (final wallet in addresses) {
      if (seen.add(wallet.address)) {
        suggestions.add(
          DesktopSearchSuggestion(
            address: wallet.address,
            username: WalletNameService.displayName(wallet.name),
            type: DesktopSearchSuggestionType.address,
          ),
        );
      }
    }

    for (final identity in identities) {
      if (seen.add(identity.address)) {
        suggestions.add(
          DesktopSearchSuggestion(
            address: identity.address,
            username: identity.name,
            type: DesktopSearchSuggestionType.identity,
          ),
        );
      }
    }

    for (final cs in cesiumPlusResults) {
      if (seen.add(cs.address)) {
        suggestions.add(
          DesktopSearchSuggestion(
            address: cs.address,
            username: cs.title,
            type: DesktopSearchSuggestionType.cesiumPlus,
          ),
        );
      }
    }

    return suggestions;
  }

  void _moveSearchHighlight(int delta, int suggestionCount) {
    if (suggestionCount == 0) return;
    setState(() {
      final nextIndex = _highlightedSearchIndex + delta;
      if (nextIndex < 0) {
        _highlightedSearchIndex = suggestionCount - 1;
      } else if (nextIndex >= suggestionCount) {
        _highlightedSearchIndex = 0;
      } else {
        _highlightedSearchIndex = nextIndex;
      }
    });

    // Item height: 10px padding top + 38px avatar + 10px padding bottom + 2px border + 6px separator = 66px
    final targetOffset = (_highlightedSearchIndex * 66).toDouble();
    if (widget.searchScrollController.hasClients) {
      widget.searchScrollController.animateTo(
        targetOffset.clamp(0, widget.searchScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  void _openSearchSuggestion(BuildContext context, DesktopSearchSuggestion suggestion) {
    NavigationService.openProfile(
      context,
      address: suggestion.address,
      username: suggestion.username?.isNotEmpty == true ? suggestion.username : null,
    );
  }

  KeyEventResult _handleDesktopSearchKeyEvent(
    BuildContext context,
    KeyEvent event,
    List<DesktopSearchSuggestion> suggestions,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _moveSearchHighlight(1, suggestions.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _moveSearchHighlight(-1, suggestions.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
        if (suggestions.isEmpty) return KeyEventResult.ignored;
        final index = _highlightedSearchIndex >= 0 ? _highlightedSearchIndex : 0;
        _openSearchSuggestion(context, suggestions[index]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        widget.searchFocusNode.unfocus();
        setState(() {
          _highlightedSearchIndex = -1;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onFocusDesktopHomeShell();
        });
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  void didUpdateWidget(covariant DesktopSearchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset highlight when search text changes (driven by parent ListenableBuilder)
    if (_highlightedSearchIndex != -1) {
      _highlightedSearchIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.searchController.text.trim();
    final isFocused = widget.searchFocusNode.hasFocus;
    final addressResultsAsync = ref.watch(searchResultsProvider);
    final identityResultsAsync = query.length >= 2
        ? ref.watch(searchIdentityProvider(query))
        : const AsyncValue<List<d.IdentitySuggestion>>.data([]);
    final cesiumPlusResultsAsync = query.length >= 2
        ? ref.watch(cesiumPlusSearchProvider(query))
        : const AsyncValue<List<CesiumPlusSearchResult>>.data([]);
    final rawCesiumPlusResults = switch (cesiumPlusResultsAsync) {
      AsyncData(:final value) => value,
      _ => const <CesiumPlusSearchResult>[],
    };
    // Hide self-declared wallets that are empty — noise in search results.
    final cesiumPlusResults = filterOutEmptyCesiumPlusResults(ref, rawCesiumPlusResults);

    final addressResults = switch (addressResultsAsync) {
      AsyncData(:final value) =>
        value
            .map(
              (wallet) => d.WalletEntity.create(
                address: wallet.address,
                name: wallet.username,
                keyPairType: d.Durt.defaultKeyPairType,
              ),
            )
            .toList(),
      _ => const <d.WalletEntity>[],
    };
    final identityResults = switch (identityResultsAsync) {
      AsyncData(:final value) => value.cast<d.IdentitySuggestion>(),
      _ => const <d.IdentitySuggestion>[],
    };
    final suggestions = query.length >= 2
        ? _buildSearchSuggestions(
            identities: identityResults,
            addresses: addressResults,
            cesiumPlusResults: cesiumPlusResults,
          )
        : const <DesktopSearchSuggestion>[];
    final hasSuggestions = suggestions.isNotEmpty;
    final isLoading = query.length >= 2 && (addressResultsAsync.isLoading || identityResultsAsync.isLoading);
    final showDropdown = isFocused && query.length >= 2;

    if (_highlightedSearchIndex >= suggestions.length && _highlightedSearchIndex != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _highlightedSearchIndex = suggestions.isEmpty ? -1 : 0;
          });
        }
      });
    }

    final searchBar = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        children: [
          Focus(
            onKeyEvent: (node, event) => _handleDesktopSearchKeyEvent(context, event, suggestions),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colorScheme.surface.withValues(alpha: 0.96),
                    context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.86),
                  ],
                ),
                borderRadius: BorderRadius.circular(showDropdown ? 26 : 24),
                border: Border.all(
                  color: isFocused
                      ? context.colorScheme.primary.withValues(alpha: 0.35)
                      : context.colorScheme.outline.withValues(alpha: 0.1),
                  width: isFocused ? 1.2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFocused
                        ? context.colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: isFocused ? 24 : 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: context.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.search_rounded, color: context.colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: widget.searchController,
                            focusNode: widget.searchFocusNode,
                            autofocus: false,
                            maxLines: 1,
                            textInputAction: TextInputAction.search,
                            onTapOutside: (_) {
                              widget.searchFocusNode.unfocus();
                              widget.onFocusDesktopHomeShell();
                            },
                            onSubmitted: (_) {
                              if (suggestions.isEmpty) return;
                              final index = _highlightedSearchIndex >= 0 ? _highlightedSearchIndex : 0;
                              _openSearchSuggestion(context, suggestions[index]);
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'desktopSearchIdentityPlaceholder'.tr(),
                              hintStyle: scaledTextStyle(
                                fontSize: 15,
                                color: context.colorScheme.onSurface.withValues(alpha: 0.38),
                              ),
                              border: InputBorder.none,
                            ),
                            style: scaledTextStyle(
                              fontSize: 15,
                              color: context.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.searchController.text.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              widget.searchController.clear();
                              widget.searchFocusNode.requestFocus();
                            },
                            splashRadius: 18,
                            icon: Icon(Icons.close_rounded, size: 20, color: context.colorScheme.onSurfaceVariant),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _searchShortcutLabel,
                              style: scaledTextStyle(
                                fontSize: 11,
                                color: context.colorScheme.onSurface.withValues(alpha: 0.52),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: !showDropdown
                        ? const SizedBox.shrink()
                        : Container(
                            key: ValueKey('${query}_${suggestions.length}_$isLoading'),
                            constraints: const BoxConstraints(maxHeight: 320),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.08)),
                              ),
                            ),
                            child: isLoading
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: context.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : !hasSuggestions
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    child: Text(
                                      'noResult'.tr(),
                                      textAlign: TextAlign.center,
                                      style: scaledTextStyle(
                                        fontSize: 12,
                                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: widget.searchScrollController,
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.all(10),
                                    itemCount: suggestions.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final suggestion = suggestions[index];
                                      return _buildDesktopSearchSuggestionTile(
                                        context,
                                        suggestion: suggestion,
                                        isHighlighted: index == _highlightedSearchIndex,
                                        onTap: () => _openSearchSuggestion(context, suggestion),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Row(
      children: [
        _buildContactsToggleButton(context),
        const SizedBox(width: 10),
        Expanded(child: searchBar),
        const SizedBox(width: 10),
        _buildActivityToggleButton(context),
      ],
    );
  }

  Widget _buildContactsToggleButton(BuildContext context) {
    final isVisuallyActive = widget.isContactsPanelOpen;
    return Tooltip(
      message: 'contactsManagement'.tr(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onToggleContactsPanel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: isVisuallyActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colorScheme.primary.withValues(alpha: 0.18),
                        context.colorScheme.primary.withValues(alpha: 0.10),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colorScheme.surface.withValues(alpha: 0.96),
                        context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.86),
                      ],
                    ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isVisuallyActive
                    ? context.colorScheme.primary.withValues(alpha: 0.4)
                    : context.colorScheme.outline.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isVisuallyActive
                      ? context.colorScheme.primary.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isVisuallyActive ? Icons.people_rounded : Icons.people_outline_rounded,
              size: 24,
              color: isVisuallyActive
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityToggleButton(BuildContext context) {
    final isVisuallyActive = widget.isActivityPanelOpen;
    return Tooltip(
      message: 'networkActivity'.tr(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onToggleActivityPanel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: isVisuallyActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colorScheme.primary.withValues(alpha: 0.18),
                        context.colorScheme.primary.withValues(alpha: 0.10),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colorScheme.surface.withValues(alpha: 0.96),
                        context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.86),
                      ],
                    ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isVisuallyActive
                    ? context.colorScheme.primary.withValues(alpha: 0.4)
                    : context.colorScheme.outline.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isVisuallyActive
                      ? context.colorScheme.primary.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isVisuallyActive ? Icons.timeline_rounded : Icons.timeline_rounded,
              size: 24,
              color: isVisuallyActive
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSearchSuggestionTile(
    BuildContext context, {
    required DesktopSearchSuggestion suggestion,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    final title = suggestion.username?.isNotEmpty == true ? suggestion.username! : getShortPubkey(suggestion.address);
    final subtitle = suggestion.username?.isNotEmpty == true ? getShortPubkey(suggestion.address) : suggestion.address;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isHighlighted
                ? context.colorScheme.primary.withValues(alpha: 0.1)
                : context.colorScheme.surface.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? context.colorScheme.primary.withValues(alpha: 0.22)
                  : context.colorScheme.outline.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              DatapodAvatar(address: suggestion.address, size: 38, name: suggestion.username),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: scaledTextStyle(
                              fontSize: 13,
                              color: context.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontStyle: suggestion.type == DesktopSearchSuggestionType.cesiumPlus
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            final isCesiumPlus = suggestion.type == DesktopSearchSuggestionType.cesiumPlus;
                            final isIdentity = suggestion.type == DesktopSearchSuggestionType.identity;
                            final pillBgColor = isIdentity
                                ? context.colorScheme.primary.withValues(alpha: 0.12)
                                : isCesiumPlus
                                ? context.geckoColors.warning.withValues(alpha: 0.18)
                                : context.colorScheme.surfaceContainerHigh;
                            final pillFgColor = isIdentity
                                ? context.colorScheme.primary
                                : isCesiumPlus
                                ? context.geckoColors.warning
                                : context.colorScheme.onSurface.withValues(alpha: 0.7);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: pillBgColor,
                                borderRadius: BorderRadius.circular(999),
                                border: isCesiumPlus
                                    ? Border.all(color: context.geckoColors.warning.withValues(alpha: 0.7), width: 1)
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCesiumPlus) ...[
                                    Icon(Icons.warning_amber_rounded, size: scaleSize(11), color: pillFgColor),
                                    SizedBox(width: scaleSize(3)),
                                  ],
                                  Text(
                                    isIdentity
                                        ? 'desktopIdentityShortLabel'.tr()
                                        : isCesiumPlus
                                        ? 'selfDeclaredName'.tr()
                                        : 'desktopWalletShortLabel'.tr(),
                                    style: scaledTextStyle(
                                      fontSize: 10,
                                      color: pillFgColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: scaledTextStyle(
                        fontSize: 10.5,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.46),
                        fontFamily: 'Monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Balance(address: suggestion.address, size: 12, color: context.colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}
