import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

class SignUpController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Brand new person: create the Auth account, then the company.
  Future<void> signUpAndCreateCompany({
    required String email,
    required String password,
    required String companyName,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).createAccount(email, password);
      await ref.read(companyRepositoryProvider).createCompany(
            companyName: companyName,
            displayName: displayName,
          );
      await _waitForClaims();
    });
  }

  /// Already signed in (e.g. a previous createCompany call failed) —
  /// just retry the company creation.
  Future<void> completeCompanySetup({
    required String companyName,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(companyRepositoryProvider).createCompany(
            companyName: companyName,
            displayName: displayName,
          );
      await _waitForClaims();
    });
  }

  /// onUserWrite sets claims asynchronously after the Firestore write
  /// commits — poll briefly instead of assuming they're ready instantly.
  Future<void> _waitForClaims() async {
    final firebaseUser = ref.read(authRepositoryProvider).currentUser;
    final claimsRepo = ref.read(claimsRepositoryProvider);

    for (var attempt = 0; attempt < 6; attempt++) {
      final appUser = await claimsRepo.loadAppUser(firebaseUser);
      if (appUser != null && appUser.companyId.isNotEmpty) {
        ref.invalidate(currentAppUserProvider);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    throw Exception(
      'Company created, but access is still syncing. Wait a few seconds and try again.',
    );
  }
}

final signUpControllerProvider = AsyncNotifierProvider<SignUpController, void>(
  SignUpController.new,
);