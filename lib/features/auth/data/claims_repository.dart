import 'package:firebase_auth/firebase_auth.dart';
import '../domain/app_user.dart';

class ClaimsRepository {
  Future<AppUser?> loadAppUser(User? firebaseUser) async {
    if (firebaseUser == null) return null;

    // forceRefresh matters: onUserWrite sets claims *after* the user doc
    // is written, so a cached token right after invite/login can be stale.
    final tokenResult = await firebaseUser.getIdTokenResult(true);
    final claims = tokenResult.claims ?? <String, dynamic>{};

    return AppUser.fromClaims(firebaseUser.uid, firebaseUser.email, claims);
  }
}