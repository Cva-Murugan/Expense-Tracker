import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'expense_form_state.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_local_repo.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/storage_service.dart';

final expenseFormProvider =
    StateNotifierProvider<ExpenseFormNotifier, ExpenseFormState>((ref) {
      return ExpenseFormNotifier();
    });

class ExpenseFormNotifier extends StateNotifier<ExpenseFormState> {
  ExpenseFormNotifier() : super(ExpenseFormState());

  void nextStep() {
    if (!validateCurrentStep()) return;

    switch (state.currentStep) {
      case ExpenseStep.info:
        state = state.copyWith(currentStep: ExpenseStep.category);
        break;
      case ExpenseStep.category:
        state = state.copyWith(currentStep: ExpenseStep.document);
        break;
      case ExpenseStep.document:
        state = state.copyWith(currentStep: ExpenseStep.review);
        break;
      case ExpenseStep.review:
        break;
    }
  }

  void previousStep() {
    switch (state.currentStep) {
      case ExpenseStep.category:
        state = state.copyWith(currentStep: ExpenseStep.info);
        break;
      case ExpenseStep.document:
        state = state.copyWith(currentStep: ExpenseStep.category);
        break;
      case ExpenseStep.review:
        state = state.copyWith(currentStep: ExpenseStep.document);
        break;
      case ExpenseStep.info:
        break;
    }
  }

  void updateTitle(String value) {
    state = state.copyWith(title: value);
  }

  void updateAmount(String value) {
    final parsed = double.tryParse(value);
    state = state.copyWith(amount: parsed);
  }

  void updateDate(DateTime value) {
    state = state.copyWith(date: value);
  }

  void updateCategory(String value) {
    state = state.copyWith(category: value);
  }

  void updateNotes(String value) {
    state = state.copyWith(notes: value);
  }

  void updateFile(String path) {
    state = state.copyWith(filePath: path);
  }

  bool validateCurrentStep() {
    switch (state.currentStep) {
      case ExpenseStep.info:
        if (state.title == null || state.title!.isEmpty) {
          state = state.copyWith(error: "Title is required");
          return false;
        }
        if (state.amount == null) {
          state = state.copyWith(error: "Valid amount required");
          return false;
        }
        if (state.date == null) {
          state = state.copyWith(error: "Date is required");
          return false;
        }
        break;

      case ExpenseStep.category:
        if (state.category == null || state.category!.isEmpty) {
          state = state.copyWith(error: "Category required");
          return false;
        }
        break;

      case ExpenseStep.document:
        break;

      case ExpenseStep.review:
        break;
    }

    state = state.copyWith(error: null);
    return true;
  }

  Future<void> submit() async {
    if (!validateCurrentStep()) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      String? uploadedUrl;

      if (state.filePath != null && state.filePath!.isNotEmpty) {
        final file = File(state.filePath!);

        final storageService = StorageService();
        uploadedUrl = await storageService.uploadFile(file);
      }

      final expense = ExpenseModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: state.title!,
        amount: state.amount!,
        date: state.date!,
        category: state.category!,
        notes: state.notes,
        filePath: uploadedUrl ?? 'empty',
        isSynced: false,
      );

      final repo = ExpenseLocalRepo();
      await repo.addExpense(expense);

      final syncService = SyncService();
      await syncService.syncExpenses();

      state = state.copyWith(isLoading: false);

      state = ExpenseFormState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
