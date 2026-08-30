import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model.dart';

final ordersProvider =
    Provider.family<ValueNotifier<List<PlacedOrder>>, String>((ref, token) {
      final orders = ValueNotifier<List<PlacedOrder>>([]);
      ref.onDispose(orders.dispose);
      return orders;
    });
