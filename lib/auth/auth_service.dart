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
  final LoginError? error;
  const LoginResult._({this.userId, this.error});
  const LoginResult.success(int userId) : this._(userId: userId);
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

  String? _email;
  String? _password;
  int _nextUserId = 1;
  int? _userId;

  Future<RegisterResult> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return const RegisterResult.failure(RegisterError.emptyFields);
    }
    if (password != confirmPassword) {
      return const RegisterResult.failure(RegisterError.passwordsDoNotMatch);
    }

    // Dummy store for this app session only.
    if (_email != null && _email == email) {
      return const RegisterResult.failure(RegisterError.accountAlreadyExists);
    }

    debugPrint('[Auth][Signup] email=$email');
    debugPrint('[Auth][Signup] password=$password');

    _email = email;
    _password = password;
    _userId = _nextUserId++;
    return RegisterResult.success(_userId!);
  }

  Future<LoginResult> loginUser({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return const LoginResult.failure(LoginError.emptyFields);
    }

    debugPrint('[Auth] LOGIN BUTTON PRESSED');
    debugPrint('[Auth][Login] email=$email');

    if (_email == null || _password == null || _userId == null) {
      return const LoginResult.failure(LoginError.invalidCredentials);
    }

    debugPrint('[Auth] USER FOUND');
    debugPrint('[Auth][Login] inputPassword=$password');
    debugPrint('[Auth][Login] storedPassword=$_password');

    if (email == _email && password == _password) {
      debugPrint('[Auth] PASSWORD MATCHED');
      return LoginResult.success(_userId!);
    }
    return const LoginResult.failure(LoginError.invalidCredentials);
  }
}

