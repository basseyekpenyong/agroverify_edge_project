import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../../home/screens/home_screen.dart' show commodityColour;

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterStatus; // null = all

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txnsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search commodity, buyer, seller…',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // ── Filter chips ──────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', selected: _filterStatus == null,
                      onTap: () => setState(() => _filterStatus = null)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Pending', selected: _filterStatus == 'pending',
                      color: AppColors.warning,
                      onTap: () => setState(() => _filterStatus = 'pending')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Synced', selected: _filterStatus == 'synced',
                      color: AppColors.primary,
                      onTap: () => setState(() => _filterStatus = 'synced')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Failed', selected: _filterStatus == 'failed',
                      color: AppColors.error,
                      onTap: () => setState(() => _filterStatus = 'failed')),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // ── List ──────────────────────────────────────────────────
          Expanded(
            child: txnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final filtered = all.where((t) {
                  final matchesQuery = _query.isEmpty ||
                      t.commodityType.contains(_query) ||
                      t.buyerId.toLowerCase().contains(_query) ||
                      t.sellerId.toLowerCase().contains(_query);
                  final matchesStatus =
                      _filterStatus == null || t.syncStatus == _filterStatus;
                  return matchesQuery && matchesStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: AppColors.border),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty || _filterStatus != null
                              ? 'No results found'
                              : 'No transactions yet',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 15),
                        ),
                        if (_query.isEmpty && _filterStatus == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Tap + to record your first transaction',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 13)),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _TransactionTile(txn: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final TransactionModel txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy · HH:mm')
        .format(DateTime.parse(txn.timestampUtc).toLocal());
    final syncColor = switch (txn.syncStatus) {
      'synced' => AppColors.primary,
      'pending' => AppColors.warning,
      'failed' => AppColors.error,
      _ => AppColors.textSecondary,
    };
    final syncIcon = switch (txn.syncStatus) {
      'synced' => Icons.cloud_done_outlined,
      'pending' => Icons.cloud_upload_outlined,
      'failed' => Icons.cloud_off_outlined,
      _ => Icons.cloud_outlined,
    };
    final cc = commodityColour(txn.commodityType);
    final commodity =
        txn.commodityType[0].toUpperCase() + txn.commodityType.substring(1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: () => context.push('/transactions/${txn.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Commodity colour avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  txn.commodityType[0].toUpperCase(),
                  style: TextStyle(
                      color: cc, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(commodity,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: cc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${txn.weight} ${txn.unit}',
                            style: TextStyle(
                                fontSize: 11,
                                color: cc,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Text('${txn.buyerId}  →  ${txn.sellerId}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Sync status
              Column(
                children: [
                  Icon(syncIcon, color: syncColor, size: 20),
                  const SizedBox(height: 4),
                  Text(txn.syncStatus,
                      style: TextStyle(
                          fontSize: 10,
                          color: syncColor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
