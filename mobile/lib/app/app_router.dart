import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/admin/admin_prediction_rules_screen.dart';
import '../features/admin/admin_matches_screen.dart';
import '../features/admin/admin_teams_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/admin/admin_users_screen.dart';
import '../features/history/history_screen.dart';
import '../features/matches/matches_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/ranking/ranking_screen.dart';
import 'session_controller.dart';
import '../ui/glass.dart';
import '../ui/shell_header.dart';

class AppRouter {
  static GoRouter create(SessionController session) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: session,
      redirect: (context, state) {
        final loggedIn = session.isLoggedIn;
        final goingToLogin = state.matchedLocation == '/login';

        if (!loggedIn && !goingToLogin) {
          return '/login';
        }
        if (loggedIn && goingToLogin) {
          return '/';
        }
        if (loggedIn && state.matchedLocation.startsWith('/admin') && !session.isAdmin) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(session: session),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return HomeShell(session: session, child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => MatchesScreen(session: session),
            ),
            GoRoute(
              path: '/ranking',
              builder: (context, state) => RankingScreen(session: session),
            ),
            GoRoute(
              path: '/history',
              builder: (context, state) => HistoryScreen(session: session),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => ProfileScreen(session: session),
            ),
            GoRoute(
              path: '/admin',
              builder: (context, state) => AdminScreen(session: session),
            ),
            GoRoute(
              path: '/admin/users',
              builder: (context, state) => AdminUsersScreen(session: session),
            ),
            GoRoute(
              path: '/admin/matches',
              builder: (context, state) => AdminMatchesScreen(session: session),
            ),
            GoRoute(
              path: '/admin/teams',
              builder: (context, state) => AdminTeamsScreen(session: session),
            ),
            GoRoute(
              path: '/admin/prediction-rules',
              builder: (context, state) => AdminPredictionRulesScreen(session: session),
            ),
          ],
        ),
      ],
    );
  }
}

class HomeShell extends StatelessWidget {
  final SessionController session;
  final Widget child;

  const HomeShell({super.key, required this.session, required this.child});

  bool _isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

  List<_NavItem> _items() {
    final base = <_NavItem>[
      _NavItem(route: '/', icon: Icons.sports_soccer, label: 'Palpites'),
      _NavItem(route: '/ranking', icon: Icons.leaderboard, label: 'Ranking'),
      _NavItem(route: '/history', icon: Icons.history, label: 'Histórico'),
      _NavItem(route: '/profile', icon: Icons.account_circle, label: 'Conta'),
    ];

    if (session.isAdmin) {
      base.add(_NavItem(route: '/admin', icon: Icons.admin_panel_settings, label: 'Admin'));
    }
    return base;
  }

  int _indexForLocation(String location, List<_NavItem> items) {
    for (var i = 0; i < items.length; i++) {
      final r = items[i].route;
      if (r == '/') {
        if (location == '/' || location.isEmpty) return i;
        continue;
      }
      if (location.startsWith(r)) return i;
    }
    return 0;
  }

  void _goForIndex(BuildContext context, int i) {
    final items = _items();
    if (i < 0 || i >= items.length) return;
    context.go(items[i].route);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final items = _items();
    final index = _indexForLocation(location, items);
    final isDesktop = _isDesktop(context);
    final extendedRail = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  Glass(
                    blur: 18,
                    borderRadius: BorderRadius.circular(0),
                    padding: EdgeInsets.zero,
                    child: NavigationRail(
                      selectedIndex: index,
                      onDestinationSelected: (i) => _goForIndex(context, i),
                      extended: extendedRail,
                      labelType: extendedRail ? null : NavigationRailLabelType.all,
                      groupAlignment: -0.75,
                      destinations: items
                          .map(
                            (it) => NavigationRailDestination(
                              icon: Icon(it.icon),
                              label: Text(it.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ShellHeader(location: location, session: session),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShellHeader(location: location, session: session),
                  Expanded(child: child),
                ],
              ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Glass(
              blur: 18,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              padding: EdgeInsets.zero,
              boxShadow: const [
                BoxShadow(color: Color(0x1400341C), blurRadius: 24, offset: Offset(0, -8)),
              ],
              child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => _goForIndex(context, i),
                destinations: items
                    .map(
                      (it) => NavigationDestination(icon: Icon(it.icon), label: it.label),
                    )
                    .toList(growable: false),
              ),
            ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.label,
  });
}
