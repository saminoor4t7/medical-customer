import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediacl_panda/customer/catalog/services.dart';

import 'model.dart';


final catalogServiceProvider = Provider<CatalogService>((ref) => CatalogService());

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(catalogServiceProvider).getCategories();
});

final medicinesProvider = FutureProvider.family<List<Medicine>, String?>(
  (ref, query) {
    return ref.read(catalogServiceProvider).getMedicines(query: query);
  },
);

final categoryMedicinesProvider =
    FutureProvider.family<List<Medicine>, int>((ref, categoryId) {
  return ref.read(catalogServiceProvider).getMedicines(categoryId: categoryId);
});

final medicineDetailProvider =
    FutureProvider.family<Medicine, int>((ref, id) {
  return ref.read(catalogServiceProvider).getMedicineDetail(id);
});

final featuredMedicinesProvider = FutureProvider<List<Medicine>>((ref) {
  return ref.read(catalogServiceProvider).getMedicines();
});
