import 'dart:convert';


import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import 'model.dart';

class PharmacyService {
  PharmacyService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<Pharmacy>> getPharmacies() async {
    final response = await _client
        .get(Uri.parse(AppUrls.pharmacyList))
        .timeout(const Duration(seconds: 20));
    _check(response);
    final body = jsonDecode(response.body);
    final list = body is List
        ? body
        : (body is Map ? (body['results'] ?? body['pharmacies'] ?? []) : []);
    return (list as List)
        .whereType<Map>()
        .map((e) => Pharmacy.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getInventory(int pharmacyId) async {
    final response = await _client
        .get(Uri.parse(AppUrls.pharmacyInventory(pharmacyId)))
        .timeout(const Duration(seconds: 20));
    _check(response);
    final body = jsonDecode(response.body);
    final list = body is List
        ? body
        : (body is Map ? (body['results'] ?? []) : []);
    return (list as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PharmacyApiException(response.statusCode, response.body);
    }
  }
}

class PharmacyApiException implements Exception {
  const PharmacyApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() =>
      'Pharmacy API error ($statusCode): ${body.trim().isEmpty ? "No response." : body.trim()}';
}
