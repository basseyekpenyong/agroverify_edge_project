import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import '../../transactions/providers/transaction_provider.dart';

// ---------------------------------------------------------------------------
// Connectivity
// ---------------------------------------------------------------------------

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final conn = ref.watch(connectivityProvider);
  return conn.when(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    loading: () => false,
    error: (_, __) => false,
  );
});

// ---------------------------------------------------------------------------
// Sync state
// ---------------------------------------------------------------------------

class SyncState {
  final bool isRunning;
  final int? lastAccepted;
  final int? lastRejected;
  final String? lastError;
  final DateTime? lastSyncTime;

  const SyncState({
    this.isRunning = false,
    this.lastAccepted,
    this.lastRejected,
    this.lastError,
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isRunning,
    int? lastAccepted,
    int? lastRejected,
    String? lastError,
    DateTime? lastSyncTime,
    bool clearError = false,
  }) =>
      SyncState(
        isRunning: isRunning ?? this.isRunning,
        lastAccepted: lastAccepted ?? this.lastAccepted,
        lastRejected: lastRejected ?? this.lastRejected,
        lastError: clearError ? null : (lastError ?? this.lastError),
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      );

  bool get hadRecentSuccess =>
      lastSyncTime != null &&
      lastError == null &&
      DateTime.now().difference(lastSyncTime!) < const Duration(minutes: 5);
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  Future<void> triggerSync() async {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, clearError: true);

    try {
      final result = await SyncService().sync();

      state = state.copyWith(
        isRunning: false,
        lastAccepted: result.accepted,
        lastRejected: result.rejected,
        lastError: result.error,
        lastSyncTime: DateTime.now(),
      );

      // Refresh the pending count after a successful sync
      if (!result.hasError) {
        ref.invalidate(pendingTransactionsProvider);
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, lastError: e.toString());
    }
  }
}

final syncStateProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
