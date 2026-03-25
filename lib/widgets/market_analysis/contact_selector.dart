import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/datapod_avatar.dart';

/// Widget for multi-selecting contacts from the user's favorites list.
///
/// Displays a list of contacts with checkboxes, avatars, and names.
/// Includes a select-all/deselect-all toggle (D-04).
class ContactSelector extends ConsumerWidget {
  const ContactSelector({
    super.key,
    required this.selectedAddresses,
    required this.onToggle,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.contacts,
  });

  /// Set of currently selected contact addresses.
  final Set<String> selectedAddresses;

  /// Callback when a single contact is toggled.
  final void Function(String address) onToggle;

  /// Callback to select all contacts.
  final VoidCallback onSelectAll;

  /// Callback to deselect all contacts.
  final VoidCallback onDeselectAll;

  /// List of contacts to display.
  final List<G1WalletsList> contacts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contacts.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(16)),
        child: Text('noContactsForAnalysis'.tr(), style: scaledTextStyle(fontSize: 14), textAlign: TextAlign.center),
      );
    }

    final allSelected = contacts.every((c) => selectedAddresses.contains(c.address));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with select all / deselect all toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('selectContacts'.tr(), style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: allSelected ? onDeselectAll : onSelectAll,
              child: Text(allSelected ? 'deselectAll'.tr() : 'selectAll'.tr(), style: scaledTextStyle(fontSize: 13)),
            ),
          ],
        ),
        // Contact list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            final isSelected = selectedAddresses.contains(contact.address);
            final displayName = contact.username ?? contact.csName ?? getShortPubkey(contact.address);

            return CheckboxListTile(
              value: isSelected,
              onChanged: (_) => onToggle(contact.address),
              secondary: SizedBox(
                width: scaleSize(40),
                height: scaleSize(40),
                child: DatapodAvatar(address: contact.address, size: scaleSize(40)),
              ),
              title: Text(displayName, style: scaledTextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
              subtitle: Text(getShortPubkey(contact.address), style: scaledTextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.trailing,
              dense: true,
            );
          },
        ),
      ],
    );
  }
}
