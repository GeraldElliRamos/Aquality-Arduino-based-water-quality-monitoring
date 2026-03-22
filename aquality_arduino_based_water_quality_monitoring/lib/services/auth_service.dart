import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}

class GoogleSignInResult {
  final bool isNewUser;
  final bool needsRoleSelection;

  const GoogleSignInResult({
    required this.isNewUser,
    required this.needsRoleSelection,
  });
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  static final ValueNotifier<String> userRole = ValueNotifier<String>('');

  static void init() {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        isLoggedIn.value = false;
        isAdmin.value = false;
        userRole.value = '';
      } else {
        isLoggedIn.value = true;
        final doc = await _db.collection('users').doc(user.uid).get();
        isAdmin.value = doc.data()?['isAdmin'] == true;
        userRole.value = doc.data()?['userType'] ?? '';
      }
    });
  }

  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = currentUid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  static Future<void> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String userType,
  }) async {
    final usernameQuery = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      throw AuthException(
        'username-already-taken',
        'That username is already taken. Please choose another.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    const bool adminRole = false;

    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'fullName': fullName.trim(),
      'username': username.trim().toLowerCase(),
      'email': email.trim().toLowerCase(),
      'userType': userType,
      'isAdmin': adminRole,
      'createdAt': FieldValue.serverTimestamp(),
    });

    isLoggedIn.value = true;
    isAdmin.value = adminRole;
    userRole.value = userType;
  }

  static Future<void> login({
    required String username,
    required String password,
  }) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw AuthException(
        'user-not-found',
        'No account found with that username.',
      );
    }

    final userData = query.docs.first.data();
    final email = userData['email'] as String;

    await _auth.signInWithEmailAndPassword(email: email, password: password);

    isLoggedIn.value = true;
    isAdmin.value = userData['isAdmin'] == true;
    userRole.value = userData['userType'] ?? '';
  }

  // ── Google Sign In ──────────────────────────────────────────────
  static Future<GoogleSignInResult> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw AuthException('cancelled', 'Google sign-in was cancelled.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    bool isNewUser = false;
    final normalizedEmail = user.email?.trim().toLowerCase() ?? '';
    final generatedUsername =
        normalizedEmail.isNotEmpty ? normalizedEmail.split('@').first : '';
    final displayName = user.displayName?.trim() ?? '';

    if (!doc.exists) {
      isNewUser = true;
      await docRef.set({
        'uid': user.uid,
        'fullName': displayName,
        'username': generatedUsername,
        'email': normalizedEmail,
        'userType': '',
        'isAdmin': false,
        'authProvider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      });
      userRole.value = '';
      isAdmin.value = false;
    } else {
      final data = doc.data() ?? {};
      final updates = <String, dynamic>{};

      if ((data['email'] as String?)?.trim().isEmpty ?? true) {
        updates['email'] = normalizedEmail;
      }
      if ((data['fullName'] as String?)?.trim().isEmpty ?? true) {
        updates['fullName'] = displayName;
      }
      if ((data['username'] as String?)?.trim().isEmpty ?? true) {
        updates['username'] = generatedUsername;
      }
      if (updates.isNotEmpty) {
        await docRef.set(updates, SetOptions(merge: true));
      }

      userRole.value = (data['userType'] as String?) ?? '';
      isAdmin.value = data['isAdmin'] == true;
    }

    isLoggedIn.value = true;
    return GoogleSignInResult(
      isNewUser: isNewUser,
      needsRoleSelection: userRole.value.isEmpty,
    );
  }

  static Future<void> completeGoogleSignupProfile({
    required String fullName,
    required String username,
    required String email,
    required String userType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('not-authenticated', 'Please sign in first.');
    }

    final normalizedUsername = username.trim().toLowerCase();
    final usernameQuery = await _db
        .collection('users')
        .where('username', isEqualTo: normalizedUsername)
        .limit(1)
        .get();

    if (usernameQuery.docs.isNotEmpty && usernameQuery.docs.first.id != user.uid) {
      throw const AuthException(
        'username-already-taken',
        'That username is already taken. Please choose another.',
      );
    }

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName.trim(),
      'username': normalizedUsername,
      'email': email.trim().toLowerCase(),
      'userType': userType,
      'isAdmin': false,
      'authProvider': 'google',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    isLoggedIn.value = true;
    isAdmin.value = false;
    userRole.value = userType;
  }

  // ── Logout ──────────────────────────────────────────────────────
  static Future<void> logout() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await _auth.signOut();
    isAdmin.value = false;
    isLoggedIn.value = false;
    userRole.value = '';
  }

  static void setAdmin(bool v) => isAdmin.value = v;
  static void setLoggedIn(bool v) => isLoggedIn.value = v;
}
