import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/model.dart';
import '../catalog/provider.dart';
import '../catalog/medicine_detail_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({required this.token, super.key});

  final String token;

  static const Color navy = Color(0xFF061A33);
  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: RefreshIndicator(
          color: teal,
          backgroundColor: cardColor,
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browse medicines by category',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories grid
              categories.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: teal),
                  ),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          e.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: muted),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            ref.invalidate(categoriesProvider);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: navy,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (cats) {
                  if (cats.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              color: muted,
                              size: 64,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No categories available',
                              style: TextStyle(color: muted, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _CategoryCard(
                          category: cats[index],
                          token: token,
                        ),
                        childCount: cats.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.token});

  final Category category;
  final String token;

  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  // Predefined icons for common medical categories
  static const _categoryIcons = <String, IconData>{
    'pain': Icons.medication_liquid,
    'fever': Icons.thermostat,
    'cold': Icons.ac_unit,
    'vitamin': Icons.brightness_high,
    'skin': Icons.face,
    'eye': Icons.visibility,
    'heart': Icons.favorite,
    'diabetes': Icons.bloodtype,
    'stomach': Icons.set_meal,
    'allergy': Icons.coronavirus,
    'bone': Icons.accessibility,
    'first aid': Icons.healing,
    'baby': Icons.child_care,
    'women': Icons.female,
    'men': Icons.male,
    'dental': Icons.medical_services,
  };

  IconData _getIcon() {
    final name = category.name.toLowerCase();
    for (final entry in _categoryIcons.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return Icons.medication_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _CategoryMedicinesScreen(
              categoryId: category.id,
              categoryName: category.name,
              token: token,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: teal.withOpacity(0.20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: teal.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: category.image != null && category.image!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        category.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          _getIcon(),
                          color: teal,
                          size: 30,
                        ),
                      ),
                    )
                  : Icon(
                      _getIcon(),
                      color: teal,
                      size: 30,
                    ),
            ),
            const SizedBox(height: 14),

            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            if (category.description != null &&
                category.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  category.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Medicine count
            if (category.medicineCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.medicineCount} items',
                  style: TextStyle(
                    color: teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Category Medicines Screen (reusable from categories)
// ────────────────────────────────────────────────────────────────

class _CategoryMedicinesScreen extends ConsumerWidget {
  const _CategoryMedicinesScreen({
    required this.categoryId,
    required this.categoryName,
    required this.token,
  });

  final int categoryId;
  final String categoryName;
  final String token;

  static const Color navy = Color(0xFF061A33);
  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicines = ref.watch(categoryMedicinesProvider(categoryId));

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Text(categoryName),
      ),
      body: medicines.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: teal)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e.toString(), style: const TextStyle(color: muted)),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.medication_outlined, color: muted, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'No medicines in this category',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: teal,
            onRefresh: () async {
              ref.invalidate(categoryMedicinesProvider(categoryId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, index) {
                final med = items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _buildMedicineDetail(med.id),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0B5061).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF102F45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: med.image != null && med.image!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    med.image!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.medication_outlined,
                                      color: teal,
                                      size: 28,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.medication_outlined,
                                  color: teal,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PKR ${med.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: teal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: muted,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicineDetail(int medicineId) {
    // Use the MedicineDetailScreen from home module
    return _MedicineDetailRedirect(medicineId: medicineId, token: token);
  }
}

/// Redirects to the proper MedicineDetailScreen
class _MedicineDetailRedirect extends StatelessWidget {
  const _MedicineDetailRedirect({
    required this.medicineId,
    required this.token,
  });
  final int medicineId;
  final String token;

  @override
  Widget build(BuildContext context) {
    // Import is at top of file via home_screen exports
    return MedicineDetailScreen(medicineId: medicineId, token: token);
  }
}
