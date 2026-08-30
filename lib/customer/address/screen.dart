import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_theme.dart';
import '../profile/location_picker.dart';
import 'model.dart';
import 'provider.dart';

class AddressScreen extends ConsumerWidget {
  const AddressScreen({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressProvider(token));

    return Scaffold(
      backgroundColor: const Color(0xFF061A33),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061A33),
        foregroundColor: Colors.white,
        title: const Text('Addresses'),
      ),
      body: addresses.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load addresses\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No addresses saved yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final address = items[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A2038),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: address.isDefault
                        ? AppTheme.primary
                        : Colors.white24,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (address.latitude != null && address.longitude != null)
                      SizedBox(
                        height: 170,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                address.latitude!,
                                address.longitude!,
                              ),
                              zoom: 15,
                            ),
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            scrollGesturesEnabled: false,
                            zoomGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            markers: {
                              Marker(
                                markerId: MarkerId(address.label),
                                position: LatLng(
                                  address.latitude!,
                                  address.longitude!,
                                ),
                              ),
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Location not available',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        IconButton(
                          tooltip: 'Delete address',
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.redAccent,
                          onPressed: address.id == null
                              ? null
                              : () => _confirmDelete(context, ref, address),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address.addressLine,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (address.city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        address.city,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    if (address.latitude != null &&
                        address.longitude != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${address.latitude}, Lng: ${address.longitude}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final selected = await Navigator.of(context).push<LocationSelection>(
            MaterialPageRoute<LocationSelection>(
              builder: (_) => const LocationPickerScreen(),
            ),
          );

          if (selected == null || !context.mounted) return;

          final newAddress = CustomerAddress(
            label: 'Home',
            addressLine:
                'Pinned location (${selected.latitude.toStringAsFixed(6)}, '
                '${selected.longitude.toStringAsFixed(6)})',
            city: 'Selected location',
            latitude: selected.latitude,
            longitude: selected.longitude,
            isDefault: true,
          );

          final existingAddresses =
              ref.read(addressProvider(token)).value ?? [];
          for (final address in existingAddresses) {
            await ref.read(addressControllerProvider).delete(token, address);
          }
          await ref.read(addressControllerProvider).create(token, newAddress);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location saved successfully.')),
            );
          }
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CustomerAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete address?'),
        content: const Text('This address will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(addressControllerProvider).delete(token, address);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Address deleted.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete address: $error')),
        );
      }
    }
  }
}
