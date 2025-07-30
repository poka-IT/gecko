import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';

/// Service for managing user contacts.
///
/// This service handles adding and removing contacts, checking contact status,
/// and managing the contact storage using Hive boxes.
class ContactService {
  /// Checks if an address is already in the contacts list.
  bool isContact(String address) {
    return contactsBox.containsKey(address);
  }

  /// Adds or removes a contact from the contacts list.
  ///
  /// If the profile is already a contact, it will be removed.
  /// If it's not a contact, it will be added.
  ///
  /// Returns a [ContactOperationResult] indicating the operation performed.
  Future<ContactOperationResult> toggleContact(G1WalletsList profile) async {
    try {
      if (isContact(profile.address)) {
        await contactsBox.delete(profile.address);
        return ContactOperationResult.removed();
      } else {
        await contactsBox.put(profile.address, profile);
        return ContactOperationResult.added();
      }
    } catch (e) {
      return ContactOperationResult.error('Failed to update contact: $e');
    }
  }

  /// Adds a contact to the contacts list.
  Future<ContactOperationResult> addContact(G1WalletsList profile) async {
    try {
      if (isContact(profile.address)) {
        return ContactOperationResult.alreadyExists();
      }

      await contactsBox.put(profile.address, profile);
      return ContactOperationResult.added();
    } catch (e) {
      return ContactOperationResult.error('Failed to add contact: $e');
    }
  }

  /// Removes a contact from the contacts list.
  Future<ContactOperationResult> removeContact(String address) async {
    try {
      if (!isContact(address)) {
        return ContactOperationResult.notFound();
      }

      await contactsBox.delete(address);
      return ContactOperationResult.removed();
    } catch (e) {
      return ContactOperationResult.error('Failed to remove contact: $e');
    }
  }

  /// Gets all contacts from the contacts list.
  List<G1WalletsList> getAllContacts() {
    try {
      return contactsBox.values.toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets a specific contact by address.
  G1WalletsList? getContact(String address) {
    try {
      return contactsBox.get(address);
    } catch (e) {
      return null;
    }
  }

  /// Clears all contacts.
  Future<void> clearAllContacts() async {
    await contactsBox.clear();
  }
}

/// Result class for contact operations.
class ContactOperationResult {
  final ContactOperationStatus status;
  final String? errorMessage;

  const ContactOperationResult._({required this.status, this.errorMessage});

  /// Creates a successful addition result.
  factory ContactOperationResult.added() {
    return const ContactOperationResult._(status: ContactOperationStatus.added);
  }

  /// Creates a successful removal result.
  factory ContactOperationResult.removed() {
    return const ContactOperationResult._(status: ContactOperationStatus.removed);
  }

  /// Creates an error result.
  factory ContactOperationResult.error(String message) {
    return ContactOperationResult._(status: ContactOperationStatus.error, errorMessage: message);
  }

  /// Creates an already exists result.
  factory ContactOperationResult.alreadyExists() {
    return const ContactOperationResult._(status: ContactOperationStatus.alreadyExists);
  }

  /// Creates a not found result.
  factory ContactOperationResult.notFound() {
    return const ContactOperationResult._(status: ContactOperationStatus.notFound);
  }

  bool get isSuccess => status == ContactOperationStatus.added || status == ContactOperationStatus.removed;
  bool get isError => status == ContactOperationStatus.error;
  bool get wasAdded => status == ContactOperationStatus.added;
  bool get wasRemoved => status == ContactOperationStatus.removed;

  /// Gets the appropriate message for the operation result.
  String get message {
    return switch (status) {
      ContactOperationStatus.added => 'addedToContacts'.tr(),
      ContactOperationStatus.removed => 'removedFromcontacts'.tr(),
      ContactOperationStatus.error => errorMessage ?? 'Error occurred',
      ContactOperationStatus.alreadyExists => 'Contact already exists',
      ContactOperationStatus.notFound => 'Contact not found',
    };
  }
}

/// Enum representing the possible states of a contact operation.
enum ContactOperationStatus { added, removed, error, alreadyExists, notFound }

/// Provider for ContactService
final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});
