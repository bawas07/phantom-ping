class ApiConstants {
  // Base URL - should be configured based on environment
  static const String baseUrl = 'http://localhost:3000';

  // Auth endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String refreshEndpoint = '/api/auth/refresh';
  static const String logoutEndpoint = '/api/auth/logout';

  // WebSocket URL
  static const String wsUrl = 'ws://localhost:3000';
}
