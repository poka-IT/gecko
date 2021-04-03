import 'dart:io';
import 'package:gecko/models/myWallets.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Files paths
Directory appPath;
Directory walletsDirectory;
File defaultWalletFile;
File currentChestFile;

WalletData defaultWallet;
String appVersion;
SharedPreferences prefs;
String endPointGVA;
int ramSys;

// String cesiumPod = "https://g1.data.le-sou.org";
String cesiumPod = "https://g1.data.e-is.pro";

// Responsive ratios
bool isTall;
double ratio;

// Logger
var log = Logger();
