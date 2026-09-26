class ParsedSmsTransaction {
  final String? smsId;

  final String sender;

  final String rawMessage;

  final DateTime smsDate;

  final String duplicateKey;

  final String? templateId;

  final double? amount;

  final DateTime? transactionDate;

  final String? merchant;

  final String? accountNumber;

  final String? referenceNumber;

  final double? balance;

  final String? description;

  final String? transactionType;

  final Map<String, String> customFields;

  final List<String> missingFields;

  final bool parsingSuccessful;

  final double confidence;

  ParsedSmsTransaction({
    this.smsId,
    required this.sender,
    required this.rawMessage,
    required this.smsDate,
    required this.duplicateKey,
    this.templateId,
    this.amount,
    this.transactionDate,
    this.merchant,
    this.accountNumber,
    this.referenceNumber,
    this.balance,
    this.description,
    this.transactionType,
    this.customFields = const {},
    this.missingFields = const [],
    this.parsingSuccessful = false,
    this.confidence = 0.0,
  });

  bool get hasAmount => amount != null;

  bool get isComplete =>
      parsingSuccessful &&
      missingFields.isEmpty;
}