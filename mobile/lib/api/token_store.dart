import 'package:shared_preferences/shared_preferences.dart';

class AuthTokens {
  final String accessToken;
  final String? refreshToken;

  const AuthTokens({required this.accessToken, this.refreshToken});
}

abstract class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

class MemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}

class SharedPreferencesTokenStore implements TokenStore {
  // Import local para evitar acoplar o resto do projeto; esta classe depende de shared_preferences.
  final SharedPreferences _prefs;
  final String prefix;

  SharedPreferencesTokenStore(this._prefs, {this.prefix = 'auth'});

  String get _accessKey => '${prefix}_access_token';
  String get _refreshKey => '${prefix}_refresh_token';

  @override
  Future<AuthTokens?> read() async {
    final access = _prefs.getString(_accessKey);
    final refresh = _prefs.getString(_refreshKey);
    if (access == null || access.isEmpty) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _prefs.setString(_accessKey, tokens.accessToken);
    if (tokens.refreshToken != null) {
      await _prefs.setString(_refreshKey, tokens.refreshToken!);
    } else {
      await _prefs.remove(_refreshKey);
    }
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
  }
}
