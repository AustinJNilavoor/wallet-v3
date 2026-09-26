import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/sms_category_mapping.dart';
import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/models/sms_template_field.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/stock.dart';
import 'package:wallet/data/models/transaction.dart';
import 'package:wallet/data/models/transaction_type.dart';
import 'package:wallet/services/transaction/transaction_service.dart';

class BackupService {
  // ============================================================
  // EXPORT
  // ============================================================

  static Future<void> exportBackup() async {
    final categoryBox = Boxes.getCategories();
    final sourceBox = Boxes.getSources();
    final transactionBox = Boxes.getTransactions();

    // ----------------------------------------------------------
    // Categories
    // ----------------------------------------------------------

    final categories = categoryBox.values.map((category) {
      return {
        'id': category.id,
        'name': category.name,
        'iconIndex': category.iconIndex,
        'colorValue': category.colorValue,
      };
    }).toList();

    // ----------------------------------------------------------
    // Sources
    // ----------------------------------------------------------

    final sources = sourceBox.values.map((source) {
      return {
        'id': source.id,
        'name': source.name,
        'iconIndex': source.iconIndex,
        'balance': source.balance,
        'isIncludedInTotal': source.isIncludedInTotal,
        'order': source.order,
        'lastUpdated': source.lastUpdated.toIso8601String(),
        'isCreditCard': source.isCreditCard,
        'isArchived': source.isArchived,
        'isBalanceHidden': source.isBalanceHidden,
        'creditLimit': source.creditLimit,
        'outstandingAmount': source.outstandingAmount,
        'billingDay': source.billingDay,
        'dueDays': source.dueDays,
        'colorValue': source.colorValue,
      };
    }).toList();

    // ----------------------------------------------------------
    // Transactions
    // ----------------------------------------------------------

    final transactions = transactionBox.values.map((transaction) {
      return {
        'id': transaction.id,
        'amount': transaction.amount,
        'createdDate': transaction.createdDate.toIso8601String(),
        'note': transaction.note,

        // For normal transactions this references a real category.
        // For transfers this will be "transfer".
        'categoryId': transaction.category.id,

        'sourceId': transaction.source.id,

        'type': transaction.type.name,

        'destinationSourceId': transaction.destinationSource?.id,
      };
    }).toList();

    // ----------------------------------------------------------
    // Stocks
    // ----------------------------------------------------------

    final stocks = Boxes.getStocks().values.map((stock) {
      return {
        'id': stock.id,
        'name': stock.name,
        'totalQty': stock.totalQty,
        'totalInvestedMoney': stock.totalInvestedMoney,
        'totalReturnedMoney': stock.totalReturnedMoney,
        'totalCharges': stock.totalCharges,
        'avgPrice': stock.avgPrice,
        'realizedProfit': stock.realizedProfit,
        'lastUpdated': stock.lastUpdated.toIso8601String(),
      };
    }).toList();

    // ----------------------------------------------------------
    // SMS templates + fields + mappings
    //
    // Pending transactions and sync state are intentionally left
    // out of the backup: they are transient processing state, not
    // user data, and are safe to lose (a fresh sync will rebuild
    // them on the new device).
    // ----------------------------------------------------------

    final smsTemplates = Boxes.getSmsTemplates().values.map((template) {
      return {
        'id': template.id,
        'name': template.name,
        'senderPattern': template.senderPattern,
        'keywords': template.keywords,
        'enabled': template.enabled,
        'priority': template.priority,
        'sampleMessage': template.sampleMessage,
        'fieldIds': template.fieldIds,
        'description': template.description,
        'createdAt': template.createdAt.toIso8601String(),
        'updatedAt': template.updatedAt.toIso8601String(),
      };
    }).toList();

    final smsTemplateFields = Boxes.getSmsTemplateFields().values.map((field) {
      return {
        'id': field.id,
        'templateId': field.templateId,
        'name': field.name,
        'fieldType': field.fieldType.name,
        'extractionType': field.extractionType.name,
        'pattern': field.pattern,
        'captureGroup': field.captureGroup,
        'required': field.required,
        'defaultValue': field.defaultValue,
        'customFieldName': field.customFieldName,
        'order': field.order,
      };
    }).toList();

    final smsCategoryMappings = Boxes.getSmsCategoryMappings().values.map((
      mapping,
    ) {
      return {
        'id': mapping.id,
        'templateId': mapping.templateId,
        'field': mapping.field.name,
        'operator': mapping.operator.name,
        'value': mapping.value,
        'categoryId': mapping.categoryId,
        'sourceId': mapping.sourceId,
        'destinationSourceId': mapping.destinationSourceId,
        'priority': mapping.priority,
        'enabled': mapping.enabled,
        'description': mapping.description,
        'createdAt': mapping.createdAt.toIso8601String(),
        'updatedAt': mapping.updatedAt.toIso8601String(),
      };
    }).toList();

    // ----------------------------------------------------------
    // Complete backup
    // ----------------------------------------------------------

    final backup = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories,
      'sources': sources,
      'transactions': transactions,
      'stocks': stocks,
      'smsTemplates': smsTemplates,
      'smsTemplateFields': smsTemplateFields,
      'smsCategoryMappings': smsCategoryMappings,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    final fileName = 'wallet_backup_${_fileDate(DateTime.now())}.json';

    // ----------------------------------------------------------
    // Share backup
    // ----------------------------------------------------------

    await Share.shareXFiles([
      XFile.fromData(bytes, name: fileName, mimeType: 'application/json'),
    ], subject: 'Wallet Backup');
  }

  // ============================================================
  // IMPORT
  // ============================================================

  static Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null) {
      return false;
    }

    final file = result.files.single;

    if (file.bytes == null) {
      throw Exception('Unable to read the selected backup file.');
    }

    // ----------------------------------------------------------
    // Decode JSON
    // ----------------------------------------------------------

    final jsonString = utf8.decode(file.bytes!);

    final dynamic decoded;

    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      throw Exception('The selected file is not valid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid wallet backup format.');
    }

    // ----------------------------------------------------------
    // Validate version
    //
    // Version 1 backups (categories/sources/transactions only) can
    // still be restored - the newer sections are simply treated as
    // empty/absent.
    // ----------------------------------------------------------

    final version = decoded['version'];

    if (version != 1 && version != 2) {
      throw Exception('Unsupported backup version: $version');
    }

    // ----------------------------------------------------------
    // Read backup sections
    // ----------------------------------------------------------

    final categories = decoded['categories'] as List<dynamic>?;

    final sources = decoded['sources'] as List<dynamic>?;

    final transactions = decoded['transactions'] as List<dynamic>?;

    // Newer, optional sections - absent entirely on v1 backups.
    final stocksRaw = decoded['stocks'] as List<dynamic>?;
    final smsTemplatesRaw = decoded['smsTemplates'] as List<dynamic>?;
    final smsTemplateFieldsRaw =
        decoded['smsTemplateFields'] as List<dynamic>?;
    final smsCategoryMappingsRaw =
        decoded['smsCategoryMappings'] as List<dynamic>?;

    if (categories == null || sources == null || transactions == null) {
      throw Exception('Backup file is missing required data.');
    }

    // ----------------------------------------------------------
    // Ask before replacing current data
    // ----------------------------------------------------------

    final context = navigatorKey.currentContext;

    if (context == null) {
      throw Exception('Unable to access application context.');
    }

    final shouldImport = await _showImportConfirmation(context);

    if (!shouldImport) {
      return false;
    }

    // ==========================================================
    // RESTORE CATEGORIES
    // ==========================================================

    final categoryMap = <String, Category>{};

    for (final raw in categories) {
      if (raw is! Map) {
        throw Exception('Invalid category data in backup.');
      }

      final data = Map<String, dynamic>.from(raw);

      final id = data['id'];

      if (id is! String || id.isEmpty) {
        throw Exception('Invalid category ID in backup.');
      }

      final name = data['name'];

      if (name is! String) {
        throw Exception('Invalid category name for category $id.');
      }

      final iconIndex = data['iconIndex'];

      if (iconIndex is! int) {
        throw Exception('Invalid icon index for category $id.');
      }

      final colorValue = data['colorValue'];

      final category = Category(
        id: id,
        name: name,
        iconIndex: iconIndex,
        colorValue: colorValue is int ? colorValue : null,
      );

      categoryMap[category.id] = category;
    }

    // ==========================================================
    // RESTORE SOURCES
    // ==========================================================

    final sourceMap = <String, Source>{};

    for (final raw in sources) {
      if (raw is! Map) {
        throw Exception('Invalid source data in backup.');
      }

      final data = Map<String, dynamic>.from(raw);

      final id = data['id'];

      if (id is! String || id.isEmpty) {
        throw Exception('Invalid source ID in backup.');
      }

      final name = data['name'];

      if (name is! String) {
        throw Exception('Invalid source name for source $id.');
      }

      final iconIndex = data['iconIndex'];

      if (iconIndex is! int) {
        throw Exception('Invalid icon index for source $id.');
      }

      final balance = data['balance'];

      if (balance is! num) {
        throw Exception('Invalid balance for source $id.');
      }

      final isIncludedInTotal = data['isIncludedInTotal'];

      if (isIncludedInTotal is! bool) {
        throw Exception('Invalid isIncludedInTotal for source $id.');
      }

      final order = data['order'];

      if (order is! int) {
        throw Exception('Invalid order for source $id.');
      }

      final lastUpdated = data['lastUpdated'];

      if (lastUpdated is! String) {
        throw Exception('Invalid lastUpdated for source $id.');
      }

      final isCreditCard = data['isCreditCard'];

      if (isCreditCard is! bool) {
        throw Exception('Invalid isCreditCard for source $id.');
      }

      final source = Source(
        id: id,
        name: name,
        iconIndex: iconIndex,
        balance: balance.toDouble(),
        isIncludedInTotal: isIncludedInTotal,
        order: order,
        lastUpdated: DateTime.parse(lastUpdated),
        isCreditCard: isCreditCard,
        isArchived: data['isArchived'] as bool? ?? false,
        isBalanceHidden: data['isBalanceHidden'] as bool? ?? false,
        creditLimit: (data['creditLimit'] as num?)?.toDouble(),
        outstandingAmount: (data['outstandingAmount'] as num?)?.toDouble(),
        billingDay: data['billingDay'] as int?,
        dueDays: data['dueDays'] as int?,
        colorValue: data['colorValue'] as int? ?? 0xFF2196F3,
      );

      sourceMap[source.id] = source;
    }

    // ==========================================================
    // VALIDATE TRANSACTIONS
    // ==========================================================

    for (final raw in transactions) {
      if (raw is! Map) {
        throw Exception('Invalid transaction data in backup.');
      }

      final data = Map<String, dynamic>.from(raw);

      final transactionId = data['id'];

      if (transactionId is! String || transactionId.isEmpty) {
        throw Exception('Invalid transaction ID in backup.');
      }

      final typeString = data['type'];

      if (typeString is! String) {
        throw Exception('Transaction $transactionId has an invalid type.');
      }

      final type = TransactionType.values.cast<TransactionType?>().firstWhere(
        (value) => value?.name == typeString,
        orElse: () => null,
      );

      if (type == null) {
        throw Exception(
          'Transaction $transactionId has unsupported type: '
          '$typeString',
        );
      }

      // --------------------------------------------------------
      // Category validation
      //
      // IMPORTANT:
      // Transfer uses a virtual category with ID "transfer".
      // It is NOT stored in the Categories Hive box.
      // --------------------------------------------------------

      final categoryId = data['categoryId'] as String?;

      if (type != TransactionType.transfer) {
        if (categoryId == null || categoryId.isEmpty) {
          throw Exception('Transaction $transactionId is missing a category.');
        }

        if (!categoryMap.containsKey(categoryId)) {
          throw Exception(
            'Transaction $transactionId references '
            'missing category: $categoryId',
          );
        }
      }

      // --------------------------------------------------------
      // Source validation
      // --------------------------------------------------------

      final sourceId = data['sourceId'] as String?;

      if (sourceId == null || sourceId.isEmpty) {
        throw Exception('Transaction $transactionId is missing a source.');
      }

      if (!sourceMap.containsKey(sourceId)) {
        throw Exception(
          'Transaction $transactionId references '
          'missing source: $sourceId',
        );
      }

      // --------------------------------------------------------
      // Destination source validation
      // --------------------------------------------------------

      final destinationSourceId = data['destinationSourceId'] as String?;

      if (type == TransactionType.transfer) {
        if (destinationSourceId == null || destinationSourceId.isEmpty) {
          throw Exception(
            'Transfer transaction $transactionId is missing '
            'destination source.',
          );
        }
      }

      if (destinationSourceId != null &&
          destinationSourceId.isNotEmpty &&
          !sourceMap.containsKey(destinationSourceId)) {
        throw Exception(
          'Transaction $transactionId references '
          'missing destination source: '
          '$destinationSourceId',
        );
      }
    }

    // ==========================================================
    // CREATE TRANSACTIONS
    // ==========================================================

    final restoredTransactions = <Transaction>[];

    for (final raw in transactions) {
      final data = Map<String, dynamic>.from(raw);

      final transactionId = data['id'] as String;

      final typeString = data['type'] as String;

      final type = TransactionType.values.firstWhere(
        (value) => value.name == typeString,
      );

      // --------------------------------------------------------
      // Category
      //
      // Transfer gets the same virtual category used
      // by the input screen.
      // --------------------------------------------------------

      late Category category;

      if (type == TransactionType.transfer) {
        category = TransactionService.transferCategory;
      } else {
        final categoryId = data['categoryId'] as String;

        final existingCategory = categoryMap[categoryId];

        if (existingCategory == null) {
          throw Exception(
            'Transaction $transactionId references '
            'missing category: $categoryId',
          );
        }

        category = existingCategory;
      }

      // --------------------------------------------------------
      // Source
      // --------------------------------------------------------

      final sourceId = data['sourceId'] as String;

      final source = sourceMap[sourceId];

      if (source == null) {
        throw Exception(
          'Transaction $transactionId references '
          'missing source: $sourceId',
        );
      }

      // --------------------------------------------------------
      // Destination source
      // --------------------------------------------------------

      final destinationSourceId = data['destinationSourceId'] as String?;

      Source? destinationSource;

      if (destinationSourceId != null && destinationSourceId.isNotEmpty) {
        destinationSource = sourceMap[destinationSourceId];

        if (destinationSource == null) {
          throw Exception(
            'Transaction $transactionId references '
            'missing destination source: '
            '$destinationSourceId',
          );
        }
      }

      // --------------------------------------------------------
      // Transaction
      // --------------------------------------------------------

      final amount = data['amount'];

      if (amount is! num) {
        throw Exception('Transaction $transactionId has invalid amount.');
      }

      final createdDate = data['createdDate'];

      if (createdDate is! String) {
        throw Exception('Transaction $transactionId has invalid date.');
      }

      final transaction = Transaction(
        id: transactionId,
        amount: amount.toDouble(),
        createdDate: DateTime.parse(createdDate),
        note: data['note'] as String? ?? '',
        category: category,
        source: source,
        type: type,
        destinationSource: destinationSource,
      );

      restoredTransactions.add(transaction);
    }

    // ==========================================================
    // PARSE STOCKS (optional section)
    // ==========================================================

    final restoredStocks = <Stock>[];

    if (stocksRaw != null) {
      for (final raw in stocksRaw) {
        if (raw is! Map) continue;

        final data = Map<String, dynamic>.from(raw);

        final id = data['id'];
        final name = data['name'];

        if (id is! String || id.isEmpty || name is! String) continue;

        final lastUpdated = data['lastUpdated'];

        restoredStocks.add(
          Stock(
            id: id,
            name: name,
            totalQty: (data['totalQty'] as num?)?.toDouble() ?? 0,
            totalInvestedMoney:
                (data['totalInvestedMoney'] as num?)?.toDouble() ?? 0,
            totalReturnedMoney:
                (data['totalReturnedMoney'] as num?)?.toDouble() ?? 0,
            totalCharges: (data['totalCharges'] as num?)?.toDouble() ?? 0,
            avgPrice: (data['avgPrice'] as num?)?.toDouble() ?? 0,
            realizedProfit: (data['realizedProfit'] as num?)?.toDouble() ?? 0,
            lastUpdated: lastUpdated is String
                ? DateTime.parse(lastUpdated)
                : DateTime.now(),
          ),
        );
      }
    }

    // ==========================================================
    // PARSE SMS TEMPLATES / FIELDS / MAPPINGS (optional sections)
    // ==========================================================

    final restoredTemplates = <SmsTemplate>[];

    if (smsTemplatesRaw != null) {
      for (final raw in smsTemplatesRaw) {
        if (raw is! Map) continue;

        final data = Map<String, dynamic>.from(raw);

        final id = data['id'];
        final name = data['name'];
        final senderPattern = data['senderPattern'];

        if (id is! String ||
            id.isEmpty ||
            name is! String ||
            senderPattern is! String) {
          continue;
        }

        final createdAt = data['createdAt'];
        final updatedAt = data['updatedAt'];

        restoredTemplates.add(
          SmsTemplate(
            id: id,
            name: name,
            senderPattern: senderPattern,
            keywords: (data['keywords'] as List?)?.cast<String>() ?? const [],
            enabled: data['enabled'] as bool? ?? true,
            priority: data['priority'] as int? ?? 0,
            sampleMessage: data['sampleMessage'] as String?,
            fieldIds: (data['fieldIds'] as List?)?.cast<String>() ?? const [],
            description: data['description'] as String?,
            createdAt: createdAt is String ? DateTime.parse(createdAt) : null,
            updatedAt: updatedAt is String ? DateTime.parse(updatedAt) : null,
          ),
        );
      }
    }

    final restoredTemplateFields = <SmsTemplateField>[];

    if (smsTemplateFieldsRaw != null) {
      for (final raw in smsTemplateFieldsRaw) {
        if (raw is! Map) continue;

        final data = Map<String, dynamic>.from(raw);

        final id = data['id'];
        final templateId = data['templateId'];
        final name = data['name'];
        final pattern = data['pattern'];

        if (id is! String ||
            id.isEmpty ||
            templateId is! String ||
            name is! String ||
            pattern is! String) {
          continue;
        }

        final fieldType = SmsFieldType.values
            .cast<SmsFieldType?>()
            .firstWhere(
              (v) => v?.name == data['fieldType'],
              orElse: () => SmsFieldType.custom,
            )!;

        final extractionType = SmsExtractionType.values
            .cast<SmsExtractionType?>()
            .firstWhere(
              (v) => v?.name == data['extractionType'],
              orElse: () => SmsExtractionType.regex,
            )!;

        restoredTemplateFields.add(
          SmsTemplateField(
            id: id,
            templateId: templateId,
            name: name,
            fieldType: fieldType,
            extractionType: extractionType,
            pattern: pattern,
            captureGroup: data['captureGroup'] as int? ?? 1,
            required: data['required'] as bool? ?? false,
            defaultValue: data['defaultValue'] as String?,
            customFieldName: data['customFieldName'] as String?,
            order: data['order'] as int? ?? 0,
          ),
        );
      }
    }

    final restoredMappings = <SmsCategoryMapping>[];

    if (smsCategoryMappingsRaw != null) {
      for (final raw in smsCategoryMappingsRaw) {
        if (raw is! Map) continue;

        final data = Map<String, dynamic>.from(raw);

        final id = data['id'];
        final value = data['value'];

        if (id is! String || id.isEmpty || value is! String) continue;

        final field = SmsMappingField.values
            .cast<SmsMappingField?>()
            .firstWhere(
              (v) => v?.name == data['field'],
              orElse: () => SmsMappingField.merchant,
            )!;

        final operator = SmsMappingOperator.values
            .cast<SmsMappingOperator?>()
            .firstWhere(
              (v) => v?.name == data['operator'],
              orElse: () => SmsMappingOperator.contains,
            )!;

        final createdAt = data['createdAt'];
        final updatedAt = data['updatedAt'];

        restoredMappings.add(
          SmsCategoryMapping(
            id: id,
            templateId: data['templateId'] as String?,
            field: field,
            operator: operator,
            value: value,
            categoryId: data['categoryId'] as String?,
            sourceId: data['sourceId'] as String?,
            destinationSourceId: data['destinationSourceId'] as String?,
            priority: data['priority'] as int? ?? 0,
            enabled: data['enabled'] as bool? ?? true,
            description: data['description'] as String?,
            createdAt: createdAt is String ? DateTime.parse(createdAt) : null,
            updatedAt: updatedAt is String ? DateTime.parse(updatedAt) : null,
          ),
        );
      }
    }

    // ==========================================================
    // REPLACE EXISTING DATA
    // ==========================================================

    final categoryBox = Boxes.getCategories();
    final sourceBox = Boxes.getSources();
    final transactionBox = Boxes.getTransactions();

    await categoryBox.clear();
    await sourceBox.clear();
    await transactionBox.clear();

    // Optional sections are only cleared/replaced when the backup
    // actually contains them, so restoring an older (v1) backup
    // never wipes out SMS templates/mappings/stocks that already
    // exist on this device.
    if (stocksRaw != null) {
      await Boxes.getStocks().clear();
    }

    if (smsTemplatesRaw != null) {
      await Boxes.getSmsTemplates().clear();
    }

    if (smsTemplateFieldsRaw != null) {
      await Boxes.getSmsTemplateFields().clear();
    }

    if (smsCategoryMappingsRaw != null) {
      await Boxes.getSmsCategoryMappings().clear();
    }

    // ==========================================================
    // SAVE CATEGORIES
    // ==========================================================

    for (final category in categoryMap.values) {
      await categoryBox.put(category.id, category);
    }

    // ==========================================================
    // SAVE SOURCES
    // ==========================================================

    for (final source in sourceMap.values) {
      await sourceBox.put(source.id, source);
    }

    // ==========================================================
    // SAVE TRANSACTIONS
    // ==========================================================

    for (final transaction in restoredTransactions) {
      await transactionBox.put(transaction.id, transaction);
    }

    // ==========================================================
    // SAVE STOCKS / SMS TEMPLATES / FIELDS / MAPPINGS
    // ==========================================================

    for (final stock in restoredStocks) {
      await Boxes.getStocks().put(stock.id, stock);
    }

    for (final template in restoredTemplates) {
      await Boxes.getSmsTemplates().put(template.id, template);
    }

    for (final field in restoredTemplateFields) {
      await Boxes.getSmsTemplateFields().put(field.id, field);
    }

    for (final mapping in restoredMappings) {
      await Boxes.getSmsCategoryMappings().put(mapping.id, mapping);
    }

    return true;
  }

  // ============================================================
  // CONFIRMATION DIALOG
  // ============================================================

  static Future<bool> _showImportConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import Backup?'),
          content: const Text(
            'This will replace the existing '
            'categories, sources, transactions, stocks and SMS '
            'templates/mappings on this device (for backups that '
            'include them).\n\n'
            'Make sure you have a backup of the '
            'current data if you want to keep it.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // FILE DATE
  // ============================================================

  static String _fileDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${date.year}'
        '${two(date.month)}'
        '${two(date.day)}_'
        '${two(date.hour)}'
        '${two(date.minute)}';
  }
}

// ============================================================
// NAVIGATOR KEY
// ============================================================
//
// Used by BackupService for the confirmation dialog.
//
// Add this navigatorKey to your MaterialApp:
//
// MaterialApp(
//   navigatorKey: navigatorKey,
//   ...
// )
//
// ============================================================

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
