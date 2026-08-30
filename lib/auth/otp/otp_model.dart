class OtpVerifyModel {
  const OtpVerifyModel({
    required this.email,
    required this.code,
    required this.role,
  });

  final String email;
  final String code;
  final String role;

  Map<String, dynamic> toJson() => {'email': email, 'code': code, 'role': role};
}

class OtpUser {
  const OtpUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.phoneVerified,
    required this.dateJoined,
  });

  final int id;
  final String username;
  final String email;
  final String role;
  final String phoneNumber;
  final bool phoneVerified;
  final DateTime? dateJoined;

  factory OtpUser.fromJson(Map<String, dynamic> json) => OtpUser(
    id: json['id'] as int? ?? 0,
    username: json['username']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    phoneNumber: json['phone_number']?.toString() ?? '',
    phoneVerified: json['phone_verified'] as bool? ?? false,
    dateJoined: DateTime.tryParse(json['date_joined']?.toString() ?? ''),
  );
}

class OtpResult {
  const OtpResult({required this.statusCode, this.data});

  final int statusCode;
  final Map<String, dynamic>? data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  String? get accessToken => data?['access']?.toString();
  String? get refreshToken => data?['refresh']?.toString();
  OtpUser? get user {
    final value = data?['user'];
    return value is Map
        ? OtpUser.fromJson(Map<String, dynamic>.from(value))
        : null;
  }
}
