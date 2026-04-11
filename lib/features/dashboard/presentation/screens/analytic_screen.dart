import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../expense/data/models/expense_model.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<ExpenseModel> expenses;

  const AnalyticsScreen({super.key, required this.expenses});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int touchedIndex = -1;
  double animationValue = 0;
  bool showChart = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        showChart = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.expenses.fold(0.0, (sum, e) => sum + e.amount);
    final categoryData = _getCategoryData(widget.expenses);
    final categoryCount = getCategoryCount(widget.expenses);
    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        // 🔥 THIS IS THE MISSING PIECE
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: List.generate(categoryData.length, (i) {
                    final e = categoryData.entries.toList()[i];
                    final isTouched = i == touchedIndex;

                    return PieChartSectionData(
                      value: showChart ? e.value * (1 + i * 0.05) : 0,
                      title: "${e.key}\n₹${e.value.toStringAsFixed(0)}",
                      radius: isTouched ? 85 : 70,
                      color: _getColor(e.key),
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 14 : 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text("Total Expense"),
                  const SizedBox(height: 6),
                  Text(
                    "₹ $total",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: categoryCount.entries.map((e) {
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: _getColor(e.key)),

                    title: Text(e.key),

                    trailing: Text(
                      "${e.value} ${e.value == 1 ? "time" : "times"}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _getCategoryData(List<ExpenseModel> expenses) {
    final Map<String, double> data = {};
    for (var e in expenses) {
      data[e.category] = (data[e.category] ?? 0) + e.amount;
    }
    return data;
  }

  Map<String, int> getCategoryCount(List<ExpenseModel> expenses) {
    final Map<String, int> data = {};

    for (var e in expenses) {
      data[e.category] = (data[e.category] ?? 0) + 1;
    }

    return data;
  }

  Color _getColor(String category) {
    switch (category.toLowerCase()) {
      case "food":
        return Colors.orange;
      case "travel":
        return Colors.blue;
      case "bills":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
