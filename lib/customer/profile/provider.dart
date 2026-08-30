import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediacl_panda/customer/profile/model.dart';
import 'package:mediacl_panda/customer/profile/services.dart';



final profileProvider = FutureProvider.family<CustomerProfile, String>((
  ref,
  token,
) {
  return ProfileService().getProfile(token);
});
