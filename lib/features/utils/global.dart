import 'package:intl/intl.dart';

DateTime? parseDate(String input) {
  try {
    String cleaned = input.trim();

    // Normalize
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Remove ordinal suffix
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d+)(st|nd|rd|th)'),
      (match) => match.group(1)!,
    );

    // Handle slash dates manually
    if (cleaned.contains('/')) {
      final parts = cleaned.split('/');

      if (parts.length == 3) {
        int first = int.tryParse(parts[0]) ?? 0;
        int second = int.tryParse(parts[1]) ?? 0;
        int year = int.tryParse(parts[2]) ?? 0;

        // Fix 2-digit year
        if (year < 100) year += 2000;

        // Detect format
        if (second > 12) {
          // MM/dd/yyyy
          return DateTime(year, first, second);
        } else {
          // dd/MM/yyyy
          return DateTime(year, second, first);
        }
      }
    }

    // Try text formats
    final formats = [
      'd MMMM yyyy',
      'd MMM yyyy',
      'MMM d yyyy',
      'MMMM d yyyy',
      'yyyy-MM-dd',
    ];

    for (var format in formats) {
      try {
        return DateFormat(format).parse(cleaned);
      } catch (_) {}
    }

    return null;
  } catch (_) {
    return null;
  }
}

/*
Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).h
*/
