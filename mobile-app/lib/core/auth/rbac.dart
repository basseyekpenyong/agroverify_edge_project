enum UserRole { fieldAgent, cooperativeManager, admin, enterprise }

extension UserRoleX on UserRole {
  String get value => switch (this) {
        UserRole.fieldAgent => 'field_agent',
        UserRole.cooperativeManager => 'cooperative_manager',
        UserRole.admin => 'admin',
        UserRole.enterprise => 'enterprise',
      };

  static UserRole fromString(String s) => switch (s) {
        'cooperative_manager' => UserRole.cooperativeManager,
        'admin' => UserRole.admin,
        'enterprise' => UserRole.enterprise,
        _ => UserRole.fieldAgent,
      };

  bool get canCreateTransactions =>
      this == UserRole.fieldAgent || this == UserRole.admin;

  bool get canViewAllTransactions =>
      this == UserRole.cooperativeManager || this == UserRole.admin;

  bool get canManageAgents => this == UserRole.admin;

  bool get canViewReports =>
      this == UserRole.cooperativeManager ||
      this == UserRole.admin ||
      this == UserRole.enterprise;
}
