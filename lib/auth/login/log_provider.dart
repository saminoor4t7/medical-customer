import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'log_model.dart';
import 'log_service.dart';

class LoginState {
  const LoginState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.message,
    this.accessToken,
    this.refreshToken,
  });

  final bool isLoading;
  final bool isLoggedIn;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
}

final loginProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

class LoginController extends Notifier<LoginState> {
  late final LoginService _service = LoginService();

  @override
  LoginState build() => const LoginState();

  Future<void> submit(LoginModel model) async {
    state = const LoginState(isLoading: true);
    try {
      final result = await _service.login(model);
      state = result.isSuccess
          ? LoginState(
              isLoggedIn: true,
              message: 'Login successful.',
              accessToken: result.accessToken,
              refreshToken: result.refreshToken,
            )
          : LoginState(message: loginMessage(result));
    } catch (_) {
      state = const LoginState(
        message: 'Unable to connect to the server. Please try again.',
      );
    }
  }
}
