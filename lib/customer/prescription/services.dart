import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import '../../core/session_recovery.dart';
import 'model.dart';

class PrescriptionService {
  PrescriptionService({http.Client? client})
      : _client = client ?? http.Client();
  final http.Client _client;

  /// Upload a prescription image/PDF for AI extraction (FR-02/FR-03).
  /// Returns the created prescription with extracted items + risk flags.
  Future<Prescription> uploadPrescription(
    String token,
    List<int> imageBytes,
    String fileName, {
    int? pharmacyId,
    String source = 'camera',
  }) async {
    final uri = Uri.parse(AppUrls.prescriptions);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['source'] = source
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ),
      );

    if (pharmacyId != null) {
      request.fields['pharmacy_id'] = pharmacyId.toString();
    }

    // AI extraction runs inline on upload; allow time for it.
    final streamedResponse = await request
        .send()
        .timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamedResponse);

    _log('POST ${AppUrls.prescriptions}', response.statusCode, response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw PrescriptionApiException(response.statusCode, response.body);
    }

    return Prescription.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  /// Convert a prescription's AI-extracted items into the customer's cart.
  /// Returns the list of unmatched raw medicine texts, if any.
  Future<List<String>> buildCartFromPrescription(
    String token,
    int prescriptionId,
  ) async {
    final url = AppUrls.prescriptionBuildCart(prescriptionId);
    final response = await _client
        .post(Uri.parse(url), headers: {
          'Authorization': 'Bearer $token',
        })
        .timeout(const Duration(seconds: 30));

    _log('POST $url', response.statusCode, response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw PrescriptionApiException(response.statusCode, response.body);
    }

    final body = jsonDecode(response.body);
    if (body is Map) {
      final unmatched = body['unmatched'];
      if (unmatched is List) {
        return unmatched.map((e) => e.toString()).toList();
      }
    }
    return const [];
  }

  /// List the customer's prescriptions (newest first per model ordering).
  Future<List<Prescription>> getPrescriptions(String token) async {
    final response = await _client.get(
      Uri.parse(AppUrls.prescriptions),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));

    _log('GET ${AppUrls.prescriptions}', response.statusCode, response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw PrescriptionApiException(response.statusCode, response.body);
    }

    final body = jsonDecode(response.body);
    final list = body is List
        ? body
        : (body is Map ? (body['results'] ?? []) : []);
    return (list as List)
        .whereType<Map>()
        .map((e) => Prescription.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Fetch one prescription (re-parses AI items server-side).
  Future<Prescription> getPrescription(String token, int id) async {
    final url = AppUrls.prescriptionDetail(id);
    final response = await _client.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));

    _log('GET $url', response.statusCode, response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw PrescriptionApiException(response.statusCode, response.body);
    }

    return Prescription.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  void _log(String request, int statusCode, String body) {
    if (kDebugMode) {
      debugPrint('[Rx] $request → $statusCode');
      debugPrint(
        '[Rx] Body: ${body.length > 400 ? body.substring(0, 400) : body}',
      );
    }
  }
}

class PrescriptionApiException implements Exception {
  const PrescriptionApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() =>
      'Prescription API error ($statusCode): ${body.trim().isEmpty ? "No response." : body.trim()}';
}
