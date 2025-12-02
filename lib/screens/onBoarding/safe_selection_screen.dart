import 'package:durt2/durt2.dart' show SafeEntity, SafeType;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class SafeSelectionScreen extends ConsumerStatefulWidget {
  final LegacyMigrationData migrationData;
  final String pinCode;

  const SafeSelectionScreen({super.key, required this.migrationData, required this.pinCode});

  @override
  ConsumerState<SafeSelectionScreen> createState() => _SafeSelectionScreenState();
}

class _SafeSelectionScreenState extends ConsumerState<SafeSelectionScreen> {
  SafeEntity? selectedSafe;
  bool importNewSafe = false;
  List<SafeEntity> availableSafes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableSafes();
  }

  Future<void> _loadAvailableSafes() async {
    try {
      final walletService = ref.read(walletServiceProvider);
      final allSafes = walletService.safeBox.getAll();

      // Filter out legacy safes and the current legacy safe being migrated
      availableSafes = allSafes.where((safe) {
        return safe.safeType == SafeType.mnemonic && safe.number >= 0; // Exclude legacy safes (number = -1)
      }).toList();

      // Sort by safe number
      availableSafes.sort((a, b) => a.number.compareTo(b.number));
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('selectTargetSafe'.tr()),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(scaleSize(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'selectTargetSafeDescription'.tr(),
                          style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.left,
                        ),
                        ScaledSizedBox(height: 24),

                        // Existing safes
                        if (availableSafes.isNotEmpty) ...[
                          Text(
                            'existingSafes'.tr(),
                            style: scaledTextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          ScaledSizedBox(height: 16),
                          ...availableSafes.map((safe) => _buildSafeTile(safe)),
                          ScaledSizedBox(height: 24),
                        ],

                        // Import new safe option
                        Text(
                          'importNewSafe'.tr(),
                          style: scaledTextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        ScaledSizedBox(height: 16),
                        _buildImportNewSafeTile(),

                        // Add bottom padding to ensure content doesn't hide behind button
                        ScaledSizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Fixed bottom button
                if (selectedSafe != null || importNewSafe)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(scaleSize(20)),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.2), width: 1),
                      ),
                    ),
                    child: SafeArea(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: scaleSize(16)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _proceedWithSelection,
                        child: Text(
                          'continue'.tr(),
                          style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSafeTile(SafeEntity safe) {
    final isSelected = selectedSafe?.id == safe.id;

    return Container(
      margin: EdgeInsets.only(bottom: scaleSize(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedSafe = safe;
            importNewSafe = false;
          });
        },
        child: Container(
          padding: EdgeInsets.all(scaleSize(16)),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colorScheme.primary.withValues(alpha: 0.1)
                : context.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? context.colorScheme.primary : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              // Safe image
              Container(
                width: scaleSize(48),
                height: scaleSize(48),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: context.colorScheme.surfaceContainerHighest,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: safe.imagePath != null
                      ? Image.asset(safe.imagePath!, fit: BoxFit.cover)
                      : Image.asset('assets/safes/${safe.number % 4}.png', fit: BoxFit.cover),
                ),
              ),
              ScaledSizedBox(width: 16),

              // Safe info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safe.name,
                      style: scaledTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    ScaledSizedBox(height: 4),
                    Text(
                      'safeNumber'.tr(args: [safe.number.toString()]),
                      style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.left,
                    ),
                    ScaledSizedBox(height: 4),
                    Text(
                      '${safe.wallets.length} ${'wallets'.tr()}',
                      style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(Icons.check_circle, color: context.colorScheme.primary, size: scaleSize(24))
              else
                Icon(Icons.radio_button_unchecked, color: context.colorScheme.onSurfaceVariant, size: scaleSize(24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportNewSafeTile() {
    final isSelected = importNewSafe;

    return Container(
      margin: EdgeInsets.only(bottom: scaleSize(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedSafe = null;
            importNewSafe = true;
          });
        },
        child: Container(
          padding: EdgeInsets.all(scaleSize(16)),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colorScheme.primary.withValues(alpha: 0.1)
                : context.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? context.colorScheme.primary : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              // Import icon
              Container(
                width: scaleSize(48),
                height: scaleSize(48),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: context.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.download_outlined, color: context.colorScheme.primary, size: scaleSize(24)),
              ),
              ScaledSizedBox(width: 16),

              // Import info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'importNewSafeTitle'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    ScaledSizedBox(height: 4),
                    Text(
                      'importNewSafeDescription'.tr(),
                      style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(Icons.check_circle, color: context.colorScheme.primary, size: scaleSize(24))
              else
                Icon(Icons.radio_button_unchecked, color: context.colorScheme.onSurfaceVariant, size: scaleSize(24)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _proceedWithSelection() async {
    if (importNewSafe) {
      // Navigate to classic import flow (RestoreSafe)
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          RouteNames.restoreSafe,
          arguments: RestoreSafeArguments(skipIntro: true),
        );
      }
    } else if (selectedSafe != null) {
      // Navigate directly to wallet selection for the selected safe
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          RouteNames.walletSelection,
          arguments: WalletSelectionArguments(
            migrationData: widget.migrationData.copyWith(targetSafeNumber: selectedSafe!.number),
            pinCode: widget.pinCode,
          ),
        );
      }
    }
  }
}
