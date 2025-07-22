import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/contacts_list.dart';
import 'package:provider/provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String searchQuery = '';
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<WalletsProfilesProvider>(context, listen: true);
    final allContacts = contactsBox.toMap().values.toList();

    // Order contacts by username
    allContacts.sort((p1, p2) {
      return Comparable.compare(p1.username?.toLowerCase() ?? 'zz', p2.username?.toLowerCase() ?? 'zz');
    });

    // Filter contacts based on search query
    final filteredContacts = searchQuery.isEmpty
        ? allContacts
        : allContacts.where((contact) {
            final username = (contact.username ?? '').toLowerCase();
            final address = contact.address.toLowerCase();
            final query = searchQuery.toLowerCase();
            return username.contains(query) || address.contains(query);
          }).toList();

    return GestureDetector(
      onTap: () {
        // Défocuser le champ de recherche quand on clique en dehors
        if (_searchFocus.hasFocus) {
          _searchFocus.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('contactsManagementWithNbr'.tr(args: ['${allContacts.length}'])),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  focusNode: _searchFocus,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'searchContacts'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.colorScheme.primary)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              Expanded(child: ContactsList(myContacts: filteredContacts)),
            ],
          ),
        ),
      ),
    );
  }
}
