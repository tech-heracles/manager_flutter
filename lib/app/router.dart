import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/access_denied_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/company_config/presentation/company_config_screen.dart';
import '../features/erp_config/presentation/erp_config_screen.dart';

/// Bridges a Stream into a Listenable so go_router knows when to
/// re-evaluate redirects (every time Firebase auth state changes).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges()),
    redirect: (context, state) {
      final appUserAsync = ref.read(currentAppUserProvider);
      final loggingIn = state.matchedLocation == '/login';
      final signingUp = state.matchedLocation == '/signup';

      // Still resolving claims after a state change — don't redirect yet.
      if (appUserAsync.isLoading) return null;

      final appUser = switch (appUserAsync) {
        AsyncData(:final value) => value,
        _ => null,
      };

      if (appUser == null) {
        return (loggingIn || signingUp) ? null : '/login';
      }
      if (appUser.companyId.isEmpty) {
        return signingUp ? null : '/signup';
      }
      if (!appUser.role.canAccessManagerApp) {
        return state.matchedLocation == '/access-denied'
            ? null
            : '/access-denied';
      }
      if (loggingIn || signingUp) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/access-denied',
        builder: (context, state) => const AccessDeniedScreen(),
      ),
      GoRoute(
        path: '/company-config',
        builder: (context, state) => const CompanyConfigScreen(),
      ),
      GoRoute(
        path: '/erp-config',
        builder: (context, state) => const ErpConfigScreen(),
      ),
    ],
  );
});
