import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'provider.dart';

class PharmacyScreen extends ConsumerWidget {
  const PharmacyScreen({super.key});

  static const Color navy = Color(0xFF061A33);
  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmaciesAsync = ref.watch(pharmaciesProvider);

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Pharmacies'),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final p = pharmacies[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: teal.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: teal.withOpacity(0.1),
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
                      const Icon(Icons.verified, color: teal, size: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
