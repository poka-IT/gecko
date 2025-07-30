import 'dart:io';
import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';

/// Service for handling wallet management operations like avatar changes and renaming.
///
/// This service provides static methods for wallet operations that don't require
/// persistent state management. For validation state, use WalletNameValidationProvider.
class WalletManagementService {
  WalletManagementService._internal();

  /// Change wallet avatar by picking and cropping an image
  ///
  /// Returns the new image path if successful, empty string if cancelled or failed.
  static Future<String> changeAvatar(String walletAddress) async {
    final picker = ImagePicker();

    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      log.w('No image selected.');
      return '';
    }

    File imageFile = File(pickedFile.path);
    if (!await avatarsDirectory.exists()) {
      log.e("Image folder doesn't exist");
      return '';
    }

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          hideBottomControls: true,
          toolbarTitle: 'cropImage'.tr(),
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          statusBarColor: Colors.deepOrange,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'cropImage'.tr(),
          cropStyle: CropStyle.circle,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          minimumAspectRatio: 1.0,
        ),
      ],
    );

    if (croppedFile == null) {
      log.w('No image selected after cropping.');
      return '';
    }

    final avatarUuid = const Uuid().v4();
    final newPath = "${avatarsDirectory.path}/$walletAddress-$avatarUuid";

    try {
      // Get wallet service through ProviderContainer
      final container = riverpod.ProviderContainer();
      final walletService = container.read(walletServiceProvider);

      final walletData = walletService.getWalletData(walletAddress);

      // Delete old avatar if exists
      if (walletData.imagePath != null) {
        final oldAvatarFile = File(walletData.imagePath!);
        if (await oldAvatarFile.exists()) {
          await oldAvatarFile.delete();
        }
      }

      // Move cropped file to new location
      await File(croppedFile.path).rename(newPath);

      // Update wallet data
      walletData.imagePath = newPath;
      await walletService.walletBox.putAsync(walletData);

      container.dispose();
      return newPath;
    } catch (e) {
      log.e('Error updating wallet avatar: $e');
      return '';
    }
  }

  /// Rename a wallet
  ///
  /// Updates the wallet name in the database.
  static Future<void> renameWallet(WalletEntity wallet, String newName) async {
    try {
      final container = riverpod.ProviderContainer();
      final walletService = container.read(walletServiceProvider);

      wallet.name = newName;
      walletService.walletBox.put(wallet);

      container.dispose();
    } catch (e) {
      log.e('Error renaming wallet: $e');
      rethrow;
    }
  }

  /// Validate wallet name
  ///
  /// Returns true if the name is valid (length, characters, uniqueness).
  /// Does not manage state - use WalletNameValidationProvider for reactive validation.
  static bool isWalletNameValid(String name, List<WalletEntity> existingWallets, {WalletEntity? excludeWallet}) {
    // Check basic constraints
    bool isNameValid = name.length >= 2 && !name.contains(':') && name.length <= 39;

    if (!isNameValid) return false;

    // Check uniqueness
    for (var wallet in existingWallets) {
      // Skip the wallet being edited
      if (excludeWallet != null && wallet.address == excludeWallet.address) {
        continue;
      }
      if (name == wallet.name) {
        return false;
      }
    }

    return true;
  }
}

/// Provider for WalletManagementService
final walletManagementServiceProvider = riverpod.Provider<WalletManagementService>((ref) {
  return WalletManagementService._internal();
});
