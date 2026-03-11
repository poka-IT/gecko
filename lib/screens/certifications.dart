import 'package:accordion/controllers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/certs_list.dart';
import 'package:gecko/widgets/certs_counter.dart';
import 'package:accordion/accordion.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/distance_quality_section.dart';

class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key, required this.address, required this.username});
  final String address;
  final String username;

  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  bool _isReceivedOpen = true;
  bool _isSentOpen = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomBarHeight = MediaQuery.of(context).padding.bottom + 60; // Bottom navigation + padding
    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - appBarHeight - bottomBarHeight;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('certificationsOf'.tr(args: [widget.username])),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 600,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Distance & Quality section (fixed at top, not collapsible)
              DistanceQualitySection(address: widget.address),

              // Certifications accordion (takes remaining space)
              Expanded(
                child: Accordion(
                  paddingListTop: scaleSize(4),
                  paddingListBottom: scaleSize(0),
                  paddingListHorizontal: 0,
                  maxOpenSections: 1,
                  headerBackgroundColorOpened: Colors.transparent,
                  scaleWhenAnimating: false,
                  openAndCloseAnimation: true,
                  headerPadding: EdgeInsets.zero,
                  sectionOpeningHapticFeedback: SectionHapticFeedback.heavy,
                  sectionClosingHapticFeedback: SectionHapticFeedback.light,
                  children: [
                    AccordionSection(
                      isOpen: _isReceivedOpen,
                      leftIcon: const SizedBox.shrink(),
                      headerBackgroundColor: context.colorScheme.surface,
                      headerBackgroundColorOpened: context.colorScheme.surface,
                      contentBackgroundColor: context.colorScheme.surface,
                      rightIcon: const SizedBox.shrink(),
                      onOpenSection: () => setState(() {
                        _isReceivedOpen = true;
                        _isSentOpen = false;
                      }),
                      onCloseSection: () => setState(() {
                        _isReceivedOpen = false;
                      }),
                      header: _buildModernHeader(
                        context: context,
                        title: 'received'.tr(),
                        icon: Icons.call_received,
                        address: widget.address,
                        isReceived: true,
                        isOpen: _isReceivedOpen,
                      ),
                      content: Container(
                        color: context.colorScheme.surface,
                        constraints: BoxConstraints(maxHeight: availableHeight * 0.65),
                        child: CertsList(address: widget.address, direction: CertDirection.received),
                      ),
                      contentHorizontalPadding: 0,
                      contentBorderWidth: 0,
                      paddingBetweenOpenSections: scaleSize(2),
                    ),
                    AccordionSection(
                      isOpen: _isSentOpen,
                      leftIcon: const SizedBox.shrink(),
                      headerBackgroundColor: context.colorScheme.surface,
                      headerBackgroundColorOpened: context.colorScheme.surface,
                      contentBackgroundColor: context.colorScheme.surface,
                      rightIcon: const SizedBox.shrink(),
                      onOpenSection: () => setState(() {
                        _isSentOpen = true;
                        _isReceivedOpen = false;
                      }),
                      onCloseSection: () => setState(() {
                        _isSentOpen = false;
                      }),
                      header: _buildModernHeader(
                        context: context,
                        title: 'sent'.tr(),
                        icon: Icons.call_made,
                        address: widget.address,
                        isReceived: false,
                        isOpen: _isSentOpen,
                      ),
                      content: Container(
                        color: context.colorScheme.surface,
                        constraints: BoxConstraints(maxHeight: availableHeight * 0.65),
                        child: CertsList(address: widget.address, direction: CertDirection.sent),
                      ),
                      contentHorizontalPadding: 0,
                      contentBorderWidth: 0,
                      paddingBetweenOpenSections: scaleSize(2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String address,
    required bool isReceived,
    required bool isOpen,
  }) {
    // Define distinct colors for received (green) and sent (blue)
    final sectionColor = isReceived ? Colors.green.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05);
    final iconColor = isReceived ? Colors.green.shade600 : Colors.blue.shade600;
    final iconBgColor = isReceived ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1);
    final iconBorderColor = isReceived ? Colors.green.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3);

    return Container(
      decoration: BoxDecoration(
        color: sectionColor,
        borderRadius: BorderRadius.circular(scaleSize(8)),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(4)),
        child: Row(
          children: [
            // Compact icon container with section-specific colors
            Container(
              width: scaleSize(28),
              height: scaleSize(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
                border: Border.all(color: iconBorderColor, width: 1),
              ),
              child: Icon(icon, size: scaleSize(14), color: iconColor),
            ),

            ScaledSizedBox(width: 12),

            // Title and counter
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: scaledTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  ScaledSizedBox(width: 6),
                  CertsCounter(address: address, isSent: !isReceived),
                ],
              ),
            ),

            // Animated expand/collapse indicator that changes based on open state
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0.0, // 180 degrees rotation when open
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: EdgeInsets.all(scaleSize(2)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorScheme.outline.withValues(alpha: 0.08),
                ),
                child: Icon(
                  Icons.expand_more,
                  size: scaleSize(16),
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
