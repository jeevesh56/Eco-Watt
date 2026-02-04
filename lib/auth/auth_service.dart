import 'package:flutter/foundation.dart';

enum RegisterError {
  emptyFields,
  passwordsDoNotMatch,
  accountAlreadyExists,
  unknown,
}

enum LoginError {
  emptyFields,
  invalidCredentials,
  unknown,
}

class RegisterResult {
  final int? userId;
  final RegisterError? error;
  const RegisterResult._({this.userId, this.error});
  const RegisterResult.success(int userId) : this._(userId: userId);
  const RegisterResult.failure(RegisterError error) : this._(error: error);
  bool get ok => userId != null;
}

class LoginResult {
  final int? userId;
  final String? username;
  final LoginError? error;
  const LoginResult._({this.userId, this.username, this.error});
  const LoginResult.success(int userId, String username) : this._(userId: userId, username: username);
  const LoginResult.failure(LoginError error) : this._(error: error);
  bool get ok => userId != null;
}

/// Dummy in-memory authentication (TEMPORARY).
///
/// Rules:
/// - No database
/// - No hashing
/// - Credentials exist only for the current app session
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  String? _username;
  String? _password;
  int _nextUserId = 1;
  int? _userId;

  Future<RegisterResult> registerUser({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return const RegisterResult.failure(RegisterError.emptyFields);
    }
    if (password != confirmPassword) {
      return const RegisterResult.failure(RegisterError.passwordsDoNotMatch);
    }

    // Dummy store for this app session only.
    if (_username != null && _username == username) {
      return const RegisterResult.failure(RegisterError.accountAlreadyExists);
    }

    debugPrint('[Auth][Signup] username=$username');
    debugPrint('[Auth][Signup] password=$password');

    _username = username;
    _password = password;
    _userId = _nextUserId++;
    return RegisterResult.success(_userId!);
  }

  Future<LoginResult> loginUser({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      return const LoginResult.failure(LoginError.emptyFields);
    }

    debugPrint('[Auth] LOGIN BUTTON PRESSED');
    debugPrint('[Auth][Login] username=$username');

    if (_username == null || _password == null || _userId == null) {
      return const LoginResult.failure(LoginError.invalidCredentials);
    }

    debugPrint('[Auth] USER FOUND');
    debugPrint('[Auth][Login] inputPassword=$password');
    debugPrint('[Auth][Login] storedPassword=$_password');

    if (username == _username && password == _password) {
      debugPrint('[Auth] PASSWORD MATCHED');
      return LoginResult.success(_userId!, username);
    }
    return const LoginResult.failure(LoginError.invalidCredentials);
  }
}

