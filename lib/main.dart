import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/expense/data/models/expense_model.dart';
import 'local_db/hive_boxes.dart';

//import 'core/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //Hive.init(".");
  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseModelAdapter());

  await Hive.openBox<ExpenseModel>(HiveBoxes.expenseBox);

  // upload expense whenever start up app
  //await SyncService().syncExpenses();

  runApp(const ProviderScope(child: MyApp()));
}
