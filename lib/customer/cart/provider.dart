import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model.dart';
import 'services.dart';

final cartServiceProvider = Provider<CartService>((ref) => CartService());
final cartProvider = FutureProvider.family<Cart, String>((ref, token) {
  return ref.read(cartServiceProvider).getCart(token);
});

final cartControllerProvider = Provider<CartController>((ref) {
  return CartController(ref, ref.read(cartServiceProvider));
});

class CartController {
  CartController(this.ref, this.service);
  final Ref ref;
  final CartService service;

  Future<void> update(String token, int itemId, int quantity) async {
    await service.updateQuantity(token, itemId, quantity);
    ref.invalidate(cartProvider(token));
  }

  Future<void> remove(String token, int itemId) async {
    await service.removeItem(token, itemId);
    ref.invalidate(cartProvider(token));
  }

  Future<void> clear(String token) async {
    await service.clear(token);
    ref.invalidate(cartProvider(token));
  }

  Future<void> addItem(String token, int medicineId, int quantity, {int? pharmacyId}) async {
    await service.addItem(token, medicineId, quantity, pharmacyId: pharmacyId);
    ref.invalidate(cartProvider(token));
  }
}
