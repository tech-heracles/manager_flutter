// lib/features/users/application/user_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../data/user_repository.dart';
import '../domain/managed_user.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: 'europe-west1'),
  ),
);

final managedUsersStreamProvider = StreamProvider<List<ManagedUser>>((ref) {
  final appUser = ref.watch(currentAppUserProvider).value;
  if (appUser == null || appUser.companyId.isEmpty) {
    return const Stream.empty();
  }
  return ref.watch(userRepositoryProvider).watchAll(appUser.companyId);
});
