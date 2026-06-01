import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../transactions/providers/transaction_provider.dart';

class SyncDashboardScreen extends ConsumerWidget {
  const SyncDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingTransactionsProvider);

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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Connectivity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    // TODO: wire to connectivity_plus stream
                    const Row(
                      children: [
                        Icon(Icons.wifi_off, color: AppColors.warning),
                        SizedBox(width: 8),
                        Text('Offline — transactions queued for sync'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Pending count card
            pendingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (pending) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        '${pending.length} transaction${pending.length == 1 ? '' : 's'} waiting',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: pending.isEmpty ? AppColors.primary : AppColors.warning,
                        ),
                      ),
                      if (pending.isNotEmpty)
                        const Text(
                          'Will sync automatically when online',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Manual sync button (disabled offline — WorkManager handles auto-sync)
            FilledButton.icon(
              onPressed: null, // enabled only when online
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sync runs automatically in the background when connectivity is restored.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
