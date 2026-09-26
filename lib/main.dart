import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet/core/backup_service.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/stock.dart';
import 'package:wallet/data/models/transaction.dart';
import 'package:wallet/data/models/transaction_type.dart';
import 'package:wallet/presentation/screens/main_screen.dart';
import 'package:wallet/data/models/pending_transaction.dart';
import 'package:wallet/data/models/sms_category_mapping.dart';
import 'package:wallet/data/models/sms_sync_state.dart';
import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/models/sms_template_field.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(SourceAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(StockAdapter());
  Hive.registerAdapter(SmsTemplateFieldAdapter());
Hive.registerAdapter(SmsFieldTypeAdapter());
Hive.registerAdapter(SmsExtractionTypeAdapter());

Hive.registerAdapter(SmsTemplateAdapter());

Hive.registerAdapter(SmsMappingFieldAdapter());
Hive.registerAdapter(SmsMappingOperatorAdapter());
Hive.registerAdapter(SmsCategoryMappingAdapter());

Hive.registerAdapter(PendingTransactionStatusAdapter());
Hive.registerAdapter(PendingTransactionAdapter());

Hive.registerAdapter(SmsSyncStateAdapter());


  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Source>('sources');
  await Hive.openBox<Stock>('stocks');

  await Hive.openBox<SmsTemplate>('sms_templates');

await Hive.openBox<SmsTemplateField>(
  'sms_template_fields',
);

await Hive.openBox<SmsCategoryMapping>(
  'sms_category_mappings',
);

await Hive.openBox<PendingTransaction>(
  'pending_transactions',
);

await Hive.openBox<SmsSyncState>(
  'sms_sync_state',
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const MainScreen(),
    );
  }
}
