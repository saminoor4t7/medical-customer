import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import '../../core/session_recovery.dart';

/// The catalog match and pharmacy stock returned for an OCR text scan.
class MedicineAvailability {
  const MedicineAvailability({
    required this.recognizedText,
    required this.matched,
    required this.available,
    required this.matchScore,
    required this.stock,
    required this.pharmacy,
    this.medicine,
  });

  final String recognizedText;
  final bool matched;
  final bool available;
  final double matchScore;
  final int stock;
  final String? pharmacy;
  final Map<String, dynamic>? medicine;

  factory MedicineAvailability.fromJson(Map<String, dynamic> json) =>
      MedicineAvailability(
        recognizedText: json['recognized_text']?.toString() ?? '',
        matched: json['matched'] == true,
        available: json['available'] == true,
        matchScore: _double(json['match_score']),
        stock: _int(json['stock']),
        pharmacy: json['pharmacy']?.toString(),
        medicine: json['medicine'] is Map
            ? Map<String, dynamic>.from(json['medicine'] as Map)
            : null,
      );

  String get displayName => medicine?['name']?.toString() ?? recognizedText;
  String get summary => !matched
      ? 'No catalog medicine matched "$recognizedText".'
      : available
      ? '$displayName is available${stock > 0 ? ' ($stock in stock)' : ''}${pharmacy == null ? '' : ' at $pharmacy'}.'
      : '$displayName was matched, but is out of stock${pharmacy == null ? '' : ' at $pharmacy'}.';
}

class AvailabilityService {
  AvailabilityService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;

  Future<MedicineAvailability> scan(
    String token,
    String text,
    int pharmacyId,
  ) async {
    final response = await _client
        .post(
          Uri.parse(AppUrls.scanAvailability),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'text': text, 'pharmacy_id': pharmacyId}),
        )
        .timeout(const Duration(seconds: 30));
    if (kDebugMode) {
      debugPrint('[OCR availability] ${response.statusCode}: ${response.body}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw AvailabilityException(response.statusCode, response.body);
    }
    return MedicineAvailability.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  /// Tries likely medicine names first, then OCR lines and adjacent lines.
  /// This avoids asking the catalog to match an entire label or prescription
  /// paragraph as if it were one medicine name.
  Future<MedicineAvailability?> scanBestMatch(
    String token, {
    required List<String> preferredTexts,
    required String recognizedText,
    required int pharmacyId,
  }) async {
    final lines = recognizedText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.length >= 3)
        .toList();
    final candidates =
        <String>[
              ...lines,
              for (var i = 0; i + 1 < lines.length; i++)
                '${lines[i]} ${lines[i + 1]}',
              ...preferredTexts,
              recognizedText,
            ]
            .map((text) => text.trim())
            .where((text) => text.isNotEmpty)
            .toSet()
            .take(10);

    MedicineAvailability? lastResult;
    for (final candidate in candidates) {
      lastResult = await scan(token, candidate, pharmacyId);
      if (lastResult.matched) return lastResult;
    }
    return lastResult;
  }
}

class AvailabilityException implements Exception {
  const AvailabilityException(this.statusCode, this.body);
  final int statusCode;
  final String body;
  @override
  String toString() => 'Availability API error ($statusCode): $body';
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
