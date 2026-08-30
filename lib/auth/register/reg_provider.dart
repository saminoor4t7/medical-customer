import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reg_model.dart';
import 'reg_services.dart';

class RegisterState {
  const RegisterState({
    this.isLoading = false,
    this.isRegistered = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isRegistered;
  final String? errorMessage;
  final String? successMessage;
}

final registerProvider = NotifierProvider<RegisterController, RegisterState>(
  RegisterController.new,
);

class RegisterController extends Notifier<RegisterState> {
  late final RegisterService _service = RegisterService();

  @override
  RegisterState build() => const RegisterState();

  Future<void> submit(RegisterModel model) async {
    state = const RegisterState(isLoading: true);
    try {
      final result = await _service.register(model);
      if (result.isSuccess) {
        state = RegisterState(
          isRegistered: true,
          successMessage: registerSuccessMessage(result),
        );
      } else {
        state = RegisterState(errorMessage: registerErrorMessage(result));
      }
    } catch (_) {
      state = const RegisterState(
        errorMessage: 'Unable to connect to the server. Please try again.',
      );
    }
  }
}
