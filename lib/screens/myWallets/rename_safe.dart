// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class RenameSafeScreen extends ConsumerStatefulWidget {
  const RenameSafeScreen({super.key, required this.currentName, required this.safeBoxNumber});

  final String currentName;
  final int safeBoxNumber;

  @override
  ConsumerState<RenameSafeScreen> createState() => _RenameSafeScreenState();
}

class _RenameSafeScreenState extends ConsumerState<RenameSafeScreen> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _renameSafe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newName = _nameController.text.trim();
      await ref.read(walletServiceProvider).renameSafe(widget.safeBoxNumber, newName);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error renaming safe: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('renameSafe'.tr()),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(scaleSize(16)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScaledSizedBox(height: 24),
                Text(
                  'enterNewSafeName'.tr(),
                  style: scaledTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                ScaledSizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  style: scaledTextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(scaleSize(8))),
                    hintText: 'safeName'.tr(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'safeNameRequired'.tr();
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _renameSafe(),
                ),
                ScaledSizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ScaledSizedBox(
                        height: 55,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style:
                              OutlinedButton.styleFrom(
                                side: BorderSide(width: scaleSize(2), color: Colors.grey.shade400),
                                padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: Colors.grey.shade100.withValues(alpha: 0.1),
                              ).copyWith(
                                elevation: WidgetStateProperty.resolveWith<double>((Set<WidgetState> states) {
                                  if (states.contains(WidgetState.pressed)) return 0;
                                  return 2;
                                }),
                                shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.15)),
                              ),
                          child: Text(
                            'cancel'.tr(),
                            style: scaledTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ScaledSizedBox(width: 16),
                    Expanded(
                      child: ScaledSizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _renameSafe,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: context.colorScheme.primary,
                            elevation: 2,
                            padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: scaleSize(20),
                                  width: scaleSize(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'save'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
