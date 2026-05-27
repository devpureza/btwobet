import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/token_store.dart';
import '../features/admin/admin_repository.dart';
import '../features/auth/auth_repository.dart';
import '../features/history/history_repository.dart';
import '../features/matches/matches_repository.dart';
import '../features/ranking/ranking_repository.dart';

class SessionController extends ChangeNotifier {
  final TokenStore tokenStore;
  final AuthRepository auth;
  final MatchesRepository matches;
  final RankingRepository ranking;
  final HistoryRepository history;
  final AdminRepository admin;

  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  bool get isAdmin => (_user?['is_admin'] as bool?) ?? false;

  SessionController._({
    required this.tokenStore,
    required this.auth,
    required this.matches,
    required this.ranking,
    required this.history,
    required this.admin,
  });

  static Future<SessionController> create(TokenStore tokenStore) async {
    final api = await ApiClient.create(tokenStore);

    final auth = AuthRepository(api.dio, tokenStore);
    final matches = MatchesRepository(api.dio);
    final ranking = RankingRepository(api.dio);
    final history = HistoryRepository(api.dio);
    final admin = AdminRepository(api.dio);

    final controller = SessionController._(
      tokenStore: tokenStore,
      auth: auth,
      matches: matches,
      ranking: ranking,
      history: history,
      admin: admin,
    );

    await controller.refresh();
    return controller;
  }

  Future<void> refresh() async {
    final token = await tokenStore.read();
    _isLoggedIn = token != null && token.isNotEmpty;
    if (_isLoggedIn) {
      try {
        final me = await auth.me().timeout(const Duration(seconds: 8));
        _user = (me['user'] as Map).cast<String, dynamic>();
      } catch (_) {
        // Mantém logged in; UI pode pedir refresh.
      }
    } else {
      _user = null;
    }
    notifyListeners();
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
