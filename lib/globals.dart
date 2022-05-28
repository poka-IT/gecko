import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Version of box data
const int dataVersion = 1;

// Files paths
Directory? appPath;

late String appVersion;
late SharedPreferences prefs;
late String endPointGVA;
const int pinLength = 5;
const String appLang = 'english';

late Box<WalletData> walletBox;
late Box<ChestData> chestBox;
late Box configBox;
late Box<G1WalletsList> g1WalletsBox;
// late Box keystoreBox;
late Directory imageDirectory;

// String cesiumPod = "https://g1.data.le-sou.org";
String cesiumPod = "https://g1.data.presles.fr";
// String cesiumPod = "https://g1.data.e-is.pro";

// Responsive ratios
late bool isTall;
late double ratio;

// Logger
var log = Logger();

// Colors
Color orangeC = const Color(0xffd07316);
Color yellowC = const Color(0xffFFD68E);
Color floattingYellow = const Color(0xffEFEFBF);
Color backgroundColor = const Color(0xFFF5F5F5);

// Substrate settings
const int ss58 = 42;
String currencyName = 'Ğdev';

// Debug
const debugPin = true;
