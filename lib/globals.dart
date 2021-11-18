import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Files paths
Directory appPath;

String appVersion;
SharedPreferences prefs;
String endPointGVA;
int ramSys;
Box<WalletData> walletBox;
Box<ChestData> chestBox;
Box configBox;

// String cesiumPod = "https://g1.data.le-sou.org";
String cesiumPod = "https://g1.data.e-is.pro";

// Responsive ratios
bool isTall;
double ratio;

// Logger
var log = Logger();

// Colors
Color orangeC = const Color(0xffd07316);
Color yellowC = const Color(0xffFFD68E);
Color floattingYellow = const Color(0xffEFEFBF);
Color backgroundColor = const Color(0xFFF5F5F5);
