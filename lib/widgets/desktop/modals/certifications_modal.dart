import 'package:accordion/accordion.dart';
import 'package:accordion/controllers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/certs_counter.dart';
import 'package:gecko/widgets/certs_list.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/distance_quality_section.dart';

/// Shows certifications (received/sent) inside a desktop modal.
Future<void> showDesktopCertificationsModal(BuildContext context, {required String address, required String username}) {
  return showDesktopModal(
    context: context,
    title: 'certificationsOf'.tr(args: [username]),
    size: DesktopModalSize.medium,
    contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
    builder: (context) => _DesktopCertificationsContent(address: address, username: username),
  );
}

class _DesktopCertificationsContent extends StatefulWidget {
  final String address;
  final String username;

  const _DesktopCertificationsContent({required this.address, required this.username});

  @override
  State<_DesktopCertificationsContent> createState() => _DesktopCertificationsContentState();
}

class _DesktopCertificationsContentState extends State<_DesktopCertificationsContent> {
  bool _isReceivedOpen = true;
  bool _isSentOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DistanceQualitySection(address: widget.address),
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
                onCloseSection: () => setState(() => _isReceivedOpen = false),
                header: _buildHeader(
                  context: context,
                  title: 'received'.tr(),
                  icon: Icons.call_received,
                  isReceived: true,
                  isOpen: _isReceivedOpen,
                ),
                content: Container(
                  color: context.colorScheme.surface,
                  constraints: const BoxConstraints(maxHeight: 320),
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
                onCloseSection: () => setState(() => _isSentOpen = false),
                header: _buildHeader(
                  context: context,
                  title: 'sent'.tr(),
                  icon: Icons.call_made,
                  isReceived: false,
                  isOpen: _isSentOpen,
                ),
                content: Container(
                  color: context.colorScheme.surface,
                  constraints: const BoxConstraints(maxHeight: 320),
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
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isReceived,
    required bool isOpen,
  }) {
    final iconColor = isReceived ? Colors.green.shade600 : Colors.blue.shade600;
    final iconBgColor = isReceived ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1);
    final iconBorderColor = isReceived ? Colors.green.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3);
    final sectionColor = isReceived ? Colors.green.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: sectionColor,
        borderRadius: BorderRadius.circular(scaleSize(8)),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(4)),
        child: Row(
          children: [
            Container(
              width: scaleSize(28),
              height: scaleSize(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
                border: Border.all(color: iconBorderColor),
              ),
              child: Icon(icon, size: scaleSize(14), color: iconColor),
            ),
            ScaledSizedBox(width: 12),
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
                  CertsCounter(address: widget.address, isSent: !isReceived),
                ],
              ),
            ),
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0.0,
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
