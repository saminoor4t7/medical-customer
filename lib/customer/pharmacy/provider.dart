import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediacl_panda/customer/pharmacy/services.dart';

import 'model.dart';

final pharmacyServiceProvider = Provider<PharmacyService>(
  (ref) => PharmacyService(),
);

final pharmaciesProvider = FutureProvider<List<Pharmacy>>((ref) {
  return ref.read(pharmacyServiceProvider).getPharmacies();
});

/// Holds the currently selected pharmacy ID for cart operations.
/// Using a Notifier so Riverpod watches the value itself (not a ValueNotifier object).
final selectedPharmacyProvider =
    NotifierProvider<SelectedPharmacyNotifier, int?>(
      SelectedPharmacyNotifier.new,
    );

class SelectedPharmacyNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) => state = id;

  /// Selects [id] only when nothing is selected yet (used for auto-select).
  void selectIfNone(int? id) {
    if (id != null && state == null) state = id;
  }
}

/// Auto-select the first available pharmacy if none is selected.
/// Returns the pharmacy ID, or null if no pharmacies are available.
int? autoSelectPharmacy(WidgetRef ref) {
  final current = ref.read(selectedPharmacyProvider);
  if (current != null) return current;

  final pharmaciesAsync = ref.read(pharmaciesProvider);
  return pharmaciesAsync.maybeWhen(
    data: (pharmacies) {
      if (pharmacies.isNotEmpty) {
        ref
            .read(selectedPharmacyProvider.notifier)
            .select(pharmacies.first.id);
        return pharmacies.first.id;
      }
      return null;
    },
    orElse: () => null,
  );
}

/// Pharmacy inventory for the currently selected pharmacy, mapped by medicine ID
/// to the pharmacy-specific selling price. Falls back to an empty map when no
/// pharmacy is selected so catalog widgets can simply use base price.
final selectedPharmacyInventoryProvider =
    FutureProvider.family<Map<int, double>, String>((ref, token) async {
      final selectedId = ref.watch(selectedPharmacyProvider);
      if (selectedId == null) return const {};
      final inventory = await ref
          .read(pharmacyServiceProvider)
          .getInventory(token, selectedId);
      return {
        for (final item in inventory)
          _inventoryMedicineId(item): _inventoryPrice(item),
      };
    });

int _inventoryMedicineId(Map<String, dynamic> item) {
  final medicine = item['medicine'];
  if (medicine is Map) return _int(medicine['id']);
  return _int(item['medicine_id']);
}

double _inventoryPrice(Map<String, dynamic> item) {
  return _number(
    item['price'] ?? item['selling_price'] ?? item['unit_price'],
  );
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _number(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
