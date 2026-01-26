import 'package:durt2/durt2.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';

// Theme color constants
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

const Color _cardColor = Color(0xFFFFFEF7);
const Color _darkCardColor = Color.fromARGB(255, 43, 43, 43);

const Color _textColor = Colors.black87;
const Color _darkTextColor = Colors.white70;

const Color _textOnContainerColor = Colors.black87;
const Color _darkTextOnContainerColor = Color.fromRGBO(224, 224, 224, 1);

const Color _textSecondaryColor = Colors.black54;
const Color _darkTextSecondaryColor = Colors.white60;

const Color _iconColor = Colors.black54;
const Color _darkIconColor = Colors.white54;

const Color _disabledColor = Color.fromRGBO(97, 97, 97, 1);
const Color _darkDisabledColor = Color.fromRGBO(189, 189, 189, 1);

const Color _errorColor = Color.fromARGB(255, 232, 211, 211);
const Color _darkErrorColor = Color.fromARGB(255, 90, 38, 38);

/// Enum representing the available theme mode settings.
enum ThemeModeSetting { system, light, dark }

/// Provider for managing theme mode state with persistent storage.
///
/// This provider handles the app's theme mode selection (system, light, dark)
/// and persists the state using Durt's config storage for consistency across app restarts.
final themeProvider = NotifierProvider<ThemeNotifier, ThemeModeSetting>(ThemeNotifier.new);

/// Notifier for managing the global theme mode state.
///
/// Automatically loads the state from storage on initialization and saves
/// changes back to storage when the theme mode is modified.
class ThemeNotifier extends Notifier<ThemeModeSetting> {
  static const String _storageKey = 'themeMode';

  @override
  ThemeModeSetting build() {
    return _loadThemePreference();
  }

  /// Load the theme preference from persistent storage
  ThemeModeSetting _loadThemePreference() {
    try {
      final configBox = ref.read(configBoxProvider);
      final themeString = configBox.getValue(_storageKey, defaultValue: 'system');

      return switch (themeString) {
        'light' => ThemeModeSetting.light,
        'dark' => ThemeModeSetting.dark,
        _ => ThemeModeSetting.system,
      };
    } catch (e) {
      // Fallback to system theme if loading fails
      return ThemeModeSetting.system;
    }
  }

  /// Set the theme mode and persist to storage
  Future<void> setThemeMode(ThemeModeSetting setting) async {
    state = setting;
    await _saveToStorage();
  }

  /// Save the current theme mode to persistent storage
  Future<void> _saveToStorage() async {
    try {
      final configBox = ref.read(configBoxProvider);
      configBox.putValue(_storageKey, state.toString().split('.').last);
    } catch (e) {
      // Silent fail - theme will revert to system on next restart
    }
  }
}

/// Provider for converting theme mode setting to Flutter's ThemeMode
///
/// This derived provider automatically converts the ThemeModeSetting enum
/// to Flutter's native ThemeMode for use in MaterialApp.
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  final themeModeSetting = ref.watch(themeProvider);

  return switch (themeModeSetting) {
    ThemeModeSetting.light => ThemeMode.light,
    ThemeModeSetting.dark => ThemeMode.dark,
    ThemeModeSetting.system => ThemeMode.system,
  };
});

/// Light theme configuration for the application
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

/// Dark theme configuration for the application
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
