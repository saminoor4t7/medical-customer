import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/register/reg_screen.dart';
import 'core/api_client.dart';
import 'core/api_client_provider.dart';
import 'core/app_theme.dart';
import 'core/auth_session.dart';
import 'core/session_recovery.dart';
import 'customer/customer_shell.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Panda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: appNavigatorKey,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loaderController;
  late final Timer _splashTimer;

  @override
  void initState() {
    super.initState();
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _splashTimer = Timer(const Duration(seconds: 2), _openInitialScreen);
  }

  Future<void> _openInitialScreen() async {
    final session = await AuthSession.read();
    if (!mounted) return;

    if (session != null) {
      ref.read(apiClientProvider.notifier).state = ApiClient(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    }

    final destination = session != null
        ? CustomerShell(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          )
        : const RegisterScreen();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  void dispose() {
    _splashTimer.cancel();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _CornerCircle(
            alignment: Alignment.topRight,
            size: 184,
            color: Color(0xFF0A7778),
          ),
          const _CornerCircle(
            alignment: Alignment.bottomLeft,
            size: 154,
            color: Color(0xFF0B526D),
          ),
          SafeArea(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00C7C2,
                            ).withValues(alpha: 0.42),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Medical ',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'Panda',
                            style: TextStyle(color: Color(0xFF00B9AB)),
                          ),
                        ],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF006E70)),
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF07384D),
                      ),
                      child: const Text(
                        'Medicines & Healthcare Delivered',
                        style: TextStyle(
                          color: Color(0xFF00B9AB),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 31),
                    const Text(
                      'Fast. Safe. Digital.',
                      style: TextStyle(color: Color(0xFF8D9BB0), fontSize: 16),
                    ),
                    const SizedBox(height: 78),
                    RotationTransition(
                      turns: _loaderController,
                      child: const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00B9AB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerCircle extends StatelessWidget {
  const _CornerCircle({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(
          alignment.x > 0 ? size * 0.48 : -size * 0.48,
          alignment.y > 0 ? size * 0.48 : -size * 0.48,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
