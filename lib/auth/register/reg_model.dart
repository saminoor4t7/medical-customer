class RegisterModel {
  const RegisterModel({
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.phoneNumber,
    required this.firstName,
  });

  final String username;
  final String email;
  final String password;
  final String role;
  final String phoneNumber;
  final String firstName;

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'role': role,
    'phone_number': phoneNumber,
    'first_name': firstName,
  };
}

class RegisterResult {
  const RegisterResult({required this.statusCode, this.data});

  final int statusCode;
  final Map<String, dynamic>? data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
