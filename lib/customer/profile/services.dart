import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mediacl_panda/customer/profile/model.dart';

import '../../core/app_urls.dart';
import '../../core/session_recovery.dart';


class ProfileService {
  ProfileService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<CustomerProfile> getProfile(String token) async {
    final response = await _client
        .get(Uri.parse(AppUrls.customerMe), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    _ensureSuccess(response);
    return CustomerProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> saveAddress(String token, CustomerAddress address) async {
    final response = await _client
        .post(
          Uri.parse(AppUrls.customerAddresses),
          headers: _headers(token),
          body: jsonEncode(address.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    _ensureSuccess(response);
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw ProfileApiException(response.statusCode, response.body);
    }
  }
}

class ProfileApiException implements Exception {
  const ProfileApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;
}
