import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'otp_model.dart';
import 'otp_service.dart';

class OtpState {
  const OtpState({
    this.isLoading = false,
    this.isVerified = false,
    this.errorMessage,
    this.result,
  });

  final bool isLoading;
  final bool isVerified;
  final String? errorMessage;
  final OtpResult? result;
}

final otpProvider = NotifierProvider<OtpController, OtpState>(
  OtpController.new,
);

class OtpController extends Notifier<OtpState> {
  late final OtpService _service = OtpService();

  @override
  OtpState build() => const OtpState();

  Future<void> verify(OtpVerifyModel model) async {
    state = const OtpState(isLoading: true);
    try {
      final result = await _service.verify(model);
      state = result.isSuccess
          ? OtpState(isVerified: true, result: result)
          : OtpState(errorMessage: otpErrorMessage(result), result: result);
    } catch (_) {
      state = const OtpState(
        errorMessage: 'Unable to connect to the server. Please try again.',
      );
    }
  }
}
