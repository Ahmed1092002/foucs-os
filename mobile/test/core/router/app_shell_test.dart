// Tests for the pure routing function in app_shell.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_os/core/router/app_shell.dart';

void main() {
  group('timerTabRouteFor', () {
    test('with active session → /session/active', () {
      expect(
        timerTabRouteFor(hasActiveSession: true),
        '/session/active',
      );
    });

    test('without active session → /quick-start', () {
      expect(
        timerTabRouteFor(hasActiveSession: false),
        '/quick-start',
      );
    });
  });
}