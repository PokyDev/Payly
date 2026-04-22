import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth        = FirebaseAuth.instance;
  final _firestore   = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    debugPrint('[Auth] signIn → email: $email');
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('[Auth] signIn OK → uid: ${cred.user?.uid}');
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signIn ERROR → code: ${e.code} | message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[Auth] signIn UNEXPECTED → $e');
      rethrow;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    debugPrint('[Auth] isUsernameAvailable → "$username"');
    final doc = await _firestore
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();
    return !doc.exists;
  }

  Future<void> _claimUsername(String uid, String username) async {
    await _firestore
        .collection('usernames')
        .doc(username.toLowerCase())
        .set({'uid': uid});
    debugPrint('[Auth] claimUsername OK → "$username" → $uid');
  }

  Future<void> _createUserProfile(String uid, String username, String? email) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'username': username,
      'email': email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('[Auth] createUserProfile OK → uid: $uid | username: $username');
  }

  Future<UserCredential> register(String email, String password, String username) async {
    debugPrint('[Auth] register → email: $email | username: $username');
    final available = await isUsernameAvailable(username);
    if (!available) throw Exception('username-taken');
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.updateDisplayName(username);
      await _claimUsername(cred.user!.uid, username);
      await _createUserProfile(cred.user!.uid, username, email);
      debugPrint('[Auth] register OK → uid: ${cred.user?.uid}');
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] register ERROR → code: ${e.code} | message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[Auth] register UNEXPECTED → $e');
      rethrow;
    }
  }

  Future<void> updateDisplayName(String name) async {
    debugPrint('[Auth] updateDisplayName → "$name"');
    await _auth.currentUser!.updateDisplayName(name);
    debugPrint('[Auth] updateDisplayName OK');
  }

  Future<void> signOut() async {
    debugPrint('[Auth] signOut → uid: ${_auth.currentUser?.uid}');
    await _auth.signOut();
    debugPrint('[Auth] signOut OK');
  }

  Future<void> sendPasswordReset(String email) async {
    debugPrint('[Auth] sendPasswordReset → $email');
    await _auth.sendPasswordResetEmail(email: email);
    debugPrint('[Auth] sendPasswordReset OK');
  }

  Future<UserCredential> signInWithGoogle() async {
    debugPrint('[Auth] signInWithGoogle → start');
    await _googleSignIn.signOut();
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint('[Auth] signInWithGoogle → cancelled by user');
      throw Exception('google-cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    debugPrint('[Auth] signInWithGoogle → got credential, signing into Firebase');
    try {
      final cred = await _auth.signInWithCredential(credential);
      debugPrint('[Auth] signInWithGoogle OK → uid: ${cred.user?.uid}');
      final hasUsername = await _hasUsernameForUid(cred.user!.uid);
      if (!hasUsername) {
        final username = await _resolveGoogleUsername(cred.user!.uid, googleUser.displayName);
        await cred.user!.updateDisplayName(username);
        await _createUserProfile(cred.user!.uid, username, cred.user!.email);
        debugPrint('[Auth] signInWithGoogle → claimed username: "$username"');
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signInWithGoogle ERROR → code: ${e.code} | message: ${e.message}');
      rethrow;
    }
  }

  Future<String?> getUsernameForUid(String uid) async {
    final snap = await _firestore
        .collection('usernames')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty ? snap.docs.first.id : null;
  }

  Future<bool> _hasUsernameForUid(String uid) async {
    final snap = await _firestore
        .collection('usernames')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<String> _resolveGoogleUsername(String uid, String? displayName) async {
    final base = _sanitizeUsername(displayName ?? 'user');
    var candidate = base;
    var suffix = 1;
    while (true) {
      final available = await isUsernameAvailable(candidate);
      if (available) {
        await _claimUsername(uid, candidate);
        return candidate;
      }
      candidate = '$base$suffix';
      suffix++;
    }
  }

  String _sanitizeUsername(String raw) {
    var name = raw
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '.')
        .replaceAll(RegExp(r'[^a-z0-9._\-]'), '');
    if (name.length < 3) name = name.padRight(3, '0');
    if (name.length > 20) name = name.substring(0, 20);
    return name;
  }
}
