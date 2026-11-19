// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookin_bookout/login_page.dart';

void main() {
  testWidgets('login screen presents Bookin & Bookout services', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Bookin & Bookout'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New to Bookin & Bookout? Register'), findsOneWidget);
  });

  testWidgets('registration screen validates details before account creation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.ensureVisible(find.text('New to Bookin & Bookout? Register'));
    await tester.tap(find.text('New to Bookin & Bookout? Register'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);

    await tester.ensureVisible(find.text('Register'));
    await tester.tap(find.text('Register'));
    await tester.pump();

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.ensureVisible(fields.at(0));
    await tester.enterText(fields.at(0), 'Reader');
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), 'reader@example.com');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), 'password123');
    await tester.ensureVisible(fields.at(3));
    await tester.enterText(fields.at(3), 'different123');
    await tester.ensureVisible(find.text('Register'));
    await tester.tap(find.text('Register'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('password reset requires a valid email address', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();

    expect(find.text('Enter a valid email address first.'), findsOneWidget);
  });
}
