import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(firestoreServiceProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirestoreService _firestoreService;
  final _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService(this._firestoreService) {
    _initGoogleSignIn();
  }

  Future<void>? _initFuture;

  void _initGoogleSignIn() {
    // IMPORTANT: This MUST be a "Web client ID" (type: Web application)
    // found in Google Cloud Console -> APIs & Services -> Credentials
    _initFuture = _googleSignIn.initialize(
      serverClientId: '723703253854-p2n77p5id2i6u7q0u660v837f48l8b8r.apps.googleusercontent.com',
    );
  }

  User? get currentUser => _auth.currentUser;

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ensure initialization is complete
      await _initFuture;

      // Start the interactive process
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      // Get tokens

      final GoogleSignInAuthentication googleAuth = account.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // accessToken is optional but helpful if available
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _syncUserToFirestore(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      print('Google Sign-In Error: $e');
      if (e.toString().contains('16')) {
        print('HINT: Check if SHA-1 is added to Firebase and if you are using a WEB client ID for serverClientId.');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  Future<void> _syncUserToFirestore(User user, {String? displayName}) async {
    await _firestoreService.upsertUser(user, displayName: displayName);
  }

  // Fallback methods for other auth types
  Future<UserCredential> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    await _syncUserToFirestore(cred.user!);
    return cred;
  }

  Future<UserCredential> signUpWithEmail(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user!.updateDisplayName(name);
    await _syncUserToFirestore(cred.user!, displayName: name);
    return cred;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _syncUserToFirestore(cred.user!);
    return cred;
  }
}
