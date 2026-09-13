// lib/features/business_units/data/business_unit_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/business_unit.dart';

class BusinessUnitRepository {
  BusinessUnitRepository(this._firestore, this._functions);
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<BusinessUnit>> watchAll(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('businessUnits')
        .orderBy('name')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BusinessUnit.fromDoc(d.id, d.data())).toList());
  }

  Future<void> create({
    required String name,
    String? address,
    String? code,
    String? defaultCustomerCode,
    String? defaultLocationCode,
  }) async {
    final callable = _functions.httpsCallable('createBusinessUnit');
    await callable.call<Map<String, dynamic>>({
      'name': name,
      if (address != null) 'address': address,
      if (code != null) 'code': code,
      if (defaultCustomerCode != null) 'defaultCustomerCode': defaultCustomerCode,
      if (defaultLocationCode != null) 'defaultLocationCode': defaultLocationCode,
    });
  }

  Future<void> update({
    required String businessUnitId,
    required String name,
    String? address,
    String? code,
    String? defaultCustomerCode,
    String? defaultLocationCode,
  }) async {
    final callable = _functions.httpsCallable('updateBusinessUnit');
    await callable.call<Map<String, dynamic>>({
      'businessUnitId': businessUnitId,
      'name': name,
      'address': address,
      'code': code,
      'defaultCustomerCode': defaultCustomerCode,
      'defaultLocationCode': defaultLocationCode,
    });
  }

  Future<void> delete(String businessUnitId) async {
    final callable = _functions.httpsCallable('deleteBusinessUnit');
    await callable.call<Map<String, dynamic>>({
      'businessUnitId': businessUnitId,
    });
  }
}
