import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../core/app_theme.dart';
import '../login/log_screen.dart';
import '../register/reg_screen.dart';
import 'otp_model.dart';
import 'otp_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({required this.email, required this.role, super.key});

  final String email;
  final String role;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _expiryTimer;
  int _remainingSeconds = 5 * 60;

  @override
  void initState() {
    super.initState();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        _expiryTimer?.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_remainingSeconds == 0) {
      _showMessage('This OTP has expired. Please request a new code.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(otpProvider.notifier)
        .verify(
          OtpVerifyModel(
            email: widget.email,
            code: _codeController.text.trim(),
            role: widget.role,
          ),
        );
    if (!mounted) return;
    final state = ref.read(otpProvider);
    if (state.isVerified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
      return;
    }
    final message = state.isVerified
        ? 'Account verified successfully.'
        : state.errorMessage;
    if (message != null) {
      _showMessage(message, isSuccess: state.isVerified);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? AppTheme.primary : AppTheme.error,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String get _formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpProvider);
    final pinTheme = PinTheme(
      width: 48,
      height: 54,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
    );
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to registration',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
          ),
        ),
        title: const Text('Verify account'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset('assets/logo.jpeg', width: 78, height: 78),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter the 6-digit code sent to ${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF8D9BB0)),
                ),
                const SizedBox(height: 12),
                Text(
                  _remainingSeconds == 0
                      ? 'Code expired'
                      : 'Code expires in $_formattedRemainingTime',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _remainingSeconds == 0
                        ? const Color(0xFFFF8A8A)
                        : AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
                Pinput(
                  controller: _codeController,
                  length: 6,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.length != 6
                      ? 'Enter the 6-digit code'
                      : null,
                  defaultPinTheme: pinTheme,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: state.isLoading || _remainingSeconds == 0
                        ? null
                        : _verify,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verify code'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
