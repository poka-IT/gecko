import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

enum ThemeModeSetting { system, light, dark }

class ThemeProvider with ChangeNotifier {
  ThemeModeSetting _themeModeSetting = ThemeModeSetting.system;

  ThemeModeSetting get themeModeSetting => _themeModeSetting;

  ThemeMode get currentThemeMode {
    if (_themeModeSetting == ThemeModeSetting.light) {
      return ThemeMode.light;
    } else if (_themeModeSetting == ThemeModeSetting.dark) {
      return ThemeMode.dark;
    } else {
      return ThemeMode.system;
    }
  }

  ThemeProvider() {
    _loadThemePreference();
  }

  void _loadThemePreference() {
    final String? themeString = configBox.get('themeMode');
    if (themeString == 'light') {
      _themeModeSetting = ThemeModeSetting.light;
    } else if (themeString == 'dark') {
      _themeModeSetting = ThemeModeSetting.dark;
    } else {
      _themeModeSetting = ThemeModeSetting.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeModeSetting setting) async {
    _themeModeSetting = setting;
    await configBox.put('themeMode', setting.toString().split('.').last);
    notifyListeners();
  }
}

const Color _orangeC = Color(0xffd07316);
const Color _darkOrangeC = Color.fromARGB(255, 132, 71, 11);

const Color _yellowC = Color(0xffFFD68E);
const Color _darkYellowC = Color.fromARGB(255, 135, 113, 75);

const Color _floattingYellow = Color(0xffEFEFBF);
const Color _darkFloattingYellow = Color(0xff1E1E1E);

const Color _backgroundColor = Color(0xffF5F5F5);
const Color _darkBackgroundColor = Color(0xff121212);

const Color _headerColor = Color(0xFFFFF3E0);
const Color _darkHeaderColor = Color(0xff1E1E1E);

const Color _cardColor = Colors.white;
const Color _darkCardColor = Color.fromARGB(255, 43, 43, 43);

const Color _textColor = Colors.black87;
const Color _darkTextColor = Colors.white70;

const Color _textOnContainerColor = Colors.black87;
Color _darkTextOnContainerColor = Colors.grey[300]!;

const Color _textSecondaryColor = Colors.black54;
const Color _darkTextSecondaryColor = Colors.white60;

const Color _iconColor = Colors.black54;
const Color _darkIconColor = Colors.white54;

Color _disabledColor = Colors.grey[700]!;
Color _darkDisabledColor = Colors.grey[400]!;

const Color _errorColor = Color.fromARGB(255, 232, 211, 211);
const Color _darkErrorColor = Color.fromARGB(255, 90, 38, 38);

final ThemeData lightTheme = ThemeData(
  primaryColor: _orangeC,
  scaffoldBackgroundColor: _backgroundColor,
  canvasColor: _backgroundColor,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: _headerColor,
    titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _textColor, fontFamily: 'Roboto'),
    iconTheme: IconThemeData(color: _iconColor),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _textColor, fontFamily: 'Roboto'),
    bodyMedium: TextStyle(fontSize: 14, color: _textColor, fontFamily: 'Roboto'),
    bodySmall: TextStyle(fontSize: 13, color: _textSecondaryColor, fontFamily: 'Roboto'),
    labelMedium: TextStyle(fontSize: 15, fontFamily: 'Monospace', fontWeight: FontWeight.w500, color: _textColor),
  ),
  colorScheme: ColorScheme.fromSeed(seedColor: _yellowC, brightness: Brightness.light).copyWith(
    secondary: _yellowC,
    tertiary: _headerColor,
    surfaceTint: _floattingYellow,
    surfaceContainer: _cardColor,
    primary: _orangeC,
    onPrimary: Colors.white,
    surface: _backgroundColor,
    onSurface: _textColor,
    onSecondaryContainer: _textOnContainerColor,
    onSurfaceVariant: _disabledColor,
    error: _errorColor,
  ),
  dialogTheme: const DialogThemeData(backgroundColor: _backgroundColor),
  iconTheme: const IconThemeData(color: _iconColor),
  popupMenuTheme: const PopupMenuThemeData(
    color: _cardColor,
    textStyle: TextStyle(color: _textColor, fontFamily: 'Roboto', fontSize: 14),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _orangeC;
      }
      return Colors.grey[400];
    }),
    trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _orangeC.withValues(alpha: 0.5);
      }
      return Colors.grey[300];
    }),
  ),
  dividerColor: Colors.grey[300],
);

final ThemeData darkTheme = ThemeData(
  primaryColor: _darkOrangeC,
  scaffoldBackgroundColor: _darkBackgroundColor,
  canvasColor: _darkBackgroundColor,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: _darkHeaderColor,
    titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _darkTextColor, fontFamily: 'Roboto'),
    iconTheme: IconThemeData(color: _darkIconColor),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _darkTextColor, fontFamily: 'Roboto'),
    bodyMedium: TextStyle(fontSize: 14, color: _darkTextColor, fontFamily: 'Roboto'),
    bodySmall: TextStyle(fontSize: 13, color: _darkTextSecondaryColor, fontFamily: 'Roboto'),
    labelMedium: TextStyle(fontSize: 15, fontFamily: 'Monospace', fontWeight: FontWeight.w500, color: _darkTextColor),
  ),
  colorScheme: ColorScheme.fromSeed(seedColor: _darkOrangeC, brightness: Brightness.dark).copyWith(
    secondary: _darkYellowC,
    tertiary: _darkHeaderColor,
    surface: _darkBackgroundColor,
    onSurface: _darkTextColor,
    primary: _darkOrangeC,
    onPrimary: Colors.black,
    surfaceContainer: _darkCardColor,
    surfaceTint: _darkFloattingYellow,
    onSurfaceVariant: _darkDisabledColor,
    onSecondaryContainer: _darkTextOnContainerColor,
    error: _darkErrorColor,
  ),
  dialogTheme: const DialogThemeData(backgroundColor: _darkCardColor),
  iconTheme: const IconThemeData(color: _darkIconColor),
  popupMenuTheme: PopupMenuThemeData(
    color: _darkCardColor,
    textStyle: TextStyle(color: _darkTextColor, fontFamily: 'Roboto', fontSize: 14),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _darkOrangeC;
      }
      return Colors.grey[600];
    }),
    trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _darkOrangeC.withValues(alpha: 0.5);
      }
      return Colors.grey[800];
    }),
  ),
  dividerColor: Colors.grey[700],
);
