import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/transaction.dart';

class Boxes {
  static Box<Transaction> getTransactions() =>
      Hive.box<Transaction>('transactions');

  static Box<Category> getCategories() => Hive.box<Category>('categories');

  static Box<Source> getSources() => Hive.box<Source>('sources');
}
