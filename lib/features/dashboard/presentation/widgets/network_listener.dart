import 'package:expense_tracker/core/utils/snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/services/network_service.dart';
import 'package:expense_tracker/core/services/sync_service.dart';

final firstInitProvider = StateProvider<bool>((ref) => true);

class NetworkListener extends ConsumerWidget {
  final Widget child;

  const NetworkListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(networkStatusProvider, (previous, next) {
      next.whenData((isOnline) async {
        final isFirst = previous == null;
        final wasOnline = previous?.value ?? false;

        if (!isOnline && (wasOnline || isFirst)) {
          SnackbarManager.show(
            message: "No internet connection",
            backgroundColor: Colors.red,
          );
        }

        if (isOnline && (!wasOnline || isFirst)) {
          final isFirstInit = ref.read(firstInitProvider);

          if (isFirstInit) {
            await Future.delayed(const Duration(seconds: 2));

            ref.read(firstInitProvider.notifier).state = false;
          }

          SnackbarManager.show(message: "Syncing...");

          final result = await ref.read(syncProvider).syncExpenses();

          if (result.status == SyncStatus.success) {
            SnackbarManager.dismiss();
            SnackbarManager.show(
              message: "Sync success",
              backgroundColor: Colors.green,
            );
          } else if (result.status == SyncStatus.noChanges) {
            debugPrint("Sync No changes");
          } else {
            SnackbarManager.dismiss();
            SnackbarManager.show(
              message: "Sync failed: ${result.message}",
              backgroundColor: Colors.red,
            );
          }
        }
      });
    });

    return child;
  }
}
