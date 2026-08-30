import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model.dart';
import 'service.dart';

class LogoutState {
  const LogoutState({
    this.isLoading = false,
    this.isLoggedOut = false,
    this.error,
  });

  final bool isLoading;
  final bool isLoggedOut;
  final String? error;
}

final logoutProvider = NotifierProvider<LogoutController, LogoutState>(
  LogoutController.new,
);

class LogoutController extends Notifier<LogoutState> {
  late final LogoutService _service = LogoutService();

  @override
  LogoutState build() => const LogoutState();

  Future<void> submit({
    required String accessToken,
    required String refreshToken,
  }) async {
    state = const LogoutState(isLoading: true);
    try {
      final result = await _service.logout(
        LogoutRequest(refreshToken: refreshToken),
        accessToken,
      );
      state = result.isSuccess
          ? const LogoutState(isLoggedOut: true)
          : LogoutState(error: 'Logout failed (${result.statusCode}).');
    } catch (_) {
      state = const LogoutState(error: 'Unable to connect to the server.');
    }
  }
}
