import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/dashboard/presentation/screens/analytic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../expense/data/models/expense_model.dart';
import '../../../../local_db/hive_boxes.dart';
import 'package:expense_tracker/features/expense/presentation/screens/expense_form_screen.dart';

//import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/features/expense/presentation/screens/expense_detail_screen.dart';
// import 'package:expense_tracker/features/dashboard/presentation/widgets/expense_chart.dart';

enum ExpenseFilter { all, today, yesterday, week, month }

final selectedFilterProvider = StateProvider<ExpenseFilter>(
  (ref) => ExpenseFilter.all,
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String getCategoryImage(String category) {
    switch (category.toLowerCase()) {
      case "food":
        return "assets/images/food.png";
      case "travel":
        return "assets/images/travel.png";
      case "bills":
        return "assets/images/bills.png";
      default:
        return "assets/images/others.png";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = Hive.box<ExpenseModel>(HiveBoxes.expenseBox);
    final selectedFilter = ref.watch(selectedFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Expense Tracker",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<ExpenseModel> box, _) {
          final expenses = box.values.toList();

          // fillter
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

          if (filteredExpenses.isEmpty) {
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

          return Column(
            children: [
              totalExpenseWidget(total),

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
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text("View Analytics"),
                ),
              ),
              SizedBox(height: 5),
              filterSelector(ref),

              SizedBox(height: 10),

              expenseCard(filteredExpenses, getCategoryImage),
            ],
          );
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

  Widget expenseCard(
    List<ExpenseModel> filteredExpenses,
    String Function(String category) getCategoryImage,
  ) {
    return Expanded(
      child: ListView.builder(
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseDetailScreen(expense: item),
                  ),
                );
              },
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),

              //image
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  getCategoryImage(item.category),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    //placeholder
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

              subtitle: Row(
                children: [
                  //const Icon(Icons.label, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    item.category,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
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

  Widget totalExpenseWidget(double total) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
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
              child: Image.asset("assets/images/moneybag.png", height: 55),
            ),
          ],
        ),
      ),
    );
  }

  Widget filterSelector(WidgetRef ref) {
    final selected = ref.watch(selectedFilterProvider);

    final filters = {
      ExpenseFilter.all: "All",
      ExpenseFilter.today: "Today",
      ExpenseFilter.yesterday: "Yesterday",
      ExpenseFilter.week: "This Week",
      ExpenseFilter.month: "This Month",
    };

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
