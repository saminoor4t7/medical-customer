import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../cart/provider.dart';
import 'model.dart';
import 'provider.dart';
import '../pharmacy/provider.dart';

class MedicineDetailScreen extends ConsumerStatefulWidget {
  const MedicineDetailScreen({
    required this.medicineId,
    required this.token,
    super.key,
  });

  final int medicineId;
  final String token;

  @override
  ConsumerState<MedicineDetailScreen> createState() =>
      _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends ConsumerState<MedicineDetailScreen> {
  static const Color navy = Color(0xFF061A33);
  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  int _quantity = 1;
  bool _addingToCart = false;

  @override
  Widget build(BuildContext context) {
    final medicine = ref.watch(medicineDetailProvider(widget.medicineId));
    final pharmacyPrice = ref
        .watch(selectedPharmacyInventoryProvider(widget.token))
        .value?[widget.medicineId];
    final price = pharmacyPrice ?? _basePrice(medicine.value);

    return Scaffold(
      backgroundColor: navy,
      body: medicine.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: teal)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 55),
              const SizedBox(height: 14),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  ref.invalidate(medicineDetailProvider(widget.medicineId));
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
        data: (med) => SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    _CircleBtn(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _CircleBtn(
                      icon: Icons.favorite_border,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFF102F45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: med.image != null && med.image!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  med.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _placeholderIcon(),
                                ),
                              )
                            : _placeholderIcon(),
                      ),

                      const SizedBox(height: 20),

                      // Name + price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (med.brand != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    med.brand!,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: teal.withValues(alpha:0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: teal.withValues(alpha:0.3),
                              ),
                            ),
                            child: Text(
                              'PKR ${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: teal,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (med.category != null)
                            _Tag(label: med.category!),
                          if (med.form != null)
                            _Tag(label: med.form!),
                          if (med.strength != null)
                            _Tag(label: med.strength!),
                          if (med.requiresPrescription)
                            const _Tag(
                              label: 'Prescription Required',
                              isWarning: true,
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Stock status
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: med.isActive
                              ? teal.withValues(alpha:0.08)
                              : Colors.red.withValues(alpha:0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: med.isActive
                                ? teal.withValues(alpha:0.2)
                                : Colors.red.withValues(alpha:0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              med.isActive
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: med.isActive ? teal : Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              med.isActive
                                  ? 'Available'
                                  : 'Not Available',
                              style: TextStyle(
                                color: med.isActive ? teal : Colors.redAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Description
                      if (med.description != null &&
                          med.description!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          med.description!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha:0.7),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Bottom Add-to-Cart bar ──
              if (med.isActive)
                _buildAddToCartBar(med, price),
            ],
          ),
        ),
      ),
    );
  }

  double _basePrice(Medicine? medicine) => medicine?.price ?? 0;

  Widget _placeholderIcon() => const Center(
        child: Icon(Icons.medication_outlined, color: teal, size: 64),
      );

  Widget _buildAddToCartBar(Medicine med, double price) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: teal.withValues(alpha:0.15)),
        ),
      ),
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF10354A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF176074)),
            ),
            child: Row(
              children: [
                _QtyBtn(
                  icon: Icons.remove,
                  onTap: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                _QtyBtn(
                  icon: Icons.add,
                  onTap: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Add to cart button
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _addingToCart ? null : () => _addToCart(med),
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _addingToCart
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: navy,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add to Cart • PKR ${(price * _quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(Medicine med) async {
    // Get selected pharmacy (or pick one)
    int? pharmacyId = ref.read(selectedPharmacyProvider);

    if (pharmacyId == null) {
      pharmacyId = autoSelectPharmacy(ref);
      if (pharmacyId == null) return; // user cancelled
    }

    setState(() => _addingToCart = true);
    try {
      await ref
          .read(cartControllerProvider)
          .addItem(widget.token, med.id, _quantity, pharmacyId: pharmacyId);
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${med.name} (x$_quantity) added to cart'),
            backgroundColor: teal,
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to add: ${e.toString()}'),
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  static const Color teal = Color(0xFF00C9A7);
  static const Color cardColor = Color(0xFF09243D);

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
            color: cardColor,
            border: Border.all(color: teal.withValues(alpha:0.3)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? const Color(0xFF526779) : Colors.white,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.isWarning = false});
  final String label;
  final bool isWarning;

  static const Color teal = Color(0xFF00C9A7);

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? Colors.orange : teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}