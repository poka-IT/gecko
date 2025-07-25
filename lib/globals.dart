import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/main.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

// Version of box data
const int dataVersion = 13;
const int walletHeaderDataVersion = 2;

late String appVersion;
const int pinLength = 4;
const int maxWalletsInSafe = 30;

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
