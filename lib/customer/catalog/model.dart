class Category {
  const Category({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.medicineCount = 0,
  });

  final int id;
  final String name;
  final String? description;
  final String? image;
  final int medicineCount;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _int(json['id']),
      name: json['name']?.toString() ?? 'Unknown',
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      medicineCount: _int(json['medicine_count'] ?? json['count']),
    );
  }
}

class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    this.genericName,
    this.description,
    this.price = 0,
    this.image,
    this.category,
    this.brand,
    this.requiresPrescription = false,
    this.isActive = true,
    this.form,
    this.strength,
  });

  final int id;
  final String name;
  final String? genericName;
  final String? description;
  final double price;
  final String? image;
  final String? category;
  final String? brand;
  final bool requiresPrescription;
  final bool isActive;
  final String? form;
  final String? strength;

  factory Medicine.fromJson(Map<String, dynamic> json) {
    final categoryRaw = json['category'];
    final brandRaw = json['brand'];
    return Medicine(
      id: _int(json['id']),
      name: json['name']?.toString() ?? 'Unknown Medicine',
      genericName: json['generic_name']?.toString(),
      description: json['description']?.toString(),
      price: _number(
        json['low_price'] ??
            json['price'] ??
            json['unit_price'] ??
            json['selling_price'],
      ),
      image: json['image']?.toString(),
      category: categoryRaw is Map
          ? categoryRaw['name']?.toString()
          : categoryRaw?.toString(),
      brand: brandRaw is Map
          ? brandRaw['name']?.toString()
          : brandRaw?.toString(),
      requiresPrescription:
          json['requires_prescription'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      form: json['form']?.toString(),
      strength: json['strength']?.toString(),
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
