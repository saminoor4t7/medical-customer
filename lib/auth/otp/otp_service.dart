import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import 'otp_model.dart';

class OtpService {
  OtpService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<OtpResult> verify(OtpVerifyModel model) async {
    final response = await _client
        .post(
          Uri.parse(AppUrls.otp),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(model.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic>? data;
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    }
    return OtpResult(statusCode: response.statusCode, data: data);
  }
}

String otpErrorMessage(OtpResult result) {
  final data = result.data;
  if (data == null || data.isEmpty) {
    return 'Verification failed. Please try again.';
  }
  final messages = <String>[];
  for (final value in data.values) {
    if (value is List) {
      messages.addAll(value.map((item) => item.toString()));
    } else {
      messages.add(value.toString());
    }
  }
  return messages.isEmpty
      ? 'Verification failed. Please try again.'
      : messages.join('\n');
}
