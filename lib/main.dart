import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/sms_mapping.dart';
import 'package:wallet/data/models/sms_mapping_type.dart';
import 'package:wallet/data/models/sms_match_field.dart';
import 'package:wallet/data/models/sms_sync_state.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/transaction.dart';
import 'package:wallet/data/models/transaction_type.dart';
import 'package:wallet/presentation/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(SourceAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(SmsSyncStateAdapter());
  Hive.registerAdapter(SmsMappingAdapter());
  Hive.registerAdapter(SmsMappingTypeAdapter());
  Hive.registerAdapter(SmsMatchFieldAdapter());

  await Hive.openBox<SmsSyncState>('smsSyncStateBox');
  await Hive.openBox<SmsMapping>('smsMappings');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Source>('sources');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const MainScreen(),
    );
  }
}
