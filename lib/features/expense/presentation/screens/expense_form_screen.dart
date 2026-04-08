import 'package:expense_tracker/features/expense/presentation/widgets/step_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../providers/expense_form_notifier.dart';
import '../providers/expense_form_state.dart';

class ExpenseFormScreen extends ConsumerWidget {
  const ExpenseFormScreen({super.key});

  int getStepIndex(ExpenseStep step) {
    switch (step) {
      case ExpenseStep.info:
        return 0;
      case ExpenseStep.category:
        return 1;
      case ExpenseStep.document:
        return 2;
      case ExpenseStep.review:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseFormProvider);
    final notifier = ref.read(expenseFormProvider.notifier);

    ref.listen(expenseFormProvider, (previous, next) {
      if (next.isLoading && previous?.isLoading != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Submitting...")));
      }

      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }

      if (previous?.isLoading == true &&
          next.isLoading == false &&
          next.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Expense added successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pop(context);
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Add Expense"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardWrapper(
                  StepProgressIndicator(
                    currentStep: getStepIndex(state.currentStep),
                  ),
                ),

                const SizedBox(height: 20),

                _buildStepContent(state, notifier, context),

                const SizedBox(height: 30),

                Row(
                  children: [
                    if (state.currentStep != ExpenseStep.info)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: notifier.previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Back"),
                        ),
                      ),

                    if (state.currentStep != ExpenseStep.info)
                      const SizedBox(width: 10),

                    Expanded(
                      child: _primaryButton(
                        text: state.currentStep == ExpenseStep.review
                            ? "Submit"
                            : "Next",
                        isLoading: state.isLoading,
                        onTap: state.isLoading
                            ? null
                            : () {
                                if (state.currentStep == ExpenseStep.review) {
                                  notifier.submit();
                                } else {
                                  notifier.nextStep();
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardWrapper(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _modernTextField({
    required String label,
    TextInputType? type,
    Function(String)? onChanged,
  }) {
    return TextField(
      keyboardType: type,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromRGBO(39, 84, 138, 1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(text),
    );
  }

  Widget _uploadButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon), const SizedBox(width: 8), Text(text)],
        ),
      ),
    );
  }

  Widget _buildStepContent(
    ExpenseFormState state,
    ExpenseFormNotifier notifier,
    BuildContext context,
  ) {
    switch (state.currentStep) {
      case ExpenseStep.info:
        return _buildStep1(state, notifier, context);
      case ExpenseStep.category:
        return _buildStep2(state, notifier);
      case ExpenseStep.document:
        return _buildStep3(state, notifier);
      case ExpenseStep.review:
        return _buildStep4(state);
    }
  }

  Widget _buildStep1(
    ExpenseFormState state,
    ExpenseFormNotifier notifier,
    BuildContext context,
  ) {
    return _cardWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Expense Info",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _modernTextField(label: "Title", onChanged: notifier.updateTitle),
          const SizedBox(height: 10),

          _modernTextField(
            label: "Amount",
            type: TextInputType.number,
            onChanged: notifier.updateAmount,
          ),
          const SizedBox(height: 10),

          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) notifier.updateDate(picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    state.date == null
                        ? "Select Date"
                        : state.date.toString().split(" ")[0],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ExpenseFormState state, ExpenseFormNotifier notifier) {
    final categories = ["Food", "Travel", "Bills", "Others"];

    return _cardWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Category",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: state.category,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: categories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {
              if (value != null) notifier.updateCategory(value);
            },
          ),

          const SizedBox(height: 16),

          _modernTextField(
            label: "Notes (optional)",
            onChanged: notifier.updateNotes,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ExpenseFormState state, ExpenseFormNotifier notifier) {
    return _cardWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upload Receipt",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _uploadButton(
            text: "Pick Image",
            icon: Icons.image,
            onTap: () async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
              );

              if (picked != null) {
                final file = File(picked.path);
                final sizeInMB = file.lengthSync() / (1024 * 1024);

                if (sizeInMB > 5) {
                  notifier.updateFile("");
                  return;
                }

                notifier.updateFile(picked.path);
              }
            },
          ),

          const SizedBox(height: 10),

          _uploadButton(
            text: "Upload File",
            icon: Icons.attach_file,
            onTap: () async {
              FilePickerResult? result = await FilePicker.pickFiles(
                allowMultiple: true,
                type: FileType.custom,
                allowedExtensions: ['jpg', 'pdf', 'doc'],
              );

              if (result != null) {
                final file = File(result.files.single.path!);
                final sizeInMB = file.lengthSync() / (1024 * 1024);

                if (sizeInMB > 5) {
                  notifier.updateFile("");
                  return;
                }

                notifier.updateFile(file.path);
              }
            },
          ),

          const SizedBox(height: 20),

          if (state.filePath != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.filePath!.split('/').last,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep4(ExpenseFormState state) {
    return _cardWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Review Expense",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          _item("Title", state.title),
          _item("Amount", state.amount?.toString()),
          _item("Date", state.date?.toString().split(" ")[0]),
          _item("Category", state.category),
          _item("Notes", state.notes ?? "-"),
          _item("File", state.filePath?.split('/').last ?? "No file"),

          const SizedBox(height: 20),

          const Text(
            "Please confirm before submitting",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _item(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? "-")),
        ],
      ),
    );
  }
}
