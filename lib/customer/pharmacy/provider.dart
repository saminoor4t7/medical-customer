import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediacl_panda/customer/pharmacy/services.dart';

import 'model.dart';


final pharmacyServiceProvider = Provider<PharmacyService>((ref) => PharmacyService());

final pharmaciesProvider = FutureProvider<List<Pharmacy>>((ref) {
  return ref.read(pharmacyServiceProvider).getPharmacies();
});

/// Holds the currently selected pharmacy ID for cart operations
final selectedPharmacyProvider = Provider<ValueNotifier<int?>>((ref) {
  final notifier = ValueNotifier<int?>(null);
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Auto-select the first available pharmacy if none is selected.
/// Returns the pharmacy ID, or null if no pharmacies are available.
int? autoSelectPharmacy(WidgetRef ref) {
  final notifier = ref.read(selectedPharmacyProvider);
  if (notifier.value != null) return notifier.value;

  final pharmaciesAsync = ref.read(pharmaciesProvider);
  return pharmaciesAsync.maybeWhen(
    data: (pharmacies) {
      if (pharmacies.isNotEmpty) {
        notifier.value = pharmacies.first.id;
        return pharmacies.first.id;
      }
      return null;
    },
    orElse: () => null,
  );
}
