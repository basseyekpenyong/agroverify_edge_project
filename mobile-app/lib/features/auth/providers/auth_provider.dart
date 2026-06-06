import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/agent_model.dart';
import '../../../core/auth/rbac.dart';
import '../../../core/database/database_service.dart';

const _storage = FlutterSecureStorage();
const _keyAgentId = 'agent_id';
const _keyEncKey = 'db_enc_key';

class AuthState {
  final bool isAuthenticated;
  final AgentModel? agent;
  AuthState({required this.isAuthenticated, this.agent});
}

/// True when a device enc key has been stored — i.e. setup has been completed.
final isDeviceSetupProvider = FutureProvider<bool>((ref) async {
  final key = await _storage.read(key: _keyEncKey);
  return key != null;
});

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async => AuthState(isAuthenticated: false);

  Future<bool> login(String pin) async {
    state = const AsyncLoading();
    try {
      final encKey = pin;
      await openAppDatabase(encKey);

      final db = getDatabase();
      final rows = await db.query('agents', limit: 1);
      if (rows.isEmpty) {
        state = AsyncData(AuthState(isAuthenticated: false));
        return false;
      }

      final agent = AgentModel.fromMap(rows.first);
      await _storage.write(key: _keyAgentId, value: agent.id);
      await _storage.write(key: _keyEncKey, value: encKey);

      state = AsyncData(AuthState(isAuthenticated: true, agent: agent));
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Called once by the admin to provision this device for a field agent.
  Future<bool> setupDevice({
    required String name,
    required String region,
    required String cooperativeId,
    required UserRole role,
    required String pin,
  }) async {
    state = const AsyncLoading();
    try {
      final encKey = pin;
      await openAppDatabase(encKey);

      final db = getDatabase();
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc().toIso8601String();

      await db.insert('agents', {
        'id': id,
        'name': name,
        'pin_hash': pin,
        'region': region,
        'cooperative_id': cooperativeId,
        'role': role.value,
        'last_active': now,
        'created_at': now,
      });

      await _storage.write(key: _keyAgentId, value: id);
      await _storage.write(key: _keyEncKey, value: encKey);

      // Refresh setup check so router re-evaluates.
      ref.invalidate(isDeviceSetupProvider);

      final agent = AgentModel(
        id: id,
        name: name,
        pinHash: pin,
        region: region,
        cooperativeId: cooperativeId,
        role: role,
        lastActive: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
      );

      state = AsyncData(AuthState(isAuthenticated: true, agent: agent));
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = AsyncData(AuthState(isAuthenticated: false));
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
