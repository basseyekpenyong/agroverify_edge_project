import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: txnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txns) => txns.isEmpty
            ? const Center(child: Text('No transactions yet.\nTap + to create one.', textAlign: TextAlign.center))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: txns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _TransactionTile(txn: txns[i]),
              ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(txn.timestampUtc).toLocal());
    final syncColor = switch (txn.syncStatus) {
      'synced' => AppColors.primary,
      'pending' => AppColors.warning,
      'failed' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return Card(
      child: ListTile(
        onTap: () => context.push('/transactions/${txn.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha:0.1),
          child: const Icon(Icons.agriculture, color: AppColors.primary),
        ),
        title: Text('${txn.commodityType} — ${txn.weight} ${txn.unit}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Chip(
          label: Text(txn.syncStatus, style: TextStyle(color: syncColor, fontSize: 11)),
          backgroundColor: syncColor.withValues(alpha:0.1),
          side: BorderSide(color: syncColor.withValues(alpha:0.3)),
        ),
      ),
    );
  }
}
