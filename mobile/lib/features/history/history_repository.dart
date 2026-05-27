import 'package:dio/dio.dart';

class HistoryRepository {
  final Dio _dio;

  HistoryRepository(this._dio);

  Future<Map<String, dynamic>> getMyHistory() async {
    final res = await _dio.get('/me/history');
    return (res.data as Map).cast<String, dynamic>();
  }
}
