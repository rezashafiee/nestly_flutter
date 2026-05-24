abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'NESTLY_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static Uri get baseUri => Uri.parse(baseUrl);
}
