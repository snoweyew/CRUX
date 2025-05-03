import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign in with user from another auth system or migration
  Future<void> signInWithExternalAuth({
    required String email,
    required String externalId,
  }) async {
    try {
      if (isAuthenticated) {
        print('Already authenticated with Supabase');
        return;
      }

      final securePassword = _generateSecurePassword(externalId);
      
      // First try to sign in
      final signInResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: securePassword,
      ).catchError((e) {
        print('Sign in error details: ${e.toString()}');
        return null;
      });

      if (signInResponse?.user != null) {
        print('Successfully signed in to Supabase: ${signInResponse!.user!.email}');
        return;
      }

      // If sign in fails, try to sign up
      print('Attempting to create new user...');
      final signUpResponse = await _supabase.auth.signUp(
        email: email,
        password: securePassword,
      ).catchError((e) {
        print('Sign up error details: ${e.toString()}');
        return null;
      });

      if (signUpResponse?.user == null) {
        throw Exception('''
Failed to authenticate with Supabase. 
Possible causes:
1. Invalid email format
2. Password too weak
3. Network connectivity issues
4. Supabase service unavailable
''');
      }

      print('Successfully created Supabase user: ${signUpResponse!.user!.email}');
    } catch (e) {
      print('Detailed auth error: ${e.toString()}');
      rethrow;
    }
  }

  // Generate a secure password using external ID
  String _generateSecurePassword(String externalId) {
    // Use external ID as a base and add some complexity
    return '${externalId}_${DateTime.now().year}#Sup@';
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
