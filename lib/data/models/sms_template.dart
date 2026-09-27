import 'package:wallet/data/models/sms_pattern_builder.dart';

/// The seven pieces of information a template can supply for a
/// transaction - mirrors exactly what the manual input screen asks
/// for.
enum SmsFieldKey {
  amount,
  date,
  category,
  source,
  destinationSource, // only meaningful when type == transfer
  type,
  note,
}

extension SmsFieldKeyLabel on SmsFieldKey {
  String get label {
    switch (this) {
      case SmsFieldKey.amount:
        return 'Amount';
      case SmsFieldKey.date:
        return 'Date';
      case SmsFieldKey.category:
        return 'Category';
      case SmsFieldKey.source:
        return 'Source';
      case SmsFieldKey.destinationSource:
        return 'Destination Source';
      case SmsFieldKey.type:
        return 'Type';
      case SmsFieldKey.note:
        return 'Note';
    }
  }
}

/// How a single field's value is obtained when a message matches this
/// template.
enum SmsFieldMappingMode {
  /// Extracted from the message text using an anchor-based pattern
  /// built from a user text-selection.
  mapped,

  /// Left blank; the user is asked to fill it in when approving the
  /// parsed transaction.
  ask,

  /// Always uses [SmsFieldMapping.defaultValue], regardless of what
  /// the message says.
  defaultValue,
}

/// How one [SmsFieldKey] is resolved for a template.
///
/// ## Anchors, not raw windows
///
/// [prefixAnchor] / [suffixAnchor] are short, *stable* keywords found
/// near the selection (e.g. `"Rs."`, `"on"`, `"debited"`) - never
/// arbitrary raw text. This is what makes a mapping reusable: the
/// anchors describe the wording around the value, and [pattern]
/// describes the *shape* of the value itself (digits, a date, free
/// text). Neither depends on the specific account number, merchant
/// name or balance that happened to appear in the one SMS the
/// template was built from.
///
/// [defaultValue] is stored as a plain string for every field so the
/// whole model stays trivially JSON-serializable:
/// - amount  -> numeric string, e.g. "649.00"
/// - date    -> ISO-8601 string
/// - note    -> raw text
/// - type    -> `TransactionType.name`, e.g. "expense"
/// - category / source / destinationSource -> the Category/Source id
class SmsFieldMapping {
  final SmsFieldKey fieldKey;
  final SmsFieldMappingMode mode;

  // --- mapped mode ---
  final String? prefixAnchor;
  final String? suffixAnchor;
  final String? pattern; // the *middle* pattern only (no anchors)
  final int captureGroup;
  final String? sampleValue; // preview captured at authoring time

  // --- default mode ---
  final String? defaultValue;

  const SmsFieldMapping({
    required this.fieldKey,
    this.mode = SmsFieldMappingMode.ask,
    this.prefixAnchor,
    this.suffixAnchor,
    this.pattern,
    this.captureGroup = 1,
    this.sampleValue,
    this.defaultValue,
  });

  /// Builds a [SmsFieldMappingMode.mapped] mapping from a text
  /// selection the user made inside [fullText].
  factory SmsFieldMapping.fromSelection({
    required SmsFieldKey fieldKey,
    required String fullText,
    required int selectionStart,
    required int selectionEnd,
  }) {
    final result = SmsPatternBuilder.buildFromSelection(
      fullText: fullText,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
    );

    return SmsFieldMapping(
      fieldKey: fieldKey,
      mode: SmsFieldMappingMode.mapped,
      prefixAnchor: result.prefixAnchor,
      suffixAnchor: result.suffixAnchor,
      pattern: result.pattern,
      captureGroup: 1,
      sampleValue: result.sampleValue,
    );
  }

  /// The full, ready-to-run regex for this mapping, or null if this
  /// field isn't in [SmsFieldMappingMode.mapped].
  String? get fullPattern {
    if (mode != SmsFieldMappingMode.mapped || pattern == null) return null;

    return SmsPatternBuilder.assemblePattern(
      prefixAnchor: prefixAnchor,
      pattern: pattern!,
      suffixAnchor: suffixAnchor,
    );
  }

  /// Runs this mapping's pattern against [message] and returns the
  /// captured value, or null if it didn't match / isn't mapped.
  String? extract(String message) {
    final full = fullPattern;
    if (full == null) return null;

    try {
      final match = RegExp(
        full,
        dotAll: true,
        caseSensitive: false,
      ).firstMatch(message);
      if (match == null) return null;
      return match.group(captureGroup)?.trim();
    } catch (_) {
      return null;
    }
  }

  SmsFieldMapping copyWith({
    SmsFieldMappingMode? mode,
    Object? prefixAnchor = _unset,
    Object? suffixAnchor = _unset,
    Object? pattern = _unset,
    int? captureGroup,
    Object? sampleValue = _unset,
    Object? defaultValue = _unset,
  }) {
    return SmsFieldMapping(
      fieldKey: fieldKey,
      mode: mode ?? this.mode,
      prefixAnchor: identical(prefixAnchor, _unset)
          ? this.prefixAnchor
          : prefixAnchor as String?,
      suffixAnchor: identical(suffixAnchor, _unset)
          ? this.suffixAnchor
          : suffixAnchor as String?,
      pattern: identical(pattern, _unset) ? this.pattern : pattern as String?,
      captureGroup: captureGroup ?? this.captureGroup,
      sampleValue: identical(sampleValue, _unset)
          ? this.sampleValue
          : sampleValue as String?,
      defaultValue: identical(defaultValue, _unset)
          ? this.defaultValue
          : defaultValue as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'fieldKey': fieldKey.name,
    'mode': mode.name,
    'prefixAnchor': prefixAnchor,
    'suffixAnchor': suffixAnchor,
    'pattern': pattern,
    'captureGroup': captureGroup,
    'sampleValue': sampleValue,
    'defaultValue': defaultValue,
  };

  factory SmsFieldMapping.fromJson(Map<String, dynamic> json) {
    return SmsFieldMapping(
      fieldKey: SmsFieldKey.values.byName(json['fieldKey'] as String),
      mode: SmsFieldMappingMode.values.byName(json['mode'] as String),
      prefixAnchor: json['prefixAnchor'] as String?,
      suffixAnchor: json['suffixAnchor'] as String?,
      pattern: json['pattern'] as String?,
      captureGroup: json['captureGroup'] as int? ?? 1,
      sampleValue: json['sampleValue'] as String?,
      defaultValue: json['defaultValue'] as String?,
    );
  }
}

const Object _unset = Object();

/// A saved SMS template: which sender it applies to, and how to pull
/// each transaction field out of a matching message.
///
/// This is the *domain* model used by the UI and the parser. It is
/// persisted via `SmsTemplateHive` (see sms_template_hive.dart), kept
/// deliberately separate so this class can stay a plain,
/// JSON-serializable value type.
class SmsTemplate {
  final String id;
  final String name;

  /// Matched with "contains" (case-insensitive) against the SMS
  /// sender id. Kept deliberately simple (no regex needed) so that
  /// operator-prefixed DLT sender ids like `AX-SBIBANK` /
  /// `AD-SBIBANK` both match a pattern of just `SBIBANK`.
  final String senderPattern;

  final String sampleMessage;
  final bool enabled;
  final List<SmsFieldMapping> fieldMappings;
  final DateTime createdAt;

  const SmsTemplate({
    required this.id,
    required this.name,
    required this.senderPattern,
    required this.sampleMessage,
    required this.fieldMappings,
    this.enabled = true,
    required this.createdAt,
  });

  SmsFieldMapping? mappingFor(SmsFieldKey key) {
    for (final m in fieldMappings) {
      if (m.fieldKey == key) return m;
    }
    return null;
  }

  bool matchesSender(String sender) {
    final s = sender.trim().toLowerCase();
    final p = senderPattern.trim().toLowerCase();
    if (p.isEmpty) return true;
    return s.contains(p);
  }

  SmsTemplate copyWith({
    String? name,
    String? senderPattern,
    String? sampleMessage,
    bool? enabled,
    List<SmsFieldMapping>? fieldMappings,
  }) {
    return SmsTemplate(
      id: id,
      name: name ?? this.name,
      senderPattern: senderPattern ?? this.senderPattern,
      sampleMessage: sampleMessage ?? this.sampleMessage,
      enabled: enabled ?? this.enabled,
      fieldMappings: fieldMappings ?? this.fieldMappings,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'senderPattern': senderPattern,
    'sampleMessage': sampleMessage,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
    'fieldMappings': fieldMappings.map((m) => m.toJson()).toList(),
  };

  factory SmsTemplate.fromJson(Map<String, dynamic> json) {
    return SmsTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      senderPattern: json['senderPattern'] as String,
      sampleMessage: json['sampleMessage'] as String,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fieldMappings: (json['fieldMappings'] as List)
          .map((m) => SmsFieldMapping.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}