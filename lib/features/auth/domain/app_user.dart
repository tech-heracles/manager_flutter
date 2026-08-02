import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.companyId,
    required this.role,
    required this.businessUnitIds,
  });

  final String uid;
  final String? email;
  final String companyId;
  final UserRole role;
  final List<String> businessUnitIds;

  factory AppUser.fromClaims(
    String uid,
    String? email,
    Map<String, dynamic> claims,
  ) {
    return AppUser(
      uid: uid,
      email: email,
      companyId: claims['companyId'] as String? ?? '',
      role: UserRole.fromString(claims['role'] as String?),
      businessUnitIds: (claims['businessUnitIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}