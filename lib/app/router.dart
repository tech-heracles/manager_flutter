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
import '../features/business_units/presentation/business_units_screen.dart';
import '../features/users/presentation/users_screen.dart';

/// Notifies go_router to re-run its redirect on every raw Firebase auth
/// change AND every time the derived app user (role/companyId claims)
/// finishes (re)loading. Listening only to auth state isn't enough: right
/// after sign-in, currentAppUserProvider is still fetching claims, the
/// redirect bails out early (isLoading), and nothing else would ever
/// prompt go_router to check again — leaving the user stuck on /login.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, _) => notifyListeners());
    ref.listen(currentAppUserProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
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
      GoRoute(
        path: '/business-units',
        builder: (context, state) => const BusinessUnitsScreen(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UsersScreen(),
      ),
    ],
  );
});
