import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// A specialized service for role-based authentication.
/// This service focuses only on role verification and authentication,
/// making the login process more reliable.
class RoleAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Login with email and password, with strict role validation
  /// Returns a UserModel if login is successful and role matches
  /// Returns null if login fails or role doesn't match
  Future<UserModel?> roleBasedLogin(String email, String password, String expectedRole) async {
    print('Attempting to login user with email: $email and role: $expectedRole');
    
    try {
      // First attempt authentication with Supabase
      print('Sending authentication request to Supabase...');
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (authResponse.user == null) {
        print('Login failed: No user returned from authentication');
        return null;
      }
      
      print('Authentication successful for user ID: ${authResponse.user!.id}');
      
      // Successfully authenticated, now check the role
      final userId = authResponse.user!.id;
      
      try {
        // Get the user's profile with role information
        print('Fetching user profile from Supabase...');
        final profileResponse = await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        
        print('Profile response: $profileResponse');
        
        if (profileResponse == null) {
          print('Login failed: No profile found for user $userId');
          // Sign out since role verification failed
          await _supabase.auth.signOut();
          return null;
        }
        
        // Extract the role from the profile
        final String actualRole = profileResponse['role']?.toString() ?? '';
        print('User role from database: "$actualRole"');
        print('Expected role: "$expectedRole"');
        
        // Strict check for exact role match
        if (actualRole == expectedRole) {
          print('Role verification successful - User has correct role: $actualRole');
          // Role matches, create and return user model
          return UserModel(
            id: userId,
            name: profileResponse['name'] ?? authResponse.user!.userMetadata?['name'] ?? 'User',
            email: email,
            role: actualRole,
            selectedCity: profileResponse['location'] ?? '',
            isEmailVerified: authResponse.user!.emailConfirmedAt != null,
            visitorType: profileResponse['visitor_type'],
          );
        } else {
          print('Login failed: Role mismatch. Expected: $expectedRole, Found: $actualRole');
          // Sign out since role verification failed
          await _supabase.auth.signOut();
          return null;
        }
      } catch (dbError) {
        print('Database error while checking role: $dbError');
        // Sign out since role verification failed
        await _supabase.auth.signOut();
        return null;
      }
    } catch (e) {
      print('Authentication error details:');
      if (e is AuthException) {
        print('- Auth error code: ${e.statusCode}');
        print('- Auth error message: ${e.message}');
      }
      print('Complete login error: $e');
      return null;
    }
  }
  
  /// Update a user's role in the database
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await _supabase.from('profiles').update({
        'role': newRole,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      
      return true;
    } catch (e) {
      print('Error updating role: $e');
      return false;
    }
  }
  
  /// Check if a user exists with the given email
  Future<bool> doesUserExist(String email) async {
    try {
      final List<dynamic> data = await _supabase
          .from('profiles')
          .select('email')
          .eq('email', email)
          .limit(1);
          
      return data.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }
  
  /// Check if a user has a specific role
  Future<bool> hasRole(String userId, String role) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      
      return data != null && data['role'] == role;
    } catch (e) {
      print('Error checking role: $e');
      return false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}