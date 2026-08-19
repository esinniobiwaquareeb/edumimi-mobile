class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'MOCK_API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const apiPrefix = '/mock-portal';
  static const appName = 'mock.edumimi';
  static const deepLinkScheme = 'mockedumimi';

  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static bool get isFirebaseConfigured => firebaseProjectId.isNotEmpty;
}
