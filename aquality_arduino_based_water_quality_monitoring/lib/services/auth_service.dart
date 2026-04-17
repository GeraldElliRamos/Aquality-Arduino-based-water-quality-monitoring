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
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  static final ValueNotifier<String> userRole = ValueNotifier<String>('');
  static final ValueNotifier<bool> isLGU = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isProfileLoading = ValueNotifier<bool>(true);
  static bool _localAdminOverride = false;

  static void init() {
    if (kIsWeb) {}

    _auth.authStateChanges().listen((user) async {
      try {
        if (user == null) {
          isLoggedIn.value = false;
          isAdmin.value = false;
          isLGU.value = false;
          userRole.value = '';
          isProfileLoading.value = false;
        } else {
          isProfileLoading.value = true;
          isLoggedIn.value = true;
          final doc = await _db.collection('users').doc(user.uid).get();
          final cloudAdmin = doc.data()?['isAdmin'] == true;
          isAdmin.value = _localAdminOverride || cloudAdmin;
          userRole.value = doc.data()?['userType'] ?? '';
          isLGU.value = userRole.value == 'lgu';
          isProfileLoading.value = false;
        }
      } on FirebaseException catch (e) {
        debugPrint('Auth state profile read failed: ${e.code} ${e.message}');
        if (user == null) {
          isLoggedIn.value = false;
        } else {
          // Keep session active even if profile lookup fails.
          isLoggedIn.value = true;
        }
        isAdmin.value = false;
        isLGU.value = false;
        userRole.value = '';
        isProfileLoading.value = false;
      } catch (e) {
        debugPrint('Auth state profile read failed: $e');
        if (user == null) {
          isLoggedIn.value = false;
        } else {
          isLoggedIn.value = true;
        }
        isAdmin.value = false;
        isLGU.value = false;
        userRole.value = '';
        isProfileLoading.value = false;
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

  /// Update user profile information
  static Future<void> updateUserProfile({
    String? fullName,
    String? email,
    String? phone,
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['fullName'] = fullName.trim();
    if (email != null) updates['email'] = email.trim().toLowerCase();
    if (phone != null) updates['phone'] = phone.trim();
    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _db.collection('users').doc(uid).update(updates);
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

  static Future<void> updateUserPassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;

    if (user != null && user.email != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      } on FirebaseAuthException catch (e) {
        throw AuthException(e.code, e.message ?? 'Authentication failed');
      }
    } else {
      throw const AuthException('no-user', 'No user is currently logged in.');
    }
  }

  static Future<String> resetPassword(String usernameOrEmail) async {
    final input = usernameOrEmail.trim();
    if (input.isEmpty) {
      throw const AuthException(
        'empty-input',
        'Please enter your username or email.',
      );
    }
    String email;
    final isEmail = input.contains('@');
    if (isEmail) {
      email = input.toLowerCase();
    } else {
      final query = await _db
          .collection('users')
          .where('username', isEqualTo: input.toLowerCase())
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        throw const AuthException(
          'user-not-found',
          'No account found with that username.',
        );
      }
      email = query.docs.first.data()['email'] as String;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw const AuthException(
            'user-not-found',
            'No account found with that email.',
          );
        case 'invalid-email':
          throw const AuthException(
            'invalid-email',
            'The email address is invalid.',
          );
        case 'too-many-requests':
          throw const AuthException(
            'too-many-requests',
            'Too many requests. Please try again later.',
          );
        default:
          throw AuthException(e.code, 'Failed to send reset email. Try again.');
      }
    }
    return _maskEmail(email);
  }

  static String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${local[0]}*@$domain';
    return '${local[0]}${local[1]}${'*' * (local.length - 2)}${local[local.length - 1]}@$domain';
  }

  static Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('cancelled', 'Google sign-in was cancelled.');
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
      final generatedUsername = normalizedEmail.isNotEmpty
          ? normalizedEmail.split('@').first
          : '';
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
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Google sign-in failed.');
    } on FirebaseException catch (e) {
      throw AuthException(
        e.code,
        e.message ?? 'Could not load your profile after Google sign-in.',
      );
    } catch (e) {
      final msg = e.toString();
      if (kIsWeb && msg.contains('XMLHttpRequest error')) {
        throw const AuthException(
          'web-network-error',
          'Google sign-in failed on web. Check Firebase Auth authorized domains and Google OAuth JavaScript origins for your current host.',
        );
      }
      throw AuthException('google-sign-in-failed', msg);
    }
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
    if (usernameQuery.docs.isNotEmpty &&
        usernameQuery.docs.first.id != user.uid) {
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

  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _localAdminOverride = false;
    isAdmin.value = false;
    isLoggedIn.value = false;
    userRole.value = '';
  }

  static void setAdmin(bool v) {
    _localAdminOverride = v;
    isAdmin.value = v;
  }

  static void setLoggedIn(bool v) => isLoggedIn.value = v;
}
