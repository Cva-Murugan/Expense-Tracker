import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRResult {
  final String? title;
  final double? amount;
  final String? date;
  final String rawText;

  OCRResult({
    required this.title,
    required this.amount,
    required this.date,
    required this.rawText,
  });
}

class OCRService {
  Future<OCRResult> process(File file) async {
    final inputImage = InputImage.fromFile(
      file,
    ); // thjs will convert documents as mutliple images
    final textRecognizer = TextRecognizer();

    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    final text = recognizedText.text;

    return OCRResult(
      title: _extractTitle(text),
      amount: _extractAmount(text),
      date: _extractDate(text),
      rawText: text,
    );
  }

  // move your existing methods here (no change)

  String? _extractTitle(String text) {
    List<String> lines = text.split('\n');

    for (var line in lines.take(3)) {
      String l = line.trim();

      if (l.isEmpty) continue;

      // Skip if mostly numbers
      if (RegExp(r'^\d+$').hasMatch(l)) continue;

      // Skip if contains too many digits
      if (RegExp(r'\d{3,}').hasMatch(l)) continue;

      return l;
    }

    return null;
  }

  double? _extractAmount(String text) {
    //final lines = text.split('\n');

    final monthWords = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];

    List<double> highPriority = [];
    List<double> mediumPriority = [];
    List<double> lowPriority = [];

    final matches = RegExp(
      r'(₹|\$|rs)?\s?(\d+\.?\d{0,2})',
      caseSensitive: false,
    ).allMatches(text);

    for (var m in matches) {
      final symbol = m.group(1);
      final value = double.tryParse(m.group(2)!);

      if (value == null) continue;

      // Ignore huge numbers (phone numbers)
      if (value > 1000000) continue;

      // Context check
      final context = text
          .substring(
            (m.start - 15).clamp(0, text.length),
            (m.end + 15).clamp(0, text.length),
          )
          .toLowerCase();

      // Ignore if near month words (date)
      if (monthWords.any((month) => context.contains(month))) continue;

      // PRIORITY LOGIC

      if (symbol != null) {
        // ₹, $, Rs -> HIGH priority
        highPriority.add(value);
      } else if (context.contains('total') || context.contains('amount')) {
        // Near keywords -> MEDIUM
        mediumPriority.add(value);
      } else {
        // Everything else -> LOW
        lowPriority.add(value);
      }
    }

    // Return best available
    if (highPriority.isNotEmpty) {
      highPriority.sort();
      return highPriority.last;
    }

    if (mediumPriority.isNotEmpty) {
      mediumPriority.sort();
      return mediumPriority.last;
    }

    if (lowPriority.isNotEmpty) {
      lowPriority.sort();
      return lowPriority.last;
    }

    return null;
  }

  String? _extractDate(String text) {
    // Numeric formats
    final numeric = RegExp(
      r'(\d{2}[/-]\d{2}[/-]\d{2,4})|(\d{4}[/-]\d{2}[/-]\d{2})',
    );

    final match1 = numeric.firstMatch(text);
    if (match1 != null) return match1.group(0);

    // Textual formats (e.g., 9 April 2026)
    final textDate = RegExp(
      r'\d{1,2}\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}',
      caseSensitive: false,
    );

    final match2 = textDate.firstMatch(text);
    return match2?.group(0);
  }
}
