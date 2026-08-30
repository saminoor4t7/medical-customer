import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_session.dart';
import '../login/log_screen.dart';
import 'provider.dart';

class LogoutScreen extends ConsumerStatefulWidget {
  const LogoutScreen({
    required this.accessToken,
    required this.refreshToken,
    super.key,
  });

  final String accessToken;
  final String refreshToken;

  @override
  ConsumerState<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends ConsumerState<LogoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _logout());
  }

  Future<void> _logout() async {
    await ref
        .read(logoutProvider.notifier)
        .submit(
          accessToken: widget.accessToken,
          refreshToken: widget.refreshToken,
        );
    if (!mounted) return;
    final state = ref.read(logoutProvider);
    if (state.isLoggedOut) {
      await AuthSession.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logoutProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Signing out')),
      body: Center(
        child: state.error == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.error!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _logout,
                    child: const Text('Try again'),
                  ),
                ],
              ),
      ),
    );
  }
}
