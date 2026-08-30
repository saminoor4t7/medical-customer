import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';

class PrescriptionService {
  PrescriptionService({http.Client? client})
      : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, dynamic>> uploadPrescription(
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

    final streamedResponse = await request
        .send()
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PrescriptionApiException(response.statusCode, response.body);
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Map<String, dynamic>> buildCartFromPrescription(
    String token,
    int prescriptionId,
  ) async {
    final response = await _client
        .post(
          Uri.parse(AppUrls.prescriptionBuildCart(prescriptionId)),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PrescriptionApiException(response.statusCode, response.body);
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<List<Map<String, dynamic>>> getPrescriptions(String token) async {
    final response = await _client.get(
      Uri.parse(AppUrls.prescriptions),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PrescriptionApiException(response.statusCode, response.body);
    }

    final body = jsonDecode(response.body);
    final list = body is List
        ? body
        : (body is Map ? (body['results'] ?? []) : []);
    return (list as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
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
