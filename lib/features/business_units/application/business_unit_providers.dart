// lib/features/business_units/application/business_unit_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../data/business_unit_repository.dart';
import '../domain/business_unit.dart';

final businessUnitRepositoryProvider = Provider<BusinessUnitRepository>(
  (ref) => BusinessUnitRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: 'europe-west1'),
  ),
);

final businessUnitsStreamProvider = StreamProvider<List<BusinessUnit>>((ref) {
  final appUser = ref.watch(currentAppUserProvider).value;
  if (appUser == null || appUser.companyId.isEmpty) {
    return const Stream.empty();
  }
  return ref.watch(businessUnitRepositoryProvider).watchAll(appUser.companyId);
});
