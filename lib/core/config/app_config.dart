class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'MOCK_API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const apiPrefix = '/mock-portal';
  static const appName = 'mock.edumimi';
}
