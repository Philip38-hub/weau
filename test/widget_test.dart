// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weau/main.dart';
import 'package:weau/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app defaults to light theme and shows the sign in CTA', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final themeProvider = ThemeProvider();
    await themeProvider.loadTheme();

    await tester.pumpWidget(FriendTrackerApp(themeProvider: themeProvider));
    await tester.pump();

    expect(find.text('Sign in with Google'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
  });
}
