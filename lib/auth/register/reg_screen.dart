import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../login/log_screen.dart';
import '../otp/otp_screen.dart';
import '../../core/app_theme.dart';
import 'reg_model.dart';
import 'reg_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _firstName = TextEditingController();
  String? _selectedRole;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _firstName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref
        .read(registerProvider.notifier)
        .submit(
          RegisterModel(
            username: _username.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            role: _selectedRole!,
            phoneNumber: _phone.text.trim(),
            firstName: _firstName.text.trim(),
          ),
        );
    if (!mounted) {
      return;
    }
    final registerState = ref.read(registerProvider);
    if (registerState.isRegistered) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              OtpScreen(email: _email.text.trim(), role: _selectedRole!),
        ),
      );
      return;
    }
    final message = registerState.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Create account'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ARE YOU NEW HERE?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your details to get started.',
                  style: TextStyle(color: Color(0xFF8D9BB0)),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF00C7C2,
                          ).withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/logo.jpeg', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  validator: (value) =>
                      value == null ? 'Please select a role' : null,
                  onChanged: (value) => setState(() => _selectedRole = value),
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: const Icon(Icons.work_outline),
                    filled: true,
                    fillColor: AppTheme.surface,
                    labelStyle: const TextStyle(color: AppTheme.mutedText),
                    prefixIconColor: AppTheme.primary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'customer',
                      child: Text('Customer'),
                    ),
                    DropdownMenuItem(value: 'rider', child: Text('Rider')),
                    DropdownMenuItem(
                      value: 'pharmacy',
                      child: Text('Pharmacy'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _field(_firstName, 'First name', Icons.person_outline),
                _field(_username, 'Username', Icons.badge_outlined),
                _field(
                  _email,
                  'Email',
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                _field(
                  _phone,
                  'Phone number',
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                _field(
                  _password,
                  'Password',
                  Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: registerState.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                    child: registerState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Register'),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Color(0xFF8D9BB0)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      ),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: _required,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppTheme.surface,
          labelStyle: const TextStyle(color: AppTheme.mutedText),
          prefixIconColor: AppTheme.primary,
          suffixIconColor: AppTheme.mutedText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
