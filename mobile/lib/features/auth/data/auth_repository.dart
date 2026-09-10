import 'package:dio/dio.dart';

import '../../../core/domain/entities.dart';
import '../../../core/error/app_failure.dart';
import '../../../data/remote/api_client.dart';
import '../../../data/remote/dto/dto.dart';
import '../../../data/remote/token_storage.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<UserEntity> signup({
    required String email,
    required String password,
    required String timezone,
  }) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        '/auth/signup',
        body: {'email': email, 'password': password, 'timezone': timezone},
      );
      final result = AuthResultDto.fromJson(resp.data!);
      await _persist(result);
      return _userFromDto(result.user);
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        '/auth/login',
        body: {'email': email, 'password': password},
      );
      final result = AuthResultDto.fromJson(resp.data!);
      await _persist(result);
      return _userFromDto(result.user);
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await _tokens.readRefreshToken();
      if (refresh != null) {
        await _api.post('/auth/logout', body: {'refreshToken': refresh});
      }
    } catch (_) {
      // best-effort; we still clear local state below
    }
    await _tokens.clear();
  }

  Future<UserEntity?> currentUser() async {
    final id = await _tokens.readUserId();
    final email = await _tokens.readEmail();
    final tz = await _tokens.readTimezone();
    if (id == null || email == null || tz == null) return null;
    // createdAt is unknown after restart; callers that need accuracy
    // should refetch /users/me in a future phase.
    return UserEntity(
      id: id,
      email: email,
      timezone: tz,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Future<bool> isLoggedIn() async {
    final access = await _tokens.readAccessToken();
    return access != null && access.isNotEmpty;
  }

  Future<void> _persist(AuthResultDto result) async {
    await _tokens.save(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
      userId: result.user.id,
      email: result.user.email,
      timezone: result.user.timezone,
    );
  }

  UserEntity _userFromDto(UserDto u) => UserEntity(
        id: u.id,
        email: u.email,
        timezone: u.timezone,
        createdAt: u.createdAt,
      );
}