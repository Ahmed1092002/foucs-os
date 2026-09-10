import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract token storage. Production uses [_SecureTokenStorage]; tests
/// supply an in-memory implementation.
abstract class TokenStorage {
  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String timezone,
  });

  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<String?> readUserId();
  Future<String?> readEmail();
  Future<String?> readTimezone();

  Future<void> clear();

  /// Update only the token pair (used after refresh).
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  });
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'auth.access_token';
  static const _kRefresh = 'auth.refresh_token';
  static const _kUserId = 'auth.user_id';
  static const _kEmail = 'auth.email';
  static const _kTimezone = 'auth.timezone';

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String timezone,
  }) async {
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
    await _storage.write(key: _kUserId, value: userId);
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kTimezone, value: timezone);
  }

  @override
  Future<String?> readAccessToken() => _storage.read(key: _kAccess);
  @override
  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);
  @override
  Future<String?> readUserId() => _storage.read(key: _kUserId);
  @override
  Future<String?> readEmail() => _storage.read(key: _kEmail);
  @override
  Future<String?> readTimezone() => _storage.read(key: _kTimezone);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kTimezone);
  }

  @override
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }
}

/// Backwards-compatible alias. The default constructor still works.
class TokenStorageFactory {
  static TokenStorage create() => SecureTokenStorage();
}