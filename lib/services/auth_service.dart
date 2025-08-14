import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For Android: clientId should be null to use google-services.json
    // For Web: prefer build-time provided client ID; if null, the web plugin
    // will attempt to read it from the meta tag in web/index.html
    clientId: kIsWeb ? _getGoogleClientId() : null,
  );

  // Resolve Google Client ID for Web from build-time definitions; otherwise null
  static String? _getGoogleClientId() {
    if (!kIsWeb) {
      // For mobile platforms, return null to use the default configuration from google-services.json
      return null;
    }
    // Prefer a build-time provided value (set via --dart-define=GOOGLE_CLIENT_ID=...)
    const String fromDefine = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    // Returning null allows the web plugin to read the client ID from the meta tag
    // <meta name="google-signin-client_id" content="..."> in web/index.html
    return null;
  }

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Constructor
  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google (with better error handling)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Clear any previous sign-in state for Android
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google user credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Handle specific Google Sign-In errors
      String errorMessage = e.toString();
      
      if (errorMessage.contains('PlatformException(sign_in_failed')) {
        // Extract the specific error details
        if (errorMessage.contains('ApiException: 10')) {
          throw Exception(
            'Google Sign-In configuration error (ApiException: 10). '
            'This usually means:\n'
            '1. The SHA-1 fingerprint doesn\'t match what\'s registered in Firebase Console\n'
            '2. The app package name doesn\'t match Firebase configuration\n'
            '3. Google Play Services needs to be updated\n'
            'Please check Firebase Console settings or use email/password sign-in.'
          );
        }
      }
      
      if (errorMessage.contains('OAuth client was not found') || 
          errorMessage.contains('invalid_client')) {
        throw Exception(
          'Google Sign-In is not configured properly. '
          'Please configure OAuth client ID in Google Cloud Console. '
          'For now, please use email/password sign-in.'
        );
      }
      
      // Generic Google Sign-In error with more details
      throw Exception('Google sign-in failed. Error details: $errorMessage');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      await currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
} 