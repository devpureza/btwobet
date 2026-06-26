import 'package:dio/dio.dart';

class RankingRepository {
  final Dio _dio;

  RankingRepository(this._dio);

  Future<List<dynamic>> getRanking() async {
    final res = await _dio.get('/ranking');
    return res.data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getUserPredictions(int userId) async {
    final res = await _dio.get('/ranking/$userId/predictions');
    return res.data['data'] as List<dynamic>;
  }
}
