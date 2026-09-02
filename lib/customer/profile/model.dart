class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.user,
    required this.walletBalance,
    required this.preferredLanguage,
    required this.addresses,
    this.dateOfBirth,
  });

  final int id;
  final int user;
  final String walletBalance;
  final String preferredLanguage;
  final List<CustomerAddress> addresses;
  final DateTime? dateOfBirth;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    final rawAddresses = json['addresses'];
    return CustomerProfile(
      id: _toInt(json['id']),
      user: _toInt(json['user']),
      walletBalance: json['wallet_balance']?.toString() ?? '0.00',
      preferredLanguage: json['preferred_language']?.toString() ?? 'en',
      dateOfBirth: DateTime.tryParse(json['date_of_birth']?.toString() ?? ''),
      addresses: rawAddresses is List
          ? rawAddresses
                .whereType<Map>()
                .map(
                  (item) =>
                      CustomerAddress.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }
}

class CustomerAddress {
  const CustomerAddress({
    this.id,
    required this.label,
    required this.addressLine,
    required this.city,
    this.latitude,
    this.longitude,
    this.isDefault = true,
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

  factory CustomerAddress.fromJson(Map<String, dynamic> json) =>
      CustomerAddress(
        id: _nullableInt(json['id']),
        label: json['label']?.toString() ?? 'Address',
        addressLine: json['address_line']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        latitude: _nullableDouble(json['latitude']),
        longitude: _nullableDouble(json['longitude']),
        isDefault: json['is_default'] as bool? ?? false,
        customer: _nullableInt(json['customer']),
      );

  Map<String, dynamic> toJson() => {
    'label': label,
    'address_line': addressLine,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'is_default': isDefault,
    'customer': customer,
  };
}

int _toInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
int? _nullableInt(Object? value) => value == null ? null : _toInt(value);
double? _nullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
