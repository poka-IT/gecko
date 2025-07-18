import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/main.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

// Version of box data
const int dataVersion = 12;
const int walletHeaderDataVersion = 2;

late String appVersion;
const int pinLength = 4;
const int maxWalletsInSafe = 30;
const String appLang = 'english';

late Box configBox;
late Box<G1WalletsList> g1WalletsBox;
late Box<G1WalletsList> contactsBox;
late Box<WalletHeaderData> walletHeaderDataBox;
// late Box keystoreBox;
late Directory avatarsDirectory;
late Directory avatarsCacheDirectory;
late bool isTall;

// Contexts
BuildContext get homeContext => Gecko.navigatorContext!;

// Logger
final log = Logger();

// Colors
const blueColor = Color(0xFF5C6BC0);
const greenColor = Color(0xFF66BB6A);

// Debug
const debugPin = false;

String indexerEndpoint = '';

// Indexer
DateTime startBlockchainTime = DateTime(0, 0, 0, 0, 0);
bool startBlockchainInitialized = false;

final Map<int, String> monthsInYear = {
  1: "month1".tr(),
  2: "month2".tr(),
  3: "month3".tr(),
  4: "month4".tr(),
  5: "month5".tr(),
  6: "month6".tr(),
  7: "month7".tr(),
  8: "month8".tr(),
  9: "month9".tr(),
  10: "month10".tr(),
  11: "month11".tr(),
  12: "month12".tr(),
};
