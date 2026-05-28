import 'package:dio/dio.dart';

class BolaoFundRepository {
  final Dio _dio;

  BolaoFundRepository(this._dio);

  Future<Map<String, dynamic>> getFund() async {
    final res = await _dio.get('/bolao/fund');
    return (res.data as Map).cast<String, dynamic>();
  }
}
