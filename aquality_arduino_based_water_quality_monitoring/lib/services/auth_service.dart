import 'package:flutter/foundation.dart';

class AuthService {
 
  static final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);
 
  static final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

  
  static void setAdmin(bool v) => isAdmin.value = v;
  static void setLoggedIn(bool v) => isLoggedIn.value = v;
  static void logout() {
    isAdmin.value = false;
    isLoggedIn.value = false;
  }
}
