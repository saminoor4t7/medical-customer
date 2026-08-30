import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model.dart';
import 'services.dart';

final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService();
});

final addressProvider = FutureProvider.family<List<CustomerAddress>, String>((
  ref,
  token,
) {
  return ref.read(addressServiceProvider).getAddresses(token);
});

final addressControllerProvider = Provider<AddressController>((ref) {
  return AddressController(ref, ref.read(addressServiceProvider));
});

class AddressController {
  AddressController(this.ref, this.service);

  final Ref ref;
  final AddressService service;

  Future<void> refresh(String token) async {
    ref.invalidate(addressProvider(token));
  }

  Future<void> create(String token, CustomerAddress address) async {
    await service.saveAddress(token, address);
    ref.invalidate(addressProvider(token));
  }

  Future<void> delete(String token, CustomerAddress address) async {
    final addressId = address.id;
    if (addressId == null) return;
    await service.deleteAddress(token, addressId);
    ref.invalidate(addressProvider(token));
  }
}
