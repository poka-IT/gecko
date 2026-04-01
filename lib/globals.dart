import 'dart:io';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:gecko/services/log_collection_service.dart';

// Version of box data
const int dataVersion = 13;
const int walletHeaderDataVersion = 2;

// Persist cache schema version - bump to flush Riverpod SQLite cache on next app start.
// Unlike dataVersion, this does NOT wipe Hive boxes or wallets.
const String persistCacheVersion = 'v3';

late String appVersion;
const int pinLength = 4;
const int maxWalletsInSafe = 30;

late Box configBox;
late Box<G1WalletsList> g1WalletsBox;
late Box<G1WalletsList> contactsBox;
late Box<WalletHeaderData> walletHeaderDataBox;
late Directory avatarsDirectory;
late Directory avatarsCacheDirectory;
late bool isTall;

// Logger with log collection
final log = Logger(
  output: MultiOutput([
    ConsoleOutput(), // Keep console output
    LogCollectionOutput(LogCollectionService.instance), // Add log collection
  ]),
);
