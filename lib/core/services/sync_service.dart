import 'package:flutter/rendering.dart';

import '../../features/expense/data/repositories/expense_local_repo.dart';
import '../../features/expense/data/repositories/expense_remote_repo.dart';

class SyncService {
  final _localRepo = ExpenseLocalRepo();
  final _remoteRepo = ExpenseRemoteRepo();

  Future<void> syncExpenses() async {
    final expenses = _localRepo.getAllExpenses();

    for (var expense in expenses) {
      if (!expense.isSynced) {
        try {
          await _remoteRepo.uploadExpense(expense);

          // mark as synced
          expense.isSynced = true;
          await expense.save();
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    }
  }
}
