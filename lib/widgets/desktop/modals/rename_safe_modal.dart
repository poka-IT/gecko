import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';

/// Shows the rename safe form inside a desktop modal.
Future<void> showDesktopRenameSafeModal(
  BuildContext context, {
  required String currentName,
  required int safeBoxNumber,
}) {
  return showDesktopModal(
    context: context,
    title: 'renameSafe'.tr(),
    size: DesktopModalSize.small,
    contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    builder: (context) => _RenameSafeContent(currentName: currentName, safeBoxNumber: safeBoxNumber),
  );
}

class _RenameSafeContent extends ConsumerStatefulWidget {
  const _RenameSafeContent({required this.currentName, required this.safeBoxNumber});
  final String currentName;
  final int safeBoxNumber;

  @override
  ConsumerState<_RenameSafeContent> createState() => _RenameSafeContentState();
}

class _RenameSafeContentState extends ConsumerState<_RenameSafeContent> {
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
    setState(() => _isLoading = true);

    try {
      final newName = _nameController.text.trim();
      await ref.read(walletServiceProvider).renameSafe(widget.safeBoxNumber, newName);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('errorRenamingSafe'.tr(args: [e.toString()])),
            backgroundColor: context.geckoColors.danger,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'enterNewSafeName'.tr(),
            style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: context.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            autofocus: true,
            style: scaledTextStyle(fontSize: 16),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              hintText: 'safeName'.tr(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'safeNameRequired'.tr();
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _renameSafe(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('cancel'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isLoading ? null : _renameSafe,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('save'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
