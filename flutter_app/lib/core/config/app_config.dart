class AppConfig {
  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.107:8000/api/v1'
  );
  
  static const String apiBaseUrl = baseUrl; // Alias for baseUrl
  
  // WebSocket Configuration
  static const String websocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'ws://192.168.1.107:8000/ws'
  );
  
  // App Configuration
  static const String appName = 'Fertility Services';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Feature Flags
  static const bool enableDebugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true
  );
  
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false
  );
  
  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: false
  );
  
  // Payment Configuration
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_your_paystack_public_key'
  );
  
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_your_stripe_publishable_key'
  );
  
  static const String flutterwavePublicKey = String.fromEnvironment(
    'FLUTTERWAVE_PUBLIC_KEY',
    defaultValue: 'FLWPUBK_your_flutterwave_public_key'
  );
  
  // Timeout Configuration
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // File Upload Configuration
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];
  
  // Cache Configuration
  static const int cacheExpiryHours = 24;
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB
  
  // Localization
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'es', 'fr'];
  
  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxPhoneLength = 20;
  static const int maxBioLength = 500;
  
  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String appointmentsEndpoint = '/appointments';
  static const String paymentsEndpoint = '/payments';
  static const String hospitalsEndpoint = '/hospitals';
  static const String messagesEndpoint = '/messages';
  static const String medicalRecordsEndpoint = '/medical-records';
  static const String bookingEndpoint = '/booking';
  
  // WebSocket Events
  static const String messageEvent = 'message';
  static const String appointmentUpdateEvent = 'appointment_update';
  static const String paymentUpdateEvent = 'payment_update';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String appSettingsKey = 'app_settings';
  static const String cacheKey = 'app_cache';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double smallBorderRadius = 8.0;
  static const double mediumBorderRadius = 12.0;
  static const double largeBorderRadius = 16.0;
  
  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unauthorizedMessage = 'Unauthorized. Please login again.';
  static const String validationErrorMessage = 'Please check your input and try again.';
  
  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registrationSuccessMessage = 'Registration successful!';
  static const String appointmentBookedMessage = 'Appointment booked successfully!';
  static const String paymentSuccessMessage = 'Payment completed successfully!';
  
  // Production URLs (for reference)
  static const String productionApiUrl = 'https://api.yourdomain.com/api/v1';
  static const String productionWebsocketUrl = 'wss://api.yourdomain.com/ws';
  static const String stagingApiUrl = 'https://staging-api.yourdomain.com/api/v1';
  static const String stagingWebsocketUrl = 'wss://staging-api.yourdomain.com/ws';
  
  // Additional UI Constants
  static const double borderRadius = 8.0;
  
  // API Configuration
  static const int connectTimeout = 30000;
  static const int sendTimeout = 30000;
  
  // Notification Configuration
  static const String notificationChannelId = 'fertility_services_channel';
  static const String notificationChannelName = 'Fertility Services';
  static const String notificationChannelDescription = 'Notifications for fertility services app';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String settingsKey = 'app_settings';
}
