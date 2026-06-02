import 'package:dio/dio.dart';

class AchievementsRepository {
  final Dio _dio;

  AchievementsRepository(this._dio);

  Future<Map<String, dynamic>> getMyAchievements() async {
    final res = await _dio.get('/me/achievements');
    return (res.data['data'] as Map).cast<String, dynamic>();
  }
}
