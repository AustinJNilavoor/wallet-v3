/// Turns a raw text selection inside an SMS into a reusable
/// extraction pattern.
///
/// ## The bug this fixes
///
/// The previous version anchored on a fixed 15-character *raw*
/// window immediately before/after the selection. That window has no
/// idea what it contains - if the user selected an amount that
/// happened to sit right after a masked account number
/// (`...A/c XX1234 Rs.500 debited...`), the literal digits `XX1234`
/// got baked into the escaped, hard-coded anchor. The template then
/// only ever matched *that exact SMS* and failed on every future
/// message, where the account number (or merchant, or balance) is
/// different.
///
/// ## The fix
///
/// Instead of a raw character window, we tokenize the text around the
/// selection and walk outward token-by-token, skipping any token that
/// *looks dynamic* (a number, a masked account, a date shape, a long
/// alphanumeric reference code) until we find a token that looks like
/// a stable, literal keyword (e.g. "Rs.", "on", "debited", "A/c",
/// "towards"). That keyword - and only that keyword - becomes the
/// anchor. If no stable token exists within the search window, the
/// anchor is simply left empty rather than falling back to unstable
/// raw text.
class SmsPatternBuilder {
  SmsPatternBuilder._();

  /// How many tokens to look back/forward for a stable anchor before
  /// giving up.
  static const int _maxTokensToScan = 4;

  /// How far (in characters) to look for anchor tokens. Generous
  /// enough to skip over one or two dynamic values, small enough to
  /// stay within the same sentence/clause.
  static const int _searchWindowChars = 50;

  /// Builds a mapping from a selection the user made inside
  /// [fullText]. Returns the pieces needed to construct an
  /// [SmsFieldMappingData]-shaped object (kept generic here so this
  /// file has no dependency on the domain model - see
  /// `SmsFieldMapping.fromSelection` in sms_template.dart for the
  /// convenience wrapper actually used by the UI).
  static SmsPatternResult buildFromSelection({
    required String fullText,
    required int selectionStart,
    required int selectionEnd,
  }) {
    final start = selectionStart.clamp(0, fullText.length);
    final end = selectionEnd.clamp(0, fullText.length);
    final sample = fullText.substring(start, end);

    final prefixAnchor = _findStableAnchorBefore(fullText, start);
    final suffixAnchor = _findStableAnchorAfter(fullText, end);

    return SmsPatternResult(
      sampleValue: sample,
      prefixAnchor: prefixAnchor,
      suffixAnchor: suffixAnchor,
      pattern: genericPatternFor(sample),
    );
  }

  /// Assembles the final, ready-to-run regex from its pieces. Anchors
  /// are optional - if a stable one couldn't be found, that side is
  /// simply left unanchored rather than filled with unstable text.
  static String assemblePattern({
    String? prefixAnchor,
    required String pattern,
    String? suffixAnchor,
  }) {
    final buffer = StringBuffer();

    if (prefixAnchor != null && prefixAnchor.isNotEmpty) {
      buffer.write(escape(prefixAnchor));
      buffer.write(r'\s*');
    }

    buffer.write('(');
    buffer.write(pattern);
    buffer.write(')');

    if (suffixAnchor != null && suffixAnchor.isNotEmpty) {
      buffer.write(r'\s*');
      buffer.write(escape(suffixAnchor));
    }

    return buffer.toString();
  }

  /// Suggests a sender-matching pattern from a raw sender id.
  ///
  /// DLT-registered sender ids in India are typically
  /// `<2-letter operator code>-<BRANDID>` (sometimes with a trailing
  /// `-S`/`-T`/`-P` service suffix), e.g. `AX-SBIBANK`, `AD-SBIBANK`,
  /// `VM-HDFCBK-S`. The leading/trailing codes vary by telecom
  /// operator even for the *same* brand, so the useful, stable part
  /// is the brand id in the middle.
  static String defaultSenderPattern(String sender) {
    final trimmed = sender.trim().toUpperCase();

    final match = RegExp(
      r'^[A-Z]{2}-([A-Z0-9]+)(?:-[A-Z])?$',
    ).firstMatch(trimmed);

    if (match != null) {
      return match.group(1)!;
    }

    return trimmed;
  }

  /// Escapes regex-special characters in [input] so it can be used as
  /// a literal match.
  static String escape(String input) {
    const specials = r'\^$.|?*+()[]{}';
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      if (specials.contains(ch)) buffer.write('\\');
      buffer.write(ch);
    }
    return buffer.toString();
  }

  /// A *generic, shape-based* pattern for the captured value itself.
  ///
  /// Unlike the anchors, this is expected to vary message-to-message
  /// (it's the whole point of extracting it) - so this only needs to
  /// describe its *shape* (digits, date, masked account, free text),
  /// never its literal content.
  static String genericPatternFor(String sample) {
    final trimmed = sample.trim();

    // Amount-like: 1,234.56 / 1234 / 45.00
    if (RegExp(r'^[\d,]+(?:\.\d{1,2})?$').hasMatch(trimmed)) {
      return r'[\d,]+(?:\.\d{1,2})?';
    }

    // Numeric date-like: 26-09-2026, 26/09/26
    if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(trimmed)) {
      return r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}';
    }

    // Textual date-like: 26-SEP-26, 26 Sep 2026
    if (RegExp(
      r'^\d{1,2}[\s-][A-Za-z]{3,9}[\s-]\d{2,4}$',
    ).hasMatch(trimmed)) {
      return r'\d{1,2}[\s-][A-Za-z]{3,9}[\s-]\d{2,4}';
    }

    // Masked account/reference: XX1234, XXXX5678, ****1234
    if (RegExp(r'^[Xx*]+\d+$').hasMatch(trimmed)) {
      return r'[Xx*]+\d+';
    }

    // Plain integer (reference numbers, etc).
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return r'\d+';
    }

    // Fallback: free text (merchant names, notes) - non-greedy,
    // meant to be bounded by a suffix anchor when one exists.
    return r'.+?';
  }

  // -----------------------------------------------------------------
  // Anchor discovery
  // -----------------------------------------------------------------

  static String? _findStableAnchorBefore(String text, int index) {
    final windowStart = (index - _searchWindowChars).clamp(0, index);
    final window = text.substring(windowStart, index);

    final tokens = RegExp(r'\S+').allMatches(window).toList();
    if (tokens.isEmpty) return null;

    // Walk backwards (closest to the selection first).
    final scanCount = tokens.length < _maxTokensToScan
        ? tokens.length
        : _maxTokensToScan;

    for (var i = 0; i < scanCount; i++) {
      final token = tokens[tokens.length - 1 - i].group(0)!;
      if (!_looksDynamic(token)) {
        return token;
      }
    }

    return null;
  }

  static String? _findStableAnchorAfter(String text, int index) {
    final windowEnd = (index + _searchWindowChars).clamp(index, text.length);
    final window = text.substring(index, windowEnd);

    final tokens = RegExp(r'\S+').allMatches(window).toList();
    if (tokens.isEmpty) return null;

    final scanCount = tokens.length < _maxTokensToScan
        ? tokens.length
        : _maxTokensToScan;

    for (var i = 0; i < scanCount; i++) {
      final token = tokens[i].group(0)!;
      if (!_looksDynamic(token)) {
        return token;
      }
    }

    return null;
  }

  /// True if [token] looks like it's part of a *value* (amount, date,
  /// masked account, long reference code) rather than fixed wording.
  static bool _looksDynamic(String token) {
    final t = token.trim();
    if (t.isEmpty) return true;

    // Amount-like.
    if (RegExp(r'^[\d,]+(?:\.\d{1,2})?[.,]?$').hasMatch(t)) return true;

    // Masked account (XX1234, ****5678).
    if (RegExp(r'^[Xx*]+\d+[.,]?$').hasMatch(t)) return true;

    // Pure digits.
    if (RegExp(r'^\d+[.,]?$').hasMatch(t)) return true;

    // Numeric date shape.
    if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}[.,]?$').hasMatch(t)) {
      return true;
    }

    // Long alphanumeric reference/UPI codes, e.g. "UPI234567890123".
    final alnum = t.replaceAll(RegExp(r'[.,]$'), '');
    if (alnum.length >= 8 &&
        RegExp(r'^[A-Za-z0-9]+$').hasMatch(alnum) &&
        RegExp(r'\d').hasMatch(alnum)) {
      return true;
    }

    return false;
  }
}

/// Plain-data result of [SmsPatternBuilder.buildFromSelection], kept
/// free of any Hive/JSON concerns so this file has zero persistence
/// dependencies.
class SmsPatternResult {
  final String sampleValue;
  final String? prefixAnchor;
  final String? suffixAnchor;
  final String pattern;

  const SmsPatternResult({
    required this.sampleValue,
    required this.prefixAnchor,
    required this.suffixAnchor,
    required this.pattern,
  });
}