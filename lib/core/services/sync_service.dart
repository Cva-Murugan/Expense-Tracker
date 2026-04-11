import 'dart:io';
import 'package:flutter/rendering.dart';

// Local and remote repositories for expense data handling
import '../../features/expense/data/repositories/expense_local_repo.dart';
import '../../features/expense/data/repositories/expense_remote_repo.dart';
// Core services for network status and storage
import 'package:expense_tracker/core/services/network_service.dart';
import 'package:expense_tracker/core/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:expense_tracker/local_db/hive_boxes.dart';
import 'package:hive/hive.dart';

enum SyncStatus { loading, success, failed, noChanges }

class SyncResult {
  final SyncStatus status;
  final String? message;

  SyncResult(this.status, {this.message});
}

// Global provider for accessing the synchronization service
final syncProvider = Provider<SyncService>((ref) {
  return SyncService();
});

// Service that manages the synchronization between local Hive storage and remote Firebase
class SyncService {
  final _localRepo = ExpenseLocalRepo();
  final _remoteRepo = ExpenseRemoteRepo();

  // Performs a full synchronization check and updates data where needed
  Future<SyncResult> syncExpenses() async {
    try {
      final networkService = NetworkService();
      final isOnline = await networkService.checkNow();

      if (!isOnline) {
        return SyncResult(SyncStatus.failed, message: "No internet");
      }

      debugPrint("Sync started...");

      final localExpenses = _localRepo.getAllExpenses();
      final remoteExpenses = await _remoteRepo.fetchExpenses();

      final localIds = localExpenses.map((e) => e.id).toSet();
      final remoteIds = remoteExpenses.map((e) => e.id).toSet();

      if (localIds.containsAll(remoteIds) && remoteIds.containsAll(localIds)) {
        debugPrint("No sync needed (IDs match)");
        return SyncResult(SyncStatus.noChanges);
      }

      final idsToUpload = localIds.difference(remoteIds);

      if (idsToUpload.isNotEmpty) {
        debugPrint("Uploading ${idsToUpload.length} missing items...");

        final storageService = StorageService();

        for (var expense in localExpenses) {
          if (!idsToUpload.contains(expense.id)) continue;

          try {
            String finalFilePath = expense.filePath ?? '';

            // Upload file if it's local
            if (finalFilePath.isNotEmpty && !finalFilePath.startsWith('http')) {
              final file = File(finalFilePath);
              finalFilePath = await storageService.uploadFile(file);

              // update local model with URL
              expense.filePath = finalFilePath;
            }

            // Upload expense to Firestore
            await _remoteRepo.uploadExpense(expense);

            // Mark as synced
            expense.isSynced = true;
            await expense.save();
          } catch (e) {
            debugPrint("Upload failed for ${expense.id}: $e");
          }
        }
      }

      final idsToDelete = remoteIds.difference(localIds);

      if (idsToDelete.isNotEmpty) {
        debugPrint("Deleting ${idsToDelete.length} extra remote items...");

        for (var id in idsToDelete) {
          try {
            await _remoteRepo.deleteExpense(id);
            debugPrint("Deleted remote expense: $id");
          } catch (e) {
            debugPrint("Delete failed for $id: $e");
          }
        }
      }

      return SyncResult(SyncStatus.success);
    } catch (e) {
      debugPrint("Sync failed: $e");
      return SyncResult(SyncStatus.failed, message: e.toString());
    }
  }

  Future<void> syncIfNeeded() async {
    try {
      final box = Hive.box<ExpenseModel>(HiveBoxes.expenseBox);

      // if (box.isNotEmpty) {
      //   debugPrint("Sync skipped (local data exists)");
      //   return;
      // }

      debugPrint("SyncIfNeeded started...");

      final remoteRepo = ExpenseRemoteRepo();
      final expenses = await remoteRepo.fetchExpenses();

      final map = {for (var e in expenses) e.id: e};
      await box.putAll(map);

      debugPrint("SyncIfNeeded completed");
    } catch (e) {
      debugPrint("SyncIfNeeded error: $e");
    }
  }
}
