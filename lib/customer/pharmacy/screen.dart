import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider.dart';

class PharmacyScreen extends ConsumerWidget {
  const PharmacyScreen({this.popOnSelect = false, super.key});

  /// When true, tapping a pharmacy pops the screen and returns the pharmacy ID.
  /// Use this when opening the screen as a picker.
  final bool popOnSelect;

  static const Color navy = Color(0xFF061A33);
  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmaciesAsync = ref.watch(pharmaciesProvider);
    final selectedId = ref.watch(selectedPharmacyProvider);

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Text(popOnSelect ? 'Select Pharmacy' : 'Pharmacies'),
      ),
      body: pharmaciesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: teal),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load pharmacies:\n$e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (pharmacies) {
          if (pharmacies.isEmpty) {
            return const Center(
              child: Text(
                'No pharmacies available.',
                style: TextStyle(color: muted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pharmacies.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final p = pharmacies[i];
              final isSelected = p.id == selectedId;
              return GestureDetector(
                onTap: () => _select(context, ref, p.id),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? teal : teal.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: teal.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy,
                          color: teal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.businessName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.city ?? p.addressLine ?? '',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (p.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.verified, color: teal, size: 20),
                        ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: teal, size: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, int id) {
    ref.read(selectedPharmacyProvider.notifier).select(id);
    if (popOnSelect && context.mounted) {
      Navigator.of(context).pop(id);
    }
  }
}
