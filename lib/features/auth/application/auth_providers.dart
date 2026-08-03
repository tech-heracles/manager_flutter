import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/claims_repository.dart';
import '../data/company_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(FirebaseAuth.instance));

final claimsRepositoryProvider =
    Provider<ClaimsRepository>((ref) => ClaimsRepository());

final companyRepositoryProvider = Provider<CompanyRepository>(
  (ref) => CompanyRepository(FirebaseFunctions.instance),
);

/// Raw Firebase sign-in/sign-out events.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Resolved app user (role, companyId, businessUnitIds), recomputed
/// every time the raw auth state changes.
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final firebaseUser = ref.watch(authStateChangesProvider).value;
  return ref.watch(claimsRepositoryProvider).loadAppUser(firebaseUser);
});