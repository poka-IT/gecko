import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

// Files paths
Directory appPath;
Directory walletsDirectory;
File defaultWalletFile;
File currentChestFile;

String defaultWallet;
String appVersion;
SharedPreferences prefs;
String endPointGVA;
int ramSys;

String cesiumPod = "https://g1.data.le-sou.org";

// Responsive ratios
bool isTall;
double ratio;
