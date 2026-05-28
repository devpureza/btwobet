import 'package:dio/dio.dart';

class ScoreSyncRepository {
  final Dio _dio;

  ScoreSyncRepository(this._dio);

  Future<Map<String, dynamic>> getStatus() async {
    final res = await _dio.get('/score-sync/status');
    return (res.data as Map).cast<String, dynamic>();
  }
}
