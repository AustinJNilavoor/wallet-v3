/// Lightweight, UI-layer representation of an SMS.
///
/// Kept separate from any SMS-reading package's own message type so
/// screens and models can depend on this instead of a third-party
/// type directly.
class SmsPreviewItem {
  final String sender;
  final String body;
  final DateTime date;

  const SmsPreviewItem({
    required this.sender,
    required this.body,
    required this.date,
  });
}