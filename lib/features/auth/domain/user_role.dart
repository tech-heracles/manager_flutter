enum UserRole {
  admin,
  supervisor,
  operator;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      default:
        return UserRole.operator;
    }
  }

  // Only these two get past the app's login gate.
  bool get canAccessManagerApp =>
      this == UserRole.admin || this == UserRole.supervisor;

  // Permission helpers for later screens (invite users, configure ERP, etc).
  bool get canManageUsers => this == UserRole.admin;
  bool get canConfigureErp => this == UserRole.admin;
}