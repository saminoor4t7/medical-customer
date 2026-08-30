class CustomerAddress {
  const CustomerAddress({
    this.id,
    required this.label,
    required this.addressLine,
    required this.city,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.customer,
  });

  final int? id;
  final String label;
  final String addressLine;
  final String city;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final int? customer;

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: _nullableInt(json['id']),
      label: json['label']?.toString() ?? 'Address',
      addressLine: json['address_line']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      latitude: _nullableDouble(json['latitude']),
      longitude: _nullableDouble(json['longitude']),
      isDefault: json['is_default'] as bool? ?? false,
      customer: _nullableInt(json['customer']),
    );
  }

  factory CustomerAddress.fromAny(Object? value) {
    if (value is Map) {
      return CustomerAddress.fromJson(Map<String, dynamic>.from(value));
    }
    throw const FormatException('Address payload must be a JSON object.');
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'address_line': addressLine,
    'city': city,
    'latitude': _roundCoordinate(latitude),
    'longitude': _roundCoordinate(longitude),
    'is_default': isDefault,
    if (customer != null) 'customer': customer,
  };
}

double? _roundCoordinate(double? value) =>
    value == null ? null : (value * 1000000).round() / 1000000;

int _toInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

int? _nullableInt(Object? value) => value == null ? null : _toInt(value);

double? _nullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
