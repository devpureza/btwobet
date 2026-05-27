import 'package:web/web.dart' as web;

/// Persistência de token via localStorage (sem plugin channel).
class TokenStorageBackend {
  static const _key = 'auth_token';

  static Future<TokenStorageBackend> create() async => TokenStorageBackend();

  Future<String?> read() async {
    final value = web.window.localStorage.getItem(_key);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> write(String token) async {
    web.window.localStorage.setItem(_key, token);
  }

  Future<void> clear() async {
    web.window.localStorage.removeItem(_key);
  }
}
