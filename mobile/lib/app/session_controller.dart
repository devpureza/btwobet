import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/token_store.dart';
import '../features/achievements/achievements_repository.dart';
import '../features/admin/admin_repository.dart';
import '../features/auth/auth_repository.dart';
import '../features/history/history_repository.dart';
import '../features/matches/bolao_fund_repository.dart';
import '../features/matches/matches_repository.dart';
import '../features/matches/score_sync_repository.dart';
import '../features/ranking/ranking_repository.dart';

class SessionController extends ChangeNotifier {
  final TokenStore tokenStore;
  final AuthRepository auth;
  final MatchesRepository matches;
  final BolaoFundRepository bolaoFund;
  final ScoreSyncRepository scoreSync;
  final RankingRepository ranking;
  final HistoryRepository history;
  final AchievementsRepository achievements;
  final AdminRepository admin;

  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  int _achievementsUnlocked = 0;
  int _achievementsTotal = 0;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  bool get isAdmin => (_user?['is_admin'] as bool?) ?? false;
  int get achievementsUnlocked => _achievementsUnlocked;
  int get achievementsTotal => _achievementsTotal;

  SessionController._({
    required this.tokenStore,
    required this.auth,
    required this.matches,
    required this.bolaoFund,
    required this.scoreSync,
    required this.ranking,
    required this.history,
    required this.achievements,
    required this.admin,
  });

  static Future<SessionController> create(TokenStore tokenStore) async {
    final api = await ApiClient.create(tokenStore);

    final auth = AuthRepository(api.dio, tokenStore);
    final matches = MatchesRepository(api.dio);
    final bolaoFund = BolaoFundRepository(api.dio);
    final scoreSync = ScoreSyncRepository(api.dio);
    final ranking = RankingRepository(api.dio);
    final history = HistoryRepository(api.dio);
    final achievements = AchievementsRepository(api.dio);
    final admin = AdminRepository(api.dio);

    final controller = SessionController._(
      tokenStore: tokenStore,
      auth: auth,
      matches: matches,
      bolaoFund: bolaoFund,
      scoreSync: scoreSync,
      ranking: ranking,
      history: history,
      achievements: achievements,
      admin: admin,
    );

    await controller.refresh().timeout(const Duration(seconds: 12));
    return controller;
  }

  Future<void> refresh() async {
    final token = await tokenStore.read();
    _isLoggedIn = token != null && token.isNotEmpty;
    if (_isLoggedIn) {
      try {
        final me = await auth.me().timeout(const Duration(seconds: 8));
        _user = (me['user'] as Map).cast<String, dynamic>();
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          await tokenStore.clear();
          _isLoggedIn = false;
          _user = null;
          _achievementsUnlocked = 0;
          _achievementsTotal = 0;
        }
      } catch (_) {
        // Timeout/rede: trata como sem sessão para não prender o router na home.
        await tokenStore.clear();
        _isLoggedIn = false;
        _user = null;
        _achievementsUnlocked = 0;
        _achievementsTotal = 0;
      }
    } else {
      _user = null;
      _achievementsUnlocked = 0;
      _achievementsTotal = 0;
    }
    notifyListeners();

    if (_isLoggedIn) {
      await refreshAchievementStats();
    }
  }

  Future<void> refreshAchievementStats({List<dynamic>? catalog}) async {
    if (!_isLoggedIn) return;

    try {
      final items = catalog ??
          ((await achievements.getMyAchievements().timeout(const Duration(seconds: 8)))['catalog']
                  as List<dynamic>? ??
              []);
      _achievementsTotal = items.length;
      _achievementsUnlocked = items.where((item) {
        return ((item as Map)['unlocked'] as bool?) ?? false;
      }).length;
      notifyListeners();
    } catch (_) {
      // Mantém valores anteriores se a API falhar.
    }
  }

  Future<void> login(String email, String password) async {
    await auth.login(email: email, password: password);
    await refresh();
  }

  Future<String> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    return auth.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  Future<void> logout() async {
    await auth.logout();
    await refresh();
  }
}
