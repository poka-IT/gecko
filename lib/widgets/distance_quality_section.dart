import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/distance_provider.dart';
import 'package:gecko/services/distance_service.dart';

class DistanceQualitySection extends ConsumerWidget {
  const DistanceQualitySection({super.key, required this.address});
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distanceState = ref.watch(distanceProvider(address));

    return Container(
      margin: EdgeInsets.fromLTRB(scaleSize(8), scaleSize(4), scaleSize(8), 0),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(scaleSize(10)),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.15), width: 1),
      ),
      child: switch (distanceState) {
        DistanceIdle() => _buildIdleState(context, ref),
        DistanceComputing(:final progress) => _buildComputingState(context, progress),
        DistanceCompleted(:final result) => _buildCompletedState(context, ref, result),
        DistanceError(:final message) => _buildErrorState(context, ref, message),
      },
    );
  }

  Widget _buildIdleState(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => ref.read(distanceProvider(address).notifier).compute(),
      borderRadius: BorderRadius.circular(scaleSize(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(10)),
        child: Row(
          children: [
            Container(
              width: scaleSize(28),
              height: scaleSize(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
              ),
              child: Icon(Icons.hub, size: scaleSize(14), color: Colors.orange.shade700),
            ),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Text(
                'distanceAndQuality'.tr(),
                style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.colorScheme.onSurface),
              ),
            ),
            Icon(Icons.play_arrow_rounded, size: scaleSize(22), color: Colors.orange.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildComputingState(BuildContext context, double progress) {
    final percentage = (progress * 100).toInt();

    String phaseText;
    if (progress < 0.15) {
      phaseText = 'fetchingIdentities'.tr();
    } else if (progress < 0.95) {
      phaseText = 'fetchingCertifications'.tr();
    } else {
      phaseText = 'computingDistance'.tr();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: scaleSize(16),
                height: scaleSize(16),
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange.shade600),
              ),
              ScaledSizedBox(width: 10),
              Text(
                '$percentage% — $phaseText',
                style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
          ScaledSizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(scaleSize(3)),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.colorScheme.outline.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade500),
              minHeight: scaleSize(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(BuildContext context, WidgetRef ref, DistanceResult result) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(10)),
      child: Row(
        children: [
          // Distance metric
          Expanded(
            child: _buildMetric(
              context,
              'distanceLabel'.tr(),
              result.distanceRatio,
              result.distanceAccessible,
              result.distanceTotal,
              result.xPercent,
            ),
          ),
          Container(width: 1, height: scaleSize(36), color: Colors.orange.withValues(alpha: 0.15)),
          // Quality metric
          Expanded(
            child: _buildMetric(
              context,
              'qualityLabel'.tr(),
              result.qualityRatio,
              result.qualityAccessible,
              result.qualityTotal,
              result.xPercent,
            ),
          ),
          // Recompute button
          InkWell(
            onTap: () => ref.read(distanceProvider(address).notifier).compute(),
            borderRadius: BorderRadius.circular(scaleSize(16)),
            child: Padding(
              padding: EdgeInsets.all(scaleSize(6)),
              child: Icon(Icons.refresh, size: scaleSize(18), color: Colors.orange.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, double ratio, int accessible, int total, double threshold) {
    final percentage = (ratio * 100).toStringAsFixed(1);
    final isOk = ratio >= threshold;
    final valueColor = isOk ? Colors.green.shade600 : Colors.red.shade600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.5))),
        ScaledSizedBox(height: 2),
        Text(
          '$percentage%',
          style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: valueColor),
        ),
        Text(
          'refereesAccessible'.tr(args: [accessible.toString(), total.toString()]),
          style: scaledTextStyle(fontSize: 10, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String message) {
    return InkWell(
      onTap: () => ref.read(distanceProvider(address).notifier).compute(),
      borderRadius: BorderRadius.circular(scaleSize(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: scaleSize(20)),
                ScaledSizedBox(width: 10),
                Expanded(
                  child: Text(
                    'distanceComputeError'.tr(),
                    style: scaledTextStyle(fontSize: 13, color: Colors.red.shade600),
                  ),
                ),
                Icon(Icons.refresh, size: scaleSize(18), color: Colors.orange.shade400),
              ],
            ),
            ScaledSizedBox(height: 6),
            Text(
              message,
              style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
