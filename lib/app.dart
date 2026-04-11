import 'package:expense_tracker/core/utils/snackbar_manager.dart';
//import 'package:expense_tracker/features/expense/presentation/screens/expense_form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'package:expense_tracker/features/dashboard/presentation/screens/dashboard_screen.dart';
//import 'package:expense_tracker/features/expense/presentation/screens/ocr_test_screen.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/network_listener.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final authState = ref.watch(authProvider);

    final ThemeData customTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color.fromRGBO(39, 84, 138, 1),
        primary: Color.fromRGBO(39, 84, 138, 1),
        secondary: Color.fromRGBO(221, 168, 83, 1),
      ).copyWith(surface: Color.fromRGBO(242, 242, 247, 1)),
      useMaterial3: true,
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 18,
          fontFamily: 'Cera Pro',
        ), //,color: Colors.white
        bodyMedium: TextStyle(fontSize: 15, fontFamily: 'Cera Pro'),
        bodySmall: TextStyle(fontSize: 12, fontFamily: 'Cera Pro'),
      ),
      iconTheme: IconThemeData(color: Colors.blue, size: 24),
    );

    return MaterialApp(
      title: 'Expense Tracker',
      locale: Locale('en', 'GB'), // forces dd/MM/yyyy
      supportedLocales: [
        Locale('en', 'US'),
        Locale('en', 'GB'),
        Locale('en', 'IN'),
      ],
      debugShowCheckedModeBanner: false,
      theme: customTheme,
      scaffoldMessengerKey: scaffoldMessengerKey,
      //home: ExpenseFormScreen(),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data != null) {
            return NetworkListener(child: DashboardScreen());
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
