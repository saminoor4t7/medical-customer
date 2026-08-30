import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import 'model.dart';

class AddressService {
  AddressService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<CustomerAddress>> getAddresses(String token) async {
    final response = await _client
        .get(Uri.parse(AppUrls.customerAddresses), headers: _headers(token))
        .timeout(const Duration(seconds: 20));

    _ensureSuccess(response);

    final body = jsonDecode(response.body);

    if (body is List) {
      return body
          .whereType<Map>()
          .map(
            (item) => CustomerAddress.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    if (body is Map) {
      final results = body['results'];
      if (results is List) {
        return results
            .whereType<Map>()
            .map(
              (item) =>
                  CustomerAddress.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      if (body.containsKey('id') || body.containsKey('address_line')) {
        return [CustomerAddress.fromJson(Map<String, dynamic>.from(body))];
      }
    }

    return const [];
  }

  Future<CustomerAddress> saveAddress(
    String token,
    CustomerAddress address,
  ) async {
    final response = await _client
        .post(
          Uri.parse(AppUrls.customerAddresses),
          headers: _headers(token),
          body: jsonEncode(address.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    _ensureSuccess(response);

    final body = jsonDecode(response.body);
    if (body is Map) {
      return CustomerAddress.fromJson(Map<String, dynamic>.from(body));
    }

    throw const FormatException(
      'Address save response was not a valid object.',
    );
  }

  Future<void> deleteAddress(String token, int addressId) async {
    final response = await _client
        .delete(
          Uri.parse('${AppUrls.customerAddresses}$addressId/'),
          headers: _headers(token),
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
      throw AddressApiException(response.statusCode, response.body);
    }
  }
}

class AddressApiException implements Exception {
  const AddressApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() =>
      'AddressApiException(statusCode: $statusCode, body: $body)';
}
