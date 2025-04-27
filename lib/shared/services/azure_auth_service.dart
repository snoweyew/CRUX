import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AzureAuthService {
  // Base URL for Azure API
  final String baseUrl;
  // API key for authentication
  final String apiKey;
  
  // Token storage
  String? _authToken;
  
  AzureAuthService({
    required this.baseUrl,
    required this.apiKey,
  });
  
  // Get the stored auth token
  String? get authToken => _authToken;
  
  // Check if user is authenticated
  bool get isAuthenticated => _authToken != null;
  
  // Register a new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        
        return UserModel(
          id: data['user']['id'],
          name: data['user']['name'],
          role: data['user']['role'],
          selectedCity: '',
          email: data['user']['email'],
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  // Login an existing user
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        
        return UserModel(
          id: data['user']['id'],
          name: data['user']['name'],
          role: data['user']['role'],
          selectedCity: '',
          email: data['user']['email'],
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  // Logout the current user
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'Authorization': 'Bearer $_authToken',
          },
        );
      }
    } catch (e) {
      // Ignore errors on logout
    } finally {
      _authToken = null;
    }
  }
  
  // Get the current user profile
  Future<UserModel> getCurrentUser() async {
    if (_authToken == null) {
      throw Exception('Not authenticated');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return UserModel(
          id: data['id'],
          name: data['name'],
          role: data['role'],
          selectedCity: data['selectedCity'] ?? '',
          email: data['email'],
        );
      } else {
        throw Exception('Failed to get user profile');
      }
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }
  
  // For demo/testing purposes - simulate API calls
  Future<UserModel> mockLogin({
    required String email,
    required String password,
    required String role,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate token
    _authToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    
    // Extract name from email
    final name = email.split('@').first;
    
    return UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      role: role,
      selectedCity: '',
      email: email,
    );
  }
} 