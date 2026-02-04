import 'package:flutter/foundation.dart';

import '../auth/auth_service.dart';

class AuthState extends ChangeNotifier {
  final AuthService _service;
  AuthState(this._service);

  bool _loaded = false;
  bool get loaded => _loaded;

  int? _currentUserId;
  int? get currentUserId => _currentUserId;

  bool get isLoggedIn => _currentUserId != null;

  Future<void> load() async {
    _loaded = true;
    notifyListeners();
  }

  Future<RegisterResult> registerUser({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    final result = await _service.registerUser(
      username: username,
      password: password,
      confirmPassword: confirmPassword,
    );
    // Registration does not log the user in.
    return result;
  }

  Future<LoginResult> loginUser({
    required String username,
    required String password,
  }) async {
    final result =
        await _service.loginUser(username: username, password: password);
    if (result.ok) {
      _currentUserId = result.userId;
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    _currentUserId = null;
    notifyListeners();
  }
}

