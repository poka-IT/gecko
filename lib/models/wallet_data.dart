// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:gecko/globals.dart';
import 'package:gecko/providers/v2s_datapod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
part 'wallet_data.g.dart';

@HiveType(typeId: 0)
class WalletData extends HiveObject {
  @HiveField(0)
  String address;

  @HiveField(1)
  int? chest;

  @HiveField(2)
  int? number;

  @HiveField(3)
  String? name;

  @HiveField(4)
  int? derivation;

  @HiveField(5)
  String? imageDefaultPath;

  @HiveField(6)
  String? imageCustomPath;

  @HiveField(7)
  bool isOwned;

  @HiveField(8)
  IdtyStatus identityStatus;

  @HiveField(9)
  double balance;

  @HiveField(10)
  List<int>? certs;

  @HiveField(11)
  DateTime? profileUpdatedTime;

  WalletData({
    required this.address,
    this.chest,
    this.number,
    this.name,
    this.derivation,
    this.imageDefaultPath,
    this.imageCustomPath,
    this.profileUpdatedTime,
    this.isOwned = false,
    this.identityStatus = IdtyStatus.unknown,
    this.balance = 0,
    this.certs,
  });

  // representation of WalletData when debugging
  @override
  String toString() {
    return name!;
  }

  // creates the ':'-separated string from the WalletData
  String inLine() {
    return "$chest:$number:$name:$derivation:$imageDefaultPath:$imageCustomPath:$identityStatus";
  }

  bool hasIdentity() {
    return identityStatus == IdtyStatus.created ||
        identityStatus == IdtyStatus.confirmed ||
        identityStatus == IdtyStatus.validated;
  }

  bool isMembre() {
    return identityStatus == IdtyStatus.validated;
  }

  bool exist() {
    return balance != 0;
  }

  Future<DateTime?> getUpdatedTime() async {
    final datapod = Provider.of<V2sDatapodProvider>(homeContext, listen: false);
    return await datapod.profileEditedAt(address);
  }

  Future<bool> shouldUpdateProfile() async {
    final remoteUpdatedProfile = await getUpdatedTime();
    late Duration difference;
    if (profileUpdatedTime != null && remoteUpdatedProfile != null) {
      difference = profileUpdatedTime!.difference(remoteUpdatedProfile);
    } else if (remoteUpdatedProfile != null) {
      return true;
    } else {
      difference = Duration.zero;
    }
    return difference.inSeconds.abs() >= 30;
  }

  /// This method get the remote avatar on v2s-datapod only if needed, and store it on disk
  Future getDatapodAvatar() async {
    if (!await shouldUpdateProfile()) return;

    final datapod = Provider.of<V2sDatapodProvider>(homeContext, listen: false);
    final avatarUuid = const Uuid().v4();

    await datapod.getRemoteAvatar(address, saveOnDisk: true, uuid: avatarUuid);

    final avatarPath = '${avatarsDirectory.path}/$address-$avatarUuid';
    if (!await File(avatarPath).exists()) return;

    profileUpdatedTime = await getUpdatedTime();
    imageCustomPath = avatarPath;

    walletBox.put(address, this);
    datapod.reload();
  }

  bool hasCustomImage() {
    return imageCustomPath != null;
  }

  List<int?> id() {
    return [chest, number];
  }
}

@HiveType(typeId: 5)
enum IdtyStatus {
  @HiveField(0)
  none,

  @HiveField(1)
  created,

  @HiveField(2)
  confirmed,

  @HiveField(3)
  validated,

  @HiveField(4)
  expired,

  @HiveField(5)
  unknown
}
