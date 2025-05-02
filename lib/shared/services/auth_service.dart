import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_auth_service.dart';

// Extension method to check if email is verified
extension UserExtension on User {
  bool? hasVerifiedEmail() {
    // Check email verification using user metadata
    return userMetadata?['email_confirmed'] == true || 
           userMetadata?['email_verified'] == true;
  }
}

class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException: $code - $message';
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseAuthService _supabaseAuth = SupabaseAuthService();
  
  // Current logged in user
  UserModel? _currentUser;
  
  // Stream controller for auth state changes
  final _authStateController = StreamController<UserModel?>.broadcast();
  
  // Stream of auth state changes
  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  
  // Get current user
  UserModel? get currentUser => _currentUser;
  
  AuthService() {
    // Listen to Supabase auth state changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        try {
          final user = session.user;
          
          // Get user data from Supabase profiles table
          final response = await _supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();
              
          if (response != null) {
            _currentUser = UserModel(
              id: user.id,
              name: response['name'] ?? user.userMetadata?['name'] ?? 'User',
              email: user.email,
              role: response['role'] ?? 'tourist',
              selectedCity: response['location'] ?? '',
              isEmailVerified: user.hasVerifiedEmail() ?? false,
              visitorType: response['visitor_type'],
            );
          } else {
            // Basic user model if no profile exists
            _currentUser = UserModel(
              id: user.id,
              name: user.userMetadata?['name'] ?? 'User',
              email: user.email,
              role: _getUserRole(user.email),
              selectedCity: '',
              isEmailVerified: user.hasVerifiedEmail() ?? false,
            );
          }
        } catch (e) {
          print('Error in auth state change: $e');
          // Basic user model on error
          _currentUser = _userFromSupabase(_supabase.auth.currentUser);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
      }
      
      // Notify listeners
      _authStateController.add(_currentUser);
    });
  }
  
  // Helper to convert Supabase User to UserModel
  UserModel? _userFromSupabase(User? user) {
    if (user == null) return null;
    
    return UserModel(
      id: user.id,
      name: user.userMetadata?['name'] ?? 'User',
      email: user.email,
      role: _getUserRole(user.email),
      selectedCity: '',
      isEmailVerified: user.hasVerifiedEmail() ?? false,
    );
  }
  
  // Get user role from email domain or default to 'tourist'
  String _getUserRole(String? email) {
    if (email == null) return 'tourist';
    
    if (email.contains('stb.gov')) {
      return 'stb_staff';
    } else if (email.contains('local.guide')) {
      return 'local_guide';
    } else {
      return 'tourist';
    }
  }

  // Fetch user data from Supabase profiles
  Future<UserModel?> getUserData(String uid) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', uid)
          .single();
          
      if (response != null) {
        final user = _supabase.auth.currentUser;
        return UserModel.fromJson({
          'id': uid,
          'name': response['name'] ?? 'User',
          'email': user?.email,
          'role': response['role'] ?? 'tourist',
          'selectedCity': response['location'] ?? '',
          'isEmailVerified': user?.hasVerifiedEmail() ?? false,
          'visitorType': response['visitor_type'],
        });
      }
      return null; // User profile doesn't exist
    } catch (e) {
      print('Error fetching user data: $e');
      return null; // Return null on error
    }
  }

  // Sign in to Supabase
  Future<void> _signInToSupabase(String email, String role) async {
    try {
      await _supabaseAuth.signInWithExternalAuth(
        email: email,
        externalId: _supabase.auth.currentUser?.id ?? DateTime.now().toString(),
      );
    } catch (e) {
      print('Error signing in to Supabase: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Get user data from profiles
        final userData = await getUserData(response.user!.id);
        return userData;
      }
      return null;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserModel> registerWithEmailAndPassword(
    String email,
    String password,
    String role,
    String name,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      if (response.user == null) {
        throw AuthException('auth/unknown', 'An unknown error occurred');
      }
      
      final userId = response.user!.id;
      
      // Create user profile in Supabase
      await _supabase.from('profiles').insert({
        'id': userId,
        'name': name,
        'email': email,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Create user model
      final user = UserModel(
        id: userId,
        name: name,
        email: email,
        role: role,
        selectedCity: '',
        isEmailVerified: response.user!.hasVerifiedEmail() ?? false,
      );
      
      return user;
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      throw AuthException('auth/unknown', e.toString());
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('Successfully signed out from Supabase');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  // Dispose
  void dispose() {
    _authStateController.close();
  }
}
