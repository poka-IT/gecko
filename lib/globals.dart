import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

// Version of box data
const int dataVersion = 9;

late String appVersion;
const int pinLength = 5;
const int maxWalletsInSafe = 30;
const String appLang = 'english';

late Box<WalletData> walletBox;
late Box<ChestData> chestBox;
late Box configBox;
late Box<G1WalletsList> g1WalletsBox;
late Box<G1WalletsList> contactsBox;
// late Box keystoreBox;
late Directory avatarsDirectory;
late Directory avatarsCacheDirectory;
late bool isTall;

const cesiumPod = "https://g1.data.le-sou.org";
// String cesiumPod = "https://g1.data.presles.fr";
// String cesiumPod = "https://g1.data.e-is.pro";

const datapodEndpoint = 'gdev-datapod.p2p.legal';
// const datapodEndpoint = '10.0.2.2:8080';

// Contexts
late BuildContext homeContext;

// Logger
final log = Logger();

// Colors
const Color orangeC = Color(0xffd07316);
const Color yellowC = Color(0xffFFD68E);
const Color floattingYellow = Color(0xffEFEFBF);
const Color backgroundColor = Color(0xFFF5F5F5);

// Substrate settings
const String currencyName = 'ĞD';

// Debug
const debugPin = true;

String indexerEndpoint = '';
late double balanceRatio;
late int udValue;

// Indexer
late DateTime startBlockchainTime;
bool startBlockchainInitialized = false;

late int currentUdIndex;

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
  12: "month12".tr()
};
