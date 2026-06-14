import 'package:dio/dio.dart';

class MatchesRepository {
  final Dio _dio;

  MatchesRepository(this._dio);

  Future<List<dynamic>> listMatches() async {
    final res = await _dio.get('/matches');
    final data = res.data['data'] as List<dynamic>;
    return data;
  }

  Future<List<Map<String, dynamic>>> upsertPrediction({
    required int matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    final res = await _dio.post('/predictions', data: {
      'match_id': matchId,
      'home_score': homeScore,
      'away_score': awayScore,
    });
    final raw = res.data['new_achievements'] as List<dynamic>? ?? [];
    return raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<List<Map<String, dynamic>>> listMatchPredictions(int matchId) async {
    final res = await _dio.get('/matches/$matchId/predictions');
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }
}
