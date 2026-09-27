import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:wallet/data/models/sms_preview_item.dart';

enum _LoadState {
  loading,
  permissionDenied,
  permissionPermanentlyDenied,
  loaded,
  error,
}

/// Full-message SMS browser, backed by the real device inbox.
///
/// Requests READ_SMS on first load, reads the inbox, and lists every
/// message full-text (no truncation). Pass [onSelect] to react to a
/// tap (e.g. to start "create template from this SMS") - leave it
/// null to make the list read-only.
class SmsListScreen extends StatefulWidget {
  final void Function(SmsPreviewItem message)? onSelect;

  const SmsListScreen({super.key, this.onSelect});

  @override
  State<SmsListScreen> createState() => _SmsListScreenState();
}

class _SmsListScreenState extends State<SmsListScreen> {
  final SmsQuery _smsQuery = SmsQuery();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM, hh:mm a');

  _LoadState _state = _LoadState.loading;
  List<SmsPreviewItem> _messages = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _state = _LoadState.loading);

    final granted = await _ensurePermission();
    if (!mounted) return;

    if (!granted) {
      return; // _ensurePermission already set the right denied state.
    }

    try {
      final rawMessages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 1000,
      );

      final mapped =
          rawMessages
              .where((m) => (m.body ?? '').trim().isNotEmpty)
              .map(
                (m) => SmsPreviewItem(
                  // Some flutter_sms_inbox versions expose this as
                  // `.sender` instead of `.address` - swap the field
                  // name below if this doesn't compile for you.
                  sender: m.address?.trim().isNotEmpty == true
                      ? m.address!.trim()
                      : 'Unknown',
                  body: m.body!.trim(),
                  date: m.date ?? DateTime.now(),
                ),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _messages = mapped;
        _state = _LoadState.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _LoadState.error);
    }
  }

  Future<bool> _ensurePermission() async {
    var status = await Permission.sms.status;

    if (!status.isGranted) {
      status = await Permission.sms.request();
    }

    if (status.isGranted) return true;

    if (!mounted) return false;

    setState(() {
      _state = status.isPermanentlyDenied
          ? _LoadState.permissionPermanentlyDenied
          : _LoadState.permissionDenied;
    });

    return false;
  }

  List<SmsPreviewItem> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _messages;

    return _messages
        .where(
          (m) =>
              m.sender.toLowerCase().contains(query) ||
              m.body.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Messages'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _state == _LoadState.loading ? null : _loadMessages,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator());

      case _LoadState.permissionDenied:
        return _buildMessageState(
          icon: Icons.sms_failed_outlined,
          title: 'SMS permission needed',
          subtitle: 'Allow SMS access to read your messages.',
          buttonLabel: 'Grant Permission',
          onPressed: _loadMessages,
        );

      case _LoadState.permissionPermanentlyDenied:
        return _buildMessageState(
          icon: Icons.sms_failed_outlined,
          title: 'SMS permission blocked',
          subtitle: 'Enable SMS access for this app from Settings.',
          buttonLabel: 'Open Settings',
          onPressed: openAppSettings,
        );

      case _LoadState.error:
        return _buildMessageState(
          icon: Icons.error_outline,
          title: 'Could not read messages',
          subtitle: 'Something went wrong while loading your inbox.',
          buttonLabel: 'Try Again',
          onPressed: _loadMessages,
        );

      case _LoadState.loaded:
        return _buildList();
    }
  }

  Widget _buildList() {
    final messages = _filtered;

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _buildSearchField(),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${messages.length} message${messages.length == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ),

          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildMessageCard(messages[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: 'Search sender or message',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        filled: true,
        fillColor: Colors.grey.shade200.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildMessageCard(SmsPreviewItem message) {
    final palette = _paletteFor(message.sender);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: widget.onSelect == null ? null : () => widget.onSelect!(message),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: palette.background,
                  child: Text(
                    _initialsFor(message.sender),
                    style: TextStyle(
                      color: palette.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message.sender,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _dateFormat.format(message.date),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              message.body,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),

            if (widget.onSelect != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to use this message',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sms_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _query.isEmpty
                  ? 'No messages found'
                  : 'No messages match "$_query"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }

  String _initialsFor(String sender) {
    final letters = sender.trim().replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.isEmpty) return '#';
    return letters.substring(0, letters.length > 1 ? 2 : 1).toUpperCase();
  }

  _AvatarPalette _paletteFor(String sender) {
    final index = sender.hashCode.abs() % _avatarPalettes.length;
    return _avatarPalettes[index];
  }
}

class _AvatarPalette {
  final Color background;
  final Color foreground;

  const _AvatarPalette(this.background, this.foreground);
}

const List<_AvatarPalette> _avatarPalettes = [
  _AvatarPalette(Color(0xFFE3DDF6), Color(0xFF6C4CD6)), // lavender
  _AvatarPalette(Color(0xFFDCEAFB), Color(0xFF2F6FE0)), // blue
  _AvatarPalette(Color(0xFFDDF3E4), Color(0xFF1F9254)), // green
  _AvatarPalette(Color(0xFFFBE0E0), Color(0xFFE0413F)), // red
  _AvatarPalette(Color(0xFFFDEBD3), Color(0xFFDB8A1F)), // orange
  _AvatarPalette(Color(0xFFDBF3F1), Color(0xFF1B9E93)), // teal
];