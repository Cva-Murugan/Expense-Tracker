// Core utility for showing feedback messages
import 'package:expense_tracker/core/utils/snackbar_manager.dart';
// Authentication provider to handle login state
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
// Detailed analytics and charts screen
import 'package:expense_tracker/features/dashboard/presentation/screens/analytic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Local database imports
import 'package:hive_flutter/hive_flutter.dart';

import '../../../expense/data/models/expense_model.dart';
import '../../../../local_db/hive_boxes.dart';
import 'package:expense_tracker/features/expense/presentation/screens/expense_form_screen.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/features/expense/presentation/screens/expense_detail_screen.dart';
// Provider for managing synchronization state
import 'package:expense_tracker/features/auth/presentation/providers/sync_loader_provider.dart';

enum ExpenseFilter { all, today, yesterday, week, month }

enum SortType { newest, oldest, highAmount, lowAmount }

final sortProvider = StateProvider<SortType>((ref) => SortType.newest);

final selectedFilterProvider = StateProvider<ExpenseFilter>(
  (ref) => ExpenseFilter.all,
);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      runSync(ref); // 🔥 THIS CALLS SYNC
    });
  }

  String getCategoryImage(String category) {
    switch (category.toLowerCase()) {
      case "food":
        return "assets/images/icons/chicken.png";
      case "travel":
        return "assets/images/icons/travel.png";
      case "bills":
        return "assets/images/icons/receipt.png";
      default:
        return "assets/images/icons/others.png";
    }
  }

  final filters = {
    ExpenseFilter.all: "All",
    ExpenseFilter.today: "Today",
    ExpenseFilter.yesterday: "Yesterday",
    ExpenseFilter.week: "This Week",
    ExpenseFilter.month: "This Month",
  };

  final currentPageProvider = StateProvider<int>((ref) => 1);
  final itemsPerPage = 4;

  // Core build method that sets up the main layout and state listeners
  @override
  Widget build(BuildContext contex) {
    final selectedFilter = ref.watch(selectedFilterProvider);
    final authState = ref.watch(authProvider);
    final isSyncing = ref.watch(syncLoadingProvider);

    return Scaffold(
      appBar: appbar(context, ref),
      backgroundColor: const Color(0xFFF5F7FB),

      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(child: Text(e.toString())),

        data: (user) {
          if (isSyncing) {
            return const Center(child: CircularProgressIndicator());
          }

          final box = Hive.box<ExpenseModel>(HiveBoxes.expenseBox);

          return valueListenableBuilder(box, selectedFilter, ref);
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  AppBar appbar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text(
        "Expense Tracker",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            final confirm = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await ref.read(authProvider.notifier).logout();
            }
          },
        ),
      ],
    );
  }

  ValueListenableBuilder<Box<ExpenseModel>> valueListenableBuilder(
    Box<ExpenseModel> box,
    ExpenseFilter selectedFilter,
    WidgetRef ref,
  ) {
    return ValueListenableBuilder<Box<ExpenseModel>>(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final expenses = box.values.toList();

        List<ExpenseModel> filteredExpenses = expenses;
        final now = DateTime.now();

        switch (selectedFilter) {
          case ExpenseFilter.today:
            filteredExpenses = expenses
                .where(
                  (e) =>
                      e.date.day == now.day &&
                      e.date.month == now.month &&
                      e.date.year == now.year,
                )
                .toList();
            break;

          case ExpenseFilter.yesterday:
            final y = now.subtract(const Duration(days: 1));
            filteredExpenses = expenses
                .where(
                  (e) =>
                      e.date.day == y.day &&
                      e.date.month == y.month &&
                      e.date.year == y.year,
                )
                .toList();
            break;

          case ExpenseFilter.week:
            final start = now.subtract(Duration(days: now.weekday - 1));
            filteredExpenses = expenses
                .where((e) => e.date.isAfter(start))
                .toList();
            break;

          case ExpenseFilter.month:
            filteredExpenses = expenses
                .where(
                  (e) => e.date.month == now.month && e.date.year == now.year,
                )
                .toList();
            break;

          case ExpenseFilter.all:
            break;
        }

        final total = filteredExpenses.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );

        // APPLY SORTING
        final sortType = ref.watch(sortProvider);

        switch (sortType) {
          case SortType.newest:
            filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
            break;
          case SortType.oldest:
            filteredExpenses.sort((a, b) => a.date.compareTo(b.date));
            break;
          case SortType.highAmount:
            filteredExpenses.sort((a, b) => b.amount.compareTo(a.amount));
            break;
          case SortType.lowAmount:
            filteredExpenses.sort((a, b) => a.amount.compareTo(b.amount));
            break;
        }

        // PAGINATION LOGIC
        final currentPage = ref.watch(currentPageProvider);

        final startIndex = (currentPage - 1) * itemsPerPage;
        final endIndex = startIndex + itemsPerPage;

        final paginatedExpenses = filteredExpenses.sublist(
          startIndex,
          endIndex > filteredExpenses.length
              ? filteredExpenses.length
              : endIndex,
        );

        if (expenses.isEmpty) {
          return noExpenseWidget();
        }

        return bodyContent(
          total,
          context,
          expenses,
          ref,
          paginatedExpenses,
          selectedFilter,
          filteredExpenses.length, // total count for pagination
        );
      },
    );
  }

  Column bodyContent(
    double total,
    BuildContext context,
    List<ExpenseModel> expenses,
    WidgetRef ref,
    List<ExpenseModel> paginatedExpenses,
    ExpenseFilter selectedFilter,
    int totalItems,
  ) {
    return Column(
      children: [
        totalExpenseWidget(context, total),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnalyticsScreen(expenses: expenses),
                ),
              );
            },
            icon: Image.asset(
              "assets/images/icons/analytics.gif",
              height: 24,
              width: 24,
            ),
            label: const Text("View Analytics"),
          ),
        ),

        const SizedBox(height: 8),

        // Filter + Sort
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // LEFT -> FILTER
              Expanded(child: dateFilterDropdown(ref)),

              const SizedBox(width: 10),

              // RIGHT -> SORT
              Expanded(child: sortDropdown(ref)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        paginationControls(ref, totalItems),
        const SizedBox(height: 8),
        expenseCard(paginatedExpenses, getCategoryImage, selectedFilter),
      ],
    );
  }

  // UI to show when there are no expenses recorded at all
  Center noExpenseWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/images/empty.png", height: 150),
          const SizedBox(height: 20),
          const Text(
            "No Expenses Yet",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Start adding your expenses"),
        ],
      ),
    );
  }

  Widget expenseCard(
    List<ExpenseModel> filteredExpenses,
    String Function(String category) getCategoryImage,
    ExpenseFilter selectedFilter,
  ) {
    final label = filters[selectedFilter]!;

    return Expanded(
      child: filteredExpenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/empty.png", height: 120), //120
                  const SizedBox(height: 16),
                  Text(
                    "No expenses for $label",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Try changing the filter",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredExpenses.length,
              itemBuilder: (context, index) {
                final item = filteredExpenses[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 4,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    onTap: () async {
                      final deletedId = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpenseDetailScreen(expense: item),
                        ),
                      );

                      if (deletedId != null) {
                        SnackbarManager.show(
                          message: "Expense deleted successfully",
                        );
                      }
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        getCategoryImage(item.category),
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.receipt_long, size: 32);
                        },
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item.category,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      "₹ ${item.amount}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget totalExpenseWidget(BuildContext context, double total) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 140, // original height + shadow space (adjust if needed)
        child: Stack(
          children: [
            // 🔻 Bottom Shadow Strip
            Positioned(
              bottom: 12,
              left: 20,
              right: 20,
              child: Container(
                height: 10,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(39, 84, 138, 0.65),
                      Color.fromRGBO(39, 84, 138, 0.20),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 5,
              left: 35,
              right: 35,
              child: Container(
                height: 7,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(39, 84, 138, 0.35),
                      Color.fromRGBO(39, 84, 138, 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
            ),

            // 🔹 Original Card (no change in size)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(39, 84, 138, 1),
                      Color.fromRGBO(39, 84, 138, 0.629),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Expense",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹ $total",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        "assets/images/moneybag.png",
                        height: 55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dateFilterDropdown(WidgetRef ref) {
    final selected = ref.watch(selectedFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExpenseFilter>(
          value: selected,
          isExpanded: true,
          items: filters.entries.map((entry) {
            return DropdownMenuItem(value: entry.key, child: Text(entry.value));
          }).toList(),
          onChanged: (value) {
            ref.read(selectedFilterProvider.notifier).state = value!;
            ref.read(currentPageProvider.notifier).state = 1;
          },
        ),
      ),
    );
  }

  Widget sortDropdown(WidgetRef ref) {
    final selected = ref.watch(sortProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortType>(
          value: selected,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: SortType.newest, child: Text("Newest")),
            DropdownMenuItem(value: SortType.oldest, child: Text("Oldest")),
            DropdownMenuItem(value: SortType.highAmount, child: Text("High ₹")),
            DropdownMenuItem(value: SortType.lowAmount, child: Text("Low ₹")),
          ],
          onChanged: (value) {
            ref.read(sortProvider.notifier).state = value!;
            ref.read(currentPageProvider.notifier).state = 1;
          },
        ),
      ),
    );
  }

  Widget filterSelector(WidgetRef ref) {
    final selected = ref.watch(selectedFilterProvider);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final key = filters.keys.elementAt(index);
          final label = filters[key]!;

          final isSelected = key == selected;

          return GestureDetector(
            onTap: () {
              ref.read(selectedFilterProvider.notifier).state = key;
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color.fromRGBO(39, 84, 138, 1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget paginationControls(WidgetRef ref, int totalItems) {
    final currentPage = ref.watch(currentPageProvider);
    final totalPages = (totalItems / itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () => ref.read(currentPageProvider.notifier).state--
              : null,
          icon: const Icon(Icons.arrow_back),
        ),
        Text("Page $currentPage / $totalPages"),
        IconButton(
          onPressed: currentPage < totalPages
              ? () => ref.read(currentPageProvider.notifier).state++
              : null,
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }

  Widget expenseLineChart(List<ExpenseModel> expenses) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: expenses.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.amount);
              }).toList(),
              isCurved: true,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
