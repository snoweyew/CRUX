import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String? supabaseUrl;
  static String? supabaseAnonKey;

  static Future<void> initialize() async {
    try {
      // Get project details via MCP
      final projectUrl = await _getProjectUrl();
      final anonKey = await _getAnonKey();

      await Supabase.initialize(
        url: projectUrl,
        anonKey: anonKey,
        debug: true,
      );
      print('Supabase initialized successfully via MCP');
    } catch (e) {
      print('Error initializing Supabase via MCP: $e');
      rethrow;
    }
  }

  static Future<String> _getProjectUrl() async {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('Missing SUPABASE_URL in environment variables');
    }
    return url;
  }

  static Future<String> _getAnonKey() async {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Missing SUPABASE_ANON_KEY in environment variables');
    }
    return key;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
