import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nowplaying/features/auth/domain/user_model.dart';
import 'package:nowplaying/features/auth/presentation/auth_screen.dart';
import 'package:nowplaying/features/birthday/presentation/birthday_admin_screen.dart';
import 'package:nowplaying/features/birthday/presentation/birthday_experience_screen.dart';
import 'package:nowplaying/features/feed/presentation/feed_screen.dart';
import 'package:nowplaying/features/friends/presentation/friends_screen.dart';
import 'package:nowplaying/features/profile/presentation/profile_screen.dart';
import 'package:nowplaying/shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAuth = state.matchedLocation.startsWith('/auth');
      if (user == null && !isAuth) return '/auth';
      if (user != null && isAuth) return '/';
      return null;
    },
    refreshListenable: _AuthChangeNotifier(),
    routes: [
      GoRoute(path: '/auth', pageBuilder: (context, state) => _fadeRoute(const AuthScreen(), state)),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (context, state) => _fadeRoute(const FeedScreen(), state)),
          GoRoute(path: '/friends', pageBuilder: (context, state) => _fadeRoute(const FriendsScreen(), state)),
          GoRoute(path: '/profile', pageBuilder: (context, state) => _fadeRoute(const ProfileScreen(), state)),
        ],
      ),
      GoRoute(
        path: '/birthday-experience',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return BirthdayExperienceScreen(content: extra['content'], year: extra['year'] as int);
        },
      ),
      GoRoute(
        path: '/birthday-setup',
        builder: (context, state) {
          final user = state.extra as UserModel;

          return PartnerBirthdaySurpriseScreen(user: user);
        },
      ),
    ],
  );
});

CustomTransitionPage<void> _fadeRoute(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, anim, _, c) => FadeTransition(opacity: anim, child: c),
    transitionDuration: const Duration(milliseconds: 200),
  );
}

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}
