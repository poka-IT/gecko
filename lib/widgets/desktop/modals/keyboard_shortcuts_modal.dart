import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';

/// Shows the keyboard shortcuts modal.
Future<void> showKeyboardShortcutsModal(BuildContext context) {
  return showDesktopModal(
    context: context,
    title: 'keyboardShortcuts'.tr(),
    size: DesktopModalSize.small,
    contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    builder: (context) => const _KeyboardShortcutsContent(),
  );
}

class _KeyboardShortcutsContent extends StatelessWidget {
  const _KeyboardShortcutsContent();

  @override
  Widget build(BuildContext context) {
    final groups = [
      _ShortcutGroup(
        title: 'keyboardShortcutsNavigation'.tr(),
        shortcuts: [
          _ShortcutEntry(keys: ['K'], description: 'keyboardShortcutSearch'.tr()),
          _ShortcutEntry(keys: ['F'], description: 'keyboardShortcutSearch'.tr()),
          _ShortcutEntry(keys: ['/'], description: 'keyboardShortcutFocusSearch'.tr()),
          _ShortcutEntry(keys: ['C'], description: 'keyboardShortcutContacts'.tr()),
          _ShortcutEntry(keys: ['Esc'], description: 'keyboardShortcutClose'.tr()),
        ],
      ),
      _ShortcutGroup(
        title: 'keyboardShortcutsSearchResults'.tr(),
        shortcuts: [
          _ShortcutEntry(keys: ['↑', '↓'], description: 'keyboardShortcutNavigateResults'.tr()),
          _ShortcutEntry(keys: ['Enter'], description: 'keyboardShortcutOpenResult'.tr()),
        ],
      ),
      _ShortcutGroup(
        title: 'keyboardShortcutsOther'.tr(),
        shortcuts: [
          _ShortcutEntry(keys: ['H'], description: 'keyboardShortcutHelp'.tr()),
          _ShortcutEntry(keys: ['←', '←', '→', '→', '→'], description: 'keyboardShortcutDisco'.tr(), isSequence: true),
        ],
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int g = 0; g < groups.length; g++) ...[
            if (g > 0) const SizedBox(height: 20),
            _buildGroupHeader(context, groups[g].title),
            const SizedBox(height: 8),
            ...groups[g].shortcuts.map((s) => _buildShortcutRow(context, s)),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.colorScheme.primary.withValues(alpha: 0.8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildShortcutRow(BuildContext context, _ShortcutEntry shortcut) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              shortcut.description,
              style: TextStyle(fontSize: 14, color: context.colorScheme.onSurface.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < shortcut.keys.length; i++) ...[
                if (i > 0 && !shortcut.isSequence)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '+',
                      style: TextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.35)),
                    ),
                  )
                else if (i > 0)
                  const SizedBox(width: 4),
                _buildKeyBadge(context, shortcut.keys[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyBadge(BuildContext context, String key) {
    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Text(
        key,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          fontFamily: 'Monospace',
        ),
      ),
    );
  }
}

class _ShortcutGroup {
  final String title;
  final List<_ShortcutEntry> shortcuts;

  const _ShortcutGroup({required this.title, required this.shortcuts});
}

class _ShortcutEntry {
  final List<String> keys;
  final String description;
  final bool isSequence;

  const _ShortcutEntry({required this.keys, required this.description, this.isSequence = false});
}
