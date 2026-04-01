import 'dart:io';
import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/avatar_providers.dart';
import 'package:gecko/providers/cs_publish_status_provider.dart';
import 'package:gecko/providers/cesium_profile_provider.dart';
import 'package:gecko/services/wallet_name_service.dart';
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
  /// Requires a [ref] to access providers from the widget tree.
  static Future<String> changeAvatar(String walletAddress, {String? pinCode, required riverpod.WidgetRef ref}) async {
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

    CroppedFile? croppedFile;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        croppedFile = await ImageCropper().cropImage(
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
      } on MissingPluginException catch (e) {
        log.w('ImageCropper plugin unavailable on this platform, using original image instead: $e');
      }
    } else {
      log.i('Image cropping is not supported on desktop, using original image.');
    }

    final avatarUuid = const Uuid().v4();
    final sourcePath = croppedFile?.path ?? imageFile.path;
    final sourceExtension = XFile(sourcePath).name.split('.').length > 1
        ? '.${XFile(sourcePath).name.split('.').last}'
        : '';
    final newPath = "${avatarsDirectory.path}/$walletAddress-$avatarUuid$sourceExtension";

    if (croppedFile == null && (Platform.isAndroid || Platform.isIOS)) {
      log.w('No image selected after cropping.');
      return '';
    }

    try {
      final walletService = ref.read(walletServiceProvider);

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

      // Move processed file to avatar storage, or copy the original file on platforms
      // where cropping is unavailable.
      await File(sourcePath).copy(newPath);

      // Update wallet data
      walletData.imagePath = newPath;
      await walletService.walletBox.putAsync(walletData);

      // Clear Flutter's image cache to force reload of the new avatar
      imageCache.clear();
      imageCache.clearLiveImages();

      // Upload to Cesium+ if pinCode is provided
      if (pinCode != null && pinCode.isNotEmpty) {
        log.i('Uploading avatar to Cesium+ pod...');

        final uploadSuccess = await uploadAvatarToCesiumPlus(walletAddress, pinCode, ref: ref);

        // Clear avatar cache AFTER successful upload and force immediate re-download
        final avatarCache = ref.read(avatarCacheProvider.notifier);
        await avatarCache.clearAvatar(walletAddress, forceReload: true);

        if (uploadSuccess) {
          log.i('Avatar successfully uploaded to Cesium+ pod and cache refreshed');
        } else {
          log.w('Failed to upload avatar to Cesium+ pod (local avatar saved, cache cleared)');
        }
      }

      return newPath;
    } catch (e) {
      log.e('Error updating wallet avatar: $e');
      return '';
    }
  }

  /// Rename a wallet
  ///
  /// Updates the wallet name in the database.
  /// Requires a [ref] to access providers from the widget tree.
  static Future<void> renameWallet(WalletEntity wallet, String newName, {required riverpod.WidgetRef ref}) async {
    try {
      final walletService = ref.read(walletServiceProvider);

      wallet.name = newName;
      walletService.walletBox.put(wallet);
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
  /// Requires a [ref] to access providers from the widget tree.
  static Future<bool> uploadAvatarToCesiumPlus(
    String walletAddress,
    String pinCode, {
    required riverpod.WidgetRef ref,
  }) async {
    try {
      final walletService = ref.read(walletServiceProvider);
      final cesiumPlusService = ref.read(cesiumPlusServiceProvider);

      final walletData = walletService.getWalletData(walletAddress);

      // Check if wallet has an avatar
      if (walletData.imagePath == null || walletData.imagePath!.isEmpty) {
        log.w('No local avatar found for wallet $walletAddress');
        return false;
      }

      // Read avatar file
      final avatarFile = File(walletData.imagePath!);
      if (!await avatarFile.exists()) {
        log.e('Avatar file does not exist: ${walletData.imagePath}');
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
        title: WalletNameService.isDefault(walletData.name) ? 'Duniter Wallet' : (walletData.name ?? 'Duniter Wallet'),
        avatarBytes: avatarBytes,
        avatarContentType: contentType,
      );

      if (success) {
        log.i('Avatar successfully uploaded to Cesium+ pod');
      } else {
        log.e('Failed to upload avatar to Cesium+ pod');
      }

      return success;
    } catch (e) {
      log.e('Error uploading avatar to Cesium+: $e');
      return false;
    }
  }

  /// Publish wallet name to CesiumPlus pod
  ///
  /// Fire-and-forget method: updates the CesiumPlus profile title to [name].
  /// Guards against default names (starting with '#').
  /// Preserves existing profile data (description, city, socials, tags, avatar).
  /// Updates [csPublishStatusProvider] to reflect progress/failure.
  /// Requires a [ref] to access providers from the widget tree.
  static Future<void> publishNameToCesiumPlus(
    String walletAddress,
    String name,
    String pinCode, {
    required riverpod.WidgetRef ref,
  }) async {
    // Never publish default names
    if (WalletNameService.isDefault(name)) return;

    final statusNotifier = ref.read(csPublishStatusProvider(walletAddress).notifier);
    statusNotifier.state = CsPublishStatus.publishing;

    try {
      final walletService = ref.read(walletServiceProvider);
      final cesiumPlusService = ref.read(cesiumPlusServiceProvider);

      // Get keypair for signing
      final keyPair = await walletService.getKeyPairFromAddress(
        address: walletAddress,
        pinCode: pinCode,
      );

      // Read existing profile to preserve fields that uploadProfile would clear
      final existing = await cesiumPlusService.getProfileByAddress(walletAddress);

      final success = await cesiumPlusService.uploadProfile(
        address: walletAddress,
        signFunction: keyPair.sign,
        title: name,
        description: existing?['description'] as String?,
        city: existing?['city'] as String?,
        geoPointLat: existing?['geoPoint']?['lat']?.toString(),
        geoPointLon: existing?['geoPoint']?['lon']?.toString(),
        socials: (existing?['socials'] as List?)
            ?.map((s) => CesiumSocial.fromJson(s as Map<String, dynamic>))
            .toList(),
        tags: (existing?['tags'] as List?)?.cast<String>(),
      );

      if (success) {
        statusNotifier.state = CsPublishStatus.success;
        // Invalidate cached profile so the new name is picked up
        ref.invalidate(cesiumProfileProvider(walletAddress));
        log.i('Name "$name" published to CesiumPlus for $walletAddress');
      } else {
        statusNotifier.state = CsPublishStatus.failed;
        log.e('CesiumPlus uploadProfile returned false for $walletAddress');
      }
    } catch (e) {
      statusNotifier.state = CsPublishStatus.failed;
      log.e('Error publishing name to CesiumPlus: $e');
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

    // Block reserved '#' prefix
    if (WalletNameService.isReservedPrefix(name)) return false;

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
