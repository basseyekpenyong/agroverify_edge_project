import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/transaction_provider.dart';
import 'photo_capture_screen.dart';
import '../../home/screens/home_screen.dart' show commodityColour;

class TransactionDetailScreen extends ConsumerWidget {
  final String id;
  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionByIdProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: txnAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txn) {
          if (txn == null) return const Center(child: Text('Transaction not found'));

          final cc = commodityColour(txn.commodityType);
          final commodity =
              txn.commodityType[0].toUpperCase() + txn.commodityType.substring(1);
          final date = DateFormat('dd MMM yyyy, HH:mm')
              .format(DateTime.parse(txn.timestampUtc).toLocal());
          final syncColor = switch (txn.syncStatus) {
            'synced' => AppColors.primary,
            'pending' => AppColors.warning,
            'failed' => AppColors.error,
            _ => AppColors.textSecondary,
          };

          return CustomScrollView(
            slivers: [
              // ── Coloured hero AppBar ───────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: cc,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cc, cc.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  txn.commodityType[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(commodity,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22)),
                                    Text('${txn.weight} ${txn.unit}',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  txn.syncStatus.toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Content ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _SectionHeader('Transaction Info'),
                    _DetailCard(icon: Icons.person_outline, label: 'Buyer', value: txn.buyerId),
                    _DetailCard(icon: Icons.storefront_outlined, label: 'Seller', value: txn.sellerId),
                    _DetailCard(icon: Icons.access_time_outlined, label: 'Timestamp', value: date),
                    if (txn.notes != null && txn.notes!.isNotEmpty)
                      _DetailCard(icon: Icons.notes_outlined, label: 'Notes', value: txn.notes!),

                    const SizedBox(height: 8),
                    const _SectionHeader('Location & Integrity'),
                    _DetailCard(
                      icon: Icons.gps_fixed,
                      label: 'GPS Coordinates',
                      value: '${txn.gpsLat.toStringAsFixed(6)}, ${txn.gpsLng.toStringAsFixed(6)}'
                          '${txn.gpsAccuracy != null ? '\n±${txn.gpsAccuracy!.toStringAsFixed(0)} m accuracy' : ''}',
                    ),
                    _DetailCard(
                      icon: Icons.fingerprint,
                      label: 'SHA-256 Integrity Hash',
                      value: txn.integrityHash,
                      mono: true,
                    ),

                    const SizedBox(height: 8),
                    const _SectionHeader('Sync Status'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: syncColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: syncColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        Icon(
                          txn.isSynced
                              ? Icons.cloud_done
                              : txn.syncStatus == 'failed'
                                  ? Icons.cloud_off
                                  : Icons.cloud_upload,
                          color: syncColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            txn.isSynced
                                ? 'Synced to server'
                                : txn.syncStatus == 'failed'
                                    ? 'Sync failed — will retry automatically'
                                    : 'Pending sync — stored securely offline',
                            style: TextStyle(
                                color: syncColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ]),
                    ),

                    OutlinedButton.icon(
                      onPressed: txn.isSynced
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    PhotoCaptureScreen(transactionId: txn.id),
                              )),
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(
                          txn.isSynced ? 'Synced — photos locked' : 'Add Photo'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: cc),
                        foregroundColor: cc,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.8)),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontFamily: mono ? 'monospace' : null,
                        color: AppColors.textPrimary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
