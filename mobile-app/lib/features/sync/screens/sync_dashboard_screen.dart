import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../providers/sync_provider.dart';

class SyncDashboardScreen extends ConsumerWidget {
  const SyncDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingTransactionsProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final connectivity = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connectivity card
            _ConnectivityCard(isOnline: isOnline, connectivity: connectivity),
            const SizedBox(height: 12),

            // Pending transactions card
            pendingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (pending) => _PendingCard(count: pending.length),
            ),
            const SizedBox(height: 12),

            // Last sync result card
            if (syncState.lastSyncTime != null)
              _LastSyncCard(syncState: syncState),

            const Spacer(),

            // Sync Now button
            FilledButton.icon(
              onPressed: (isOnline && !syncState.isRunning) ? () => ref.read(syncStateProvider.notifier).triggerSync() : null,
              icon: syncState.isRunning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(syncState.isRunning ? 'Syncing…' : 'Sync Now'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOnline
                  ? 'Sync also runs automatically every 15 minutes in the background.'
                  : 'You are offline. Sync will run automatically when connectivity is restored.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectivityCard extends StatelessWidget {
  final bool isOnline;
  final AsyncValue<List<ConnectivityResult>> connectivity;
  const _ConnectivityCard({required this.isOnline, required this.connectivity});

  @override
  Widget build(BuildContext context) {
    final label = connectivity.when(
      data: (results) {
        if (results.contains(ConnectivityResult.wifi)) return 'WiFi';
        if (results.contains(ConnectivityResult.mobile)) return 'Mobile data';
        if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
        return 'Offline';
      },
      loading: () => 'Checking…',
      error: (_, __) => 'Unknown',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: isOnline ? AppColors.primary : AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isOnline ? AppColors.primary : AppColors.warning,
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final int count;
  const _PendingCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pending Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '$count transaction${count == 1 ? '' : 's'} waiting',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: count == 0 ? AppColors.primary : AppColors.warning,
              ),
            ),
            if (count > 0)
              const Text(
                'Stored securely offline — will sync when online.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _LastSyncCard extends StatelessWidget {
  final SyncState syncState;
  const _LastSyncCard({required this.syncState});

  @override
  Widget build(BuildContext context) {
    final hasError = syncState.lastError != null;
    final time = syncState.lastSyncTime;
    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '';

    return Card(
      color: hasError
          ? AppColors.error.withValues(alpha: 0.08)
          : AppColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasError ? Icons.error_outline : Icons.check_circle_outline,
                  color: hasError ? AppColors.error : AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  hasError ? 'Last sync failed' : 'Last sync successful',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasError ? AppColors.error : AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(timeStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            if (hasError) ...[
              const SizedBox(height: 4),
              Text(syncState.lastError!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                '${syncState.lastAccepted ?? 0} accepted · ${syncState.lastRejected ?? 0} rejected',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
