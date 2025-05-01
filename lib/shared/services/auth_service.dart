import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'supabase_auth_service.dart';

class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException: $code - $message';
}

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        // Get user data from Firestore
        try {
          final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
          if (userDoc.exists) {
            _currentUser = UserModel.fromJson({
              'id': firebaseUser.uid,
              'name': firebaseUser.displayName ?? 'User',
              'email': firebaseUser.email,
              'role': userDoc.data()?['role'] ?? 'tourist',
              'selectedCity': userDoc.data()?['selectedCity'] ?? '',
              'isEmailVerified': firebaseUser.emailVerified,
              'visitorType': userDoc.data()?['visitorType'],
            });

            // Sign in to Supabase
            if (firebaseUser.email != null) {
              await _signInToSupabase(firebaseUser.email!, userDoc.data()?['role'] ?? 'tourist');
            }
          } else {
            // If user document doesn't exist, create a basic user model
            _currentUser = _userFromFirebase(firebaseUser);
          }
        } catch (e) {
          print('Error in auth state change: $e');
          // If there's an error getting user data, create a basic user model
          _currentUser = _userFromFirebase(firebaseUser);
        }
      } else {
        _currentUser = null;
        // Sign out from Supabase
        await _supabaseAuth.signOut();
      }
      
      // Notify listeners
      _authStateController.add(_currentUser);
    });
  }

  // Sign in to Supabase
  Future<void> _signInToSupabase(String email, String role) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw AuthException('auth/not-signed-in', 'Not signed in to Firebase');
      }

      await _supabaseAuth.signInWithFirebaseUser(
        email: email,
        firebaseUid: currentUser.uid,
      );
    } catch (e) {
      print('Error signing in to Supabase: $e');
    }
  }
  
  // Helper to convert Firebase User to UserModel
  UserModel _userFromFirebase(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email,
      role: _getUserRole(firebaseUser),
      selectedCity: '',
      isEmailVerified: firebaseUser.emailVerified,
    );
  }
  
  // Get user role from custom claims or default to 'tourist'
  String _getUserRole(firebase_auth.User firebaseUser) {
    // In a real app, you would get this from Firebase custom claims
    // For now, we'll determine based on email domain
    final email = firebaseUser.email ?? '';
    if (email.contains('stb.gov')) {
      return 'stb_staff';
    } else if (email.contains('local.guide')) {
      return 'local_guide';
    } else {
      return 'tourist';
    }
  }

  // Fetch user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final firebaseUser = _firebaseAuth.currentUser; // Get current Firebase user for emailVerified status
        return UserModel.fromJson({
          'id': uid,
          'name': data['name'] ?? firebaseUser?.displayName ?? 'User',
          'email': data['email'] ?? firebaseUser?.email,
          'role': data['role'] ?? 'tourist',
          'selectedCity': data['selectedCity'] ?? '',
          'isEmailVerified': firebaseUser?.emailVerified ?? false,
          'visitorType': data['visitorType'],
        });
      }
      return null; // User document doesn't exist
    } catch (e) {
      print('Error fetching user data: $e');
      return null; // Return null on error
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Sign in with Firebase
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get user data from Firestore
        final userData = await getUserData(userCredential.user!.uid);
        
        // Sync with Supabase
        await _syncSupabaseAuth(email, userCredential.user!.uid);
        
        return userData;
      }
      return null;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Sync Firebase auth with Supabase
  Future<void> _syncSupabaseAuth(String email, String firebaseUid) async {
    try {
      await _supabaseAuth.signInWithFirebaseUser(
        email: email,
        firebaseUid: firebaseUid,
      );
      
      // Verify Supabase session
      final isAuthenticated = await _supabaseAuth.verifySession();
      if (!isAuthenticated) {
        throw Exception('Failed to authenticate with Supabase after sync');
      }
      
      print('Successfully synced Firebase auth with Supabase');
    } catch (e) {
      print('Error syncing with Supabase: $e');
      // Rethrow the exception to signal failure
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
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw AuthException('auth/unknown', 'An unknown error occurred');
      }
      
      // Update user profile with name
      await userCredential.user!.updateDisplayName(name);
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'role': role,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign in to Supabase
      await _signInToSupabase(email, role);
      
      // Reload user to get updated profile
      await userCredential.user!.reload();
      final updatedUser = _firebaseAuth.currentUser;
      
      if (updatedUser == null) {
        throw AuthException('auth/user-not-found', 'User not found after registration');
      }
      
      // Create user model
      final user = UserModel(
        id: updatedUser.uid,
        name: name,
        email: email,
        role: role,
        selectedCity: '',
        isEmailVerified: updatedUser.emailVerified,
      );
      
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Registration failed');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Supabase first
      await _supabaseAuth.signOut();
      
      // Then sign out from Firebase
      await _firebaseAuth.signOut();
      
      print('Successfully signed out from both Firebase and Supabase');
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
