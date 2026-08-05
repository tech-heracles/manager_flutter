// lib/features/company_config/application/company_config_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../data/company_config_repository.dart';
import '../domain/company_config.dart';

final companyConfigRepositoryProvider = Provider<CompanyConfigRepository>(
  (ref) => CompanyConfigRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: 'europe-west1'),
  ),
);

final companyConfigStreamProvider = StreamProvider<CompanyConfig>((ref) {
  final appUser = ref.watch(currentAppUserProvider).value;
  if (appUser == null || appUser.companyId.isEmpty) {
    return const Stream.empty();
  }
  return ref.watch(companyConfigRepositoryProvider).watch(appUser.companyId);
});