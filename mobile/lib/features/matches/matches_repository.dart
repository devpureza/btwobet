import 'package:dio/dio.dart';

class MatchesRepository {
  final Dio _dio;

  MatchesRepository(this._dio);

  Future<List<dynamic>> listMatches() async {
    final res = await _dio.get('/matches');
    final data = res.data['data'] as List<dynamic>;
    return data;
  }

  Future<void> upsertPrediction({
    required int matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    await _dio.post('/predictions', data: {
      'match_id': matchId,
      'home_score': homeScore,
      'away_score': awayScore,
    });
  }
}
