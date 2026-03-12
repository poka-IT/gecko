// ignore_for_file: use_build_context_synchronously

import 'dart:io' show Platform;

import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/services/image_cache_service.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/network_activity_provider.dart';
import 'package:gecko/providers/network_certifications_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/network_identities_provider.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/providers/safe_data_provider.dart';
import 'package:gecko/providers/search_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/myWallets/switch_safe.dart';
import 'package:gecko/screens/profile_view.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/animated_header_image.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/buttons/home_settings_button.dart';
import 'package:gecko/widgets/bottom_sheets/safe_options_menu.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/easter_egg_detector.dart';
import 'package:gecko/widgets/drag_tule_action.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/identity_display_item.dart';
import 'package:gecko/models/certification_display_item.dart';
import 'package:gecko/utils/identity_utils.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Desktop home layout for wide screens (>= 900px)
/// Two-panel layout: branding + activity on left, dashboard on right
class DesktopHomeWidget extends ConsumerStatefulWidget {
  final bool isEasterEggActive;
  final ValueChanged<bool> onEasterEggStateChange;

  const DesktopHomeWidget({super.key, required this.isEasterEggActive, required this.onEasterEggStateChange});

  @override
  ConsumerState<DesktopHomeWidget> createState() => _DesktopHomeWidgetState();
}

class _DesktopHomeWidgetState extends ConsumerState<DesktopHomeWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<ScrollController> _scrollControllers;
  late TextEditingController _desktopSearchController;
  late FocusNode _desktopSearchFocusNode;
  late FocusNode _desktopHomeFocusNode;
  late ScrollController _desktopSearchScrollController;
  final EasterEggController _easterEggController = EasterEggController();
  int _activeActivityTabIndex = 0;
  int _highlightedSearchIndex = -1;

  String get _searchShortcutLabel {
    if (!kIsWeb && Platform.isMacOS) {
      return 'Cmd+K';
    }
    return 'Ctrl+K';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollControllers = List.generate(3, (_) => ScrollController());
    _desktopSearchController = TextEditingController();
    _desktopSearchFocusNode = FocusNode();
    _desktopHomeFocusNode = FocusNode(debugLabel: 'desktop_home_shortcuts');
    _desktopSearchScrollController = ScrollController();
    _tabController.addListener(_handleActivityTabChange);
    for (final sc in _scrollControllers) {
      sc.addListener(_onScroll);
    }
    _desktopSearchController.addListener(_onDesktopSearchChanged);
    _desktopSearchFocusNode.addListener(_onDesktopSearchFocusChanged);
  }

  @override
  void dispose() {
    for (final sc in _scrollControllers) {
      sc.removeListener(_onScroll);
      sc.dispose();
    }
    _desktopSearchController.removeListener(_onDesktopSearchChanged);
    _desktopSearchController.dispose();
    _desktopSearchFocusNode.removeListener(_onDesktopSearchFocusChanged);
    _desktopSearchFocusNode.dispose();
    _desktopHomeFocusNode.dispose();
    _desktopSearchScrollController.dispose();
    _tabController.removeListener(_handleActivityTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleActivityTabChange() {
    if (_tabController.indexIsChanging || _activeActivityTabIndex != _tabController.index) {
      setState(() {
        _activeActivityTabIndex = _tabController.index;
      });
    }
  }

  void _onDesktopSearchChanged() {
    ref.read(searchTextProvider.notifier).set(_desktopSearchController.text);
    if (_highlightedSearchIndex != -1) {
      setState(() {
        _highlightedSearchIndex = -1;
      });
    } else {
      setState(() {});
    }
  }

  void _onDesktopSearchFocusChanged() {
    setState(() {});
  }

  void _onScroll() {
    final sc = _scrollControllers[_tabController.index];
    if (!sc.hasClients) return;
    if (sc.position.pixels < sc.position.maxScrollExtent * 0.7) return;

    switch (_tabController.index) {
      case 0:
        loadMoreNetworkTransactions(ref);
        break;
      case 1:
        loadMoreNetworkIdentities(ref);
        break;
      case 2:
        loadMoreNetworkCertifications(ref);
        break;
    }
  }

  Future<void> _openQrScanner(BuildContext context) async {
    final scanQr = ref.read(qrScanProvider);
    await scanQr(context);
  }

  void _openSafeSwitcher(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SwitchSafe()));
  }

  void _openSafeOptions(BuildContext context) {
    showSafeOptionsMenu(context);
  }

  void _focusDesktopHomeShell() {
    if (!_desktopHomeFocusNode.hasFocus) {
      _desktopHomeFocusNode.requestFocus();
    }
  }

  KeyEventResult _handleDesktopHomeKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _desktopSearchFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _easterEggController.addInput(TapSide.left);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _easterEggController.addInput(TapSide.right);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  List<_DesktopSearchSuggestion> _buildSearchSuggestions({
    required List<d.IdentitySuggestion> identities,
    required List<d.WalletEntity> addresses,
  }) {
    final seen = <String>{};
    final suggestions = <_DesktopSearchSuggestion>[];

    for (final wallet in addresses) {
      if (seen.add(wallet.address)) {
        suggestions.add(
          _DesktopSearchSuggestion(
            address: wallet.address,
            username: wallet.name,
            type: _DesktopSearchSuggestionType.address,
          ),
        );
      }
    }

    for (final identity in identities) {
      if (seen.add(identity.address)) {
        suggestions.add(
          _DesktopSearchSuggestion(
            address: identity.address,
            username: identity.name,
            type: _DesktopSearchSuggestionType.identity,
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

    final targetOffset = (_highlightedSearchIndex * 76).toDouble();
    if (_desktopSearchScrollController.hasClients) {
      _desktopSearchScrollController.animateTo(
        targetOffset.clamp(0, _desktopSearchScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  void _openSearchSuggestion(BuildContext context, _DesktopSearchSuggestion suggestion) {
    _pushDesktopProfileRoute(context, address: suggestion.address, username: suggestion.username);
  }

  void _pushDesktopProfileRoute(BuildContext context, {required String address, String? username}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProfileViewScreen(address: address, username: username?.isNotEmpty == true ? username : null),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: Tween<double>(begin: 0.985, end: 1).animate(curved), child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  KeyEventResult _handleDesktopSearchKeyEvent(
    BuildContext context,
    KeyEvent event,
    List<_DesktopSearchSuggestion> suggestions,
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
        _desktopSearchFocusNode.unfocus();
        setState(() {
          _highlightedSearchIndex = -1;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusDesktopHomeShell();
        });
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showImage = ref.watch(backgroundImageProvider);
    final imageCache = ImageCacheService();
    final view = View.of(context);
    final screenSize = view.physicalSize / view.devicePixelRatio;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _focusDesktopHomeShell,
      child: Focus(
        autofocus: true,
        focusNode: _desktopHomeFocusNode,
        onKeyEvent: _handleDesktopHomeKeyEvent,
        child: EasterEggDetector(
          controller: _easterEggController,
          onPlayingStateChanged: widget.onEasterEggStateChange,
          child: Stack(
            children: [
              // Background layer
              Positioned(
                top: 0,
                left: 0,
                width: screenSize.width,
                height: screenSize.height,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-0.9, -1),
                      end: const Alignment(1, 1),
                      colors: [
                        context.colorScheme.surface,
                        Color.lerp(context.colorScheme.surface, context.colorScheme.primary, 0.08)!,
                        Color.lerp(context.colorScheme.surface, context.colorScheme.secondary, 0.05)!,
                        context.colorScheme.surface,
                      ],
                      stops: const [0.0, 0.42, 0.74, 1.0],
                    ),
                    image: showImage
                        ? DecorationImage(
                            opacity: 0.11,
                            image: imageCache.getImageProvider("assets/home/background.jpg"),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                top: -80,
                right: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          context.colorScheme.primary.withValues(alpha: 0.10),
                          context.colorScheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          context.colorScheme.secondary.withValues(alpha: 0.07),
                          context.colorScheme.secondary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 11, child: _buildLeftPanel(context, ref)),
                      const SizedBox(width: 18),
                      Expanded(flex: 9, child: _buildActivityPanel(context, ref)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Left Panel ───────────────────────────

  Widget _buildLeftPanel(BuildContext context, WidgetRef ref) {
    return _buildPanelShell(
      context,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(top: scaleSize(2), left: 0, child: IconHomeSettings()),
                      Positioned(
                        top: scaleSize(52),
                        left: scaleSize(2),
                        child: _buildTopShortcutButton(
                          context: context,
                          icon: Icons.qr_code_scanner_rounded,
                          tooltip: 'scanQRCode'.tr(),
                          onTap: () => _openQrScanner(context),
                        ),
                      ),
                      Align(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Transform.translate(
                            offset: Offset(0, -scaleSize(38)),
                            child: AnimatedHeaderImage(
                              isEasterEggActive: widget.isEasterEggActive,
                              height: scaleSize(126),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: scaleSize(42),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, left: 24, right: 24),
                      child: DefaultTextStyle(
                        textAlign: TextAlign.center,
                        style: scaledTextStyle(
                          color: context.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        child: Consumer(
                          builder: (context, ref, _) {
                            final homeMessage = ref.watch(homeMessageProvider);
                            final homeMessageNotifier = ref.read(homeMessageProvider.notifier);
                            return GestureDetector(
                              onTap: () {
                                if (homeMessage == "noLizard".tr()) {
                                  homeMessageNotifier.showWisdomOfTheDay(context);
                                }
                              },
                              child: AnimatedFadeOutIn<String>(
                                data: homeMessage,
                                duration: const Duration(milliseconds: 200),
                                builder: (value) => Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildDesktopSearchSection(context, ref),
                  const SizedBox(height: 16),
                  _buildTotalBalanceCard(context, ref),
                  const SizedBox(height: 12),
                  _buildWalletOverview(context, ref),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildNetworkStatusCard(context, ref),
        ],
      ),
    );
  }

  // ─── Activity Panel (right, full height) ───

  Widget _buildActivityPanel(BuildContext context, WidgetRef ref) {
    return _buildPanelShell(context, child: _buildNetworkActivityFeed(context, ref));
  }

  Widget _buildTopShortcutButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            width: scaleSize(44),
            height: scaleSize(44),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 5)),
              ],
            ),
            child: Icon(icon, size: scaleSize(22), color: context.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSearchSection(BuildContext context, WidgetRef ref) {
    final query = _desktopSearchController.text.trim();
    final isFocused = _desktopSearchFocusNode.hasFocus;
    final addressResultsAsync = ref.watch(searchResultsProvider);
    final identityResultsAsync = query.length >= 2
        ? ref.watch(searchIdentityProvider(query))
        : const AsyncValue<List<d.IdentitySuggestion>>.data([]);

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
        ? _buildSearchSuggestions(identities: identityResults, addresses: addressResults)
        : const <_DesktopSearchSuggestion>[];
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

    return ConstrainedBox(
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
                            controller: _desktopSearchController,
                            focusNode: _desktopSearchFocusNode,
                            autofocus: false,
                            maxLines: 1,
                            textInputAction: TextInputAction.search,
                            onTapOutside: (_) {
                              _desktopSearchFocusNode.unfocus();
                              _focusDesktopHomeShell();
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
                        if (_desktopSearchController.text.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _desktopSearchController.clear();
                              _desktopSearchFocusNode.requestFocus();
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
                                    controller: _desktopSearchScrollController,
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
  }

  Widget _buildDesktopSearchSuggestionTile(
    BuildContext context, {
    required _DesktopSearchSuggestion suggestion,
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: suggestion.type == _DesktopSearchSuggestionType.identity
                                ? context.colorScheme.primary.withValues(alpha: 0.12)
                                : context.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            suggestion.type == _DesktopSearchSuggestionType.identity
                                ? 'desktopIdentityShortLabel'.tr()
                                : 'desktopWalletShortLabel'.tr(),
                            style: scaledTextStyle(
                              fontSize: 10,
                              color: suggestion.type == _DesktopSearchSuggestionType.identity
                                  ? context.colorScheme.primary
                                  : context.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

  // ─── Network Activity Feed ───

  Widget _buildNetworkActivityFeed(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkProvider);
    final networkLabel = network.name.toUpperCase();
    final txState = ref.watch(networkActivityProvider);
    final identityState = ref.watch(networkIdentitiesProvider);
    final certState = ref.watch(networkCertificationsProvider);
    final activeCertifications = certState.certifications.where((certification) => certification.isActive).toList();
    final totalsAsync = ref.watch(networkTotalsProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == d.ConnectionStatus.connected;
    final fallbackTxCount = _formatPagedMetric(txState.transactions.length, txState.hasNextPage);
    final fallbackIdentityCount = _formatPagedMetric(identityState.identities.length, identityState.hasNextPage);
    final fallbackCertCount = _formatPagedMetric(activeCertifications.length, certState.hasNextPage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActivityControlsBar(
          context,
          networkLabel: networkLabel,
          isConnected: isConnected,
          txCount: totalsAsync.when(
            data: (totals) => _formatExactMetric(totals.transactions, fallbackTxCount),
            loading: () => fallbackTxCount,
            error: (_, _) => fallbackTxCount,
          ),
          identityCount: totalsAsync.when(
            data: (totals) => _formatExactMetric(totals.identities, fallbackIdentityCount),
            loading: () => fallbackIdentityCount,
            error: (_, _) => fallbackIdentityCount,
          ),
          identityDetails: _buildIdentityMetricDetails(totalsAsync),
          certCount: totalsAsync.when(
            data: (totals) => _formatExactMetric(totals.certifications, fallbackCertCount),
            loading: () => fallbackCertCount,
            error: (_, _) => fallbackCertCount,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _buildGlassCard(
            context,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: _buildAnimatedActivityTabContent(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityControlsBar(
    BuildContext context, {
    required String networkLabel,
    required bool isConnected,
    required String txCount,
    required String identityCount,
    required List<_ActivityMetricDetail> identityDetails,
    required String certCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colorScheme.surface.withValues(alpha: 0.96),
            context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'networkActivity'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        color: context.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      networkLabel,
                      style: scaledTextStyle(
                        fontSize: 10.5,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green.withValues(alpha: 0.10) : Colors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isConnected ? 'connectedToNode'.tr(args: [networkLabel]) : 'connecting'.tr(),
                      style: scaledTextStyle(
                        fontSize: 10,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorAnimation: TabIndicatorAnimation.elastic,
              dividerColor: Colors.transparent,
              indicator: UnderlineTabIndicator(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(color: context.colorScheme.primary.withValues(alpha: 0.95), width: 3),
                insets: const EdgeInsets.fromLTRB(24, 0, 24, 6),
              ),
              indicatorPadding: EdgeInsets.zero,
              labelColor: context.colorScheme.onSurface,
              unselectedLabelColor: context.colorScheme.onSurface.withValues(alpha: 0.55),
              labelStyle: scaledTextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: scaledTextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              splashBorderRadius: BorderRadius.circular(16),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                  return context.colorScheme.primary.withValues(alpha: 0.05);
                }
                if (states.contains(WidgetState.pressed)) {
                  return context.colorScheme.primary.withValues(alpha: 0.08);
                }
                return Colors.transparent;
              }),
              tabs: [
                _buildActivityTab(context, Icons.swap_horiz_rounded, 'transactions'.tr(), count: txCount),
                _buildActivityTab(context, Icons.person_rounded, 'identities'.tr(), count: identityCount),
                _buildActivityTab(context, Icons.verified_rounded, 'certifications'.tr(), count: certCount),
              ],
            ),
          ),
          if (identityDetails.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: identityDetails.map((detail) => _buildIdentityDetailChip(context, detail)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdentityDetailChip(BuildContext context, _ActivityMetricDetail detail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: scaledTextStyle(
            fontSize: 10,
            color: context.colorScheme.onSurface.withValues(alpha: 0.62),
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '${detail.label}: '),
            TextSpan(
              text: detail.value,
              style: scaledTextStyle(fontSize: 10, color: context.colorScheme.onSurface, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPagedMetric(int loadedCount, bool hasNextPage) {
    if (loadedCount == 0) return '0';
    return hasNextPage ? '$loadedCount+' : '$loadedCount';
  }

  String _formatExactMetric(int totalCount, String fallback) {
    if (totalCount <= 0) return fallback;
    return '$totalCount';
  }

  List<_ActivityMetricDetail> _buildIdentityMetricDetails(AsyncValue<NetworkTotals> totalsAsync) {
    return totalsAsync.when(
      data: (totals) => [
        _ActivityMetricDetail(label: 'member'.tr(), value: '${totals.memberIdentities}'),
        _ActivityMetricDetail(label: 'unconfirmed'.tr(), value: '${totals.unconfirmedIdentities}'),
        _ActivityMetricDetail(label: 'unvalidated'.tr(), value: '${totals.unvalidatedIdentities}'),
        _ActivityMetricDetail(label: 'identityExpired'.tr(), value: '${totals.expiredIdentities}'),
      ],
      loading: () => const [],
      error: (_, _) => const [],
    );
  }

  Widget _buildActivityTab(BuildContext context, IconData icon, String label, {required String count}) {
    return Tab(
      height: 58,
      child: SizedBox.expand(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 8),
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  overflow: TextOverflow.ellipsis,
                  style: scaledTextStyle(
                    fontSize: 10,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.46),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedActivityTabContent(BuildContext context, WidgetRef ref) {
    final currentIndex = _activeActivityTabIndex;
    return IndexedStack(
      index: currentIndex.clamp(0, 2),
      children: [
        _buildTransactionsTab(context, ref),
        _buildIdentitiesTab(context, ref),
        _buildCertificationsTab(context, ref),
      ],
    );
  }

  Widget _buildTransactionsTab(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(networkActivityProvider);

    if (activityState.transactions.isEmpty) {
      if (activityState.isLoading) {
        return Center(child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 2));
      }
      return _buildEmptyState(context, Icons.swap_horiz, 'noNetworkActivity'.tr());
    }

    return ListView.separated(
      controller: _scrollControllers[0],
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: activityState.transactions.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.06)),
      itemBuilder: (context, index) {
        final tx = activityState.transactions[index];
        return _buildCompactTransactionTile(context, tx);
      },
    );
  }

  Widget _buildIdentitiesTab(BuildContext context, WidgetRef ref) {
    final identitiesState = ref.watch(networkIdentitiesProvider);

    if (identitiesState.identities.isEmpty) {
      if (identitiesState.isLoading) {
        return Center(child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 2));
      }
      return _buildEmptyState(context, Icons.person_outline, 'noIdentityActivity'.tr());
    }

    return ListView.separated(
      controller: _scrollControllers[1],
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: identitiesState.identities.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.06)),
      itemBuilder: (context, index) {
        return _buildCompactIdentityTile(context, identitiesState.identities[index]);
      },
    );
  }

  Widget _buildCertificationsTab(BuildContext context, WidgetRef ref) {
    final certsState = ref.watch(networkCertificationsProvider);
    final activeCertifications = certsState.certifications.where((certification) => certification.isActive).toList();

    if (activeCertifications.isEmpty) {
      if (certsState.isLoading) {
        return Center(child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 2));
      }
      return _buildEmptyState(context, Icons.verified_outlined, 'noCertificationActivity'.tr());
    }

    return ListView.separated(
      controller: _scrollControllers[2],
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: activeCertifications.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.06)),
      itemBuilder: (context, index) {
        return _buildCompactCertificationTile(context, activeCertifications[index]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: context.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Text(
            message,
            style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  String _relativeTime(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).languageCode;
    return timeago.format(dateTime, locale: locale);
  }

  // ─── Helpers ───

  /// Wraps a child widget to navigate to a profile on tap, with pointer cursor.
  Widget _buildClickableProfile(
    BuildContext context, {
    required String address,
    String? username,
    required Widget child,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _pushDesktopProfileRoute(context, address: address, username: username),
        child: child,
      ),
    );
  }

  // ─── Compact Desktop Tiles ───

  Widget _buildCompactTransactionTile(BuildContext context, TransactionDisplayItem tx) {
    final isReceived = tx.isReceived;
    final amount = isReceived ? tx.amount : tx.amount * BigInt.from(-1);
    final amountColor = isReceived ? context.colorScheme.primary : Colors.blue;

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
              _relativeTime(context, tx.transactionTime),
              style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    // Migration tile
    if (tx.type == TransactionType.identityMigrationFrom || tx.type == TransactionType.identityMigrationTo) {
      final isMigFrom = tx.type == TransactionType.identityMigrationFrom;
      return _buildClickableProfile(
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
                _relativeTime(context, tx.transactionTime),
                style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),
      );
    }

    // Normal transfer tile
    final String? username = tx.username == '' ? null : tx.username;

    return _buildClickableProfile(
      context,
      address: tx.address,
      username: username,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Small avatar
            DatapodAvatar(address: tx.address, size: 28, name: username),
            const SizedBox(width: 8),
            // Name/address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username ?? getShortPubkey(tx.address),
                    style: scaledTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                      fontFamily: username == null ? 'monospace' : null,
                    ),
                    overflow: TextOverflow.ellipsis,
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
            // Amount + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BalanceDisplay(value: amount, size: 13, color: amountColor),
                const SizedBox(height: 2),
                Text(
                  _relativeTime(context, tx.transactionTime),
                  style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactIdentityTile(BuildContext context, IdentityDisplayItem identity) {
    final isCreated = IdentityUtils.isCreatedStatusString(identity.status);
    final displayName = identity.name.isEmpty
        ? getShortPubkey(identity.accountId ?? '')
        : IdentityUtils.getDisplayNameFromString(identity.name, identity.status);

    return _buildClickableProfile(
      context,
      address: identity.relevantAccountId!,
      username: identity.name.isNotEmpty ? identity.name : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Avatar
            DatapodAvatar(
              address: identity.relevantAccountId!,
              size: 28,
              name: identity.name.isNotEmpty ? identity.name : null,
            ),
            const SizedBox(width: 8),
            // Name + status description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: scaledTextStyle(
                      fontSize: 13,
                      fontWeight: isCreated ? FontWeight.w500 : FontWeight.w600,
                      fontStyle: isCreated ? FontStyle.italic : FontStyle.normal,
                      color: isCreated ? context.colorScheme.onSurfaceVariant : context.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(identity.getStatusIcon(), size: 12, color: identity.getStatusColor()),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          identity.displayStatus,
                          style: scaledTextStyle(
                            fontSize: 11,
                            color: identity.getStatusColor(),
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
              _relativeTime(context, identity.timestamp),
              style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCertificationTile(BuildContext context, CertificationDisplayItem cert) {
    final statusColor = cert.getStatusColor();
    final issuerName = cert.issuerName ?? getShortPubkey(cert.issuerAccountId);
    final receiverName = cert.receiverName ?? getShortPubkey(cert.receiverAccountId);
    const timeColumnWidth = 210.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Status indicator dot
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
                  child: _buildClickableProfile(
                    context,
                    address: cert.issuerAccountId,
                    username: cert.issuerName,
                    child: Row(
                      children: [
                        DatapodAvatar(address: cert.issuerAccountId, size: 20, name: issuerName),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            issuerName,
                            style: scaledTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildClickableProfile(
                    context,
                    address: cert.receiverAccountId,
                    username: cert.receiverName,
                    child: Row(
                      children: [
                        DatapodAvatar(address: cert.receiverAccountId, size: 20, name: receiverName),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            receiverName,
                            style: scaledTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: timeColumnWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _relativeTime(context, cert.timestamp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
                if (cert.expirationText != null && !cert.isExpired)
                  Text(
                    cert.expirationText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: scaledTextStyle(fontSize: 10, color: Colors.orange),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colorScheme.surface.withValues(alpha: 0.92),
            context.colorScheme.surfaceContainer.withValues(alpha: 0.68),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPanelShell(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 32, offset: const Offset(0, 18)),
        ],
      ),
      child: child,
    );
  }

  // ─── Total Balance Card ───

  Widget _buildTotalBalanceCard(BuildContext context, WidgetRef ref) {
    final currentSafe = ref.watch(currentSafeNumberProvider);
    final safeData = ref.watch(safeOnChainDataProvider(currentSafe));

    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: safeData.when(
        data: (data) {
          var total = BigInt.zero;
          for (final balance in data.balances.values) {
            total += balance.transferableBalance;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'soldeTotal'.tr(),
                style: scaledTextStyle(
                  fontSize: 12,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: BalanceDisplay(
                  value: total,
                  size: 20,
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
        loading: () => SizedBox(
          height: 24,
          child: Center(
            child: CircularProgressIndicator(
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, _) =>
            Text('errorLoadingWalletData'.tr(), style: scaledTextStyle(fontSize: 12, color: Colors.red[300]!)),
      ),
    );
  }

  // ─── Wallet Overview Card ───

  Widget _buildWalletOverview(BuildContext context, WidgetRef ref) {
    final walletService = ref.watch(walletServiceProvider);
    final currentSafeNumber = ref.watch(currentSafeNumberProvider);
    final allSafes = walletService.safeBox.getAll()..sort((a, b) => a.number.compareTo(b.number));
    final safeGroups = allSafes
        .map((safe) {
          final query = walletService.walletBox.query()
            ..link(WalletEntity_.safe, SafeEntity_.number.equals(safe.number));
          final wallets = query.build().find()..sort((a, b) => a.number.compareTo(b.number));
          return _DesktopSafeWalletGroup(safe: safe, wallets: wallets, isCurrent: safe.number == currentSafeNumber);
        })
        .where((group) => group.wallets.isNotEmpty)
        .toList(growable: false);
    final totalWallets = safeGroups.fold<int>(0, (sum, group) => sum + group.wallets.length);
    final hasSingleSafe = safeGroups.length <= 1;
    final hasSingleWallet = totalWallets == 1;

    return _buildGlassCard(
      context,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: scaleSize(14),
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'myWalletsTitle'.tr(),
                style: scaledTextStyle(
                  fontSize: 13,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalWallets',
                  style: scaledTextStyle(fontSize: 11, color: context.colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (safeGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'noWalletFound'.tr(),
                  style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            )
          else if (hasSingleWallet)
            _buildSingleWalletOverview(context, ref, safeGroups.single, safeGroups.single.wallets.single)
          else if (hasSingleSafe)
            _buildSingleSafeWalletList(context, ref, safeGroups.single)
          else
            _buildMultiSafeWalletList(context, ref, safeGroups),
          if (safeGroups.isNotEmpty) ...[const SizedBox(height: 14), _buildSecondarySafeActions(context, safeGroups)],
        ],
      ),
    );
  }

  Widget _buildSingleWalletOverview(
    BuildContext context,
    WidgetRef ref,
    _DesktopSafeWalletGroup group,
    d.WalletEntity wallet,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colorScheme.primary.withValues(alpha: 0.12),
            context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSafeHeader(context, group, compact: true),
          const SizedBox(height: 12),
          _buildWalletRow(context, ref, wallet, isPrimary: true, isOnlyWallet: true),
        ],
      ),
    );
  }

  Widget _buildSingleSafeWalletList(BuildContext context, WidgetRef ref, _DesktopSafeWalletGroup group) {
    return Column(
      children: [
        _buildSafeHeader(context, group, compact: true),
        const SizedBox(height: 10),
        for (final wallet in group.wallets)
          _buildWalletRow(context, ref, wallet, isPrimary: _isPrimaryWallet(group.wallets, wallet)),
      ],
    );
  }

  Widget _buildMultiSafeWalletList(BuildContext context, WidgetRef ref, List<_DesktopSafeWalletGroup> groups) {
    return Column(
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          _buildSafeSection(context, ref, groups[i]),
          if (i != groups.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildSafeSection(BuildContext context, WidgetRef ref, _DesktopSafeWalletGroup group) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: group.isCurrent
              ? context.colorScheme.primary.withValues(alpha: 0.16)
              : context.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          _buildSafeHeader(context, group),
          const SizedBox(height: 10),
          for (final wallet in group.wallets)
            _buildWalletRow(context, ref, wallet, isPrimary: _isPrimaryWallet(group.wallets, wallet)),
        ],
      ),
    );
  }

  Widget _buildSafeHeader(BuildContext context, _DesktopSafeWalletGroup group, {bool compact = false}) {
    final safeLabel = WalletNameService.displayName(group.safe.name);
    return Row(
      children: [
        Container(
          width: compact ? 38 : 34,
          height: compact ? 38 : 34,
          decoration: BoxDecoration(
            color: group.isCurrent
                ? context.colorScheme.primary.withValues(alpha: 0.14)
                : context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: group.isCurrent ? context.colorScheme.primary : context.colorScheme.onSurface.withValues(alpha: 0.7),
            size: compact ? 20 : 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                safeLabel,
                overflow: TextOverflow.ellipsis,
                style: scaledTextStyle(
                  fontSize: compact ? 14 : 13,
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                group.wallets.length > 1
                    ? 'desktopWalletsCountLabel'.tr(args: ['${group.wallets.length}'])
                    : 'desktopWalletCountLabel'.tr(args: ['${group.wallets.length}']),
                style: scaledTextStyle(fontSize: 10.5, color: context.colorScheme.onSurface.withValues(alpha: 0.46)),
              ),
            ],
          ),
        ),
        if (group.isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'identityActive'.tr(),
              style: scaledTextStyle(fontSize: 10, color: context.colorScheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _buildSecondarySafeActions(BuildContext context, List<_DesktopSafeWalletGroup> groups) {
    final currentGroup = groups.firstWhere((group) => group.isCurrent, orElse: () => groups.first);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  WalletNameService.displayName(currentGroup.safe.name),
                  overflow: TextOverflow.ellipsis,
                  style: scaledTextStyle(
                    fontSize: 12,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '#${currentGroup.safe.number}',
                style: scaledTextStyle(fontSize: 10.5, color: context.colorScheme.onSurface.withValues(alpha: 0.42)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryActionButton(
                  context,
                  icon: Icons.swap_horiz_rounded,
                  label: 'changeSafe'.tr(),
                  onTap: () => _openSafeSwitcher(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSecondaryActionButton(
                  context,
                  icon: Icons.tune_rounded,
                  label: 'manageSafe'.tr(),
                  onTap: () => _openSafeOptions(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.72)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: scaledTextStyle(
                    fontSize: 11,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPrimaryWallet(List<d.WalletEntity> wallets, d.WalletEntity wallet) {
    if (wallets.isEmpty) return false;
    final primary = wallets.firstWhere((candidate) => candidate.derivation == null, orElse: () => wallets.first);
    return primary.address == wallet.address;
  }

  Widget _buildWalletRow(
    BuildContext context,
    WidgetRef ref,
    d.WalletEntity wallet, {
    bool isPrimary = false,
    bool isOnlyWallet = false,
  }) {
    final idtyStatus = ref.watch(safeWalletIdtyStatusProvider(wallet.address));
    final dragState = ref.watch(dragDropProvider);
    final isDraggingAnotherWallet = dragState.dragAddress != null && dragState.dragAddress!.address != wallet.address;
    final isHoveredTarget = dragState.lastFlyBy?.address == wallet.address && isDraggingAnotherWallet;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DragTuleAction(
        wallet: wallet,
        desktopMode: true,
        desktopChildBuilder: (dragHandle) => Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              _pushDesktopProfileRoute(context, address: wallet.address, username: wallet.name);
            },
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: isOnlyWallet ? 12 : 10, vertical: isOnlyWallet ? 12 : 10),
              decoration: BoxDecoration(
                gradient: isHoveredTarget
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.colorScheme.primary.withValues(alpha: 0.2),
                          context.colorScheme.surface.withValues(alpha: 0.95),
                        ],
                      )
                    : isPrimary
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.colorScheme.primary.withValues(alpha: 0.14),
                          context.colorScheme.surface.withValues(alpha: 0.88),
                        ],
                      )
                    : null,
                color: (isHoveredTarget || isPrimary) ? null : context.colorScheme.surface.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isHoveredTarget
                      ? context.colorScheme.primary.withValues(alpha: 0.3)
                      : isPrimary
                      ? context.colorScheme.primary.withValues(alpha: 0.18)
                      : context.colorScheme.outline.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: scaleSize(34),
                    height: scaleSize(34),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
                    ),
                    child: ClipOval(
                      child:
                          wallet.imagePath != null &&
                              wallet.imagePath!.isNotEmpty &&
                              !wallet.imagePath!.startsWith('assets/')
                          ? CachedAvatarImage(imagePath: wallet.imagePath!, fit: BoxFit.cover, isCircular: false)
                          : Image.asset('assets/avatars/${wallet.number % 4}.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: NameByAddress(
                                wallet: wallet,
                                size: isOnlyWallet ? 13 : 12.5,
                                color: context.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isPrimary) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.primary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'walletNameMain'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 9.5,
                                    color: context.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (idtyStatus != null && idtyStatus != d.IdtyStatus.none)
                              Padding(padding: const EdgeInsets.only(right: 5), child: _buildIdtyStatusDot(idtyStatus)),
                            Expanded(
                              child: Text(
                                getShortPubkey(wallet.address),
                                style: scaledTextStyle(
                                  fontSize: 9.5,
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.42),
                                  fontFamily: 'Monospace',
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
                  if (isDraggingAnotherWallet && !isHoveredTarget)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        size: 16,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.22),
                      ),
                    ),
                  if (isHoveredTarget)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'pay'.tr(),
                          style: scaledTextStyle(
                            fontSize: 9.5,
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Balance(address: wallet.address, size: 12, color: context.colorScheme.onSurface),
                  const SizedBox(width: 8),
                  dragHandle,
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: context.colorScheme.onSurface.withValues(alpha: 0.22)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdtyStatusDot(d.IdtyStatus status) {
    final color = switch (status) {
      d.IdtyStatus.validated => Colors.green,
      d.IdtyStatus.confirmed => Colors.orange,
      d.IdtyStatus.created => Colors.blue,
      d.IdtyStatus.expired => Colors.red,
      d.IdtyStatus.revoked => Colors.grey,
      _ => Colors.grey,
    };

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 3, spreadRadius: 1)],
      ),
    );
  }

  Widget _buildStatusDot(bool isConnected) {
    final color = isConnected ? Colors.green : Colors.orange;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)],
      ),
    );
  }

  // ─── Network Status Card ───

  Widget _buildNetworkStatusCard(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final squidStatus = ref.watch(squidConnectionStatusProvider);
    final blockHeight = ref.watch(blockHeightProvider);
    final isDuniterConnected = connectionStatus == d.ConnectionStatus.connected;
    final isSquidConnected = squidStatus == d.ConnectionStatus.connected;

    String duniterDisplay = '';
    String squidDisplay = '';
    if (isDuniterConnected) {
      try {
        duniterDisplay = d.Networks.duniterEndpoint.replaceFirst('wss://', '').replaceFirst('ws://', '');
      } catch (_) {}
    }
    if (isSquidConnected) {
      try {
        squidDisplay = d.Networks.squidEndpoint.replaceFirst('https://', '').replaceFirst('http://', '');
      } catch (_) {}
    }

    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Node info (left side)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Duniter node row
                Row(
                  children: [
                    _buildStatusDot(isDuniterConnected),
                    const SizedBox(width: 6),
                    Text(
                      'Duniter',
                      style: scaledTextStyle(
                        fontSize: 10,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isDuniterConnected ? duniterDisplay : 'connecting'.tr(),
                        style: scaledTextStyle(
                          fontSize: 10,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Squid indexer row
                Row(
                  children: [
                    _buildStatusDot(isSquidConnected),
                    const SizedBox(width: 6),
                    Text(
                      'Indexer',
                      style: scaledTextStyle(
                        fontSize: 10,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isSquidConnected ? squidDisplay : 'connecting'.tr(),
                        style: scaledTextStyle(
                          fontSize: 10,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Block height (right side, vertically centered)
          if (isDuniterConnected && blockHeight > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '#$blockHeight',
                style: scaledTextStyle(
                  fontSize: 12,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _DesktopSearchSuggestionType { address, identity }

class _DesktopSearchSuggestion {
  const _DesktopSearchSuggestion({required this.address, required this.username, required this.type});

  final String address;
  final String? username;
  final _DesktopSearchSuggestionType type;
}

class _ActivityMetricDetail {
  final String label;
  final String value;

  const _ActivityMetricDetail({required this.label, required this.value});
}

class _DesktopSafeWalletGroup {
  const _DesktopSafeWalletGroup({required this.safe, required this.wallets, required this.isCurrent});

  final d.SafeEntity safe;
  final List<d.WalletEntity> wallets;
  final bool isCurrent;
}
