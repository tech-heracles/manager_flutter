// lib/features/users/data/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../auth/domain/user_role.dart';
import '../domain/managed_user.dart';

class UserRepository {
  UserRepository(this._firestore, this._functions);
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<ManagedUser>> watchAll(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .orderBy('displayName')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ManagedUser.fromDoc(d.id, d.data())).toList());
  }

  /// Returns the password-reset link so the Admin can share it with the
  /// new operator (MVP: no outbound email yet).
  Future<String> invite({
    required String companyId,
    required String email,
    required String displayName,
    required UserRole role,
    List<String> businessUnitIds = const [],
  }) async {
    final callable = _functions.httpsCallable('inviteUser');
    final result = await callable.call<Map<String, dynamic>>({
      'companyId': companyId,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'businessUnitIds': businessUnitIds,
    });
    return result.data['resetLink'] as String? ?? '';
  }

  Future<void> updateUser({
    required String uid,
    UserRole? role,
    List<String>? businessUnitIds,
  }) async {
    final callable = _functions.httpsCallable('updateUser');
    await callable.call<Map<String, dynamic>>({
      'uid': uid,
      if (role != null) 'role': role.name,
      if (businessUnitIds != null) 'businessUnitIds': businessUnitIds,
    });
  }

  Future<void> setActive(String uid, bool active) async {
    final callable = _functions.httpsCallable('setUserActive');
    await callable.call<Map<String, dynamic>>({
      'uid': uid,
      'active': active,
    });
  }
}
