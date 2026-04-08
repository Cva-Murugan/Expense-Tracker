import 'package:flutter/material.dart';

class StepProgressPainter extends CustomPainter {
  final int currentStep;
  final int totalSteps;

  StepProgressPainter({required this.currentStep, required this.totalSteps});

  @override
  void paint(Canvas canvas, Size size) {
    final paintActive = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3;

    final paintInactive = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 3;

    final stepWidth = size.width / (totalSteps - 1);

    // Draw lines
    for (int i = 0; i < totalSteps - 1; i++) {
      final startX = i * stepWidth;
      final endX = (i + 1) * stepWidth;

      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(endX, size.height / 2),
        i < currentStep ? paintActive : paintInactive,
      );
    }

    // Draw circles
    for (int i = 0; i < totalSteps; i++) {
      final x = i * stepWidth;

      final isActive = i <= currentStep;

      final paint = Paint()
        ..color = isActive ? Colors.blue : Colors.grey.shade300;

      canvas.drawCircle(Offset(x, size.height / 2), 8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;

  const StepProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPaint(
          size: const Size(double.infinity, 40),
          painter: StepProgressPainter(currentStep: currentStep, totalSteps: 4),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Info"),
            Text("Category"),
            Text("Document"),
            Text("Review"),
          ],
        ),
      ],
    );
  }
}
