import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pupshape/services/web_auth_service.dart';
import 'package:pupshape/services/onesignal_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      print('🔄 Initializing AuthProvider...');
      
      // Initialize GoogleSignIn for mobile platforms only
      if (!kIsWeb) {
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        print('✅ GoogleSignIn initialized for mobile');
      }

      // Handle redirect result on web first
      if (kIsWeb) {
        await _handleWebRedirectResult();
      }

      // Set initial user state
      _user = _auth.currentUser;
      print('📱 Initial user state: ${_user?.email ?? 'null'}');

      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        print('🔄 Auth state changed: ${user?.email ?? 'null'}');
        
        // Always update the user state
        final bool userChanged = _user?.uid != user?.uid;
        _user = user;
        
        if (userChanged && _isInitialized) {
          print('👤 User changed, notifying listeners');
          notifyListeners();
        }
      });

      // Mark as initialized and notify once
      _isInitialized = true;
      notifyListeners();
      print('✅ AuthProvider initialized with user: ${_user?.email ?? 'null'}');
    } catch (e) {
      print('❌ Error initializing AuthProvider: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _handleWebRedirectResult() async {
    if (!kIsWeb) return;
    
    try {
      print('🔍 Checking for redirect result...');
      final result = await WebAuthService.handleGoogleSignInRedirect();
      if (result != null && result.user != null) {
        print('✅ Found redirect result for user: ${result.user!.email}');
        _user = result.user;
        
        // Create user document if it's a new user
        if (result.additionalUserInfo?.isNewUser == true && _user != null) {
          await _createUserDocument(_user!, _user!.displayName ?? 'User');
        }
      } else {
        print('ℹ️ No redirect result found');
      }
    } catch (e) {
      print('❌ Error handling redirect result: $e');
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      print('⏳ Loading state changed to: $loading');
      notifyListeners();
    }
  }

  void _setError(String error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      print('❌ Error: $error');
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _setError('');
      
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = result.user;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String name) async {
    try {
      _setLoading(true);
      _setError('');
      
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = result.user;
      
      // Update user profile
      await _user?.updateDisplayName(name);
      
      // Create user document in Firestore
      await _createUserDocument(_user!, name);
      
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      print('🔄 Starting Google Sign-In...');
      _setLoading(true);
      _setError('');
      
      UserCredential? result;
      
      if (kIsWeb) {
        // Web-specific Google Sign-In
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Add scopes
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // Set custom parameters
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });

        try {
          // Try popup first
          result = await _auth.signInWithPopup(googleProvider);
          print('✅ Popup sign-in successful: ${result.user?.email}');
        } catch (popupError) {
          print('❌ Popup failed: $popupError');
          
          // If popup fails, use redirect
          if (popupError.toString().contains('popup-blocked') || 
              popupError.toString().contains('popup-closed-by-user') ||
              popupError.toString().contains('Cross-Origin-Opener-Policy')) {
            
            print('🔄 Using redirect method...');
            await _auth.signInWithRedirect(googleProvider);
            _setLoading(false);
            return true; // Redirect initiated
          } else {
            throw popupError;
          }
        }
        
      } else {
        // Mobile Google Sign-In
        if (_googleSignIn == null) {
          _setError('Google Sign-In not available on this platform');
          _setLoading(false);
          return false;
        }

        print('📱 Starting mobile Google Sign-In...');
        
        // Sign out first to ensure clean state
        await _googleSignIn!.signOut();
        
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          print('❌ User cancelled Google Sign-In');
          _setLoading(false);
          return false; // User cancelled
        }

        print('✅ Google user selected: ${googleUser.email}');

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          print('❌ Failed to get Google authentication tokens');
          _setError('Failed to get authentication tokens');
          _setLoading(false);
          return false;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        print('🔄 Signing in with Firebase...');
        result = await _auth.signInWithCredential(credential);
        print('✅ Firebase sign-in successful: ${result.user?.email}');
      }
      
      if (result != null && result.user != null) {
        _user = result.user;
        
        // Create user document if it's a new user
        if (result.additionalUserInfo?.isNewUser == true && _user != null) {
          print('👤 Creating user document for new user');
          await _createUserDocument(_user!, _user!.displayName ?? 'User');
        }
        
        _setLoading(false);
        print('✅ Google Sign-In completed successfully');
        return true;
      } else {
        print('❌ No user returned from sign-in');
        _setError('Sign-in failed - no user returned');
        _setLoading(false);
        return false;
      }
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      print('❌ Unexpected error during Google Sign-In: $e');
      String errorMessage = 'Google sign in failed';
      
      if (e.toString().contains('popup-closed-by-user') || 
          e.toString().contains('cancelled')) {
        errorMessage = 'Sign in was cancelled';
      } else if (e.toString().contains('popup-blocked')) {
        errorMessage = 'Popup was blocked. Trying redirect method...';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage = 'Google sign-in failed. Please try again';
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      print('🔄 Signing out user...');
      _setLoading(true);
      
      // Sign out from OneSignal
      if (!kIsWeb) {
        try {
          await OneSignalService.logout();
          print('✅ OneSignal logout completed');
        } catch (e) {
          print('⚠️ Failed to logout from OneSignal: $e');
        }
      }
      
      // Sign out from Firebase
      await _auth.signOut();
      
      // Sign out from Google on mobile
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.signOut();
        await _googleSignIn!.disconnect();
      }
      
      _user = null;
      _errorMessage = '';
      _setLoading(false);
      print('✅ Sign out completed');
    } catch (e) {
      print('❌ Error signing out: $e');
      _setLoading(false);
    }
  }

  Future<void> _createUserDocument(User user, String name) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        await userDoc.set({
          'name': name,
          'email': user.email,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ User document created');
      } else {
        print('ℹ️ User document already exists');
      }
      
      // Sync user with OneSignal
      if (!kIsWeb) {
        try {
          await OneSignalService.setUserId(user.uid);
          if (user.email != null) {
            await OneSignalService.setEmail(user.email!);
          }
          print('✅ User synced with OneSignal');
        } catch (e) {
          print('⚠️ Failed to sync with OneSignal: $e');
        }
      }
    } catch (e) {
      print('❌ Error creating user document: $e');
      // Don't throw error - user is still authenticated
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError('');
      
      await _auth.sendPasswordResetEmail(email: email);
      
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials';
      case 'invalid-credential':
        return 'The credential is malformed or has expired';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account';
      default:
        return e.message ?? 'An authentication error occurred';
    }
  }
}
