import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import 'model.dart';

class PlaceOrderService {
  PlaceOrderService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<PlacedOrder> placeOrder(
    String token,
    PlaceOrderRequest request,
  ) async {
    final response = await _client
        .post(
          Uri.parse(AppUrls.placeOrder),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlaceOrderApiException(response.statusCode, response.body);
    }

    return PlacedOrder.fromJson(jsonDecode(response.body));
  }
}

class PlaceOrderApiException implements Exception {
  const PlaceOrderApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() =>
      'PlaceOrderApiException(statusCode: $statusCode, body: $body)';
}
