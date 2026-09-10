/// Build-time API configuration.
///
/// Override for physical-device testing:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
class ApiConfig {
  const ApiConfig._();

  /// Use 10.0.2.2 (Android emulator host loopback) by default.
  /// For iOS simulator, the same URL works.
  /// Override with --dart-define=API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );
}