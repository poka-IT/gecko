import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/transaction_history_providers.dart';

/// Elegant transaction filter widget that allows switching between transfers and all transactions
class TransactionFilter extends ConsumerStatefulWidget {
  const TransactionFilter({super.key, required this.address});

  final String address;

  @override
  ConsumerState<TransactionFilter> createState() => _TransactionFilterState();
}

class _TransactionFilterState extends ConsumerState<TransactionFilter> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasCheckedForUDs = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUDEnabled = ref.watch(universalDividendsToggleProvider);

    // Check if UDs are available
    final combinedState = ref.watch(combinedHistoryProvider(widget.address));
    final hasUDs = combinedState.transactions.any(
      (transaction) => transaction.type == TransactionType.universalDividend,
    );

    // Animate in when UDs are detected for the first time
    if (hasUDs && !_hasCheckedForUDs) {
      _hasCheckedForUDs = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    }

    // Hide if no UDs available
    if (!hasUDs) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.only(left: scaleSize(16), right: scaleSize(16), top: scaleSize(8), bottom: scaleSize(8)),
          child: Row(
            children: [
              Icon(Icons.filter_list_outlined, size: scaleSize(16), color: context.colorScheme.onSurfaceVariant),
              SizedBox(width: scaleSize(8)),
              Text(
                'transactionFilter'.tr(),
                style: scaledTextStyle(
                  fontSize: 12,
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: scaleSize(12)),
              Expanded(child: _buildFilterToggle(context, isUDEnabled)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterToggle(BuildContext context, bool isUDEnabled) {
    return _FilterToggle(
      label: 'showUniversalDividends'.tr(),
      icon: Icons.water_drop,
      isEnabled: isUDEnabled,
      onTap: () {
        toggleUniversalDividends(ref, widget.address);
      },
    );
  }
}

/// Single toggle button for Universal Dividends
class _FilterToggle extends StatelessWidget {
  const _FilterToggle({required this.label, required this.icon, required this.isEnabled, required this.onTap});

  final String label;
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: scaleSize(7)),
          decoration: BoxDecoration(
            color: isEnabled
                ? context.colorScheme.primary.withValues(alpha: 0.15)
                : context.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEnabled
                  ? context.colorScheme.primary.withValues(alpha: 0.4)
                  : context.colorScheme.outline.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: isEnabled ? 0.1 : 0.0,
                child: Icon(
                  icon,
                  size: scaleSize(16),
                  color: isEnabled ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: scaleSize(8)),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: scaledTextStyle(
                    fontSize: 12,
                    color: isEnabled ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
                    fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
