class Cart {
  const Cart({
    required this.items,
    this.subtotal = 0,
    this.discountTotal = 0,
    this.grandTotal = 0,
    this.deliveryFee = 0,
  });

  final List<CartItem> items;
  final double subtotal;
  final double discountTotal;
  final double grandTotal;
  final double deliveryFee;

  factory Cart.fromJson(Object? json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : null;
    final rawItems = json is List
        ? json
        : map?['items'] ?? map?['cart_items'] ?? map?['products'] ?? const [];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
              .toList()
        : <CartItem>[];
    return Cart(
      items: items,
      subtotal: _number(map?['subtotal']),
      discountTotal: _number(map?['discount_total']),
      grandTotal: _number(map?['grand_total']),
      deliveryFee: _number(
        map?['delivery_fee'] ?? map?['delivery_charges'] ?? map?['shipping_fee'],
      ),
    );
  }

  double get calculatedTotal =>
      items.fold(0, (sum, item) => sum + item.lineTotal);
}

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
  });

  final int id;
  final int productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;

  double get lineTotal => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : <String, dynamic>{};
    return CartItem(
      id: _int(json['id']),
      productId: _int(
        json['product_id'] ?? json['medicine_id'] ?? product['id'],
      ),
      name:
          (json['name'] ??
                  json['product_name'] ??
                  product['name'] ??
                  (json['medicine'] is Map
                      ? (json['medicine'] as Map)['name']
                      : null) ??
                  'Product')
              .toString(),
      quantity: _int(json['quantity'], fallback: 1),
      unitPrice: _number(
        json['unit_price'] ?? json['price'] ?? product['price'],
      ),
      imageUrl:
          (json['image'] ??
                  json['image_url'] ??
                  product['image'] ??
                  (json['medicine'] is Map
                      ? (json['medicine'] as Map)['image']
                      : null))
              ?.toString(),
    );
  }
}

class CartQuantityRequest {
  const CartQuantityRequest({required this.quantity});
  final int quantity;
  Map<String, dynamic> toJson() => {'quantity': quantity};
}

int _int(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
double _number(Object? value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}
