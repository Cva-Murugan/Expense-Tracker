import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../../../local_db/hive_boxes.dart';
import '../../../expense/data/repositories/expense_remote_repo.dart';
import '../../../expense/data/models/expense_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((
  ref,
) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  final _auth = FirebaseAuth.instance;

  void _init() {
    _auth.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  Future<void> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user == null) {
        throw Exception("Login failed. Please try again.");
      }

      final box = Hive.box<ExpenseModel>(HiveBoxes.expenseBox);
      await box.clear();

      final remoteRepo = ExpenseRemoteRepo();
      final expenses = await remoteRepo.fetchExpenses();

      for (var expense in expenses) {
        await box.put(expense.id, expense);
      }

      state = AsyncValue.data(user);
    } catch (e) {
      debugPrint(e.toString());
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> logout() async {
    await Hive.box<ExpenseModel>(HiveBoxes.expenseBox).clear();
    await _auth.signOut();
  }
}
