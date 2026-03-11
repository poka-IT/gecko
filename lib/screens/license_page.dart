import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/license_provider.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class MonetaryLicensePage extends ConsumerWidget {
  const MonetaryLicensePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = context.locale.languageCode;
    final licenseAsync = ref.watch(licenseProvider(langCode));

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('monetaryLicense'.tr()),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 700,
          padding: EdgeInsets.zero,
          child: licenseAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: EdgeInsets.all(scaleSize(24)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: scaleSize(64), color: context.colorScheme.error),
                    ScaledSizedBox(height: 16),
                    Text(
                      'errorLoadingLicense'.tr(),
                      textAlign: TextAlign.center,
                      style: scaledTextStyle(
                        fontSize: 16,
                        color: context.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ScaledSizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                    ScaledSizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(licenseProvider(langCode)),
                      child: Text('retry'.tr()),
                    ),
                  ],
                ),
              ),
            ),
            data: (licenseContent) => Scrollbar(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(scaleSize(20)),
                child: TextMarkDown(
                  licenseContent,
                  style: scaledTextStyle(fontSize: 14, height: 1.6, color: context.colorScheme.onSurface),
                  textAlign: WrapAlignment.start,
                  selectable: true,
                  softLineBreak: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
