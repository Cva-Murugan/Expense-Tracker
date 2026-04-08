import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

Widget expensePieChart(Map<String, double> data) {
  final total = data.values.fold(0.0, (a, b) => a + b);

  return AspectRatio(
    aspectRatio: 1.3,
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Expenses by Category",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: PieChart(
                PieChartData(
                  sections: data.entries.map((entry) {
                    final percentage = (entry.value / total) * 100;

                    return PieChartSectionData(
                      value: entry.value,
                      title: "${percentage.toStringAsFixed(0)}%",
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      color: _getColor(entry.key),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
