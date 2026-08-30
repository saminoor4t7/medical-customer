class LogoutRequest {
  const LogoutRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refresh': refreshToken};
}

class LogoutResult {
  const LogoutResult({required this.statusCode, this.data});

  final int statusCode;
  final Map<String, dynamic>? data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  String get message => data?['detail']?.toString() ?? 'Logout successful.';
}
