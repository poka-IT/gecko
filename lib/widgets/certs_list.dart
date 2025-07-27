import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/certification_list_providers.dart';
import 'package:gecko/widgets/cert_tile.dart';

class CertDisplayItem {
  final String address;
  final String name;
  final DateTime date;

  CertDisplayItem({required this.address, required this.name, required this.date});
}

class CertsList extends ConsumerStatefulWidget {
  const CertsList({super.key, required this.address, this.direction = CertDirection.received});
  final String address;
  final CertDirection direction;

  @override
  ConsumerState<CertsList> createState() => _CertsListState();
}

class _CertsListState extends ConsumerState<CertsList> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _newCertController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  bool _showNewCertIndicator = false;
  bool _isInitialLoad = true;
  DateTime? _lastCertTimestamp;
  bool _isDisposed = false;

  bool get _isAtTop => _scrollController.hasClients && _scrollController.position.pixels <= 50;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Enhanced animation for new certification indicator
    _newCertController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _newCertController, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _newCertController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    _newCertController.dispose();
    super.dispose();
  }

  void _onNewCertificationReceived() {
    if (mounted && !_isDisposed) {
      setState(() {
        _showNewCertIndicator = true;
      });

      // Only call forward if not disposed
      if (!_isDisposed) {
        _newCertController.forward();
      }

      // Hide the indicator after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && !_isDisposed) {
          _hideNewCertIndicator();
        }
      });
    }
  }

  void _hideNewCertIndicator() {
    // Only proceed if not disposed and widget is still mounted
    if (mounted && !_isDisposed) {
      _newCertController.reverse().then((_) {
        if (mounted && !_isDisposed) {
          setState(() {
            _showNewCertIndicator = false;
          });
        }
      });
    } else if (mounted) {
      // If disposed but widget is still mounted, just hide the indicator
      setState(() {
        _showNewCertIndicator = false;
      });
    }
  }

  void _onIndicatorTapped() {
    // Scroll to top of the list
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);

    // Hide the indicator immediately
    _hideNewCertIndicator();
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have network connection
    final connectionStatus = ref.watch(squidConnectionStatusProvider);
    final isNetworkAvailable = connectionStatus == d.ConnectionStatus.connected;

    if (!isNetworkAvailable) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: scaleSize(20)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: scaleSize(32), color: context.colorScheme.onSurface.withValues(alpha: 0.3)),
              ScaledSizedBox(height: 12),
              Text(
                "noNetworkNoHistory".tr(),
                textAlign: TextAlign.center,
                style: scaledTextStyle(fontSize: 15, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      );
    }

    final certState = ref.watch(certificationListProvider((address: widget.address, direction: widget.direction)));

    // Check for new certifications using timestamp comparison
    if (!_isInitialLoad && !certState.isLoading && certState.certifications.isNotEmpty) {
      // Extract timestamp from first certification
      final currentLatestTimestamp = certState.certifications.first.date;

      // Check if we have a newer certification than before
      if (_lastCertTimestamp != null && currentLatestTimestamp.isAfter(_lastCertTimestamp!)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onNewCertificationReceived();
        });
      }

      // Always update the latest timestamp
      _lastCertTimestamp = currentLatestTimestamp;
    }

    // Set initial timestamp after first load
    if (_isInitialLoad && !certState.isLoading && certState.certifications.isNotEmpty) {
      _lastCertTimestamp = certState.certifications.first.date;
      _isInitialLoad = false;
    }

    // Mark initial load as complete even if no certifications
    if (_isInitialLoad && !certState.isLoading) {
      _isInitialLoad = false;
    }

    return Stack(
      children: [
        Builder(
          builder: (context) {
            // Handle loading state
            if (certState.isLoading && certState.certifications.isEmpty) {
              return Container(
                padding: EdgeInsets.symmetric(vertical: scaleSize(40)),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: context.colorScheme.primary),
                      ScaledSizedBox(height: 12),
                      Text(
                        'loadingCertifications'.tr(),
                        style: scaledTextStyle(
                          fontSize: 13,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Handle error state
            if (certState.hasError && certState.certifications.isEmpty) {
              return Container(
                padding: EdgeInsets.symmetric(vertical: scaleSize(20)),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: scaleSize(32),
                        color: context.colorScheme.error.withValues(alpha: 0.6),
                      ),
                      ScaledSizedBox(height: 12),
                      Text(
                        "noNetworkNoHistory".tr(),
                        textAlign: TextAlign.center,
                        style: scaledTextStyle(
                          fontSize: 15,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Handle empty state
            if (certState.certifications.isEmpty && !certState.isLoading) {
              return Container(
                padding: EdgeInsets.symmetric(vertical: scaleSize(20)),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.direction == CertDirection.received ? Icons.call_received : Icons.call_made,
                        size: scaleSize(32),
                        color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      ScaledSizedBox(height: 12),
                      Text(
                        "noDataToDisplay".tr(),
                        style: scaledTextStyle(
                          fontSize: 15,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Handle success state with certifications
            return RefreshIndicator(
              color: context.colorScheme.primary,
              onRefresh: () async {
                await ref
                    .read(certificationListProvider((address: widget.address, direction: widget.direction)).notifier)
                    .refresh();
              },
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white, Colors.white.withValues(alpha: 0.0)],
                    stops: const [0.0, 0.95, 1.0], // Fade starts at 95% of the height
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ListView(
                  key: keyListTransactions,
                  controller: _scrollController,
                  shrinkWrap: true, // Allow ListView to shrink to content size
                  padding: EdgeInsets.only(
                    top: scaleSize(4),
                    bottom: scaleSize(24),
                    left: scaleSize(8),
                    right: scaleSize(8),
                  ), // Extra bottom padding for fade effect
                  children: <Widget>[
                    Column(children: <Widget>[CertTile(listCerts: certState.certifications)]),
                    // Show loading indicator at the bottom when refreshing
                    if (certState.isLoading && certState.certifications.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                        alignment: Alignment.center,
                        child: Container(
                          padding: EdgeInsets.all(scaleSize(8)),
                          decoration: BoxDecoration(
                            color: context.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(scaleSize(16)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: scaleSize(14),
                                width: scaleSize(14),
                                child: CircularProgressIndicator(strokeWidth: 2, color: context.colorScheme.primary),
                              ),
                              ScaledSizedBox(width: 6),
                              Text(
                                'refreshing'.tr(),
                                style: scaledTextStyle(
                                  fontSize: 11,
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Certification indicator
        if (_showNewCertIndicator)
          Positioned(
            top: scaleSize(12),
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: GestureDetector(
                    onTap: _onIndicatorTapped,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(8)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.colorScheme.primary, context.colorScheme.primary.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(scaleSize(20)),
                        boxShadow: [
                          BoxShadow(
                            color: context.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user, color: Colors.white, size: scaleSize(14)),
                          ScaledSizedBox(width: 6),
                          Text(
                            widget.direction == CertDirection.received
                                ? "newCertificationReceived".tr()
                                : "newCertificationSent".tr(),
                            style: scaledTextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          if (!_isAtTop) ...[
                            ScaledSizedBox(width: 6),
                            Icon(Icons.keyboard_arrow_up, color: Colors.white, size: scaleSize(14)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum CertDirection { received, sent }
