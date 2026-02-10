import 'package:flutter/foundation.dart';

class AuthService {
  // Use a ValueNotifier so UI can react to changes during development/testing.
  static final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);
  // Tracks whether a user is logged in (admin or regular user)
  static final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

  // Helpers for tests or UI toggles
  static void setAdmin(bool v) => isAdmin.value = v;
  static void setLoggedIn(bool v) => isLoggedIn.value = v;
  static void logout() {
    isAdmin.value = false;
    isLoggedIn.value = false;
  }
}
