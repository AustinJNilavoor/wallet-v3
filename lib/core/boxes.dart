import 'package:hive_flutter/hive_flutter.dart';

import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/pending_transaction.dart';
import 'package:wallet/data/models/sms_category_mapping.dart';
import 'package:wallet/data/models/sms_sync_state.dart';
import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/models/sms_template_field.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/stock.dart';
import 'package:wallet/data/models/transaction.dart';

class Boxes {
  static Box<Transaction> getTransactions() =>
      Hive.box<Transaction>('transactions');

  static Box<Category> getCategories() =>
      Hive.box<Category>('categories');

  static Box<Source> getSources() =>
      Hive.box<Source>('sources');

  static Box<Stock> getStocks() =>
      Hive.box<Stock>('stocks');

  // -----------------------------
  // SMS IMPORT BOXES
  // -----------------------------

  static Box<SmsTemplate> getSmsTemplates() =>
      Hive.box<SmsTemplate>('sms_templates');

  static Box<SmsTemplateField> getSmsTemplateFields() =>
      Hive.box<SmsTemplateField>('sms_template_fields');

  static Box<SmsCategoryMapping> getSmsCategoryMappings() =>
      Hive.box<SmsCategoryMapping>('sms_category_mappings');

  static Box<PendingTransaction> getPendingTransactions() =>
      Hive.box<PendingTransaction>('pending_transactions');

  static Box<SmsSyncState> getSmsSyncState() =>
      Hive.box<SmsSyncState>('sms_sync_state');
}