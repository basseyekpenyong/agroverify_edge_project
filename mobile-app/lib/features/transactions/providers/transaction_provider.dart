import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../../../core/database/transaction_dao.dart';

final transactionDaoProvider = Provider<TransactionDao>((_) => TransactionDao.fromSingleton());

final allTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final dao = ref.watch(transactionDaoProvider);
  final rows = await dao.getAll();
  final list = rows.map(TransactionModel.fromMap).toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
});

final pendingTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final dao = ref.watch(transactionDaoProvider);
  final rows = await dao.getPending();
  return rows.map(TransactionModel.fromMap).toList();
});

final transactionByIdProvider = FutureProvider.family<TransactionModel?, String>((ref, id) async {
  final dao = ref.watch(transactionDaoProvider);
  final row = await dao.getById(id);
  return row == null ? null : TransactionModel.fromMap(row);
});

/// Summary stats for the home dashboard (recomputed from allTransactionsProvider).
class DashboardSummary {
  final int todayCount;
  final int allTimeCount;
  final String topCommodityToday;

  const DashboardSummary({
    required this.todayCount,
    required this.allTimeCount,
    required this.topCommodityToday,
  });
}

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final all = await ref.watch(allTransactionsProvider.future);
  final now = DateTime.now();

  final todayTxns = all.where((t) {
    final dt = DateTime.parse(t.timestampUtc).toLocal();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }).toList();

  final counts = <String, int>{};
  for (final t in todayTxns) {
    counts[t.commodityType] = (counts[t.commodityType] ?? 0) + 1;
  }
  final topCommodity = counts.isEmpty
      ? '—'
      : (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key;

  return DashboardSummary(
    todayCount: todayTxns.length,
    allTimeCount: all.length,
    topCommodityToday: topCommodity,
  );
});

/// Last 5 transactions for the home screen recent-activity list.
final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final all = await ref.watch(allTransactionsProvider.future);
  return all.take(5).toList(); // already sorted newest-first
});
