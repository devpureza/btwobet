import 'package:dio/dio.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  Future<List<dynamic>> listUsers({String? q}) async {
    final res = await _dio.get('/admin/users', queryParameters: q == null || q.isEmpty ? null : {'q': q});
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final res = await _dio.post('/admin/users', data: data);
    return (res.data['data'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/admin/users/$id', data: data);
    return (res.data['data'] as Map).cast<String, dynamic>();
  }

  Future<void> deleteUser(int id) async {
    await _dio.delete('/admin/users/$id');
  }

  Future<List<dynamic>> listMatches({String? group, String? stage, String? status}) async {
    final params = <String, dynamic>{};
    if (group != null && group.isNotEmpty) params['group'] = group;
    if (stage != null && stage.isNotEmpty) params['stage'] = stage;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await _dio.get('/admin/matches', queryParameters: params.isEmpty ? null : params);
    return res.data['data'] as List<dynamic>;
  }

  Future<void> updateMatch(int id, Map<String, dynamic> data) async {
    await _dio.patch('/admin/matches/$id', data: data);
  }

  Future<void> updateMatchResult(int id, {required String status, int? homeScore, int? awayScore}) async {
    await _dio.patch('/admin/matches/$id/result', data: {
      'status': status,
      if (homeScore != null) 'home_score': homeScore,
      if (awayScore != null) 'away_score': awayScore,
    });
  }

  Future<List<dynamic>> listTeams({String? q, String? group}) async {
    final params = <String, dynamic>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (group != null && group.isNotEmpty) params['group'] = group;
    final res = await _dio.get('/admin/teams', queryParameters: params.isEmpty ? null : params);
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateTeam(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/admin/teams/$id', data: data);
    return (res.data['data'] as Map).cast<String, dynamic>();
  }

  Future<String> uploadTeamFlag(int id, List<int> bytes, String filename) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post('/admin/teams/$id/flag', data: form);
    return (res.data['data']['flag_url'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> getPredictionRules() async {
    final res = await _dio.get('/admin/prediction-rules');
    return (res.data['data'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updatePredictionRules(Map<String, dynamic> data) async {
    final res = await _dio.patch('/admin/prediction-rules', data: data);
    return (res.data['data'] as Map).cast<String, dynamic>();
  }
}
