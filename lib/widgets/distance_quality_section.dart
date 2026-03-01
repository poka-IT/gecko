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

    return switch (distanceState) {
      DistanceIdle() => _buildIdleState(context, ref),
      DistanceComputing(:final progress) => _buildComputingState(context, progress),
      DistanceCompleted(:final result) => _buildCompletedState(context, ref, result),
      DistanceError(:final message) => _buildErrorState(context, ref, message),
    };
  }

  Widget _buildIdleState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(16)),
        child: FilledButton.icon(
          onPressed: () => ref.read(distanceProvider(address).notifier).compute(),
          icon: Icon(Icons.play_circle_outline, size: scaleSize(20)),
          label: Text('computeDistanceQuality'.tr()),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: scaleSize(20), vertical: scaleSize(10)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleSize(12))),
          ),
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
      padding: EdgeInsets.all(scaleSize(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: context.colorScheme.outline.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
            borderRadius: BorderRadius.circular(scaleSize(4)),
            minHeight: scaleSize(6),
          ),
          ScaledSizedBox(height: 10),
          Text(
            '$percentage% — $phaseText',
            style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(BuildContext context, WidgetRef ref, DistanceResult result) {
    return Padding(
      padding: EdgeInsets.all(scaleSize(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context: context,
                  label: 'distanceLabel'.tr(),
                  ratio: result.distanceRatio,
                  accessible: result.distanceAccessible,
                  total: result.distanceTotal,
                  threshold: result.xPercent,
                ),
              ),
              ScaledSizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context: context,
                  label: 'qualityLabel'.tr(),
                  ratio: result.qualityRatio,
                  accessible: result.qualityAccessible,
                  total: result.qualityTotal,
                  threshold: result.xPercent,
                ),
              ),
            ],
          ),
          ScaledSizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.read(distanceProvider(address).notifier).compute(),
            icon: Icon(Icons.refresh, size: scaleSize(16)),
            label: Text('recompute'.tr()),
            style: TextButton.styleFrom(foregroundColor: Colors.orange.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String label,
    required double ratio,
    required int accessible,
    required int total,
    required double threshold,
  }) {
    final percentage = (ratio * 100).toStringAsFixed(1);
    final isAboveThreshold = ratio >= threshold;
    final badgeColor = isAboveThreshold ? Colors.green : Colors.red;

    return Container(
      padding: EdgeInsets.all(scaleSize(12)),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(scaleSize(10)),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: scaledTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          ScaledSizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(10), vertical: scaleSize(4)),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(scaleSize(8)),
            ),
            child: Text(
              '$percentage%',
              style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: badgeColor.shade700),
            ),
          ),
          ScaledSizedBox(height: 6),
          Text(
            'refereesAccessible'.tr(args: [accessible.toString(), total.toString()]),
            style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String message) {
    return Padding(
      padding: EdgeInsets.all(scaleSize(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: scaleSize(32)),
          ScaledSizedBox(height: 8),
          Text(
            'distanceComputeError'.tr(),
            style: scaledTextStyle(fontSize: 14, color: Colors.red.shade600),
            textAlign: TextAlign.center,
          ),
          ScaledSizedBox(height: 4),
          Text(
            message,
            style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          ScaledSizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => ref.read(distanceProvider(address).notifier).compute(),
            icon: Icon(Icons.refresh, size: scaleSize(16)),
            label: Text('recompute'.tr()),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade600, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
