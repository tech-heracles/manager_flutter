// lib/features/users/domain/managed_user.dart
import '../../auth/domain/user_role.dart';

class ManagedUser {
  const ManagedUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.businessUnitIds,
    required this.active,
  });

  final String uid;
  final String displayName;
  final String? email;
  final UserRole role;
  final List<String> businessUnitIds;
  final bool active;

  factory ManagedUser.fromDoc(String uid, Map<String, dynamic> data) {
    return ManagedUser(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String?,
      role: UserRole.fromString(data['role'] as String?),
      businessUnitIds: (data['businessUnitIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      active: (data['status'] as String?) != 'inactive',
    );
  }
}
