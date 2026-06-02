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
import '../ui/achievement_unlock_feed.dart';

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
  final Set<String> _knownUnlockedSlugs = {};
  final Set<String> _bannerDismissedSlugs = {};
  final List<Map<String, dynamic>> _recentUnlocks = [];

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  bool get isAdmin => (_user?['is_admin'] as bool?) ?? false;
  int get achievementsUnlocked => _achievementsUnlocked;
  int get achievementsTotal => _achievementsTotal;
  List<Map<String, dynamic>> get recentUnlocks => List.unmodifiable(_recentUnlocks);

  List<Map<String, dynamic>> get unreadRecentUnlocks => _recentUnlocks
      .where((item) => !_bannerDismissedSlugs.contains(item['slug'] as String?))
      .toList(growable: false);

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
          _knownUnlockedSlugs.clear();
        }
      } catch (_) {
        // Timeout/rede: trata como sem sessão para não prender o router na home.
        await tokenStore.clear();
        _isLoggedIn = false;
        _user = null;
        _achievementsUnlocked = 0;
        _achievementsTotal = 0;
        _knownUnlockedSlugs.clear();
      }
    } else {
      _user = null;
      _achievementsUnlocked = 0;
      _achievementsTotal = 0;
      _knownUnlockedSlugs.clear();
    }
    notifyListeners();

    if (_isLoggedIn) {
      await refreshAchievementStats();
    }
  }

  Future<void> refreshAchievementStats({List<dynamic>? catalog}) async {
    if (!_isLoggedIn) return;

    try {
      final payload = catalog == null
          ? await achievements.getMyAchievements().timeout(const Duration(seconds: 8))
          : null;
      final items = catalog ??
          (payload?['catalog'] as List<dynamic>? ?? []);
      final fromApi = payload == null
          ? const <Map<String, dynamic>>[]
          : (payload['newly_unlocked'] as List<dynamic>? ?? [])
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList();
      if (fromApi.isNotEmpty) {
        markUnlocksKnown(fromApi);
      }
      _achievementsTotal = items.length;
      _achievementsUnlocked = items.where((item) {
        return ((item as Map)['unlocked'] as bool?) ?? false;
      }).length;
      syncKnownUnlocks(items);
      notifyListeners();
    } catch (_) {
      // Mantém valores anteriores se a API falhar.
    }
  }

  /// Conquistas recém-desbloqueadas em relação ao último estado conhecido.
  List<Map<String, dynamic>> detectNewUnlocks(List<dynamic> catalog) {
    final fresh = <Map<String, dynamic>>[];
    for (final item in catalog) {
      final map = (item as Map).cast<String, dynamic>();
      final slug = map['slug'] as String?;
      final unlocked = map['unlocked'] as bool? ?? false;
      if (slug == null || !unlocked || _knownUnlockedSlugs.contains(slug)) continue;
      _knownUnlockedSlugs.add(slug);
      fresh.add(map);
    }
    return fresh;
  }

  void syncKnownUnlocks(List<dynamic> catalog) {
    for (final item in catalog) {
      final map = (item as Map).cast<String, dynamic>();
      final slug = map['slug'] as String?;
      final unlocked = map['unlocked'] as bool? ?? false;
      if (slug != null && unlocked) _knownUnlockedSlugs.add(slug);
    }
  }

  void markUnlocksKnown(Iterable<Map<String, dynamic>> unlocked) {
    for (final map in unlocked) {
      final slug = map['slug'] as String?;
      if (slug != null) _knownUnlockedSlugs.add(slug);
    }
    recordRecentUnlocks(unlocked);
  }

  void recordRecentUnlocks(Iterable<Map<String, dynamic>> unlocked) {
    for (final unlock in unlocked) {
      final slug = unlock['slug'] as String?;
      if (slug == null) continue;

      _bannerDismissedSlugs.remove(slug);
      _recentUnlocks.removeWhere((item) => item['slug'] == slug);
      _recentUnlocks.insert(0, {
        'slug': slug,
        'name': unlock['name'] as String? ?? 'Conquista',
        'tier': unlock['tier'] as String? ?? 'bronze',
        'recorded_at': DateTime.now().toIso8601String(),
      });
    }

    while (_recentUnlocks.length > 5) {
      final removed = _recentUnlocks.removeLast();
      final slug = removed['slug'] as String?;
      if (slug != null) _bannerDismissedSlugs.remove(slug);
    }
    notifyListeners();
  }

  void dismissRecentUnlockBanner({String? slug}) {
    if (slug != null) {
      _bannerDismissedSlugs.add(slug);
    } else {
      for (final item in _recentUnlocks) {
        final s = item['slug'] as String?;
        if (s != null) _bannerDismissedSlugs.add(s);
      }
    }
    notifyListeners();
  }

  void presentUnlockedAchievements(List<Map<String, dynamic>> unlocked) {
    if (unlocked.isEmpty) return;
    markUnlocksKnown(unlocked);
    showAchievementUnlocks(unlocked);
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
