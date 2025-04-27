import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API configuration
  static String get apiUrl => dotenv.env['API_URL'] ?? 'http://34.159.109.82:8000';
  static String get apiKey => dotenv.env['API_KEY'] ?? 'XHDuqR20XIzCloRTBt33DyXbNHQ+4nl95kPeTPlKXcq80GI2ekA5awRCYRcilTGC1NFtBR2CKU3QfS8Fw/9mqw==';
  
  // App version
  static const String appVersion = '1.0.0';
  
  // Feature flags
  static const bool enableMockData = true; // Set to false in production
  
  // Timeout durations
  static const int apiTimeoutSeconds = 60;
  
  // Cache configuration
  static const int cacheDurationMinutes = 60;
} 