import 'package:dio/dio.dart';

import 'hall_entry.dart';

class HallRepository {
  final Dio _dio;

  HallRepository(this._dio);

  Future<HallOfWeekData> getHallOfWeek() async {
    final res = await _dio.get('/hall-of-week');
    final data = res.data as Map<String, dynamic>? ?? {};
    return HallOfWeekData.fromJson(data);
  }
}
