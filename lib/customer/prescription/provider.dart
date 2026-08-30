import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'services.dart';

final prescriptionServiceProvider =
    Provider<PrescriptionService>((ref) => PrescriptionService());

final prescriptionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, token) {
  return ref.read(prescriptionServiceProvider).getPrescriptions(token);
});
