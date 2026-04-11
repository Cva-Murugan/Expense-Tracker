import 'dart:io';
import 'package:expense_tracker/core/utils/snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_local_repo.dart';
import '../../data/repositories/expense_remote_repo.dart';
import 'fullscreen_viewer.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  final ExpenseLocalRepo _localRepo = ExpenseLocalRepo();
  final ExpenseRemoteRepo _remoteRepo = ExpenseRemoteRepo();

  ExpenseDetailScreen({super.key, required this.expense});

  bool get isImage {
    final path = expense.filePath ?? "";
    return path.endsWith(".jpg") ||
        path.endsWith(".png") ||
        path.endsWith(".jpeg");
  }

  bool get hasFile => expense.filePath != null && expense.filePath!.isNotEmpty;

  Future<void> openFile() async {
    if (expense.filePath != null) {
      final url = Uri.parse(expense.filePath!);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        print("Could not open file");
      }
    }
  }

  Future<void> _deleteExpense(BuildContext context) async {
    try {
      Navigator.pop(context, expense.id);

      await _localRepo.deleteExpense(expense.id);

      try {
        await _remoteRepo.deleteExpense(expense.id);
      } catch (e) {
        debugPrint('delete error: ${e.toString()}');
      }
    } catch (e) {
      if (!context.mounted) return;
      SnackbarManager.show(message: "Delete failed. Please try again.");

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Delete failed. Please try again.")),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    //hides snacbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SnackbarManager.dismiss();
    });
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Expense Details"),
        //backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        //      elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹ ${expense.amount}",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _card(
              child: Row(
                children: [
                  const Icon(Icons.category, color: Colors.indigo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      expense.category,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    expense.date.toString().split(" ")[0],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (hasFile)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Document",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenViewer(
                              pathOrUrl: expense.filePath!,
                              productName: expense.id, // local OR firebase
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildPreview(expense.filePath!),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            if (expense.notes != null && expense.notes!.isNotEmpty)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Notes",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      expense.notes!,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => _showDeleteDialog(context),
          icon: const Icon(Icons.delete),
          label: const Text("Delete Expense"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPreview(String path) {
    final lower = path.toLowerCase();

    final isImage =
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    final isPdf = lower.endsWith('.pdf');

    // IMAGE PREVIEW
    if (isImage) {
      if (path.startsWith("http")) {
        return Image.network(
          path,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          File(path),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    // PDF PREVIEW (simple placeholder)
    if (isPdf) {
      return Container(
        height: 120,
        width: double.infinity,
        color: Colors.red.shade50,
        child: const Center(
          child: Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
        ),
      );
    }

    // OTHER FILES
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.insert_drive_file, size: 50)),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text("Are you sure you want to delete this expense?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              _deleteExpense(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
