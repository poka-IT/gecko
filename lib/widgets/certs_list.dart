import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/certification_list_providers.dart';
import 'package:gecko/widgets/cert_tile.dart';

class CertDisplayItem {
  final String address;
  final String name;
  final String date;

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
  bool _showNewCertIndicator = false;
  bool _isInitialLoad = true;
  DateTime? _lastCertTimestamp;
  bool _isDisposed = false;

  bool get _isAtTop => _scrollController.hasClients && _scrollController.position.pixels <= 50;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Animation for new certification indicator
    _newCertController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _newCertController, curve: Curves.easeInOut));
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

      // Hide the indicator after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
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
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final windowHeight = screenHeight - appBarHeight - (isTall ? 170 : 140);

    // Check if we have network connection
    final connectionStatus = ref.watch(squidConnectionStatusProvider);
    final isNetworkAvailable = connectionStatus == d.ConnectionStatus.connected;

    if (!isNetworkAvailable) {
      return Column(
        children: <Widget>[
          ScaledSizedBox(height: 50),
          Text("noNetworkNoHistory".tr(), textAlign: TextAlign.center, style: scaledTextStyle(fontSize: 17)),
        ],
      );
    }

    final certState = ref.watch(certificationListProvider((address: widget.address, direction: widget.direction)));

    // Check for new certifications using timestamp comparison
    if (!_isInitialLoad && !certState.isLoading && certState.certifications.isNotEmpty) {
      // Extract timestamp from first certification
      final dateParts = certState.certifications.first.date.split('-');
      if (dateParts.length == 3) {
        final currentLatestTimestamp = DateTime(
          int.parse(dateParts[2]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[0]), // day
        );

        // Check if we have a newer certification than before
        if (_lastCertTimestamp != null && currentLatestTimestamp.isAfter(_lastCertTimestamp!)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onNewCertificationReceived();
          });
        }

        // Always update the latest timestamp
        _lastCertTimestamp = currentLatestTimestamp;
      }
    }

    // Set initial timestamp after first load
    if (_isInitialLoad && !certState.isLoading && certState.certifications.isNotEmpty) {
      final dateParts = certState.certifications.first.date.split('-');
      if (dateParts.length == 3) {
        _lastCertTimestamp = DateTime(
          int.parse(dateParts[2]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[0]), // day
        );
      }
      _isInitialLoad = false;
    }

    // Mark initial load as complete even if no certifications
    if (_isInitialLoad && !certState.isLoading) {
      _isInitialLoad = false;
    }

    return Stack(
      children: [
        SizedBox(
          height: windowHeight,
          child: Builder(
            builder: (context) {
              // Handle loading state
              if (certState.isLoading && certState.certifications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Handle error state
              if (certState.hasError && certState.certifications.isEmpty) {
                return Column(
                  children: <Widget>[
                    ScaledSizedBox(height: 50),
                    Text("noNetworkNoHistory".tr(), textAlign: TextAlign.center, style: scaledTextStyle(fontSize: 17)),
                  ],
                );
              }

              // Handle empty state
              if (certState.certifications.isEmpty && !certState.isLoading) {
                return Column(
                  children: <Widget>[
                    ScaledSizedBox(height: 50),
                    Text("noDataToDisplay".tr(), style: scaledTextStyle(fontSize: 17)),
                  ],
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
                child: ListView(
                  key: keyListTransactions,
                  controller: _scrollController,
                  children: <Widget>[
                    Column(children: <Widget>[CertTile(listCerts: certState.certifications)]),
                    // Show a small loading indicator at the bottom when refreshing
                    if (certState.isLoading && certState.certifications.isNotEmpty)
                      Container(
                        height: 30,
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: context.colorScheme.primary),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // New certification indicator
        if (_showNewCertIndicator)
          Positioned(
            top: 16,
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
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.direction == CertDirection.received
                            ? "newCertificationReceived".tr()
                            : "newCertificationSent".tr(),
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
    );
  }
}

enum CertDirection { received, sent }
