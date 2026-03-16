import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Custom exception — defined BEFORE AuthService so DDC resolves it ──
class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Reactive state ──────────────────────────────────────────────
  static final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

  /// Call once in main() after Firebase.initializeApp().
  /// Keeps session alive across hot-restart / app relaunch.
  static void init() {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        isLoggedIn.value = false;
        isAdmin.value = false;
      } else {
        isLoggedIn.value = true;
        final doc = await _db.collection('users').doc(user.uid).get();
        isAdmin.value = doc.data()?['isAdmin'] == true;
      }
    });
  }

  // ── Current user helpers ────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = currentUid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ── Sign Up ─────────────────────────────────────────────────────
  static Future<void> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String userType,
  }) async {
    // 1. Check username uniqueness
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

    // 2. Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final bool adminRole = userType == 'fishPondOwner' || userType == 'lgu';

    // 3. Save profile to Firestore
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
  }

  // ── Login ───────────────────────────────────────────────────────
  static Future<void> login({
    required String username,
    required String password,
  }) async {
    // 1. Resolve username → email via Firestore
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

    // 2. Sign in with Firebase Auth
    await _auth.signInWithEmailAndPassword(email: email, password: password);

    isLoggedIn.value = true;
    isAdmin.value = userData['isAdmin'] == true;
  }

  // ── Logout ──────────────────────────────────────────────────────
  static Future<void> logout() async {
    await _auth.signOut();
    isAdmin.value = false;
    isLoggedIn.value = false;
  }

  // ── Legacy setters (kept for compatibility) ─────────────────────
  static void setAdmin(bool v) => isAdmin.value = v;
  static void setLoggedIn(bool v) => isLoggedIn.value = v;
}
