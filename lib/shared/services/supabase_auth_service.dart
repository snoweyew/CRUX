import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign in with Firebase user
  Future<void> signInWithFirebaseUser({
    required String email,
    required String firebaseUid,
  }) async {
    try {
      // Check if already signed in
      if (isAuthenticated) {
        print('Already authenticated with Supabase');
        return;
      }

      // Generate a secure password using Firebase UID
      final securePassword = _generateSecurePassword(firebaseUid);
      
      try {
        // Try to sign in first
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: securePassword,
        );
        
        if (response.user == null) {
          throw Exception('Failed to sign in to Supabase');
        }
        
        print('Successfully signed in to Supabase: ${response.user?.email}');
      } catch (e) {
        print('Sign in failed, attempting to create new user: $e');
        
        // If sign in fails, create a new user
        final response = await _supabase.auth.signUp(
          email: email,
          password: securePassword,
        );
        
        if (response.user == null) {
          throw Exception('Failed to create Supabase user');
        }
        
        print('Successfully created Supabase user: ${response.user?.email}');
      }
    } catch (e) {
      print('Error in Supabase auth: $e');
      rethrow;
    }
  }

  // Generate a secure password using Firebase UID
  String _generateSecurePassword(String firebaseUid) {
    // Use Firebase UID as a base and add some complexity
    return '${firebaseUid}_${DateTime.now().year}#Sup@';
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (isAuthenticated) {
        await _supabase.auth.signOut();
        print('Successfully signed out from Supabase');
      }
    } catch (e) {
      print('Error signing out from Supabase: $e');
      rethrow;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  // Verify authentication status
  Future<bool> verifySession() async {
    try {
      final session = _supabase.auth.currentSession; // Use currentSession property
      return session?.user != null;
    } catch (e) {
      print('Error verifying Supabase session: $e');
      return false;
    }
  }
}