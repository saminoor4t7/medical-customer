import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  static Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessTokenKey, accessToken);
    await preferences.setString(_refreshTokenKey, refreshToken);
  }

  static Future<({String accessToken, String refreshToken})?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final accessToken = preferences.getString(_accessTokenKey);
    final refreshToken = preferences.getString(_refreshTokenKey);

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    return (accessToken: accessToken, refreshToken: refreshToken);
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
  }
}
