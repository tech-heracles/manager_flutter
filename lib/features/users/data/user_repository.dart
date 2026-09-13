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

  /// Admin/Supervisor accounts get a password-reset link to share (MVP: no
  /// outbound email yet). Operators have no real email — they get a 6-digit
  /// PIN the Admin sets directly, active immediately, meant for POS login.
  Future<({String? resetLink, String? pin})> invite({
    required String companyId,
    required String displayName,
    required UserRole role,
    String? email,
    String? pin,
    List<String> businessUnitIds = const [],
  }) async {
    final callable = _functions.httpsCallable('inviteUser');
    final result = await callable.call<Map<String, dynamic>>({
      'companyId': companyId,
      'displayName': displayName,
      'role': role.name,
      'businessUnitIds': businessUnitIds,
      if (email != null) 'email': email,
      if (pin != null) 'pin': pin,
    });
    return (
      resetLink: result.data['resetLink'] as String?,
      pin: result.data['pin'] as String?,
    );
  }

  Future<void> resetPin({required String uid, required String pin}) async {
    final callable = _functions.httpsCallable('resetOperatorPin');
    await callable.call<Map<String, dynamic>>({'uid': uid, 'pin': pin});
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
