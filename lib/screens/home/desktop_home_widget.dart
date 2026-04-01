import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/home_alert_provider.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/screens/home/gecko_home_widget.dart' show handleHomeAlertTap;
import 'package:gecko/services/config_service.dart';
import 'package:gecko/providers/network_activity_provider.dart';
import 'package:gecko/providers/network_certifications_provider.dart';
import 'package:gecko/providers/network_identities_provider.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/providers/search_provider.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/home/desktop/desktop_activity_panel.dart';
import 'package:gecko/screens/home/desktop/desktop_activity_tiles.dart';
import 'package:gecko/screens/home/desktop/desktop_search_section.dart';
import 'package:gecko/screens/home/desktop/desktop_shared.dart';
import 'package:gecko/screens/home/desktop/desktop_status_cards.dart';
import 'package:gecko/screens/home/desktop/desktop_wallet_overview.dart';
import 'package:gecko/screens/home/desktop/desktop_welcome_section.dart';
import 'package:gecko/services/image_cache_service.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/widgets/animated_header_image.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/desktop/desktop_drag_info_bar.dart';
import 'package:gecko/widgets/desktop/modals/keyboard_shortcuts_modal.dart';
import 'package:gecko/widgets/desktop/modals/settings_modal.dart';
import 'package:gecko/widgets/desktop/panels/contacts_panel.dart';
import 'package:gecko/widgets/easter_egg_detector.dart';
import 'package:gecko/widgets/global_search_palette_dialog.dart';

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
  bool _isContactsPanelOpen = ConfigService(configBox).contactsPanelOpen;
  bool _isActivityPanelOpen = ConfigService(configBox).activityPanelOpen;
  bool _isSearchPaletteOpen = false;

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
    // No setState needed -- the search section rebuilds via its own ListenableBuilder
  }

  void _onDesktopSearchFocusChanged() {
    // No setState needed -- the search section rebuilds via its own ListenableBuilder
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

  void _toggleContactsPanel() {
    final config = ref.read(configServiceProvider);
    setState(() {
      _isContactsPanelOpen = !_isContactsPanelOpen;
      // On narrow screens, auto-close activity panel when opening contacts
      if (_isContactsPanelOpen && _isActivityPanelOpen && _isNarrowDesktop) {
        _isActivityPanelOpen = false;
        config.activityPanelOpen = false;
      }
    });
    config.contactsPanelOpen = _isContactsPanelOpen;
  }

  void _toggleActivityPanel() {
    final config = ref.read(configServiceProvider);
    setState(() {
      _isActivityPanelOpen = !_isActivityPanelOpen;
      // On narrow screens, auto-close contacts panel when opening activity
      if (_isActivityPanelOpen && _isContactsPanelOpen && _isNarrowDesktop) {
        _isContactsPanelOpen = false;
        config.contactsPanelOpen = false;
      }
    });
    config.activityPanelOpen = _isActivityPanelOpen;
  }

  bool get _isNarrowDesktop => MediaQuery.of(context).size.width < 1200;

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

  /// Returns true when the primary focus is inside any text input (TextField,
  /// TextFormField, etc.). Used to prevent single-letter shortcuts from firing
  /// while the user is typing - regardless of which text field has focus.
  bool _isTextInputFocused() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return false;
    final ctx = primaryFocus.context;
    if (ctx == null) return false;
    var found = false;
    ctx.visitAncestorElements((element) {
      if (element.widget is EditableText) {
        found = true;
        return false; // stop walking
      }
      return true; // continue
    });
    return found;
  }

  KeyEventResult _handleDesktopHomeKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _isTextInputFocused()) {
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

    // K, F or R -- open global search palette
    if (event.logicalKey == LogicalKeyboardKey.keyK ||
        event.logicalKey == LogicalKeyboardKey.keyF ||
        event.logicalKey == LogicalKeyboardKey.keyR) {
      _openGlobalSearchPalette();
      return KeyEventResult.handled;
    }

    // H -- open keyboard shortcuts modal
    if (event.logicalKey == LogicalKeyboardKey.keyH) {
      showKeyboardShortcutsModal(context);
      return KeyEventResult.handled;
    }

    // / -- focus search bar
    if (event.logicalKey == LogicalKeyboardKey.slash) {
      _desktopSearchFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // C -- toggle contacts panel
    if (event.logicalKey == LogicalKeyboardKey.keyC) {
      _toggleContactsPanel();
      return KeyEventResult.handled;
    }

    // S -- open QR code scanner
    if (event.logicalKey == LogicalKeyboardKey.keyS) {
      _openQrScanner(context);
      return KeyEventResult.handled;
    }

    // A -- toggle activity panel
    if (event.logicalKey == LogicalKeyboardKey.keyA) {
      _toggleActivityPanel();
      return KeyEventResult.handled;
    }

    // P -- open settings
    if (event.logicalKey == LogicalKeyboardKey.keyP) {
      showDesktopSettingsModal(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _pushDesktopProfileRoute(BuildContext context, {required String address, String? username}) {
    NavigationService.openProfile(context, address: address, username: username?.isNotEmpty == true ? username : null);
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
                      final showContacts = _isContactsPanelOpen;
                      final showActivity = _isActivityPanelOpen;
                      final bothOpen = showContacts && showActivity;
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1600),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showContacts) ...[
                                Expanded(flex: bothOpen ? 3 : 4, child: _buildContactsColumn(context, ref)),
                                const SizedBox(width: 18),
                              ],
                              Expanded(
                                flex: bothOpen ? 5 : (showContacts || showActivity ? 6 : 1),
                                child: _buildLeftPanel(context, ref),
                              ),
                              if (showActivity) ...[
                                const SizedBox(width: 18),
                                Expanded(flex: bothOpen ? 4 : 5, child: _buildActivityPanel(context, ref)),
                              ],
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
    return buildDesktopPanelShell(
      context,
      child: DesktopContactsPanel(
        onContactTap: (address, username) => _pushDesktopProfileRoute(context, address: address, username: username),
      ),
    );
  }

  // ─────────────────────────── Center Panel ───────────────────────────

  Widget _buildLeftPanel(BuildContext context, WidgetRef ref) {
    final hasWallets = ref.watch(isWalletsExistsProvider);

    return buildDesktopPanelShell(
      context,
      child: Column(
        children: [
          // Top fixed section: header + message + search
          _buildLeftPanelHeader(context, ref),
          // Main content area
          if (hasWallets)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const DesktopTotalBalanceCard(),
                    const SizedBox(height: 12),
                    const DesktopWalletOverview(),
                  ],
                ),
              ),
            )
          else
            const Expanded(child: Center(child: DesktopWelcomeSection())),
          const SizedBox(height: 14),
          const DesktopNetworkStatusCard(),
        ],
      ),
    );
  }

  /// Top section of the left panel: header image, message, search bar
  Widget _buildLeftPanelHeader(BuildContext context, WidgetRef ref) {
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
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 4, left: 48, right: 24),
          child: DefaultTextStyle(
            textAlign: TextAlign.center,
            style: scaledTextStyle(color: context.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700),
            child: const _DesktopHomeMessageDisplay(),
          ),
        ),
        const SizedBox(height: 18),
        // ListenableBuilder isolates search rebuilds from the rest of the left panel
        ListenableBuilder(
          listenable: Listenable.merge([_desktopSearchController, _desktopSearchFocusNode]),
          builder: (context, _) => DesktopSearchSection(
            searchController: _desktopSearchController,
            searchFocusNode: _desktopSearchFocusNode,
            searchScrollController: _desktopSearchScrollController,
            onFocusDesktopHomeShell: _focusDesktopHomeShell,
            onToggleContactsPanel: _toggleContactsPanel,
            onToggleActivityPanel: _toggleActivityPanel,
            isContactsPanelOpen: _isContactsPanelOpen,
            isActivityPanelOpen: _isActivityPanelOpen,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── Activity Panel (right, full height) ───

  Widget _buildActivityPanel(BuildContext context, WidgetRef ref) {
    return buildDesktopPanelShell(
      context,
      child: DesktopNetworkActivityFeed(
        tabController: _tabController,
        activeTabIndex: _activeActivityTabIndex,
        scrollControllers: _scrollControllers,
        tileBuilders: (
          tx: (context, tx) => buildCompactTransactionTile(context, tx),
          identity: (context, identity) => buildCompactIdentityTile(context, identity),
          cert: (context, cert) => buildCompactCertificationTile(context, cert),
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
}

/// Desktop variant of the home message display with alert sync.
class _DesktopHomeMessageDisplay extends ConsumerWidget {
  const _DesktopHomeMessageDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeMessage = ref.watch(homeMessageProvider);
    final homeMessageNotifier = ref.read(homeMessageProvider.notifier);

    final alert = ref.watch(homeAlertProvider);
    ref.listen(homeAlertProvider, (_, next) {
      homeMessageNotifier.syncWithAlert(next);
    });

    final isIdle = homeMessage == HomeMessageNotifier.idleKey;
    final displayText = isIdle ? (alert.hasAlert ? alert.message : 'noLizard'.tr()) : homeMessage;

    return GestureDetector(
      onTap: () {
        if (alert.hasAlert) {
          handleHomeAlertTap(context, alert);
        } else if (isIdle) {
          homeMessageNotifier.showWisdomOfTheDay(context);
        }
      },
      child: AnimatedFadeOutIn<String>(
        data: displayText,
        duration: const Duration(milliseconds: 200),
        builder: (value) => Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
