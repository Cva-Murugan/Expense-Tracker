enum ExpenseStep { info, category, document, review }

class ExpenseFormState {
  final String? title;
  final double? amount;
  final DateTime? date;
  final String? category;
  final String? notes;
  final String? filePath;
  final ExpenseStep currentStep;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  ExpenseFormState({
    this.title,
    this.amount,
    this.date,
    this.category,
    this.notes,
    this.filePath,
    this.currentStep = ExpenseStep.info,
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ExpenseFormState copyWith({
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
    String? filePath,
    ExpenseStep? currentStep,
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return ExpenseFormState(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      filePath: filePath ?? this.filePath,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
