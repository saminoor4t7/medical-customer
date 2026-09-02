import '../catalog/model.dart';

/// AI copilot safety flag computed by the backend
/// (`apps/customer/medicine_checks.py`) — duplicate ingredients or
/// known drug interactions on one prescription.
class PrescriptionRiskFlag {
  const PrescriptionRiskFlag({
    required this.severity,
    required this.type,
    required this.title,
    required this.message,
    this.items = const [],
  });

  final String severity; // 'high' | 'moderate' | 'info'
  final String type; // 'duplicate' | 'interaction'
  final String title;
  final String message;
  final List<String> items;

  bool get isHigh => severity == 'high';

  factory PrescriptionRiskFlag.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return PrescriptionRiskFlag(
      severity: json['severity']?.toString() ?? 'info',
      type: json['type']?.toString() ?? 'info',
      title: json['title']?.toString() ?? 'Safety check',
      message: json['message']?.toString() ?? '',
      items: rawItems is List
          ? rawItems.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
          : const [],
    );
  }
}

class Prescription {
  const Prescription({
    required this.id,
    this.file,
    this.source,
    this.sourceDisplay,
    this.status,
    this.statusDisplay,
    this.doctorName,
    this.patientName,
    this.pharmacyName,
    this.reviewedByName,
    this.rejectionReason,
    this.aiRawResponse,
    this.items = const [],
    this.riskFlags = const [],
    this.createdAt,
  });

  final int id;
  final String? file;
  final String? source;
  final String? sourceDisplay;
  final String? status;
  final String? statusDisplay;
  final String? doctorName;
  final String? patientName;
  final String? pharmacyName;
  final String? reviewedByName;
  final String? rejectionReason;
  final Map<String, dynamic>? aiRawResponse;
  final List<PrescriptionItem> items;
  final List<PrescriptionRiskFlag> riskFlags;
  final String? createdAt;

  bool get hasRiskFlags => riskFlags.isNotEmpty;
  bool get hasHighRisk => riskFlags.any((f) => f.isHigh);

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawFlags = json['risk_flags'];
    return Prescription(
      id: _int(json['id']),
      file: json['file']?.toString(),
      source: json['source']?.toString(),
      sourceDisplay: json['source_display']?.toString(),
      status: json['status']?.toString(),
      statusDisplay: json['status_display']?.toString(),
      doctorName: json['doctor_name']?.toString(),
      patientName: json['patient_name']?.toString(),
      pharmacyName: json['pharmacy_name']?.toString(),
      reviewedByName: json['reviewed_by_name']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      aiRawResponse: json['ai_raw_response'] is Map
          ? Map<String, dynamic>.from(json['ai_raw_response'] as Map)
          : null,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => PrescriptionItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      riskFlags: rawFlags is List
          ? rawFlags
              .whereType<Map>()
              .map((e) => PrescriptionRiskFlag.fromJson(Map<String, dynamic>.from(e)))
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
    this.strength,
    this.dosage,
    this.frequency,
    this.duration,
    this.quantity,
    this.specialInstructions,
    this.confidence,
    this.isAmbiguous = false,
  });

  final int id;
  final String? rawMedicineText;
  final Medicine? medicine;
  final String? strength;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final int? quantity;
  final String? specialInstructions;
  final double? confidence;
  final bool isAmbiguous;

  /// Best display name: catalog match, else the raw OCR text.
  String get displayName {
    final matched = medicine?.name;
    if (matched != null && matched.isNotEmpty) return matched;
    final raw = rawMedicineText;
    if (raw != null && raw.isNotEmpty) return raw;
    return 'Unknown item';
  }

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    final medicineRaw = json['medicine'];
    return PrescriptionItem(
      id: _int(json['id']),
      rawMedicineText: json['raw_medicine_text']?.toString(),
      medicine: medicineRaw is Map
          ? Medicine.fromJson(Map<String, dynamic>.from(medicineRaw))
          : null,
      strength: json['strength']?.toString(),
      dosage: json['dosage']?.toString(),
      frequency: json['frequency']?.toString(),
      duration: json['duration']?.toString(),
      quantity: _intOrNull(json['quantity']),
      specialInstructions: json['special_instructions']?.toString(),
      confidence: _doubleOrNull(json['confidence']),
      isAmbiguous: json['is_ambiguous'] as bool? ?? false,
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
