import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sync/providers/sync_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/models/transaction_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(authStateProvider).value?.agent;
    final isOnline = ref.watch(isOnlineProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final pendingAsync = ref.watch(pendingTransactionsProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(allTransactionsProvider);
            ref.invalidate(pendingTransactionsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // ── Header card ──────────────────────────────────────────
              _HeaderCard(agent: agent, isOnline: isOnline),
              const SizedBox(height: 20),

              // ── Stats grid ───────────────────────────────────────────
              summaryAsync.when(
                loading: () => _StatsGridShimmer(),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) => pendingAsync.when(
                  loading: () => _StatsGridShimmer(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (pending) => _StatsGrid(
                    todayCount: summary.todayCount,
                    allTimeCount: summary.allTimeCount,
                    pendingCount: pending.length,
                    topCommodity: summary.topCommodityToday,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── New transaction CTA ───────────────────────────────────
              FilledButton.icon(
                onPressed: () => context.push('/transactions/new'),
                icon: const Icon(Icons.add, size: 22),
                label: const Text('Record New Transaction',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 24),

              // ── Recent activity ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Activity',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () => context.go('/transactions'),
                    child: const Text('View all', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              recentAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
                data: (txns) => txns.isEmpty
                    ? _EmptyActivity()
                    : Column(
                        children: txns
                            .map((t) => _RecentTile(txn: t))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header card with gradient, agent info, live connectivity dot
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final dynamic agent;
  final bool isOnline;
  const _HeaderCard({required this.agent, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.58,
                    child: Image.asset('assets/images/logo.png', height: 48,
                        color: Colors.white, colorBlendMode: BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('AgroVy',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              _ConnectivityBadge(isOnline: isOnline),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hello, ${agent?.name ?? 'Agent'} 👋',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text('${agent?.region ?? ''}  ·  ${agent?.cooperativeId ?? ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          Text(today, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ConnectivityBadge extends StatelessWidget {
  final bool isOnline;
  const _ConnectivityBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isOnline ? Colors.greenAccent.shade400 : Colors.orangeAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          isOnline ? 'Online' : 'Offline',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats 2×2 grid
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int todayCount;
  final int allTimeCount;
  final int pendingCount;
  final String topCommodity;
  const _StatsGrid({
    required this.todayCount,
    required this.allTimeCount,
    required this.pendingCount,
    required this.topCommodity,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _StatCard(
          label: "Today's Transactions",
          value: '$todayCount',
          icon: Icons.receipt_long_outlined,
          color: AppColors.primary,
        ),
        _StatCard(
          label: 'All-time Verified',
          value: '$allTimeCount',
          icon: Icons.verified_outlined,
          color: const Color(0xFF7C3AED),
        ),
        _StatCard(
          label: 'Pending Sync',
          value: '$pendingCount',
          icon: Icons.cloud_upload_outlined,
          color: pendingCount > 0 ? AppColors.warning : AppColors.primary,
        ),
        _StatCard(
          label: "Today's Top Crop",
          value: topCommodity == '—'
              ? '—'
              : topCommodity[0].toUpperCase() + topCommodity.substring(1),
          icon: Icons.eco_outlined,
          color: const Color(0xFF0891B2),
          smallValue: topCommodity.length > 8,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool smallValue;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: smallValue ? 16 : 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGridShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent activity list
// ─────────────────────────────────────────────────────────────────────────────

class _RecentTile extends StatelessWidget {
  final TransactionModel txn;
  const _RecentTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(txn.timestampUtc).toLocal();
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr = isToday
        ? DateFormat('HH:mm').format(dt)
        : DateFormat('dd MMM').format(dt);

    final syncColor = switch (txn.syncStatus) {
      'synced' => AppColors.primary,
      'pending' => AppColors.warning,
      'failed' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    final commodityColor = commodityColour(txn.commodityType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => context.push('/transactions/${txn.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: commodityColor.withValues(alpha: 0.15),
          child: Text(
            txn.commodityType[0].toUpperCase(),
            style: TextStyle(color: commodityColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        title: Text(
          '${_capitalize(txn.commodityType)}  ·  ${txn.weight} ${txn.unit}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${txn.buyerId}  →  ${txn.sellerId}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: syncColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(txn.syncStatus,
                  style: TextStyle(fontSize: 10, color: syncColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(children: [
        Icon(Icons.inbox_outlined, size: 40, color: AppColors.border),
        SizedBox(height: 8),
        Text('No transactions yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        SizedBox(height: 4),
        Text('Tap "Record New Transaction" to get started',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared commodity helpers (used by list + detail screens too)
// ─────────────────────────────────────────────────────────────────────────────

Color commodityColour(String commodity) => switch (commodity) {
      'maize' => const Color(0xFFD97706),
      'cassava' => const Color(0xFFEA580C),
      'sorghum' => const Color(0xFF92400E),
      'rice' => const Color(0xFFCA8A04),
      'soy' => const Color(0xFF16A34A),
      'groundnuts' => const Color(0xFFA16207),
      'yam' => const Color(0xFFC2410C),
      'millet' => const Color(0xFF65A30D),
      'cocoa' => const Color(0xFF7C2D12),
      'palm_oil' => const Color(0xFFD97706),
      _ => AppColors.primary,
    };

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
