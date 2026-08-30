import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import 'model.dart';
import 'provider.dart';
import '../ai/screen.dart';
import '../cart/provider.dart';
import '../pharmacy/provider.dart';

import '../prescription/screen.dart';
import 'medicine_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  Timer? _debounce;

  static const Color navy = Color(0xFF061A33);
  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = value);
      ref.invalidate(medicinesProvider(value.isEmpty ? null : value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final medicines = ref.watch(
      medicinesProvider(_searchQuery.isEmpty ? null : _searchQuery),
    );
    final featured = ref.watch(featuredMedicinesProvider);

    ref.watch(pharmaciesProvider); // pre-load pharmacies for auto-select
    return Scaffold(
      backgroundColor: navy,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AIChatScreen(token: widget.token),
            ),
          );
        },
        backgroundColor: teal,
        child: const Icon(Icons.chat, color: navy, size: 26),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: teal,
          backgroundColor: cardColor,
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(featuredMedicinesProvider);
            ref.invalidate(medicinesProvider(null));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(child: _buildHeader()),

              // ── Search Bar ──
              SliverToBoxAdapter(child: _buildSearchBar()),

              // ── AI Prescription Banner ──
              SliverToBoxAdapter(child: _buildAiBanner()),

              // ── Categories ──
              SliverToBoxAdapter(
                child: _buildCategoriesSection(categories),
              ),

              // ── Search Results or Featured ──
              if (_searchQuery.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSearchResults(medicines),
                )
              else
                SliverToBoxAdapter(
                  child: _buildFeaturedSection(featured),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // HEADER
  // ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Medical ',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'Panda',
                        style: TextStyle(color: teal),
                      ),
                    ],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your health, delivered fast',
                  style: TextStyle(color: muted, fontSize: 14),
                ),
              ],
            ),
          ),
          _CircleIcon(
            icon: Icons.notifications_none,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1D3C5B).withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: muted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Search medicines, brands...',
                  hintStyle: TextStyle(color: muted, fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() => _searchQuery = '');
                  ref.invalidate(medicinesProvider(null));
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.close, color: muted, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // AI PRESCRIPTION BANNER
  // ────────────────────────────────────────────────────────────

  Widget _buildAiBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PrescriptionUploadScreen(token: widget.token),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF079B83), Color(0xFF0877A0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Prescription',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'AI reads your prescription & builds your cart',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // CATEGORIES SECTION
  // ────────────────────────────────────────────────────────────

  Widget _buildCategoriesSection(AsyncValue<List<Category>> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop by Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: categories.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: teal),
              ),
              error: (_, __) => const Center(
                child: Text('Failed to load', style: TextStyle(color: muted)),
              ),
              data: (cats) {
                if (cats.isEmpty) {
                  return const Center(
                    child: Text('No categories', style: TextStyle(color: muted)),
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) =>
                      _CategoryChip(category: cats[index], token: widget.token),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // SEARCH RESULTS
  // ────────────────────────────────────────────────────────────

  Widget _buildSearchResults(AsyncValue<List<Medicine>> medicines) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results for "$_searchQuery"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          medicines.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: teal)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(e.toString(), style: const TextStyle(color: muted)),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off, color: muted, size: 48),
                        SizedBox(height: 12),
                        Text('No medicines found', style: TextStyle(color: muted)),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (_, index) => _MedicineListTile(
                  medicine: items[index],
                  token: widget.token,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // FEATURED MEDICINES
  // ────────────────────────────────────────────────────────────

  Widget _buildFeaturedSection(AsyncValue<List<Medicine>> featured) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Medicines',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          featured.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: teal)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(e.toString(), style: const TextStyle(color: muted)),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No medicines yet', style: TextStyle(color: muted)),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (_, index) => _MedicineCard(
                  medicine: items[index],
                  token: widget.token,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// CATEGORY CHIP
// ────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.token});
  final Category category;
  final String token;

  static const Color teal = Color(0xFF00C9A7);
  static const Color cardColor = Color(0xFF09243D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _CategoryDetailScreen(
              categoryId: category.id,
              categoryName: category.name,
              token: token,
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: teal.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: teal.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: category.image != null && category.image!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        category.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.medication_outlined,
                          color: teal,
                          size: 22,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.medication_outlined,
                      color: teal,
                      size: 22,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// MEDICINE CARD (GRID)
// ────────────────────────────────────────────────────────────────

class _MedicineCard extends ConsumerWidget {
  const _MedicineCard({required this.medicine, required this.token});
  final Medicine medicine;
  final String token;

  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MedicineDetailScreen(
              medicineId: medicine.id,
              token: token,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0B5061).withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF102F45),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: medicine.image != null && medicine.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          medicine.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderIcon(),
                        ),
                      )
                    : _placeholderIcon(),
              ),
            ),

            // Info area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (medicine.brand != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        medicine.brand!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'PKR ${medicine.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: teal,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        _AddButton(
                          onTap: () => _addToCart(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() => const Center(
        child: Icon(Icons.medication_outlined, color: teal, size: 38),
      );

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    final selectedNotifier = ref.read(selectedPharmacyProvider);
    int? pharmacyId = selectedNotifier.value;
    if (pharmacyId == null) {
      pharmacyId = autoSelectPharmacy(ref);
      if (pharmacyId == null) return;
    }
    try {
      await ref
          .read(cartControllerProvider)
          .addItem(token, medicine.id, 1, pharmacyId: pharmacyId);
      if (context.mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${medicine.name} added to cart'),
            backgroundColor: teal,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
      }
    }
  }
}

// ────────────────────────────────────────────────────────────────
// MEDICINE LIST TILE (SEARCH RESULTS)
// ────────────────────────────────────────────────────────────────

class _MedicineListTile extends ConsumerWidget {
  const _MedicineListTile({required this.medicine, required this.token});
  final Medicine medicine;
  final String token;

  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MedicineDetailScreen(
              medicineId: medicine.id,
              token: token,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0B5061).withOpacity(0.4)),
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
              child: medicine.image != null && medicine.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        medicine.image!,
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
                    medicine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (medicine.brand != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      medicine.brand!,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${medicine.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: teal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _AddButton(
              onTap: () async {
                final selectedNotifier = ref.read(selectedPharmacyProvider);
                int? pharmacyId = selectedNotifier.value;
                if (pharmacyId == null) {
                  pharmacyId = autoSelectPharmacy(ref);
                  if (pharmacyId == null) return;
                }
                try {
                  await ref
                      .read(cartControllerProvider)
                      .addItem(token, medicine.id, 1, pharmacyId: pharmacyId);
                  if (context.mounted) {
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('${medicine.name} added to cart'),
                        backgroundColor: teal,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Failed: ${e.toString()}'),
                        backgroundColor: const Color(0xFFB3261E),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// ADD BUTTON
// ────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  static const Color teal = Color(0xFF00C9A7);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: teal.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: teal.withOpacity(0.4)),
        ),
        child: const Icon(Icons.add, color: teal, size: 20),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// PHARMACY PICKER DIALOG
// ────────────────────────────────────────────────────────────────

// ────────────────────────────────────────────────────────────────
// CIRCLE ICON
// ────────────────────────────────────────────────────────────────

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF09243D),
            border: Border.all(
              color: const Color(0xFF00C9A7).withOpacity(0.25),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// CATEGORY DETAIL (inline, shows medicines in a category)
// ────────────────────────────────────────────────────────────────

class _CategoryDetailScreen extends ConsumerWidget {
  const _CategoryDetailScreen({
    required this.categoryId,
    required this.categoryName,
    required this.token,
  });

  final int categoryId;
  final String categoryName;
  final String token;

  static const Color navy = Color(0xFF061A33);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicines = ref.watch(categoryMedicinesProvider(categoryId));

    ref.watch(pharmaciesProvider); // pre-load pharmacies for auto-select
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
              child: Text(
                'No medicines in this category',
                style: TextStyle(color: muted),
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
              itemBuilder: (_, index) => _CategoryMedicineTile(
                medicine: items[index],
                token: token,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryMedicineTile extends ConsumerWidget {
  const _CategoryMedicineTile({required this.medicine, required this.token});
  final Medicine medicine;
  final String token;

  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MedicineDetailScreen(
              medicineId: medicine.id,
              token: token,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0B5061).withOpacity(0.4)),
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
              child: medicine.image != null && medicine.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        medicine.image!,
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
                    medicine.name,
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
                    'PKR ${medicine.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: teal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _AddButton(
              onTap: () async {
                final selectedNotifier = ref.read(selectedPharmacyProvider);
                int? pharmacyId = selectedNotifier.value;
                if (pharmacyId == null) {
                  pharmacyId = autoSelectPharmacy(ref);
                  if (pharmacyId == null) return;
                }
                try {
                  await ref
                      .read(cartControllerProvider)
                      .addItem(token, medicine.id, 1, pharmacyId: pharmacyId);
                  if (context.mounted) {
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('${medicine.name} added to cart'),
                        backgroundColor: teal,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Failed: ${e.toString()}'),
                        backgroundColor: const Color(0xFFB3261E),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}