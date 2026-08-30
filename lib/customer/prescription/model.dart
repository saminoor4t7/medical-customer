import '../catalog/model.dart';

class Prescription {
  const Prescription({
    required this.id,
    this.file,
    this.source,
    this.status,
    this.doctorName,
    this.patientName,
    this.aiRawResponse,
    this.items = const [],
    this.createdAt,
  });

  final int id;
  final String? file;
  final String? source;
  final String? status;
  final String? doctorName;
  final String? patientName;
  final Map<String, dynamic>? aiRawResponse;
  final List<PrescriptionItem> items;
  final String? createdAt;

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return Prescription(
      id: _int(json['id']),
      file: json['file']?.toString(),
      source: json['source']?.toString(),
      status: json['status']?.toString(),
      doctorName: json['doctor_name']?.toString(),
      patientName: json['patient_name']?.toString(),
      aiRawResponse: json['ai_raw_response'] is Map
          ? Map<String, dynamic>.from(json['ai_raw_response'] as Map)
          : null,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => PrescriptionItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      createdAt: json['created_at']?.toString(),
    );
  }
}

class PrescriptionItem {
  const PrescriptionItem({
    required this.id,
    this.rawMedicineText,
    this.medicine,
    this.quantity,
    this.confidence,
  });

  final int id;
  final String? rawMedicineText;
  final Medicine? medicine;
  final int? quantity;
  final double? confidence;

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    final medicineRaw = json['medicine'];
    return PrescriptionItem(
      id: _int(json['id']),
      rawMedicineText: json['raw_medicine_text']?.toString(),
      medicine: medicineRaw is Map
          ? Medicine.fromJson(Map<String, dynamic>.from(medicineRaw))
          : null,
      quantity: _intOrNull(json['quantity']),
      confidence: _doubleOrNull(json['confidence']),
    );
  }
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

int? _intOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _doubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
