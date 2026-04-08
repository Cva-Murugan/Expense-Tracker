import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../../../../local_db/hive_boxes.dart';

class ExpenseLocalRepo {
  final Box<ExpenseModel> _box = Hive.box<ExpenseModel>(HiveBoxes.expenseBox);

  Future<void> addExpense(ExpenseModel expense) async {
    await _box.put(expense.id, expense);
  }

  List<ExpenseModel> getAllExpenses() {
    return _box.values.toList();
  }

  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }
}
