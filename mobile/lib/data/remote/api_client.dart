import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/error/app_failure.dart';
import 'token_storage.dart';
import 'dto/dto.dart';

/// Configured Dio client with:
///   - bearer-token injection
///   - automatic refresh on 401
///   - error envelope → AppFailure translation
class ApiClient {
  ApiClient({TokenStorage? tokenStorage})
      : _tokens = tokenStorage ?? SecureTokenStorage(),
        _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          contentType: 'application/json',
          responseType: ResponseType.json,
        )) {
    _dio.interceptors.add(_AuthInterceptor(_dio, _tokens));
    _dio.interceptors.add(_ErrorInterceptor());
  }

  final Dio _dio;
  final TokenStorage _tokens;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {Object? body}) =>
      _dio.post<T>(path, data: body);

  Future<Response<T>> patch<T>(String path, {Object? body}) =>
      _dio.patch<T>(path, data: body);

  Future<Response<T>> put<T>(String path, {Object? body}) =>
      _dio.put<T>(path, data: body);

  Future<Response<void>> delete(String path) => _dio.delete(path);

  /// Pull all server-side changes since the given ISO timestamp.
  Future<SyncPullResponseDto> pull({DateTime? since}) => get<Map<String, dynamic>>(
        '/sync/pull',
        query: since != null ? {'since': since.toIso8601String()} : null,
      ).then((r) => SyncPullResponseDto.fromJson(r.data! as Map<String, dynamic>));
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;
  bool _refreshing = false;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final access = await _tokens.readAccessToken();
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Single-flight refresh to avoid stampedes.
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != '/auth/refresh' &&
        err.requestOptions.path != '/auth/login' &&
        err.requestOptions.path != '/auth/signup' &&
        !_refreshing) {
      _refreshing = true;
      try {
        final refresh = await _tokens.readRefreshToken();
        if (refresh == null || refresh.isEmpty) return handler.next(err);

        final resp = await _dio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refreshToken': refresh},
          options: Options(headers: {'_skipRefresh': true}),
        );
        final access = resp.data?['accessToken'] as String?;
        final newRefresh = resp.data?['refreshToken'] as String?;
        if (access != null && newRefresh != null) {
          await _tokens.updateTokens(
            accessToken: access,
            refreshToken: newRefresh,
          );

          // Retry the original request with the new bearer.
          final retry = err.requestOptions;
          retry.headers['Authorization'] = 'Bearer $access';
          final clone = await _dio.fetch(retry);
          return handler.resolve(clone);
        }
      } catch (_) {
        // Refresh failed → surface original 401.
      } finally {
        _refreshing = false;
      }
    }
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = _mapError(err);
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: failure,
      message: failure.message,
    ));
  }

  AppFailure _mapError(DioException err) {
    final code = err.response?.statusCode;
    final data = err.response?.data;
    String message = err.message ?? 'Network error';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    }
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      return NetworkFailure('Cannot reach the server. Check your connection.');
    }
    switch (code) {
      case 400:
        return ValidationFailure(message);
      case 401:
        return UnauthorizedFailure(message);
      case 404:
        return NotFoundFailure(message);
      case 409:
        return ConflictFailure(message);
      default:
        return UnknownFailure(message);
    }
  }
}