class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.addressId,
    this.paymentMethod = 'cod',
  });

  final int addressId;
  final String paymentMethod;

  Map<String, dynamic> toJson() => {
    'address_id': addressId,
    'payment_method': paymentMethod,
  };
}

class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.items,
    this.pharmacyName,
    this.deliveryAddress,
  });

  final int id;
  final String status;
  final String paymentMethod;
  final bool isPaid;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final List<PlacedOrderItem> items;
  final String? pharmacyName;
  final String? deliveryAddress;

  factory PlacedOrder.fromJson(Object? value) {
    final json = value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
    final rawItems = json['items'];
    return PlacedOrder(
      id: _int(json['id']),
      status: json['status']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      isPaid: json['is_paid'] as bool? ?? false,
      subtotal: _number(json['subtotal']),
      deliveryFee: _number(json['delivery_fee']),
      discount: _number(json['discount']),
      total: _number(json['total']),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => PlacedOrderItem.fromJson(item))
                .toList()
          : const [],
      pharmacyName: _nestedName(json['pharmacy']),
      deliveryAddress: _nestedAddress(json['delivery_address']),
    );
  }
}

class PlacedOrderItem {
  const PlacedOrderItem({
    required this.quantity,
    required this.lineTotal,
    this.medicineName,
    this.unitPrice,
  });

  final int quantity;
  final double lineTotal;
  final String? medicineName;
  final double? unitPrice;

  factory PlacedOrderItem.fromJson(Map item) {
    final medicine = item['medicine'] is Map
        ? Map<String, dynamic>.from(item['medicine'] as Map)
        : null;
    return PlacedOrderItem(
      quantity: _int(item['quantity']),
      lineTotal: _number(item['line_total']),
      medicineName:
          medicine?['name']?.toString() ?? item['medicine_name']?.toString(),
      unitPrice: item['unit_price'] != null ? _number(item['unit_price']) : null,
    );
  }
}

String? _nestedName(Object? value) {
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    return map['business_name']?.toString() ?? map['username']?.toString();
  }
  return null;
}

String? _nestedAddress(Object? value) {
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final parts = <String>[
      map['label']?.toString() ?? '',
      map['address_line']?.toString() ?? '',
      map['city']?.toString() ?? '',
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' • ');
  }
  return null;
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _number(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
