import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showSnackBar(String message, Color color) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      margin: const EdgeInsets.all(10),
      behavior: SnackBarBehavior.floating,
      elevation: 2,
    ),
  );
}
