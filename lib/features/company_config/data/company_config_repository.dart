// lib/features/company_config/data/company_config_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/company_config.dart';

class CompanyConfigRepository {
  CompanyConfigRepository(this._firestore, this._functions);
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<CompanyConfig> watch(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .snapshots()
        .map((snap) => CompanyConfig.fromMap(snap.data() ?? {}));
  }

  Future<void> update(CompanyConfig config) async {
    final callable = _functions.httpsCallable('updateCompanyConfig');
    await callable.call<Map<String, dynamic>>(config.toUpdateMap());
  }
}