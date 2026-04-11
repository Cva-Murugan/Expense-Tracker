import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importing the sync service that handles communication between local and remote data
import 'package:expense_tracker/core/services/sync_service.dart';

// This provider tracks whether the sync process is currently running or not
final syncLoadingProvider = StateProvider<bool>((ref) => false);

// Helper function to trigger the sync process and manage the loading state
Future<void> runSync(WidgetRef ref) async {
  try {
    // Setting the loading state to true before starting the sync
    ref.read(syncLoadingProvider.notifier).state = true;

    // Accessing the sync provider and starting the expense synchronization
    final syncService = ref.read(syncProvider);
    await syncService.syncIfNeeded();
  } catch (e) {
    print("Sync failed: $e");
  } finally {
    ref.read(syncLoadingProvider.notifier).state = false;
  }
}
