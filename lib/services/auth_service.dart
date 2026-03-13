import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(firestoreServiceProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirestoreService _firestoreService;
  final _auth = FirebaseAuth.instance;

  AuthService(this._firestoreService);

  User? get currentUser => _auth.currentUser;

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    await GoogleSignIn.instance.initialize();
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    return _auth.signInWithCredential(credential);
  }

  /// Guest / anonymous sign in for testing
  Future<UserCredential> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    await _syncUserToFirestore(cred.user!);
    return cred;
  }

  /// Email + password sign up
  Future<UserCredential> signUpWithEmail(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user!.updateDisplayName(name);
    await _syncUserToFirestore(cred.user!, displayName: name);
    return cred;
  }

  /// Email + password sign in
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _syncUserToFirestore(cred.user!);
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _syncUserToFirestore(User user, {String? displayName}) async {
    await _firestoreService.upsertUser(user, displayName: displayName);
  }
}
