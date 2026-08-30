class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.businessName,
    this.addressLine,
    this.city,
    this.isVerified = false,
    this.isOpen = true,
    this.rating = 0,
  });

  final int id;
  final String businessName;
  final String? addressLine;
  final String? city;
  final bool isVerified;
  final bool isOpen;
  final double rating;

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: _int(json['id']),
      businessName: json['business_name']?.toString() ?? 'Pharmacy',
      addressLine: json['address_line']?.toString(),
      city: json['city']?.toString(),
      isVerified: json['is_verified'] as bool? ?? false,
      isOpen: json['is_open'] as bool? ?? true,
      rating: _number(json['rating']),
    );
  }
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _number(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
