import 'package:hive/hive.dart';

part 'pending_transaction.g.dart';

@HiveType(typeId: 11)
enum PendingTransactionStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  approved,

  @HiveField(2)
  rejected,
}

@HiveType(typeId: 12)
class PendingTransaction extends HiveObject {
  @HiveField(0)
  String id;

  /// Android/provider SMS identifier if available.
  @HiveField(1)
  String? smsId;

  /// Hash generated from sender + body + timestamp.
  ///
  /// Used as a second layer of duplicate protection.
  @HiveField(2)
  String duplicateKey;

  @HiveField(3)
  String sender;

  @HiveField(4)
  String rawMessage;

  /// Original SMS timestamp.
  @HiveField(5)
  DateTime smsDate;

  /// Date when this pending record was created.
  @HiveField(6)
  DateTime createdAt;

  /// ID of the template that parsed this SMS.
  @HiveField(7)
  String? templateId;

  /// Parsed amount.
  @HiveField(8)
  double? amount;

  /// Parsed transaction date.
  @HiveField(9)
  DateTime? transactionDate;

  /// Parsed merchant/payee.
  @HiveField(10)
  String? merchant;

  /// Parsed account number.
  ///
  /// Prefer storing the masked/last-four form rather than
  /// a complete account number.
  @HiveField(11)
  String? accountNumber;

  @HiveField(12)
  String? referenceNumber;

  @HiveField(13)
  double? balance;

  @HiveField(14)
  String? description;

  /// Existing Category ID.
  @HiveField(15)
  String? categoryId;

  /// Existing Source ID.
  @HiveField(16)
  String? sourceId;

  /// Existing destination Source ID.
  @HiveField(17)
  String? destinationSourceId;

  /// Stored as a string to avoid coupling this model
  /// to TransactionType Hive serialization.
  ///
  /// Values:
  /// income
  /// expense
  /// transfer
  @HiveField(18)
  String? transactionType;

  @HiveField(19)
  String? note;

  @HiveField(20)
  PendingTransactionStatus status;

  /// 0.0 - 1.0.
  ///
  /// This is not an AI score. It represents how complete/
  /// deterministic the parsing was.
  @HiveField(21)
  double confidence;

  /// Whether all required template fields were extracted.
  @HiveField(22)
  bool parsingSuccessful;

  /// IDs/names of fields that failed to parse.
  @HiveField(23)
  List<String> missingFields;

  /// Arbitrary extracted values from custom fields.
  ///
  /// Example:
  /// {
  ///   "upiId": "merchant@upi",
  ///   "terminal": "123456"
  /// }
  @HiveField(24)
  Map<String, String> customFields;

  @HiveField(25)
  DateTime updatedAt;

  @HiveField(26)
  DateTime? reviewedAt;

  PendingTransaction({
    required this.id,
    this.smsId,
    required this.duplicateKey,
    required this.sender,
    required this.rawMessage,
    required this.smsDate,
    DateTime? createdAt,
    this.templateId,
    this.amount,
    this.transactionDate,
    this.merchant,
    this.accountNumber,
    this.referenceNumber,
    this.balance,
    this.description,
    this.categoryId,
    this.sourceId,
    this.destinationSourceId,
    this.transactionType,
    this.note,
    this.status = PendingTransactionStatus.pending,
    this.confidence = 0.0,
    this.parsingSuccessful = false,
    this.missingFields = const [],
    this.customFields = const {},
    DateTime? updatedAt,
    this.reviewedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isPending =>
      status == PendingTransactionStatus.pending;

  bool get isApproved =>
      status == PendingTransactionStatus.approved;

  bool get isRejected =>
      status == PendingTransactionStatus.rejected;

  PendingTransaction copyWith({
    String? id,
    Object? smsId = _unset,
    String? duplicateKey,
    String? sender,
    String? rawMessage,
    DateTime? smsDate,
    DateTime? createdAt,
    Object? templateId = _unset,
    Object? amount = _unset,
    Object? transactionDate = _unset,
    Object? merchant = _unset,
    Object? accountNumber = _unset,
    Object? referenceNumber = _unset,
    Object? balance = _unset,
    Object? description = _unset,
    Object? categoryId = _unset,
    Object? sourceId = _unset,
    Object? destinationSourceId = _unset,
    Object? transactionType = _unset,
    Object? note = _unset,
    PendingTransactionStatus? status,
    double? confidence,
    bool? parsingSuccessful,
    List<String>? missingFields,
    Map<String, String>? customFields,
    DateTime? updatedAt,
    Object? reviewedAt = _unset,
  }) {
    return PendingTransaction(
      id: id ?? this.id,
      smsId: identical(smsId, _unset) ? this.smsId : smsId as String?,
      duplicateKey: duplicateKey ?? this.duplicateKey,
      sender: sender ?? this.sender,
      rawMessage: rawMessage ?? this.rawMessage,
      smsDate: smsDate ?? this.smsDate,
      createdAt: createdAt ?? this.createdAt,
      templateId: identical(templateId, _unset)
          ? this.templateId
          : templateId as String?,
      amount: identical(amount, _unset) ? this.amount : amount as double?,
      transactionDate: identical(transactionDate, _unset)
          ? this.transactionDate
          : transactionDate as DateTime?,
      merchant: identical(merchant, _unset)
          ? this.merchant
          : merchant as String?,
      accountNumber: identical(accountNumber, _unset)
          ? this.accountNumber
          : accountNumber as String?,
      referenceNumber: identical(referenceNumber, _unset)
          ? this.referenceNumber
          : referenceNumber as String?,
      balance: identical(balance, _unset) ? this.balance : balance as double?,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as String?,
      sourceId: identical(sourceId, _unset)
          ? this.sourceId
          : sourceId as String?,
      destinationSourceId: identical(destinationSourceId, _unset)
          ? this.destinationSourceId
          : destinationSourceId as String?,
      transactionType: identical(transactionType, _unset)
          ? this.transactionType
          : transactionType as String?,
      note: identical(note, _unset) ? this.note : note as String?,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      parsingSuccessful: parsingSuccessful ?? this.parsingSuccessful,
      missingFields: missingFields ?? List<String>.from(this.missingFields),
      customFields:
          customFields ?? Map<String, String>.from(this.customFields),
      updatedAt: updatedAt ?? DateTime.now(),
      reviewedAt: identical(reviewedAt, _unset)
          ? this.reviewedAt
          : reviewedAt as DateTime?,
    );
  }
}

/// Sentinel used by [PendingTransaction.copyWith] to distinguish
/// "field not passed" from "field explicitly set to null" for
/// nullable fields.
const Object _unset = Object();