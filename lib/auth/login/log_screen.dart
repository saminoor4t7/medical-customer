import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/auth_session.dart';
import '../../customer/customer_shell.dart';
import '../register/reg_screen.dart';
import 'log_model.dart';
import 'log_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _selectedRole;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(loginProvider.notifier)
        .submit(
          LoginModel(
            username: _username.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            role: _selectedRole!,
          ),
        );
    if (!mounted) return;
    final state = ref.read(loginProvider);
    if (state.isLoggedIn &&
        state.accessToken != null &&
        state.refreshToken != null) {
      await AuthSession.save(
        accessToken: state.accessToken!,
        refreshToken: state.refreshToken!,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CustomerShell(
            accessToken: state.accessToken!,
            refreshToken: state.refreshToken!,
          ),
        ),
      );
      return;
    }
    if (state.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: state.isLoggedIn ? AppTheme.primary : AppTheme.error,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(
                state.isLoggedIn
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.message!,
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
    final state = ref.watch(loginProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Welcome back'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset('assets/logo.jpeg', width: 78, height: 78),
                ),
                const SizedBox(height: 24),
                const Text(
                  'LOGIN TO YOUR ACCOUNT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your details to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8D9BB0)),
                ),
                const SizedBox(height: 28),
                _field(_username, 'Username', Icons.badge_outlined),
                _field(
                  _email,
                  'Email',
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
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
                    labelStyle: const TextStyle(color: Color(0xFF8D9BB0)),
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
                    onPressed: state.isLoading ? null : _submit,
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
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'New to Medical Panda? ',
                      style: TextStyle(color: Color(0xFF8D9BB0)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text('Create account'),
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
          labelStyle: const TextStyle(color: Color(0xFF8D9BB0)),
          prefixIconColor: AppTheme.primary,
          suffixIconColor: const Color(0xFF8D9BB0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
