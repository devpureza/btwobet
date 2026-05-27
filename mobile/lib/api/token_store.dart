import 'token_store_backend.dart'
    if (dart.library.html) 'token_store_web.dart'
    if (dart.library.io) 'token_store_mobile.dart';

/// Persiste o token Sanctum (localStorage na web, secure storage no mobile/desktop).
class TokenStore {
  final TokenStorageBackend _backend;

  TokenStore._(this._backend);

  static Future<TokenStore> create() async {
    final backend = await TokenStorageBackend.create();
    return TokenStore._(backend);
  }

  Future<String?> read() => _backend.read();

  Future<void> write(String token) => _backend.write(token);

  Future<void> clear() => _backend.clear();
}
