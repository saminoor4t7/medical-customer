import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model.dart';
import 'services.dart';

final placeOrderServiceProvider = Provider<PlaceOrderService>((ref) {
  return PlaceOrderService();
});

final placeOrderControllerProvider = Provider<PlaceOrderController>((ref) {
  return PlaceOrderController(ref.read(placeOrderServiceProvider));
});

class PlaceOrderController {
  const PlaceOrderController(this.service);

  final PlaceOrderService service;

  Future<PlacedOrder> place(String token, PlaceOrderRequest request) {
    return service.placeOrder(token, request);
  }
}
