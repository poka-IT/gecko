import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/cert_alert_provider.dart';
import 'package:gecko/widgets/certs_list.dart';

/// A small colored dot indicator for certification alert status.
///
/// Renders a circular badge overlay:
/// - Red ([CertAlertStatus.expired]) when any certification has expired
/// - Orange ([CertAlertStatus.expiringSoon]) when any certification expires within 30 days
/// - Nothing ([SizedBox.shrink]) when all certifications are healthy
///
/// Designed to be positioned on top of wallet tiles or contact avatars
/// using a [Stack] + [Positioned] layout.
class CertAlertDot extends ConsumerWidget {
  const CertAlertDot({
    super.key,
    required this.address,
    required this.direction,
    this.size = 10,
  });

  /// The wallet or contact address to check certifications for.
  final String address;

  /// Whether to check received or sent certifications.
  final CertDirection direction;

  /// The diameter of the dot in logical pixels (before scaling).
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(certAlertStatusProvider((address: address, direction: direction)));

    if (status == CertAlertStatus.none) {
      return const SizedBox.shrink();
    }

    final color = switch (status) {
      CertAlertStatus.expired => context.geckoColors.danger,
      CertAlertStatus.expiringSoon => context.geckoColors.warning,
      CertAlertStatus.none => Colors.transparent, // unreachable
    };

    return Container(
      width: scaleSize(size),
      height: scaleSize(size),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
