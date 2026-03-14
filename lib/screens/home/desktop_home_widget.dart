// ignore_for_file: use_build_context_synchronously

import 'dart:io' show Platform;

import 'package:durt2/durt2.dart' as d;
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
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/animated_header_image.dart';
import 'package:gecko/widgets/desktop/desktop_drag_info_bar.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/widgets/desktop/modals/safe_options_modal.dart';
import 'package:gecko/widgets/desktop/modals/settings_modal.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/easter_egg_detector.dart';
import 'package:gecko/widgets/desktop/panels/contacts_panel.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/widgets/bubble_speak.dart';
import 'package:gecko/widgets/drag_tule_action.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/identity_display_item.dart';
import 'package:gecko/models/certification_display_item.dart';
import 'package:gecko/utils/identity_utils.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/providers/identity_filters_provider.dart';
import 'package:gecko/providers/certification_filters_provider.dart';
import 'package:gecko/widgets/network_activity/identity_filters.dart';
import 'package:gecko/widgets/network_activity/certification_filters.dart';
import 'package:gecko/widgets/transaction_filters.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/widgets/desktop/modals/keyboard_shortcuts_modal.dart';
import 'package:gecko/widgets/global_search_palette_dialog.dart';
import 'package:gecko/widgets/desktop/modals/legacy_migration_modal.dart';
import 'package:gecko/widgets/desktop/modals/onboarding_modal.dart';
import 'package:gecko/widgets/desktop/modals/restore_modal.dart';
import 'package:gecko/widgets/desktop/modals/wallet_options_modal.dart';
import 'package:gecko/screens/onBoarding/import_choice_screen.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/screens/home/test_wallet_button.dart';
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
  bool _isContactsPanelOpen = false;
  bool _isSearchPaletteOpen = false;

  String get _searchShortcutLabel {
    if (!kIsWeb && Platform.isMacOS) {
      return '⌘K';
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
    if (_activeActivityTabIndex != _tabController.index) {
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
    }
    // No setState needed — the search section rebuilds via its own ListenableBuilder
  }

  void _onDesktopSearchFocusChanged() {
    // No setState needed — the search section rebuilds via its own ListenableBuilder
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

  void _focusDesktopHomeShell() {
    if (!_desktopHomeFocusNode.hasFocus) {
      _desktopHomeFocusNode.requestFocus();
    }
  }

  void _openGlobalSearchPalette() {
    if (_isSearchPaletteOpen || !mounted) return;
    _isSearchPaletteOpen = true;
    showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierLabel: 'global_search',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => const GlobalSearchPaletteDialog(),
    ).whenComplete(() {
      _isSearchPaletteOpen = false;
    });
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

    // K or F — open global search palette
    if (event.logicalKey == LogicalKeyboardKey.keyK || event.logicalKey == LogicalKeyboardKey.keyF) {
      _openGlobalSearchPalette();
      return KeyEventResult.handled;
    }

    // H — open keyboard shortcuts modal
    if (event.logicalKey == LogicalKeyboardKey.keyH) {
      showKeyboardShortcutsModal(context);
      return KeyEventResult.handled;
    }

    // / — focus search bar
    if (event.logicalKey == LogicalKeyboardKey.slash) {
      _desktopSearchFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // C — toggle contacts panel
    if (event.logicalKey == LogicalKeyboardKey.keyC) {
      setState(() => _isContactsPanelOpen = !_isContactsPanelOpen);
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

    // Item height: 10px padding top + 38px avatar + 10px padding bottom + 2px border + 6px separator = 66px
    final targetOffset = (_highlightedSearchIndex * 66).toDouble();
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
    NavigationService.openProfile(context, address: address, username: username?.isNotEmpty == true ? username : null);
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canShowContacts = constraints.maxWidth >= 1200;
                      final showContactsColumn = canShowContacts && _isContactsPanelOpen;
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1600),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showContactsColumn) ...[
                                Expanded(flex: 3, child: _buildContactsColumn(context, ref)),
                                const SizedBox(width: 18),
                              ],
                              Expanded(
                                flex: showContactsColumn ? 5 : 11,
                                child: _buildLeftPanel(context, ref, canShowContacts: canShowContacts),
                              ),
                              const SizedBox(width: 18),
                              Expanded(flex: showContactsColumn ? 4 : 9, child: _buildActivityPanel(context, ref)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const DesktopDragInfoBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Contacts Column (left, visible >= 1200px) ───

  Widget _buildContactsColumn(BuildContext context, WidgetRef ref) {
    return _buildPanelShell(
      context,
      child: DesktopContactsPanel(
        onContactTap: (address, username) => _pushDesktopProfileRoute(context, address: address, username: username),
      ),
    );
  }

  // ─────────────────────────── Center Panel ───────────────────────────

  Widget _buildLeftPanel(BuildContext context, WidgetRef ref, {bool canShowContacts = false}) {
    final hasWallets = ref.watch(isWalletsExistsProvider);

    return _buildPanelShell(
      context,
      child: Column(
        children: [
          // Top fixed section: header + message + search
          _buildLeftPanelHeader(context, ref, canShowContacts: canShowContacts),
          // Main content area
          if (hasWallets)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTotalBalanceCard(context, ref),
                    const SizedBox(height: 12),
                    _buildWalletOverview(context, ref),
                  ],
                ),
              ),
            )
          else
            Expanded(child: Center(child: _buildWelcomeSection(context))),
          const SizedBox(height: 14),
          _buildNetworkStatusCard(context, ref),
        ],
      ),
    );
  }

  /// Top section of the left panel: header image, message, search bar
  Widget _buildLeftPanelHeader(BuildContext context, WidgetRef ref, {bool canShowContacts = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final headerHeight = (constraints.maxWidth * 0.24).clamp(scaleSize(88), scaleSize(126));
            final headerLift = (headerHeight * 0.18).clamp(0.0, scaleSize(26));
            final topBleedCompensation = scaleSize(18);
            final desiredOffset = headerLift + topBleedCompensation;
            final reservedHeight = (headerHeight - desiredOffset + scaleSize(12)).clamp(scaleSize(72), headerHeight);
            final safeOffset = (headerHeight - reservedHeight).clamp(0.0, desiredOffset);

            return SizedBox(
              height: reservedHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Transform.translate(
                          offset: Offset(0, -safeOffset),
                          child: AnimatedHeaderImage(isEasterEggActive: widget.isEasterEggActive, height: headerHeight),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: scaleSize(2),
                    left: 0,
                    child: IconButton(
                      icon: Icon(
                        Icons.settings_rounded,
                        size: scaleSize(28),
                        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      tooltip: 'parameters'.tr(),
                      onPressed: () => showDesktopSettingsModal(context),
                    ),
                  ),
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
                ],
              ),
            );
          },
        ),
        SizedBox(
          height: scaleSize(42),
          child: Padding(
            padding: const EdgeInsets.only(top: 2, left: 24, right: 24),
            child: DefaultTextStyle(
              textAlign: TextAlign.center,
              style: scaledTextStyle(color: context.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
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
        // ListenableBuilder isolates search rebuilds from the rest of the left panel
        ListenableBuilder(
          listenable: Listenable.merge([_desktopSearchController, _desktopSearchFocusNode]),
          builder: (context, _) => _buildDesktopSearchSection(context, ref, canShowContacts: canShowContacts),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── Welcome Section (replaces wallets when no wallet exists) ───

  Widget _buildWelcomeSection(BuildContext context) {
    final imageCache = ImageCacheService();
    final primary = context.colorScheme.primary;

    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gecko mascot with bubble — gecko sits right on top of the button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gecko + bubble row — bubble aligned with gecko's mouth
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image(image: imageCache.getImageProvider('assets/home/gecko-bienvenue.png'), height: 140),
                  Flexible(
                    child: Transform.translate(
                      offset: const Offset(-10, 0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 112),
                        child: BubbleSpeakWithTail(text: "noLizard".tr(), fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              // Create wallet button — flush against gecko's feet
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: keyOnboardingNewSafe,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: Colors.white),
                  label: Text(
                    'createWallet'.tr(),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: primary.withValues(alpha: 0.3),
                  ),
                  onPressed: () => showDesktopOnboardingModal(context),
                ),
              ),
              const SizedBox(height: 14),
              // Restore / Import wallet button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: keyRestoreSafe,
                  icon: Icon(Icons.key_rounded, size: 20, color: primary),
                  label: Text(
                    'restoreWallet'.tr(),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(width: 2.5, color: primary.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: primary.withValues(alpha: 0.04),
                  ),
                  onPressed: () => showDesktopRestoreModal(context),
                ),
              ),
              const TestWalletButton(),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Activity Panel (right, full height) ───

  Widget _buildActivityPanel(BuildContext context, WidgetRef ref) {
    return _buildPanelShell(
      context,
      child: _NetworkActivityFeed(
        tabController: _tabController,
        activeTabIndex: _activeActivityTabIndex,
        scrollControllers: _scrollControllers,
        tileBuilders: (
          tx: (context, tx) => _buildCompactTransactionTile(context, tx),
          identity: (context, identity) => _buildCompactIdentityTile(context, identity),
          cert: (context, cert) => _buildCompactCertificationTile(context, cert),
        ),
      ),
    );
  }

  Widget _buildTopShortcutButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
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
              color: isActive
                  ? context.colorScheme.primary.withValues(alpha: 0.15)
                  : context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? context.colorScheme.primary.withValues(alpha: 0.4)
                    : context.colorScheme.outline.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 5)),
              ],
            ),
            child: Icon(
              icon,
              size: scaleSize(22),
              color: isActive ? context.colorScheme.primary : context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSearchSection(BuildContext context, WidgetRef ref, {bool canShowContacts = false}) {
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

    if (!canShowContacts) return searchBar;

    return Row(
      children: [
        _buildContactsToggleButton(context),
        const SizedBox(width: 10),
        Expanded(child: searchBar),
      ],
    );
  }

  Widget _buildContactsToggleButton(BuildContext context) {
    return Tooltip(
      message: 'contactsManagement'.tr(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _isContactsPanelOpen = !_isContactsPanelOpen),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: _isContactsPanelOpen
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
                color: _isContactsPanelOpen
                    ? context.colorScheme.primary.withValues(alpha: 0.4)
                    : context.colorScheme.outline.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: _isContactsPanelOpen
                      ? context.colorScheme.primary.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              _isContactsPanelOpen ? Icons.people_rounded : Icons.people_outline_rounded,
              size: 24,
              color: _isContactsPanelOpen
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

  // Activity panel controls and tab content have been extracted to
  // _NetworkActivityFeed and _NetworkActivityControlsBar ConsumerWidgets
  // to isolate provider watches and prevent cascading rebuilds.

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

  Widget _buildCompactProfileLabel(
    BuildContext context, {
    required String text,
    required bool isAddressLabel,
    required TextStyle style,
    TextAlign textAlign = TextAlign.start,
  }) {
    final label = Text(text, style: style, overflow: TextOverflow.ellipsis, textAlign: textAlign, maxLines: 1);

    if (!isAddressLabel) {
      return label;
    }

    return Tooltip(
      message: text,
      waitDuration: const Duration(milliseconds: 80),
      preferBelow: true,
      verticalOffset: 24,
      child: label,
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
                        child: _buildClickableProfile(
                          context,
                          address: fromAddress,
                          username: tx.fromUsername,
                          child: _buildCompactProfileLabel(
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
                      Expanded(
                        child: _buildClickableProfile(
                          context,
                          address: toAddress,
                          username: tx.toUsername,
                          child: _buildCompactProfileLabel(
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
                    _relativeTime(context, tx.transactionTime),
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

    return _buildClickableProfile(
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
                  _buildCompactProfileLabel(
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
    final accountId = identity.relevantAccountId;
    if (accountId == null) return const SizedBox.shrink();

    final isCreated = IdentityUtils.isCreatedStatusString(identity.status);
    final displayName = identity.name.isEmpty
        ? getShortPubkey(accountId)
        : IdentityUtils.getDisplayNameFromString(identity.name, identity.status);

    return _buildClickableProfile(
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
                  _buildCompactProfileLabel(
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
                      child: _buildClickableProfile(
                        context,
                        address: cert.issuerAccountId,
                        username: cert.issuerName,
                        child: Row(
                          children: [
                            DatapodAvatar(address: cert.issuerAccountId, size: 20, name: issuerName),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildCompactProfileLabel(
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
                      child: _buildClickableProfile(
                        context,
                        address: cert.receiverAccountId,
                        username: cert.receiverName,
                        child: Row(
                          children: [
                            DatapodAvatar(address: cert.receiverAccountId, size: 20, name: receiverName),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildCompactProfileLabel(
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
      },
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child, EdgeInsets? padding}) {
    return Container(
      clipBehavior: Clip.hardEdge,
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
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == d.ConnectionStatus.connected;
    final safeGroups = ref.watch(safeWalletGroupsProvider);

    // Sum balances across ALL safes
    var total = BigInt.zero;
    var anyLoading = false;
    var anyError = false;

    for (final group in safeGroups) {
      final safeData = ref.watch(safeOnChainDataProvider(group.safe.number));
      safeData.when(
        data: (data) {
          for (final balance in data.balances.values) {
            total += balance.transferableBalance;
          }
        },
        loading: () => anyLoading = true,
        error: (_, _) => anyError = true,
      );
    }

    final Widget content;
    if (anyLoading && total == BigInt.zero) {
      // All safes still loading, show placeholder
      content = Text(
        '–',
        style: scaledTextStyle(
          fontSize: 20,
          color: context.colorScheme.onSurface.withValues(alpha: 0.3),
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (anyError && total == BigInt.zero) {
      content = Text('errorLoadingWalletData'.tr(), style: scaledTextStyle(fontSize: 12, color: Colors.red[300]!));
    } else {
      // Don't show "0" balance when not connected — it's misleading
      final showPlaceholder = !isConnected && total == BigInt.zero;
      content = showPlaceholder
          ? Text(
              '–',
              style: scaledTextStyle(
                fontSize: 20,
                color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                fontWeight: FontWeight.bold,
              ),
            )
          : BalanceDisplay(value: total, size: 20, color: context.colorScheme.onSurface, fontWeight: FontWeight.bold);
    }

    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
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
          Flexible(child: content),
        ],
      ),
    );
  }

  // ─── Wallet Overview Card ───

  Widget _buildWalletOverview(BuildContext context, WidgetRef ref) {
    final providerGroups = ref.watch(safeWalletGroupsProvider);
    final safeGroups = providerGroups
        .map((g) => _DesktopSafeWalletGroup(safe: g.safe, wallets: g.wallets, isCurrent: g.isCurrent))
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
              const SizedBox(width: 6),
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
        color: context.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSafeHeader(context, ref, group, compact: true),
          const SizedBox(height: 12),
          _buildWalletRow(context, ref, wallet, isPrimary: true, isOnlyWallet: true),
        ],
      ),
    );
  }

  Widget _buildSingleSafeWalletList(BuildContext context, WidgetRef ref, _DesktopSafeWalletGroup group) {
    return Column(
      children: [
        _buildSafeHeader(context, ref, group, compact: true),
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
          _buildSafeHeader(context, ref, group),
          const SizedBox(height: 10),
          for (final wallet in group.wallets)
            _buildWalletRow(context, ref, wallet, isPrimary: _isPrimaryWallet(group.wallets, wallet)),
        ],
      ),
    );
  }

  Widget _buildSafeHeader(BuildContext context, WidgetRef ref, _DesktopSafeWalletGroup group, {bool compact = false}) {
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
        const SizedBox(width: 4),
        _buildAddDerivationButton(context, ref, safeNumber: group.safe.number),
        const SizedBox(width: 2),
        SizedBox(
          width: 28,
          height: 28,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showDesktopSafeOptionsModal(context, ref, safeNumber: group.safe.number),
              child: Icon(
                Icons.settings_rounded,
                size: 16,
                color: context.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateOrRestoreMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) return;

    final position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        overlay.size.width - position.dx - size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'create',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 18, color: context.colorScheme.primary),
              const SizedBox(width: 10),
              Text('createSafe'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'restore',
          child: Row(
            children: [
              Icon(Icons.key_rounded, size: 18, color: context.colorScheme.primary),
              const SizedBox(width: 10),
              Text('restoreWallet'.tr()),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'create') {
        showDesktopOnboardingModal(context);
      } else if (value == 'restore') {
        showDesktopRestoreModal(context);
      }
    });
  }

  Widget _buildAddDerivationButton(BuildContext context, WidgetRef ref, {required int safeNumber}) {
    final derivationState = ref.watch(derivationStateProvider);

    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: derivationState.isLoading
              ? null
              : () async {
                  final walletService = ref.read(walletServiceProvider);
                  final wallets = walletService.getWalletDataList(safeNumber);
                  if (wallets.isEmpty) return;
                  if (!await PinCodeService.askPinCode(wallet: wallets.first)) return;
                  final lastNum = wallets.last.number;
                  final name = WalletNameService.defaultN(lastNum + 2);
                  await ref.read(walletActionsProvider.notifier).generateNewDerivation(name, safeNumber: safeNumber);
                },
          child: derivationState.isLoading
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.colorScheme.primary),
                )
              : Icon(Icons.add_rounded, size: 18, color: context.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildSecondarySafeActions(BuildContext context, List<_DesktopSafeWalletGroup> groups) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildSecondaryActionButton(
          context,
          icon: Icons.add_circle_outline_rounded,
          label: 'addNewSafe'.tr(),
          onTap: () => _showCreateOrRestoreMenu(context),
        ),
        if (ImportChoiceScreen.enableLegacyLogin)
          _buildSecondaryActionButton(
            context,
            iconWidget: SvgPicture.asset(
              'assets/cesium_bw2.svg',
              height: 16,
              colorFilter: ColorFilter.mode(context.colorScheme.onSurface.withValues(alpha: 0.72), BlendMode.srcIn),
            ),
            label: 'importIdPasswordAccount'.tr(),
            onTap: () => showDesktopLegacyMigrationModal(context),
          ),
      ],
    );
  }

  Widget _buildSecondaryActionButton(
    BuildContext context, {
    IconData? icon,
    Widget? iconWidget,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget ?? Icon(icon, size: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.72)),
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
            onTap: () => showDesktopWalletOptionsModal(context, wallet: wallet),
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: isOnlyWallet ? 12 : 10, vertical: isOnlyWallet ? 12 : 10),
              decoration: BoxDecoration(
                color: isHoveredTarget
                    ? context.colorScheme.primary.withValues(alpha: 0.08)
                    : isPrimary
                    ? context.colorScheme.primary.withValues(alpha: 0.06)
                    : context.colorScheme.surface.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  if (isPrimary || isHoveredTarget)
                    Container(
                      width: 3,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
                      'indexer'.tr(),
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
          // Block height — isolated Consumer to avoid rebuilding the entire left panel every ~6s
          if (isDuniterConnected)
            Consumer(
              builder: (context, ref, _) {
                final blockHeight = ref.watch(blockHeightProvider);
                if (blockHeight <= 0) return const SizedBox.shrink();
                return Padding(
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
                );
              },
            ),
          const SizedBox(width: 8),
          // Keyboard shortcuts hint
          Tooltip(
            message: 'keyboardShortcuts'.tr(),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showKeyboardShortcutsModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_rounded,
                      size: 13,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'H',
                      style: scaledTextStyle(
                        fontSize: 11,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Monospace',
                      ),
                    ),
                  ],
                ),
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

// ─── Isolated activity feed widget (prevents cascading rebuilds to parent) ───

/// Record type for tile builder callbacks
typedef _TileBuilders = ({
  Widget Function(BuildContext, TransactionDisplayItem) tx,
  Widget Function(BuildContext, IdentityDisplayItem) identity,
  Widget Function(BuildContext, CertificationDisplayItem) cert,
});

class _NetworkActivityFeed extends ConsumerWidget {
  final TabController tabController;
  final int activeTabIndex;
  final List<ScrollController> scrollControllers;
  final _TileBuilders tileBuilders;

  const _NetworkActivityFeed({
    required this.tabController,
    required this.activeTabIndex,
    required this.scrollControllers,
    required this.tileBuilders,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkProvider);
    final networkLabel = network.name.toUpperCase();
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == d.ConnectionStatus.connected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NetworkActivityControlsBar(tabController: tabController, networkLabel: networkLabel, isConnected: isConnected),
        const SizedBox(height: 14),
        Expanded(
          child: _buildGlassCard(
            context,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                _DesktopFilterBar(activeTabIndex: activeTabIndex),
                const SizedBox(height: 6),
                Expanded(
                  child: IndexedStack(
                    index: activeTabIndex.clamp(0, 2),
                    children: [
                      _DesktopTransactionsTab(scrollController: scrollControllers[0], tileBuilder: tileBuilders.tx),
                      _DesktopIdentitiesTab(scrollController: scrollControllers[1], tileBuilder: tileBuilders.identity),
                      _DesktopCertificationsTab(scrollController: scrollControllers[2], tileBuilder: tileBuilders.cert),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child, EdgeInsets? padding}) {
    return Container(
      clipBehavior: Clip.hardEdge,
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

/// Isolated controls bar — only rebuilds when totals or connection changes,
/// NOT when transaction/identity/certification lists change.
class _NetworkActivityControlsBar extends ConsumerWidget {
  final TabController tabController;
  final String networkLabel;
  final bool isConnected;

  const _NetworkActivityControlsBar({
    required this.tabController,
    required this.networkLabel,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(networkTotalsProvider);
    // Use .value to keep last known totals during AsyncLoading (avoids flicker to "–")
    final totals = totalsAsync.value;

    String resolveCount(String Function(NetworkTotals) fromTotals) {
      if (totals != null) return fromTotals(totals);
      return '–';
    }

    String formatExactMetric(int totalCount) {
      if (totalCount <= 0) return '–';
      return '$totalCount';
    }

    final txCount = resolveCount((t) => formatExactMetric(t.transactions));
    final identityCount = resolveCount((t) => formatExactMetric(t.identities));
    final certCount = resolveCount((t) => formatExactMetric(t.certifications));

    List<_ActivityMetricDetail> identityDetails = [
      _ActivityMetricDetail(
        label: 'member'.tr(),
        value: totals != null && totals.memberIdentities > 0 ? '${totals.memberIdentities}' : '–',
      ),
      _ActivityMetricDetail(
        label: 'unconfirmed'.tr(),
        value: totals != null && totals.unconfirmedIdentities > 0 ? '${totals.unconfirmedIdentities}' : '–',
      ),
      _ActivityMetricDetail(
        label: 'unvalidated'.tr(),
        value: totals != null && totals.unvalidatedIdentities > 0 ? '${totals.unvalidatedIdentities}' : '–',
      ),
      _ActivityMetricDetail(
        label: 'identityExpired'.tr(),
        value: totals != null && totals.expiredIdentities > 0 ? '${totals.expiredIdentities}' : '–',
      ),
    ];

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
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final useCompactTabs = screenWidth < 1100;

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  controller: tabController,
                  tabAlignment: TabAlignment.fill,
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
                  labelStyle: scaledTextStyle(fontSize: useCompactTabs ? 10.5 : 11.5, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: scaledTextStyle(
                    fontSize: useCompactTabs ? 10.5 : 11.5,
                    fontWeight: FontWeight.w600,
                  ),
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
                    _buildActivityTab(
                      context,
                      Icons.swap_horiz_rounded,
                      'transactions'.tr(),
                      count: txCount,
                      compact: useCompactTabs,
                    ),
                    _buildActivityTab(
                      context,
                      Icons.person_rounded,
                      'identities'.tr(),
                      count: identityCount,
                      compact: useCompactTabs,
                    ),
                    _buildActivityTab(
                      context,
                      Icons.verified_rounded,
                      'certifications'.tr(),
                      count: certCount,
                      compact: useCompactTabs,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: identityDetails
                .map(
                  (detail) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${detail.label}: ',
                          style: scaledTextStyle(
                            fontSize: 10,
                            color: context.colorScheme.onSurface.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          detail.value,
                          style: scaledTextStyle(
                            fontSize: 10,
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(
    BuildContext context,
    IconData icon,
    String label, {
    required String count,
    required bool compact,
  }) {
    final tabChild = SizedBox.expand(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (compact)
                Icon(icon, size: 18)
              else
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
    );

    return Tab(
      height: 58,
      child: compact
          ? Tooltip(
              message: label,
              waitDuration: const Duration(milliseconds: 80),
              preferBelow: true,
              verticalOffset: 24,
              child: tabChild,
            )
          : tabChild,
    );
  }
}

// ─── Isolated Tab Widgets (rebuild only when their own provider changes) ───

class _DesktopTransactionsTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Widget Function(BuildContext, TransactionDisplayItem) tileBuilder;

  const _DesktopTransactionsTab({required this.scrollController, required this.tileBuilder});

  @override
  ConsumerState<_DesktopTransactionsTab> createState() => _DesktopTransactionsTabState();
}

class _DesktopTransactionsTabState extends ConsumerState<_DesktopTransactionsTab> {
  Set<String> _knownIds = {};
  Set<String> _newIds = {};

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(adaptiveFilteredNetworkActivityProvider);
    final items = activityState.transactions;

    if (items.isEmpty) {
      final hasFilters = ref.watch(networkFiltersProvider).hasActiveFilters;
      return _buildEmptyTabState(
        context,
        Icons.swap_horiz,
        hasFilters ? 'noResultsForFilter'.tr() : 'noNetworkActivity'.tr(),
      );
    }

    // Detect new items by comparing IDs
    final currentIds = items.map((tx) => tx.squidId ?? '${tx.timestamp.millisecondsSinceEpoch}').toSet();
    if (_knownIds.isNotEmpty) {
      _newIds = currentIds.difference(_knownIds);
    }
    _knownIds = currentIds;

    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.06)),
      itemBuilder: (context, index) {
        final tx = items[index];
        final txId = tx.squidId ?? '${tx.timestamp.millisecondsSinceEpoch}';
        final isNew = _newIds.contains(txId);
        final child = widget.tileBuilder(context, tx);
        return isNew ? _NewItemHighlight(child: child) : child;
      },
    );
  }
}

class _DesktopIdentitiesTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Widget Function(BuildContext, IdentityDisplayItem) tileBuilder;

  const _DesktopIdentitiesTab({required this.scrollController, required this.tileBuilder});

  @override
  ConsumerState<_DesktopIdentitiesTab> createState() => _DesktopIdentitiesTabState();
}

class _DesktopIdentitiesTabState extends ConsumerState<_DesktopIdentitiesTab> {
  Set<String> _knownIds = {};
  Set<String> _newIds = {};

  @override
  Widget build(BuildContext context) {
    final identitiesState = ref.watch(adaptiveFilteredNetworkIdentitiesProvider);
    final items = identitiesState.identities;

    if (items.isEmpty) {
      final hasFilters = ref.watch(identityFiltersProvider).hasActiveFilters;
      return _buildEmptyTabState(
        context,
        Icons.person_outline,
        hasFilters ? 'noResultsForFilter'.tr() : 'noIdentityActivity'.tr(),
      );
    }

    final currentIds = items.map((i) => '${i.accountId ?? i.name}_${i.timestamp.millisecondsSinceEpoch}').toSet();
    if (_knownIds.isNotEmpty) {
      _newIds = currentIds.difference(_knownIds);
    }
    _knownIds = currentIds;

    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.06)),
      itemBuilder: (context, index) {
        final identity = items[index];
        final identityId = '${identity.accountId ?? identity.name}_${identity.timestamp.millisecondsSinceEpoch}';
        final isNew = _newIds.contains(identityId);
        final child = widget.tileBuilder(context, identity);
        return isNew ? _NewItemHighlight(child: child) : child;
      },
    );
  }
}

class _DesktopCertificationsTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Widget Function(BuildContext, CertificationDisplayItem) tileBuilder;

  const _DesktopCertificationsTab({required this.scrollController, required this.tileBuilder});

  @override
  ConsumerState<_DesktopCertificationsTab> createState() => _DesktopCertificationsTabState();
}

class _DesktopCertificationsTabState extends ConsumerState<_DesktopCertificationsTab> {
  Set<String> _knownIds = {};
  Set<String> _newIds = {};

  @override
  Widget build(BuildContext context) {
    final certsState = ref.watch(adaptiveFilteredNetworkCertificationsProvider);
    final items = certsState.certifications;

    if (items.isEmpty) {
      final hasFilters = ref.watch(certificationFiltersProvider).hasActiveFilters;
      return _buildEmptyTabState(
        context,
        Icons.verified_outlined,
        hasFilters ? 'noResultsForFilter'.tr() : 'noCertificationActivity'.tr(),
      );
    }

    final currentIds = items.map((c) => c.id).toSet();
    if (_knownIds.isNotEmpty) {
      _newIds = currentIds.difference(_knownIds);
    }
    _knownIds = currentIds;

    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.06)),
      itemBuilder: (context, index) {
        final cert = items[index];
        final isNew = _newIds.contains(cert.id);
        final child = widget.tileBuilder(context, cert);
        return isNew ? _NewItemHighlight(child: child) : child;
      },
    );
  }
}

/// Subtle highlight animation for newly arrived items
class _NewItemHighlight extends StatefulWidget {
  final Widget child;
  const _NewItemHighlight({required this.child});

  @override
  State<_NewItemHighlight> createState() => _NewItemHighlightState();
}

class _NewItemHighlightState extends State<_NewItemHighlight> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _highlightAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: _highlightAnimation.value * 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Filter bar for desktop activity tabs — compact inline filter button with badge
class _DesktopFilterBar extends ConsumerWidget {
  final int activeTabIndex;

  const _DesktopFilterBar({required this.activeTabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the appropriate filter provider based on active tab
    final activeFilterCount = switch (activeTabIndex) {
      0 => ref.watch(networkFiltersProvider).activeFilterCount,
      1 => ref.watch(identityFiltersProvider).activeFilterCount,
      2 => ref.watch(certificationFiltersProvider).activeFilterCount,
      _ => 0,
    };
    final hasFilters = activeFilterCount > 0;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openFilterModal(context, ref),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: hasFilters
                      ? context.colorScheme.primary.withValues(alpha: 0.08)
                      : context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasFilters
                        ? context.colorScheme.primary.withValues(alpha: 0.2)
                        : context.colorScheme.outline.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 16,
                      color: hasFilters
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'filters'.tr(),
                      style: scaledTextStyle(
                        fontSize: 12,
                        color: hasFilters
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: hasFilters ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (hasFilters) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activeFilterCount',
                          style: scaledTextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: hasFilters
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasFilters) ...[
          const SizedBox(width: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _clearFilters(ref),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: context.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colorScheme.error.withValues(alpha: 0.15)),
                ),
                child: Icon(
                  Icons.filter_list_off_rounded,
                  size: 16,
                  color: context.colorScheme.error.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openFilterModal(BuildContext context, WidgetRef ref) {
    switch (activeTabIndex) {
      case 0:
        _showTransactionFiltersModal(context);
        break;
      case 1:
        _showIdentityFiltersModal(context);
        break;
      case 2:
        _showCertificationFiltersModal(context);
        break;
    }
  }

  void _showTransactionFiltersModal(BuildContext context) {
    // Show the same bottom sheet as mobile — it adapts via maxWidth constraint
    showTransactionFilterSheet(context, FilterMode.network);
  }

  void _showIdentityFiltersModal(BuildContext context) {
    showIdentityFilterSheet(context);
  }

  void _showCertificationFiltersModal(BuildContext context) {
    showCertificationFilterSheet(context);
  }

  void _clearFilters(WidgetRef ref) {
    switch (activeTabIndex) {
      case 0:
        ref.read(networkFiltersProvider.notifier).reset();
        break;
      case 1:
        ref.read(identityFiltersProvider.notifier).reset();
        break;
      case 2:
        ref.read(certificationFiltersProvider.notifier).reset();
        break;
    }
  }
}

Widget _buildEmptyTabState(BuildContext context, IconData icon, String message) {
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
