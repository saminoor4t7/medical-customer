class LoginModel {
  const LoginModel({
    required this.username,
    required this.email,
    required this.password,
    required this.role,
  });

  final String username;
  final String email;
  final String password;
  final String role;

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'role': role,
  };
}

class LoginResult {
  const LoginResult({required this.statusCode, this.data});

  final int statusCode;
  final Map<String, dynamic>? data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  String? get accessToken => data?['access']?.toString();
  String? get refreshToken => data?['refresh']?.toString();
}
