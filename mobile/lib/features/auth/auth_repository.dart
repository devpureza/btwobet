import 'package:dio/dio.dart';

import '../../api/token_store.dart';

class AuthRepository {
  final Dio _dio;
  final TokenStore _tokenStore;

  AuthRepository(this._dio, this._tokenStore);

  Dio get dio => _dio;

  Future<String> login({required String email, required String password}) async {
    final res = await _dio.post('/login', data: {
      'email': email,
      'password': password,
    });

    final token = res.data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Token não retornado pelo backend');
    }

    await _tokenStore.write(token);
    return token;
  }

  Future<void> logout() async {
    await _tokenStore.clear();
  }

  Future<String?> getToken() => _tokenStore.read();

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('/me');
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.patch('/me', data: data);
    return (res.data['user'] as Map).cast<String, dynamic>();
  }
}
