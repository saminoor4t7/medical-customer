import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import 'reg_model.dart';

class RegisterService {
  RegisterService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RegisterResult> register(RegisterModel model) async {
    final response = await _client
        .post(
          Uri.parse(AppUrls.register),
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
    return RegisterResult(statusCode: response.statusCode, data: data);
  }
}

String registerErrorMessage(RegisterResult result) {
  final data = result.data;
  if (data == null || data.isEmpty) {
    return 'Registration failed. Please try again.';
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
      ? 'Registration failed. Please try again.'
      : messages.join('\n');
}

String registerSuccessMessage(RegisterResult result) {
  final data = result.data;
  if (data != null) {
    for (final key in ['message', 'detail', 'success']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
  }
  return 'Registration successful.';
}
