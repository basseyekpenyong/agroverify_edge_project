import '../../../core/auth/rbac.dart';

class AgentModel {
  final String id;
  final String name;
  final String pinHash;
  final String region;
  final String cooperativeId;
  final UserRole role;
  final DateTime? lastActive;
  final DateTime createdAt;

  const AgentModel({
    required this.id,
    required this.name,
    required this.pinHash,
    required this.region,
    required this.cooperativeId,
    required this.role,
    this.lastActive,
    required this.createdAt,
  });

  factory AgentModel.fromMap(Map<String, dynamic> m) => AgentModel(
        id: m['id'] as String,
        name: m['name'] as String,
        pinHash: m['pin_hash'] as String,
        region: m['region'] as String,
        cooperativeId: m['cooperative_id'] as String,
        role: UserRoleX.fromString(m['role'] as String),
        lastActive: m['last_active'] != null ? DateTime.parse(m['last_active'] as String) : null,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'pin_hash': pinHash,
        'region': region,
        'cooperative_id': cooperativeId,
        'role': role.value,
        'last_active': lastActive?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
