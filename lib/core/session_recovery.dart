import 'package:flutter/material.dart';

import '../auth/login/log_screen.dart';
import 'app_theme.dart';
import 'auth_session.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

bool _recoveryInFlight = false;

/// Invoked by services when the API answers 401: the stored token is dead
/// (expired or its user no longer exists), so clear the session and send the
/// user back to the login screen instead of retrying forever.
void handleUnauthorized() {
  if (_recoveryInFlight) return;
  _recoveryInFlight = true;

  AuthSession.clear().then((_) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      _recoveryInFlight = false;
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    final context = appNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your session has expired. Please log in again.',
                  style: TextStyle(
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
    _recoveryInFlight = false;
  });
}
