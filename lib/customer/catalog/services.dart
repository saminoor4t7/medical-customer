import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import 'model.dart';

class CatalogService {
  CatalogService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<Category>> getCategories() async {
    final response = await _client
        .get(Uri.parse(AppUrls.categories))
        .timeout(const Duration(seconds: 20));
    _check(response);
    final body = jsonDecode(response.body);
    final list = body is List
        ? body
        : (body is Map ? (body['results'] ?? body['categories'] ?? []) : []);
    return (list as List)
        .whereType<Map>()
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Medicine>> getMedicines({String? query, int? categoryId}) async {
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) queryParams['q'] = query;
    if (categoryId != null) queryParams['category'] = categoryId.toString();

    final uri = Uri.parse(AppUrls.medicines).replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));
    _check(response);
    final body = jsonDecode(response.body);
    final list = body is List
        ? body
        : (body is Map ? (body['results'] ?? body['medicines'] ?? []) : []);
    // Debug: print first item keys so you can see backend field names
    if (kDebugMode && list is List && list.isNotEmpty && list.first is Map) {
      debugPrint('[CatalogService] First medicine keys: ${(list.first as Map).keys.toList()}');
      debugPrint('[CatalogService] First medicine data: ${list.first}');
    }
    return (list as List)
        .whereType<Map>()
        .map((e) => Medicine.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Medicine> getMedicineDetail(int id) async {
    final response = await _client
        .get(Uri.parse(AppUrls.medicineDetail(id)))
        .timeout(const Duration(seconds: 20));
    _check(response);
    return Medicine.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CatalogApiException(
        statusCode: response.statusCode,
        body: response.body,
        url: response.request?.url.toString() ?? '',
      );
    }
  }
}

class CatalogApiException implements Exception {
  const CatalogApiException({
    required this.statusCode,
    required this.body,
    required this.url,
  });

  final int statusCode;
  final String body;
  final String url;

  @override
  String toString() =>
      'Catalog request failed ($statusCode) at $url: ${body.trim().isEmpty ? "No response body." : body.trim()}';
}
