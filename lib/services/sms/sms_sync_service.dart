import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/sms_constants.dart';
import 'package:wallet/data/models/pending_transaction.dart';
import 'package:wallet/data/repositories/sms_sync_repository.dart';
import 'package:wallet/services/sms/sms_duplicate_service.dart';
import 'package:wallet/services/sms/sms_mapping_service.dart';
import 'package:wallet/services/sms/sms_parser_service.dart';
import 'package:wallet/services/sms/sms_reader_service.dart';
import 'package:wallet/services/sms/sms_template_matcher.dart';

class SmsSyncResult {
  final bool successful;
  final int scanned;
  final int imported;
  final int duplicates;
  final int unmatched;
  final int parsingFailed;
  final String? error;

  const SmsSyncResult({
    required this.successful,
    required this.scanned,
    required this.imported,
    required this.duplicates,
    required this.unmatched,
    required this.parsingFailed,
    this.error,
  });

  factory SmsSyncResult.disabled() => const SmsSyncResult(
    successful: true,
    scanned: 0,
    imported: 0,
    duplicates: 0,
    unmatched: 0,
    parsingFailed: 0,
  );

  factory SmsSyncResult.failure(Object error) {
    return SmsSyncResult(
      successful: false,
      scanned: 0,
      imported: 0,
      duplicates: 0,
      unmatched: 0,
      parsingFailed: 0,
      error: error.toString(),
    );
  }
}

class SmsSyncService {
  SmsSyncService({
    SmsReaderService? reader,
    SmsTemplateMatcher? matcher,
    SmsParserService? parser,
    SmsDuplicateService? duplicateService,
    SmsMappingService? mappingService,
    SmsSyncRepository? syncRepository,
  }) : _reader = reader ?? SmsReaderService(),
       _matcher = matcher ?? SmsTemplateMatcher(),
       _parser = parser ?? SmsParserService(),
       _duplicateService = duplicateService ?? SmsDuplicateService(),
       _mappingService = mappingService ?? SmsMappingService(),
       _syncRepository = syncRepository ?? SmsSyncRepository();

  final SmsReaderService _reader;
  final SmsTemplateMatcher _matcher;
  final SmsParserService _parser;
  final SmsDuplicateService _duplicateService;
  final SmsMappingService _mappingService;
  final SmsSyncRepository _syncRepository;

  final _pendingBox = Boxes.getPendingTransactions();

  Future<SmsSyncResult> sync() async {
    final state = _syncRepository.getOrCreate();

    if (!state.enabled) {
      return SmsSyncResult.disabled();
    }

    state.markSyncStarted();
    await _syncRepository.save(state);

    try {
      final messages = await _reader.readInbox(
        count: SmsConstants.defaultReadCount,
      );

      final effectiveFrom = state.effectiveSyncFrom;

      int scanned = 0;
      int imported = 0;
      int duplicates = 0;
      int unmatched = 0;
      int parsingFailed = 0;

      for (final message in messages) {
        final body = message.body?.trim();
        final sender = message.sender?.trim();
        final smsDate = message.date;

        if (body == null || body.isEmpty) continue;
        if (sender == null || sender.isEmpty) continue;
        if (smsDate == null) continue;

        // Ignore messages older than the sync window.
        if (effectiveFrom != null && smsDate.isBefore(effectiveFrom)) {
          continue;
        }

        scanned++;

        final duplicateKey = _duplicateService.generateDuplicateKey(
          sender: sender,
          body: body,
          date: smsDate,
        );

        final smsId = message.id?.toString();

        if (_duplicateService.hasProcessedSms(
          smsId: smsId,
          duplicateKey: duplicateKey,
        )) {
          duplicates++;
          continue;
        }

        final template = _matcher.findTemplate(sender: sender, body: body);

        if (template == null) {
          unmatched++;
          continue;
        }

        final parsed = _parser.parse(
          sender: sender,
          body: body,
          smsDate: smsDate,
          template: template,
          smsId: smsId,
        );

        if (!parsed.parsingSuccessful) {
          parsingFailed++;
        }

        final mapping = _mappingService.applyMappings(parsed: parsed);

        final pending = PendingTransaction(
          id: _generatePendingId(smsId: smsId, duplicateKey: duplicateKey),
          smsId: smsId,
          duplicateKey: duplicateKey,
          sender: sender,
          rawMessage: body,
          smsDate: smsDate,
          templateId: template.id,
          amount: parsed.amount,
          transactionDate: parsed.transactionDate ?? smsDate,
          merchant: parsed.merchant,
          accountNumber: parsed.accountNumber,
          referenceNumber: parsed.referenceNumber,
          balance: parsed.balance,
          description: parsed.description,
          categoryId: mapping.categoryId,
          sourceId: mapping.sourceId,
          destinationSourceId: mapping.destinationSourceId,
          transactionType: mapping.transactionType ?? parsed.transactionType,
          note: parsed.description,
          status: PendingTransactionStatus.pending,
          confidence: parsed.confidence,
          parsingSuccessful: parsed.parsingSuccessful,
          missingFields: parsed.missingFields,
          customFields: parsed.customFields,
        );

        await _pendingBox.put(pending.id, pending);

        imported++;
      }

      final latestDate =
          _getLatestDate(messages, fallback: state.lastSyncedAt) ??
          DateTime.now();

      state.markSyncCompleted(
        syncedAt: latestDate,
        smsId: _getLatestSmsId(messages),
        scanCount: scanned,
        importedCount: imported,
        duplicateCount: duplicates,
        unmatchedCount: unmatched,
      );

      await _syncRepository.save(state);

      return SmsSyncResult(
        successful: true,
        scanned: scanned,
        imported: imported,
        duplicates: duplicates,
        unmatched: unmatched,
        parsingFailed: parsingFailed,
      );
    } catch (error) {
      state.markSyncFailed(error);
      await _syncRepository.save(state);

      return SmsSyncResult.failure(error);
    }
  }

  DateTime? _getLatestDate(List<SmsMessage> messages, {DateTime? fallback}) {
    DateTime? latest = fallback;

    for (final message in messages) {
      final date = message.date;
      if (date == null) continue;

      if (latest == null || date.isAfter(latest)) {
        latest = date;
      }
    }

    return latest;
  }

  String? _getLatestSmsId(List<SmsMessage> messages) {
    SmsMessage? latest;

    for (final message in messages) {
      if (message.date == null) continue;

      if (latest == null ||
          (latest.date == null) ||
          message.date!.isAfter(latest.date!)) {
        latest = message;
      }
    }

    return latest?.id?.toString();
  }

  String _generatePendingId({String? smsId, required String duplicateKey}) {
    if (smsId != null && smsId.isNotEmpty) {
      return 'sms_$smsId';
    }

    return 'sms_$duplicateKey';
  }
}
