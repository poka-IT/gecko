import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/text_size_mode.dart';
import 'package:gecko/providers/text_scaling_provider.dart';

/// Text size slider with preset dot anchors.
class TextSizeSetting extends ConsumerWidget {
  const TextSizeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_size_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Text(
              'textSize'.tr(),
              style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ],
        ),
        ScaledSizedBox(height: 16),
        Consumer(
          builder: (context, ref, _) {
            final currentScale = ref.watch(textScalingProvider);

            return Column(
              children: [
                // Current size indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      TextScaling.getLabelKey(currentScale).tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                ScaledSizedBox(height: 16),

                // Slider with preset anchors
                Column(
                  children: [
                    GestureDetector(
                      onDoubleTap: () {
                        // Double tap to reset to normal size
                        ref.read(textScalingProvider.notifier).setTextScale(TextScaling.defaultScale);
                      },
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                          activeTrackColor: context.colorScheme.primary,
                          inactiveTrackColor: context.colorScheme.primary.withValues(alpha: 0.3),
                          thumbColor: context.colorScheme.primary,
                          overlayColor: context.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: currentScale,
                          min: TextScaling.minScale,
                          max: TextScaling.maxScale,
                          divisions: 30, // Allows fine-grained control
                          onChanged: (double value) {
                            ref.read(textScalingProvider.notifier).setTextScale(value);
                          },
                          onChangeEnd: (double value) {
                            // Snap to nearest preset if close enough
                            final snapped = TextScaling.snapToPreset(value);
                            if ((value - snapped).abs() < 0.05) {
                              ref.read(textScalingProvider.notifier).setTextScale(snapped);
                            }
                          },
                        ),
                      ),
                    ),

                    // Points positioned exactly like slider values
                    SizedBox(
                      height: scaleSize(30),
                      child: Stack(
                        children: [
                          // 0.85 = 0% (tout à gauche)
                          Positioned(
                            left: scaleSize(24) - scaleSize(6), // Slider padding - half dot
                            top: scaleSize(9),
                            child: _buildDot(0.85, currentScale, ref, context),
                          ),
                          // 1.0 = 20% de la barre
                          Positioned(
                            left:
                                scaleSize(24) +
                                ((MediaQuery.of(context).size.width - scaleSize(96)) * 0.2) -
                                scaleSize(6),
                            top: scaleSize(9),
                            child: _buildDot(1.0, currentScale, ref, context),
                          ),
                          // 1.30 = 60% de la barre
                          Positioned(
                            left:
                                scaleSize(24) +
                                ((MediaQuery.of(context).size.width - scaleSize(96)) * 0.6) -
                                scaleSize(6),
                            top: scaleSize(9),
                            child: _buildDot(1.30, currentScale, ref, context),
                          ),
                          // 1.60 = 100% (tout à droite)
                          Positioned(
                            right: scaleSize(24) - scaleSize(6), // Slider padding - half dot
                            top: scaleSize(9),
                            child: _buildDot(1.60, currentScale, ref, context),
                          ),
                        ],
                      ),
                    ),

                    // Labels simples sous les points
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(18)),
                      child: Row(
                        children: [
                          Text(
                            'textSizeSmall'.tr(),
                            style: scaledTextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          Expanded(child: Container()),
                          Text(
                            'textSizeNormal'.tr(),
                            style: scaledTextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          Expanded(child: Container()),
                          Text(
                            'textSizeLarge'.tr(),
                            style: scaledTextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          Expanded(child: Container()),
                          Text(
                            'textSizeExtraLarge'.tr(),
                            style: scaledTextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                ScaledSizedBox(height: 12),
                Text(
                  'textSizeDescription'.tr(),
                  style: scaledTextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDot(double preset, double currentScale, WidgetRef ref, BuildContext context) {
    final isSelected = (currentScale - preset).abs() < 0.01;
    return GestureDetector(
      onTap: () {
        ref.read(textScalingProvider.notifier).setTextScale(preset);
      },
      child: Container(
        width: scaleSize(12),
        height: scaleSize(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? context.colorScheme.primary : context.colorScheme.primary.withValues(alpha: 0.5),
          border: Border.all(color: context.colorScheme.primary, width: isSelected ? 2 : 1),
        ),
      ),
    );
  }
}
