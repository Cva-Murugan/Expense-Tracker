import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseRemoteRepo {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> uploadExpense(ExpenseModel expense) async {
    final userId = _auth.currentUser!.uid;

    await _firestore
        .collection("users")
        .doc(userId)
        .collection("expenses")
        .doc(expense.id)
        .set({
          "id": expense.id,
          "title": expense.title,
          "amount": expense.amount,
          "date": expense.date.toIso8601String(),
          "category": expense.category,
          "notes": expense.notes,
          "filePath": expense.filePath,
        });
  }

  Future<List<ExpenseModel>> fetchExpenses() async {
    final userId = _auth.currentUser!.uid;

    final snapshot = await _firestore
        .collection("users")
        .doc(userId)
        .collection("expenses")
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return ExpenseModel(
        id: data['id'],
        title: data['title'],
        amount: (data['amount'] as num).toDouble(),
        date: DateTime.parse(data['date']),
        category: data['category'],
        notes: data['notes'],
        filePath: data['filePath'],
        isSynced: true,
      );
    }).toList();
  }
}
