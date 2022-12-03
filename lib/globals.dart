import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

// Version of box data
const int dataVersion = 4;

late String appVersion;
const int pinLength = 5;
const String appLang = 'english';

late Box<WalletData> walletBox;
late Box<ChestData> chestBox;
late Box configBox;
late Box<G1WalletsList> g1WalletsBox;
late Box<G1WalletsList> contactsBox;
// late Box keystoreBox;
late Directory imageDirectory;

// String cesiumPod = "https://g1.data.le-sou.org";
String cesiumPod = "https://g1.data.presles.fr";
// String cesiumPod = "https://g1.data.e-is.pro";

// Responsive ratios
late bool isTall;
late double ratio;

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
