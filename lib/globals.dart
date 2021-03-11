import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

Directory appPath;
Directory walletsDirectory;
File defaultWalletFile;
String defaultWallet;
String appVersion;
SharedPreferences prefs;
String endPointGVA;
int ramSys;

// Responsive ratios
bool isTall;
double ratio;
