import 'package:flutter/foundation.dart';

class AppUrls {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.7:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String get login => '$baseUrl/accounts/login/';
  static String get register => '$baseUrl/accounts/register/';
  static String get otp => '$baseUrl/accounts/register/verify/';
  static String get logout => '$baseUrl/accounts/logout/';
  static String get tokenRefresh => '$baseUrl/auth/token/refresh/';
  static String get customerMe => '$baseUrl/customer/me/';
  static String get customerAddresses => '$baseUrl/customer/addresses/';
  static String get cart => '$baseUrl/customer/cart/';
  static String get cartItems => '$baseUrl/customer/cart-items/';

  static String get placeOrder => '$baseUrl/customer/orders/place/';

  // Catalog
  static String get medicines => '$baseUrl/catalog/medicines/';
  static String get categories => '$baseUrl/catalog/categories/';
  static String medicineDetail(int id) => '$baseUrl/catalog/medicines/$id/';
  static String categoryMedicines(int id) =>
      '$baseUrl/catalog/medicines/?category=$id';

  // AI Prescription
  static String get prescriptions => '$baseUrl/customer/prescriptions/';
  static String prescriptionDetail(int id) => '$baseUrl/customer/prescriptions/$id/';
  static String prescriptionBuildCart(int id) =>
      '$baseUrl/customer/prescriptions/$id/build-cart/';

  // Orders
  static String ordersList() => '$baseUrl/orders/';

  // Pharmacy
  static String get pharmacyList => '$baseUrl/pharmacy/list/';
  static String get pharmacyDirectory => '$baseUrl/pharmacy/directory/';
  static String pharmacyInventory(int pharmacyId) =>
      '$baseUrl/pharmacy/$pharmacyId/inventory/';

  // AI Assistant (Panda AI)
  static String get aiChat => '$baseUrl/ai/chat/';
  static String get aiConversations =>
      '$baseUrl/ai/assistant/conversations/';
  static String aiConversationDetail(int id) =>
      '$baseUrl/ai/assistant/conversations/$id/';
}
