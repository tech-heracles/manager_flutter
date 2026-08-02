import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial async work needed — this just gives us an AsyncValue
    // (loading/data/error) to drive the login screen's UI.
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signIn(email.trim(), password);
    });
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendPasswordReset(email.trim());
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);