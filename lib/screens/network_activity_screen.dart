import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/network_activity_provider.dart';
import 'package:gecko/providers/network_identities_provider.dart';
import 'package:gecko/providers/network_certifications_provider.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/providers/identity_filters_provider.dart';
import 'package:gecko/providers/certification_filters_provider.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/network_activity/transaction_activity_tab.dart';
import 'package:gecko/widgets/network_activity/identity_activity_tab.dart';
import 'package:gecko/widgets/network_activity/certification_activity_tab.dart';

class NetworkActivityScreen extends ConsumerStatefulWidget {
  const NetworkActivityScreen({super.key});

  @override
  ConsumerState<NetworkActivityScreen> createState() => _NetworkActivityScreenState();
}

class _NetworkActivityScreenState extends ConsumerState<NetworkActivityScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late AnimationController _newActivityController;
  late Animation<double> _fadeInAnimation;
  bool _showNewActivityIndicator = false;
  bool _isDisposed = false;
  Timer? _hideIndicatorTimer;
  double _lastScrollOffset = 0.0;
  double _filterTranslationY = 0.0;

  bool get _isAtTop => _scrollController.hasClients && _scrollController.position.pixels <= 50;

  @override
  void initState() {
    super.initState();

    // Initialize tab controller with 3 tabs
    _tabController = TabController(length: 3, vsync: this);

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Animation for new activity indicator
    _newActivityController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _newActivityController, curve: Curves.easeInOut));

    // Clear all filters when opening network activity screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          Future.delayed(Duration.zero, () {
            if (mounted) {
              ref.read(networkFiltersProvider.notifier).reset();
              ref.read(identityFiltersProvider.notifier).reset();
              ref.read(certificationFiltersProvider.notifier).reset();
            }
          });
        } catch (e) {
          // Silently handle any errors during filter reset
          debugPrint('Network filter reset error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hideIndicatorTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();

    // Stop any ongoing animation before disposing
    if (_newActivityController.isAnimating) {
      _newActivityController.stop();
    }
    _newActivityController.dispose();

    super.dispose();
  }

  void _onScroll() {
    final currentTabIndex = _tabController.index;

    // Load more content based on current tab
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7) {
      switch (currentTabIndex) {
        case 0: // Transactions
          loadMoreNetworkTransactions(ref);
          break;
        case 1: // Identities
          loadMoreNetworkIdentities(ref);
          break;
        case 2: // Certifications
          loadMoreNetworkCertifications(ref);
          break;
      }
    }

    // Handle filter visibility for current tab
    _handleFilterVisibility(currentTabIndex);
  }

  void _handleFilterVisibility(int tabIndex) {
    if (!_scrollController.hasClients) return;

    // Get appropriate filter provider based on tab
    bool hasAdvancedFilters = false;
    bool isFilterPanelExpanded = false;

    switch (tabIndex) {
      case 0: // Transactions
        hasAdvancedFilters = ref.read(networkFiltersProvider).hasActiveFilters;
        isFilterPanelExpanded = ref.read(networkFilterPanelExpandedProvider);
        break;
      case 1: // Identities
        hasAdvancedFilters = ref.read(identityFiltersProvider).hasActiveFilters;
        isFilterPanelExpanded = ref.read(identityFilterPanelExpandedProvider);
        break;
      case 2: // Certifications
        hasAdvancedFilters = ref.read(certificationFiltersProvider).hasActiveFilters;
        isFilterPanelExpanded = ref.read(certificationFilterPanelExpandedProvider);
        break;
    }

    if (!hasAdvancedFilters && !isFilterPanelExpanded) {
      final currentOffset = _scrollController.position.pixels;
      final scrollDelta = currentOffset - _lastScrollOffset;

      // Always show filter when at the top
      if (currentOffset <= 50) {
        if (_filterTranslationY != 0.0) {
          setState(() {
            _filterTranslationY = 0.0;
          });
        }
      } else if (scrollDelta.abs() > 2.0) {
        // Threshold to avoid jitter
        const sensitivity = 0.02;

        // Update translation based on scroll direction
        double newTranslation = _filterTranslationY - (scrollDelta * sensitivity);
        newTranslation = newTranslation.clamp(-1.0, 0.0);

        if ((newTranslation - _filterTranslationY).abs() > 0.01) {
          setState(() {
            _filterTranslationY = newTranslation;
          });
        }
      }

      _lastScrollOffset = currentOffset;
    }
  }

  void _onNewNetworkActivityReceived(String activityType) {
    // Only show notification for the currently active tab
    final currentTabIndex = _tabController.index;
    final expectedType = ['transactions', 'identities', 'certifications'][currentTabIndex];

    // Only trigger notification if the activity matches the current tab
    if (activityType == expectedType && mounted && !_isDisposed) {
      setState(() {
        _showNewActivityIndicator = true;
      });

      // Only call forward if not disposed
      if (!_isDisposed) {
        _newActivityController.forward();
      }

      // Cancel previous timer if exists
      _hideIndicatorTimer?.cancel();

      // Hide the indicator after 3 seconds
      _hideIndicatorTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isDisposed) {
          _hideNewActivityIndicator();
        }
      });
    }
  }

  void _hideNewActivityIndicator() {
    // Cancel the timer since we're hiding manually
    _hideIndicatorTimer?.cancel();

    // Only proceed if not disposed and widget is still mounted
    if (mounted && !_isDisposed) {
      // Check if animation controller is still valid
      if (_newActivityController.isAnimating || _newActivityController.status == AnimationStatus.completed) {
        _newActivityController
            .reverse()
            .then((_) {
              if (mounted && !_isDisposed) {
                setState(() {
                  _showNewActivityIndicator = false;
                });
              }
            })
            .catchError((error) {
              // Ignore errors from disposed animation controller
            });
      } else {
        // If animation is not running, just hide immediately
        if (mounted && !_isDisposed) {
          setState(() {
            _showNewActivityIndicator = false;
          });
        }
      }
    }
  }

  void _onIndicatorTapped() {
    // Scroll to top of the list
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);

    // Hide the indicator immediately
    _hideNewActivityIndicator();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(scaleSize(57) + 72), // GeckoAppBar height + tabs height with padding
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GeckoAppBar('networkActivity'.tr()),
              Material(
                color: context.colorScheme.surface,
                child: SizedBox(
                  height: 72, // Fixed height for TabBar with icon + text
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: context.colorScheme.primary,
                    labelColor: context.colorScheme.primary,
                    unselectedLabelColor: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    labelStyle: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.swap_horiz, size: scaleSize(20)),
                        text: 'transactions'.tr(),
                      ),
                      Tab(
                        icon: Icon(Icons.person, size: scaleSize(20)),
                        text: 'identities'.tr(),
                      ),
                      Tab(
                        icon: Icon(Icons.verified, size: scaleSize(20)),
                        text: 'certifications'.tr(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              TransactionActivityTab(
                scrollController: _scrollController,
                filterTranslationY: _filterTranslationY,
                onNewActivityDetected: () => _onNewNetworkActivityReceived('transactions'),
              ),
              IdentityActivityTab(
                scrollController: _scrollController,
                filterTranslationY: _filterTranslationY,
                onNewActivityDetected: () => _onNewNetworkActivityReceived('identities'),
              ),
              CertificationActivityTab(
                scrollController: _scrollController,
                filterTranslationY: _filterTranslationY,
                onNewActivityDetected: () => _onNewNetworkActivityReceived('certifications'),
              ),
            ],
          ),
          // New activity indicator (positioned absolutely)
          if (_showNewActivityIndicator)
            Positioned(
              top: 16, // Position at top with margin
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: GestureDetector(
                  onTap: _onIndicatorTapped,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.public, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "newNetworkActivity".tr(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        if (!_isAtTop) Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
