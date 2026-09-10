// Unit tests for AuthRepository using a fake Dio adapter.
//
// We avoid hitting any real backend. The fake adapter is plumbed into the
// real Dio client so the auth interceptor + error envelope mapping both
// run. This catches regressions in the failure-translation layer.
//
// `flutter_secure_storage` ships with an in-memory implementation that
// works in Dart VM tests when we override the platform channels via the
// `FlutterSecureStorage` with the `IOSOptions(accessibility: ...)` and
// supply an in-memory backend through `setMockInitialValues`. The simpler
// path: substitute a `TokenStorage` that uses a `Map`-backed shim.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_os/data/remote/api_client.dart';
import 'package:focus_os/data/remote/token_storage.dart';
import 'package:focus_os/core/error/app_failure.dart';
import 'package:focus_os/features/auth/data/auth_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);
  final Future<ResponseBody> Function(RequestOptions options) responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      responder(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, {int status = 200}) {
  final bytes = Uint8List.fromList(utf8.encode(json.encode(body)));
  return ResponseBody.fromBytes(bytes, status, headers: {
    'content-type': ['application/json'],
  });
}

void main() {
  late TokenStorage tokens;
  late ApiClient api;

  setUpAll(() {
    // flutter_secure_storage uses MethodChannels; provide no-op shim so the
    // library doesn't crash in the Dart VM test environment.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    // Replace the real flutter_secure_storage with an in-memory Map.
    // We bypass TokenStorage's constructor and use a custom subclass.
    tokens = _InMemoryTokenStorage();
    api = ApiClient(tokenStorage: tokens);
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      if (opts.path == '/auth/login' &&
          opts.data is Map &&
          (opts.data as Map)['email'] == 'good@x.com') {
        return _json({
          'user': {
            'id': 'u1',
            'email': 'good@x.com',
            'timezone': 'UTC',
            'createdAt': '2026-01-01T00:00:00Z',
          },
          'tokens': {'accessToken': 'a', 'refreshToken': 'b'},
        });
      }
      return _json(
        {'code': 'UNAUTHENTICATED', 'message': 'Invalid credentials'},
        status: 401,
      );
    });
  });

  test('login success persists tokens and returns user', () async {
    final repo = AuthRepository(api, tokens);
    final user = await repo.login(email: 'good@x.com', password: 'hunter22long');
    expect(user.email, 'good@x.com');
    expect(await tokens.readAccessToken(), 'a');
    expect(await tokens.readRefreshToken(), 'b');
  });

  test('login failure surfaces UnauthorizedFailure', () async {
    final repo = AuthRepository(api, tokens);
    expect(
      () => repo.login(email: 'bad@x.com', password: 'wrong'),
      throwsA(isA<UnauthorizedFailure>()),
    );
  });
}

/// Test-only TokenStorage that uses an in-memory Map instead of Keychain.
class _InMemoryTokenStorage implements TokenStorage {
  final Map<String, String> _m = {};

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String timezone,
  }) async {
    _m['auth.access_token'] = accessToken;
    _m['auth.refresh_token'] = refreshToken;
    _m['auth.user_id'] = userId;
    _m['auth.email'] = email;
    _m['auth.timezone'] = timezone;
  }

  @override
  Future<String?> readAccessToken() async => _m['auth.access_token'];
  @override
  Future<String?> readRefreshToken() async => _m['auth.refresh_token'];
  @override
  Future<String?> readUserId() async => _m['auth.user_id'];
  @override
  Future<String?> readEmail() async => _m['auth.email'];
  @override
  Future<String?> readTimezone() async => _m['auth.timezone'];
  @override
  Future<void> clear() async => _m.clear();
  @override
  Future<void> updateTokens({required String accessToken, required String refreshToken}) async {
    _m['auth.access_token'] = accessToken;
    _m['auth.refresh_token'] = refreshToken;
  }
}