import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/agent_model.dart';
import '../../../core/database/database_service.dart';

const _storage = FlutterSecureStorage();
const _keyAgentId = 'agent_id';
const _keyEncKey = 'db_enc_key';

class AuthState {
  final bool isAuthenticated;
  final AgentModel? agent;
  AuthState({required this.isAuthenticated, this.agent});
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async => AuthState(isAuthenticated: false);

  Future<bool> login(String pin) async {
    state = const AsyncLoading();
    try {
      // Derive DB encryption key from PIN (in production: PBKDF2 derivation)
      final encKey = pin; // TODO: replace with PBKDF2(pin, salt)
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

  Future<void> logout() async {
    await _storage.deleteAll();
    state = AsyncData(AuthState(isAuthenticated: false));
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
