import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageBackend {
  static const _key = 'auth_token';
  final FlutterSecureStorage _secure;

  TokenStorageBackend(this._secure);

  static Future<TokenStorageBackend> create() async {
    return TokenStorageBackend(const FlutterSecureStorage());
  }

  Future<String?> read() => _secure.read(key: _key);

  Future<void> write(String token) => _secure.write(key: _key, value: token);

  Future<void> clear() => _secure.delete(key: _key);
}
