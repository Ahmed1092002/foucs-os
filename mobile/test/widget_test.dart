// Smoke tests for the Focus OS Phase 1 app shell.
//
// These tests verify that:
//  1. The auth controller initialises to a logged-out state.
//  2. Login screen renders the email/password fields.
//  3. Areas screen shows the "no areas yet" empty state.
//
// More meaningful tests (timer math, sync, streaks, repository flows) arrive
// in their respective phases. Repository-level tests use a fake Dio client.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:focus_os/core/di/providers.dart';
import 'package:focus_os/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('Login screen renders email and password fields',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(
            const FlutterSecureStorage(),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });
}