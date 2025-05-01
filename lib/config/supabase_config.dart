import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace placeholders with actual values
  static const String supabaseUrl = 'https://jvzjvkjgkhdptkkkffei.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2emp2a2pna2hkcHRra2tmZmVpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYxMDEzNzgsImV4cCI6MjA2MTY3NzM3OH0.7sd7XjLfkhEQ0PPcN1NxZDO4Qrk0bOK4jaX728KqYbA';

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true, // Enable for development, disable in production
      );
      print('Supabase initialized successfully');
    } catch (e) {
      print('Error initializing Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}