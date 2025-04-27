import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

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
          } else {
            // If user document doesn't exist, create a basic user model
            _currentUser = _userFromFirebase(firebaseUser);
          }
        } catch (e) {
          // If there's an error getting user data, create a basic user model
          _currentUser = _userFromFirebase(firebaseUser);
        }
      } else {
        _currentUser = null;
      }
      
      // Notify listeners
      _authStateController.add(_currentUser);
    });
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

  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
    String role,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw AuthException('auth/unknown', 'An unknown error occurred');
      }
      
      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      // Check if user exists in Firestore
      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'role': role,
          'name': userCredential.user!.displayName ?? 'User',
          'email': userCredential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Verify role matches
        final userRole = userDoc.data()?['role'];
        if (userRole != null && userRole != role) {
          // Sign out if role doesn't match
          await _firebaseAuth.signOut();
          throw AuthException(
            'wrong-role',
            'This email is not registered as a $role',
          );
        }
      }
      
      // Create user model
      final user = UserModel(
        id: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'User',
        email: userCredential.user!.email,
        role: role,
        selectedCity: userDoc.data()?['selectedCity'] ?? '',
        isEmailVerified: userCredential.user!.emailVerified,
        visitorType: userDoc.data()?['visitorType'],
      );
      
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Authentication failed');
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
    await _firebaseAuth.signOut();
  }
  
  // Dispose
  void dispose() {
    _authStateController.close();
  }
}
