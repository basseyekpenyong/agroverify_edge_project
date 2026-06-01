import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../../../core/database/transaction_dao.dart';

final transactionDaoProvider = Provider<TransactionDao>((_) => TransactionDao.fromSingleton());

final allTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final dao = ref.watch(transactionDaoProvider);
  final rows = await dao.getAll();
  return rows.map(TransactionModel.fromMap).toList();
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
