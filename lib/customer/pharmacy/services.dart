import 'dart:convert';


import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import '../../core/session_recovery.dart';
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

  Future<List<Map<String, dynamic>>> getInventory(
    String token,
    int pharmacyId,
  ) async {
    // The backend paginates inventory (PAGE_SIZE 20), so follow `next` links.
    final items = <Map<String, dynamic>>[];
    String? url = AppUrls.pharmacyInventory(pharmacyId);
    while (url != null) {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));
      _check(response);
      final body = jsonDecode(response.body);
      if (body is List) {
        items.addAll(
          body.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
        break;
      }
      if (body is Map) {
        final results = body['results'];
        if (results is List) {
          items.addAll(
            results.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          );
        }
        final next = body['next'];
        url = next is String && next.isNotEmpty ? next : null;
      } else {
        break;
      }
    }
    return items;
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
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
