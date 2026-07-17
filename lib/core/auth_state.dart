import 'package:flutter/foundation.dart';

/// App-wide auth signal. Two jobs:
///  - lets widgets watch `loggedIn` via Provider without re-reading secure
///    storage themselves;
///  - doubles as GoRouter's `refreshListenable` so a hard token-refresh
///    failure (see ApiService._refreshToken) forces an immediate redirect
///    to /login instead of waiting for the user's next manual navigation.
class AuthState extends ChangeNotifier {
  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  void markLoggedIn() {
    if (_loggedIn) return;
    _loggedIn = true;
    notifyListeners();
  }

  void markLoggedOut() {
    if (!_loggedIn) return;
    _loggedIn = false;
    notifyListeners();
  }
}

/// Single app-lifetime instance, shared between main.dart (Provider +
/// GoRouter refreshListenable) and api_service.dart (which has no access
/// to the widget tree) without either file importing the other.
final authState = AuthState();
