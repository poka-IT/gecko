// CUSTOM METHODES
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';

Future goKey(WidgetTester tester, Key buttonKey,
    {Finder? customFinder, int duration = 100}) async {
  await tester.pumpAndSettle(Duration(milliseconds: duration));
  final Finder finder = customFinder ?? find.byKey(buttonKey);
  log.d('INTEGRATION TEST: Tap on ${finder.description}}');
  await tester.tap(finder);
  // await tester.pumpAndSettle(Duration(milliseconds: duration));
}

Future goBack(WidgetTester tester) async {
  final NavigatorState navigator = tester.state(find.byType(Navigator));
  log.d('INTEGRATION TEST: Go back');
  navigator.pop();
  await tester.pump();
}

Future enterText(WidgetTester tester, Key fieldKey, String textIn,
    [int duration = 200]) async {
  await tester.pumpAndSettle(Duration(milliseconds: duration));
  log.d('INTEGRATION TEST: Enter text: $textIn');
  await tester.enterText(find.byKey(fieldKey), textIn);
}

Future<void> waitFor(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);

  Finder finder = find.textContaining(text);
  log.d('INTEGRATION TEST: Wait for: $text');

  do {
    if (DateTime.now().isAfter(end)) {
      
      throw Exception('Timed out waiting for text $text');
    }

    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 100));
  } while (finder.evaluate().isEmpty);
}

// Test if text is visible on screen, return a boolean
Future<bool> isPresent(WidgetTester tester, String text,
    {Duration timeout = const Duration(seconds: 1)}) async {
  try {
    await waitFor(tester, text, timeout: timeout);
    return true;
  } catch (exception) {
    return false;
  }
}

// Test if widget exist on screen, return a boolean
Future<bool> isIconPresent(WidgetTester tester, IconData icon,
    {Duration timeout = const Duration(seconds: 1)}) async {
  await tester.pumpAndSettle();
  final finder = find.byIcon(icon);
  log.d('tatatatatatata: ${finder.evaluate()}');
  return finder.evaluate().isEmpty ? false : true;
}

extension Truncate on String {
  String truncate({required int max, String suffix = ''}) {
    return length < max
        ? this
        : '${substring(0, substring(0, max - suffix.length).lastIndexOf(" "))}$suffix';
  }
}
