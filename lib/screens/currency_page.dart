import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/currency_provider.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class CurrencyPage extends ConsumerStatefulWidget {
  const CurrencyPage({super.key});

  @override
  ConsumerState<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends ConsumerState<CurrencyPage> {
  bool showAllRulesCurrency = false;
  bool showAllRulesWot = false;
  bool useRelativeUnit = false;

  @override
  Widget build(BuildContext context) {
    final currencyDataAsync = ref.watch(currencyDataProvider);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('currency'.tr()),
      body: SafeArea(
        child: currencyDataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: scaleSize(64), color: context.colorScheme.error),
                ScaledSizedBox(height: 16),
                Text(
                  'errorLoadingCurrencyData'.tr(),
                  textAlign: TextAlign.center,
                  style: scaledTextStyle(fontSize: 16, color: context.colorScheme.error, fontWeight: FontWeight.w500),
                ),
                ScaledSizedBox(height: 8),
                Text(
                  error.toString(),
                  style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
                ScaledSizedBox(height: 24),
                ElevatedButton(onPressed: () => ref.refresh(currencyDataProvider), child: Text('retry'.tr())),
              ],
            ),
          ),
          data: (currencyData) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currencyDataProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(scaleSize(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrencyDescription(context, currencyData.currencyParams),
                  ScaledSizedBox(height: 24),
                  _buildCurrencySection(context, currencyData.currencyParams),
                  ScaledSizedBox(height: 24),
                  _buildWotSection(context, currencyData.wotParams),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyDescription(BuildContext context, CurrencyParameters params) {
    final genesisTimeAsync = ref.watch(genesisTimeProvider);

    return genesisTimeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (genesisTime) {
        // Calculate time since blockchain start
        final timeSinceStart = DateTime.now().difference(genesisTime);
        final startedAgo = _formatDuration(timeSinceStart.inMilliseconds);

        // Format UD period using existing duration formatting
        final udPeriod = _formatDuration(params.udCreationPeriodMs);

        // Build description text with parameters
        final description = 'currencyDescription'.tr(
          args: [params.currencyName, startedAgo, params.members.toString(), udPeriod],
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(scaleSize(20)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colorScheme.primary.withValues(alpha: 0.1),
                context.colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            children: [
              Text(
                description,
                textAlign: TextAlign.justify,
                style: scaledTextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencySection(BuildContext context, CurrencyParameters params) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(scaleSize(16)),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance, color: context.colorScheme.primary, size: scaleSize(24)),
                ScaledSizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    'currencyParameters'.tr(),
                    style: scaledTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          showAllRulesCurrency = !showAllRulesCurrency;
                        });
                      },
                      icon: Icon(
                        showAllRulesCurrency ? Icons.expand_less : Icons.expand_more,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(scaleSize(16)),
            child: Column(
              children: [
                _buildCurrencyRow(context, 'currencyName'.tr(), params.currencyName),
                _buildCurrencyRow(context, 'network'.tr(), params.currencyNetwork.toUpperCase()),
                _buildCurrencyRow(context, 'symbol'.tr(), params.currencySymbol),
                _buildCurrencyRow(context, 'members'.tr(), params.members.toString()),
                _buildCurrencyRow(
                  context,
                  'monetaryMass'.tr(),
                  '${params.monetaryMass.toStringAsFixed(2)} ${params.currencySymbol}',
                ),
                _buildCurrencyRow(
                  context,
                  'currentUD'.tr(),
                  '${params.currentUd.toStringAsFixed(2)} ${params.currencySymbol}',
                ),

                if (showAllRulesCurrency) ...[
                  ScaledSizedBox(height: 8),
                  _buildCurrencyRow(
                    context,
                    'initialUD'.tr(),
                    '${params.ud0.toStringAsFixed(2)} ${params.currencySymbol}',
                  ),
                  _buildCurrencyRow(context, 'udCreationPeriod'.tr(), _formatDuration(params.udCreationPeriodMs)),
                  _buildCurrencyRow(context, 'udReevalPeriod'.tr(), _formatDuration(params.udReevalPeriodMs)),
                  _buildCurrencyRow(context, 'growthRate'.tr(), '${(params.growthRate * 100).toStringAsFixed(4)}%'),
                  _buildCurrencyRow(context, 'pastReevals'.tr(), params.pastReevals.toString()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWotSection(BuildContext context, WotParameters params) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(scaleSize(16)),
            decoration: BoxDecoration(
              color: context.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline, color: context.colorScheme.onSecondaryContainer, size: scaleSize(24)),
                ScaledSizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    'wotParameters'.tr(),
                    style: scaledTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          showAllRulesWot = !showAllRulesWot;
                        });
                      },
                      icon: Icon(
                        showAllRulesWot ? Icons.expand_less : Icons.expand_more,
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(scaleSize(16)),
            child: Column(
              children: [
                _buildWotRow(context, 'minCertificationsRequired'.tr(), params.sigQtyRule.toString()),
                _buildWotRow(context, 'certificationValidityPeriod'.tr(), _formatDuration(params.sigValidity)),
                _buildWotRow(context, 'maxCertificationsPerIssuer'.tr(), params.sigStock.toString()),

                if (showAllRulesWot) ...[
                  ScaledSizedBox(height: 8),
                  _buildWotRow(context, 'certificationWindow'.tr(), _formatDuration(params.sigWindow)),
                  _buildWotRow(context, 'certificationPeriod'.tr(), _formatDuration(params.sigPeriod)),
                  _buildWotRow(context, 'membershipWindow'.tr(), _formatDuration(params.msWindow)),
                  _buildWotRow(context, 'membershipValidity'.tr(), _formatDuration(params.msValidity)),
                  _buildWotRow(context, 'maxDistanceReferees'.tr(), params.stepMax.toString()),
                  _buildWotRow(context, 'minSmithCertifications'.tr(), params.sentries.toString()),
                  _buildWotRow(context, 'xPercentRule'.tr(), '${(params.xPercent * 100).toStringAsFixed(2)}%'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.colorScheme.onSurface),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWotRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.colorScheme.onSurface),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    if (duration.inDays > 365) {
      return 'years'.tr(args: [(duration.inDays ~/ 365).toString()]);
    } else if (duration.inDays > 30) {
      return 'months'.tr(args: [(duration.inDays ~/ 30).toString()]);
    } else if (duration.inDays > 0) {
      return duration.inDays == 1 ? 'everyDay'.tr() : 'days'.tr(args: [duration.inDays.toString()]);
    } else if (duration.inHours > 0) {
      return duration.inHours == 1 ? 'everyHour'.tr() : 'hours'.tr(args: [duration.inHours.toString()]);
    } else {
      return duration.inMinutes == 1 ? 'everyMinute'.tr() : 'minutes'.tr(args: [duration.inMinutes.toString()]);
    }
  }
}
