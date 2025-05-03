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
  final String? friendlyMessage;

  AuthException(this.code, this.message, {this.friendlyMessage});

  @override
  String toString() => friendlyMessage ?? 'AuthException: $code - $message';
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
        
        // Get role with fallback mechanisms
        String userRole = response['role'];
        
        // If role is null or empty, try alternative approaches
        if (userRole == null || userRole.isEmpty) {
          // Try to determine role from email domain
          userRole = _getUserRole(user?.email);
          
          // Update the profile with the determined role
          try {
            await _supabase.from('profiles').update({
              'role': userRole,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', uid);
            print('Updated missing role in profile to: $userRole');
          } catch (updateError) {
            print('Failed to update role in profile: $updateError');
          }
        }
        
        print('Retrieved user role: $userRole');
        
        return UserModel.fromJson({
          'id': uid,
          'name': response['name'] ?? user?.userMetadata?['name'] ?? 'User',
          'email': user?.email,
          'role': userRole,
          'selectedCity': response['location'] ?? '',
          'isEmailVerified': user?.hasVerifiedEmail() ?? false,
          'visitorType': response['visitor_type'],
        });
      }
      return null; // User profile doesn't exist
    } catch (e) {
      print('Error fetching user data: $e');
      
      // Fallback: Try to create a basic user model from auth user
      try {
        final user = _supabase.auth.currentUser;
        if (user != null && user.id == uid) {
          final role = _getUserRole(user.email);
          return UserModel(
            id: uid,
            name: user.userMetadata?['name'] ?? 'User',
            email: user.email,
            role: role,
            selectedCity: '',
            isEmailVerified: user.hasVerifiedEmail() ?? false,
          );
        }
      } catch (fallbackError) {
        print('Fallback user creation also failed: $fallbackError');
      }
      
      return null;
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
        
        // Debug: Print user data to understand what's happening
        print('User login data: ${userData?.toJson()}');
        
        return userData;
      }
      return null;
    } catch (e) {
      // Provide user-friendly error messages
      if (e.toString().contains('Invalid login credentials')) {
        throw AuthException('auth/invalid-credentials', 
          'Invalid email or password', 
          friendlyMessage: 'The email or password you entered is incorrect.');
      } else if (e.toString().contains('Email not confirmed')) {
        throw AuthException('auth/email-not-verified', 
          'Email not verified', 
          friendlyMessage: 'Please verify your email address before logging in.');
      } else {
        throw AuthException('auth/unknown', 
          'Login error: ${e.toString()}', 
          friendlyMessage: 'An error occurred during login. Please try again.');
      }
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
      // Check if role is valid
      if (!['tourist', 'local_guide', 'stb_staff'].contains(role)) {
        throw AuthException('auth/invalid-role', 
          'Invalid role: $role', 
          friendlyMessage: 'The selected role is not valid.');
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        throw AuthException('auth/unknown', 'Registration failed');
      }

      final userId = response.user!.id;
      final now = DateTime.now().toIso8601String();

      try {
        // Create user profile with defensive coding to avoid duplicate key errors
        await _supabase.rpc(
          'handle_new_user_registration',
          params: {
            'user_id': userId,
            'user_name': name,
            'user_email': email, 
            'user_role': role,
            'created_at_time': now,
          },
        );
      } catch (dbError) {
        print('Using fallback profile creation method due to error: $dbError');
        
        // Try direct insert as fallback
        try {
          await _supabase.from('profiles').insert({
            'id': userId,
            'name': name,
            'email': email,
            'role': role,
            'created_at': now,
            'updated_at': now,
          });
        } catch (directInsertError) {
          print('Direct insert also failed: $directInsertError');
          // Continue anyway since the auth user is created
        }
      }

      // Create user model
      return UserModel(
        id: userId,
        name: name,
        email: email,
        role: role,
        selectedCity: '',
        isEmailVerified: response.user!.hasVerifiedEmail() ?? false,
      );
    } catch (e) {
      // Handle specific auth errors with user-friendly messages
      if (e.toString().contains('already exists')) {
        throw AuthException('auth/email-already-in-use', 
          'The email address is already in use', 
          friendlyMessage: 'This email is already registered. Please use a different email or login instead.');
      } else if (e.toString().contains('password') && e.toString().contains('weak')) {
        throw AuthException('auth/weak-password', 
          'The password is too weak', 
          friendlyMessage: 'Your password is too weak. Please use at least 6 characters with a mix of letters and numbers.');
      } else if (e is AuthException) {
        rethrow;
      } else {
        throw AuthException('auth/unknown', 
          'Registration error: ${e.toString()}', 
          friendlyMessage: 'Registration failed. Please try again later.');
      }
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('Successfully signed out from Supabase');
    } catch (e) {
      print('Error signing out: $e');
      throw AuthException('auth/sign-out-error', 
        'Error signing out: ${e.toString()}', 
        friendlyMessage: 'There was a problem signing out. Please try again.');
    }
  }
  
  // Dispose
  void dispose() {
    _authStateController.close();
  }
}
