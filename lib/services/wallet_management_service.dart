import 'dart:io';
import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/avatar_providers.dart';
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
  /// If pinCode is provided, will also upload the avatar to Cesium+.
  static Future<String> changeAvatar(String walletAddress, {String? pinCode}) async {
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
          statusBarLight: false,
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
          // Evict old image from Flutter's cache before deleting
          final oldImageProvider = FileImage(oldAvatarFile);
          await oldImageProvider.evict();

          await oldAvatarFile.delete();
        }
      }

      // Move cropped file to new location
      await File(croppedFile.path).rename(newPath);

      // Update wallet data
      walletData.imagePath = newPath;
      await walletService.walletBox.putAsync(walletData);

      // Clear Flutter's image cache to force reload of the new avatar
      imageCache.clear();
      imageCache.clearLiveImages();

      // Upload to Cesium+ if pinCode is provided
      if (pinCode != null && pinCode.isNotEmpty) {
        log.i('📤 Uploading avatar to Cesium+ pod...');

        final uploadSuccess = await uploadAvatarToCesiumPlus(walletAddress, pinCode);

        // Clear avatar cache AFTER successful upload and force immediate re-download
        final avatarCache = container.read(avatarCacheProvider.notifier);
        await avatarCache.clearAvatar(walletAddress, forceReload: true);

        if (uploadSuccess) {
          log.i('✅ Avatar successfully uploaded to Cesium+ pod and cache refreshed');
        } else {
          log.w('⚠️ Failed to upload avatar to Cesium+ pod (local avatar saved, cache cleared)');
        }
      }

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

  /// Upload wallet avatar to Cesium+ pod
  ///
  /// Uploads the local avatar to the Cesium+ pod to make it publicly visible.
  /// Requires PIN code for authentication.
  /// Returns true if successful, false otherwise.
  static Future<bool> uploadAvatarToCesiumPlus(String walletAddress, String pinCode) async {
    try {
      final container = riverpod.ProviderContainer();
      final walletService = container.read(walletServiceProvider);
      final cesiumPlusService = container.read(cesiumPlusServiceProvider);

      final walletData = walletService.getWalletData(walletAddress);

      // Check if wallet has an avatar
      if (walletData.imagePath == null || walletData.imagePath!.isEmpty) {
        log.w('No local avatar found for wallet $walletAddress');
        container.dispose();
        return false;
      }

      // Read avatar file
      final avatarFile = File(walletData.imagePath!);
      if (!await avatarFile.exists()) {
        log.e('Avatar file does not exist: ${walletData.imagePath}');
        container.dispose();
        return false;
      }

      final avatarBytes = await avatarFile.readAsBytes();

      // Determine content type from file extension
      String contentType = 'image/png';
      if (walletData.imagePath!.toLowerCase().endsWith('.jpg') ||
          walletData.imagePath!.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }

      // Get wallet keypair using pinCode
      final keyPair = await walletService.getKeyPairFromAddress(address: walletAddress, pinCode: pinCode);

      // Upload profile with avatar (service handles SS58 to base58 conversion)
      // Use wallet name for now (identity name would require additional query)
      final success = await cesiumPlusService.uploadProfile(
        address: walletAddress,
        signFunction: keyPair.sign,
        title: walletData.name ?? 'Duniter Wallet',
        avatarBytes: avatarBytes,
        avatarContentType: contentType,
      );

      container.dispose();

      if (success) {
        log.i('✅ Avatar successfully uploaded to Cesium+ pod');
      } else {
        log.e('❌ Failed to upload avatar to Cesium+ pod');
      }

      return success;
    } catch (e) {
      log.e('Error uploading avatar to Cesium+: $e');
      return false;
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
