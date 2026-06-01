import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/transaction_provider.dart';
import 'photo_capture_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String id;
  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionByIdProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: txnAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txn) {
          if (txn == null) return const Center(child: Text('Transaction not found'));
          final date = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(txn.timestampUtc).toLocal());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DetailCard(title: 'Commodity', value: txn.commodityType),
              _DetailCard(title: 'Weight', value: '${txn.weight} ${txn.unit}'),
              _DetailCard(title: 'Buyer', value: txn.buyerId),
              _DetailCard(title: 'Seller', value: txn.sellerId),
              _DetailCard(title: 'Timestamp', value: date),
              _DetailCard(
                title: 'GPS',
                value: '${txn.gpsLat.toStringAsFixed(6)}, ${txn.gpsLng.toStringAsFixed(6)}'
                    '${txn.gpsAccuracy != null ? ' (±${txn.gpsAccuracy!.toStringAsFixed(0)}m)' : ''}',
              ),
              _DetailCard(title: 'Sync Status', value: txn.syncStatus.toUpperCase()),
              _DetailCard(title: 'SHA-256 Hash', value: txn.integrityHash, mono: true),
              if (txn.notes != null) _DetailCard(title: 'Notes', value: txn.notes!),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: txn.isSynced
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PhotoCaptureScreen(transactionId: txn.id),
                          ),
                        ),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(txn.isSynced ? 'Synced — photos locked' : 'Add Photo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String value;
  final bool mono;
  const _DetailCard({required this.title, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontFamily: mono ? 'monospace' : null,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}
