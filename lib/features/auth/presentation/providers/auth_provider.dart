//import 'package:flutter/widgets.dart';
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
    _auth.authStateChanges().listen((user) async {
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

      // here i need to set
      final user = result.user;

      if (user == null) {
        print("Login failed. Please try again.");
      }

      //  final box = Hive.box<ExpenseModel>(HiveBoxes.expenseBox);
      // await box.clear();

      // final remoteRepo = ExpenseRemoteRepo();
      // final expenses = await remoteRepo.fetchExpenses();

      // for (var expense in expenses) {
      //   await box.put(expense.id, expense);
      // }

      state = AsyncValue.data(user);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(_mapFirebaseError(e), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(
        "Something went wrong. Try again.",
        StackTrace.current,
      );
    }
  }

  Future<void> logout() async {
    await Hive.box<ExpenseModel>(HiveBoxes.expenseBox).clear();
    await _auth.signOut();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No account found with this email.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'invalid-email':
        return "Invalid email format.";
      case 'user-disabled':
        return "This account has been disabled.";
      case 'too-many-requests':
        return "Too many attempts. Try again later.";
      case 'network-request-failed':
        return "No internet connection.";
      default:
        return "Login failed. Please try again.";
    }
  }
}
