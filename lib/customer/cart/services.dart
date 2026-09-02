import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import '../../core/session_recovery.dart';
import 'model.dart';

class CartService {
  CartService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Cart> getCart(String token) async {
    final response = await _client.get(
      Uri.parse(AppUrls.cart),
      headers: _headers(token),
    );
    _check(response);
    return Cart.fromJson(jsonDecode(response.body));
  }

  Future<void> updateQuantity(String token, int itemId, int quantity) async {
    final response = await _client.patch(
      Uri.parse('${AppUrls.cartItems}$itemId/'),
      headers: _headers(token),
      body: jsonEncode(CartQuantityRequest(quantity: quantity).toJson()),
    );
    _check(response);
  }

  Future<void> removeItem(String token, int itemId) async {
    final response = await _client.delete(
      Uri.parse('${AppUrls.cartItems}$itemId/'),
      headers: _headers(token),
    );
    _check(response);
  }

  Future<void> clear(String token) async {
    final response = await _client.delete(
      Uri.parse(AppUrls.cart),
      headers: _headers(token),
    );
    _check(response);
  }

  Future<CartItem> addItem(String token, int medicineId, int quantity, {int? pharmacyId}) async {
    final body = <String, dynamic>{
      'medicine_id': medicineId,
      'quantity': quantity,
    };
    if (pharmacyId != null) body['pharmacy_id'] = pharmacyId;

    final response = await _client.post(
      Uri.parse(AppUrls.cart),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    _check(response);
    // Backend returns full cart after POST
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['items'] is List) {
      final items = (decoded['items'] as List).whereType<Map>().toList();
      if (items.isNotEmpty) {
        return CartItem.fromJson(Map<String, dynamic>.from(items.last));
      }
    }
    return CartItem.fromJson(
      Map<String, dynamic>.from(decoded is Map ? decoded : {}),
    );
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw CartApiException(
        statusCode: response.statusCode,
        body: response.body,
        url: response.request?.url.toString() ?? AppUrls.cart,
      );
    }
  }
}

class CartApiException implements Exception {
  const CartApiException({
    required this.statusCode,
    required this.body,
    required this.url,
  });

  final int statusCode;
  final String body;
  final String url;

  @override
  String toString() {
    final detail = body.trim().isEmpty ? 'No response body.' : body.trim();
    return 'Cart request failed ($statusCode) at $url: $detail';
  }
}
