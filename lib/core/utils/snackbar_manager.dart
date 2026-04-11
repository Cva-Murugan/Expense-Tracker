import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class SnackbarManager {
  static void show({
    required String message,
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.black,
    Color textColor = Colors.white,
    bool infinite = false,
    bool dismissPrevious = true,
  }) {
    final messenger = scaffoldMessengerKey.currentState;

    if (messenger == null) return;

    // remove previous snackbar
    if (dismissPrevious) {
      messenger.hideCurrentSnackBar();
    }

    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: textColor)),
      backgroundColor: backgroundColor,
      duration: infinite ? const Duration(days: 1) : duration,
      behavior: SnackBarBehavior.fixed,
      // margin: const EdgeInsets.only(
      //   bottom: 10, // control this
      //   left: 10,
      //   right: 10,
      // ),
    );

    messenger.showSnackBar(snackBar);
  }

  static void dismiss() {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }
}
