import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:wallet/presentation/screens/input_screen.dart';
import 'package:wallet/services/sms_transaction_service.dart';

class SmsPreview {
  final String id;
  final String sender;
  final String body;
  final DateTime date;

  const SmsPreview({
    required this.id,
    required this.sender,
    required this.body,
    required this.date,
  });
}

class SmsListScreen extends StatefulWidget {
  final List<SmsPreview>? messages;
  final void Function(SmsPreview message)? onMessageTap;

  const SmsListScreen({
    super.key,
    this.messages,
    this.onMessageTap,
  });

  @override
  State<SmsListScreen> createState() => _SmsListScreenState();
}

class _SmsListScreenState extends State<SmsListScreen> {
  static const Color _backgroundColor = Color(0xFFF5F7FA);

  // SMS
  final SmsQuery _smsQuery = SmsQuery();

  // Search
  final TextEditingController _searchController =
      TextEditingController();

  // SMS -> Transaction business logic
  final SmsTransactionService _transactionService =
      const SmsTransactionService();

  List<SmsPreview> _allMessages = [];

  String _searchQuery = '';

  bool _isLoading = true;

  String? _errorMessage;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    _loadMessages();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      _searchQuery =
          _searchController.text.trim().toLowerCase();
    });
  }

  // ===========================================================================
  // LOAD SMS
  // ===========================================================================

  Future<void> _loadMessages() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // -----------------------------------------------------------------------
      // If messages were supplied externally, use them.
      // -----------------------------------------------------------------------

      if (widget.messages != null) {
        final messages =
            List<SmsPreview>.from(widget.messages!);

        messages.sort(
          (a, b) => b.date.compareTo(a.date),
        );

        if (!mounted) return;

        setState(() {
          _allMessages = messages;
          _isLoading = false;
        });

        return;
      }

      // -----------------------------------------------------------------------
      // Request SMS permission.
      // -----------------------------------------------------------------------

      final permissionGranted =
          await _requestSmsPermission();

      if (!permissionGranted) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              'SMS permission is required to read your messages.';
        });

        return;
      }

      // -----------------------------------------------------------------------
      // Read inbox SMS.
      // -----------------------------------------------------------------------

      final messages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 1000,
        sort: true,
      );

      final previews = <SmsPreview>[];

      for (int index = 0;
          index < messages.length;
          index++) {
        final sms = messages[index];

        previews.add(
          SmsPreview(
            id: _buildMessageId(sms, index),
            sender: sms.sender ?? 'Unknown',
            body: sms.body ?? '',
            date: sms.date ?? DateTime.now(),
          ),
        );
      }

      // Newest first.
      previews.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      if (!mounted) return;

      setState(() {
        _allMessages = previews;
        _isLoading = false;
      });
    } catch (e) {
//TODO: Handle error appropriately, e.g., log it or show a message to the user.
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to read SMS messages.';
      });
    }
  }

  // ===========================================================================
  // SMS PERMISSION
  // ===========================================================================

  Future<bool> _requestSmsPermission() async {
    var status = await Permission.sms.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.sms.request();

      if (status.isGranted) {
        return true;
      }
    }

    if (status.isPermanentlyDenied) {
      if (!mounted) {
        return false;
      }

      await _showPermissionSettingsDialog();

      return false;
    }

    return false;
  }

  Future<void> _showPermissionSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'SMS Permission Required',
          ),
          content: const Text(
            'SMS access has been permanently denied. '
            'Please enable SMS permission from app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);

                await openAppSettings();
              },
              child: const Text(
                'Open Settings',
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // MESSAGE ID
  // ===========================================================================

  String _buildMessageId(
    SmsMessage message,
    int index,
  ) {
    final timestamp =
        message.date?.millisecondsSinceEpoch ?? 0;

    return '${message.sender ?? 'unknown'}_${timestamp}_$index';
  }

  // ===========================================================================
  // FILTER
  // ===========================================================================

  List<SmsPreview> get _filteredMessages {
    if (_searchQuery.isEmpty) {
      return _allMessages;
    }

    return _allMessages.where((message) {
      final sender =
          message.sender.toLowerCase();

      final body =
          message.body.toLowerCase();

      return sender.contains(_searchQuery) ||
          body.contains(_searchQuery);
    }).toList();
  }

  // ===========================================================================
  // GROUP BY DATE
  // ===========================================================================

  List<MapEntry<String, List<SmsPreview>>>
      get _groupedMessages {
    final groups =
        <String, List<SmsPreview>>{};

    for (final message in _filteredMessages) {
      final label =
          _dateLabel(message.date);

      groups
          .putIfAbsent(
            label,
            () => [],
          )
          .add(message);
    }

    return groups.entries.toList();
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final messageDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        today.difference(messageDate).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    return DateFormat(
      'dd MMM yyyy',
    ).format(date);
  }

  // ===========================================================================
  // SELECT SMS
  // ===========================================================================

  Future<void> _openSmsInInputScreen(
    SmsPreview message,
  ) async {
    // -------------------------------------------------------------------------
    // The selected SMS is passed to the service.
    //
    // This screen does NOT:
    // - extract amount
    // - determine transaction type
    // - find source
    // - find category
    // - create Transaction
    //
    // SmsTransactionService handles all of that.
    // -------------------------------------------------------------------------

    final result =
        _transactionService.createTransaction(
      sender: message.sender,
      body: message.body,
      date: message.date,
    );

    // -------------------------------------------------------------------------
    // Transaction creation failed.
    // -------------------------------------------------------------------------

    if (!result.isSuccess) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                'Unable to create transaction from this SMS.',
          ),
        ),
      );

      return;
    }

    // -------------------------------------------------------------------------
    // Notify parent.
    // -------------------------------------------------------------------------

    widget.onMessageTap?.call(message);

    // -------------------------------------------------------------------------
    // Open InputScreen.
    // -------------------------------------------------------------------------

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InputScreen(
          editTransaction:
              result.transaction!,
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final groups = _groupedMessages;

    return Scaffold(
      backgroundColor: _backgroundColor,

      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.black87,
            ),
            onPressed:
                _isLoading ? null : _loadMessages,
          ),
        ],
      ),

      body: Column(
        children: [
          _buildSearchField(),

          const SizedBox(height: 4),

          Expanded(
            child: _buildBody(groups),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody(
    List<MapEntry<String, List<SmsPreview>>> groups,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (groups.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,

      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),

        itemCount: groups.length,

        itemBuilder: (context, index) {
          final entry = groups[index];

          return _buildGroup(
            entry.key,
            entry.value,
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SEARCH FIELD
  // ===========================================================================

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        0,
      ),

      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,

          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),

        child: TextField(
          controller: _searchController,

          textInputAction:
              TextInputAction.search,

          decoration: InputDecoration(
            hintText:
                'Search sender or message',

            prefixIcon: const Icon(
              Icons.search,
              color: Colors.grey,
            ),

            suffixIcon:
                _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),

            border: InputBorder.none,

            contentPadding:
                const EdgeInsets.symmetric(
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DATE GROUP
  // ===========================================================================

  Widget _buildGroup(
    String label,
    List<SmsPreview> messages,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            top: 16,
            bottom: 8,
          ),

          child: Text(
            label,

            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),

        ...messages.map(
          _buildMessageCard,
        ),
      ],
    );
  }

  // ===========================================================================
  // SMS CARD
  // ===========================================================================

  Widget _buildMessageCard(
    SmsPreview message,
  ) {
    final style =
        _styleFor(message.body);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(
              alpha: 0.06,
            ),
            blurRadius: 10,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        borderRadius:
            BorderRadius.circular(14),

        child: InkWell(
          borderRadius:
              BorderRadius.circular(14),

          onTap: () {
            _openSmsInInputScreen(
              message,
            );
          },

          child: Padding(
            padding: const EdgeInsets.all(
              14,
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // -------------------------------------------------------------
                // ICON
                // -------------------------------------------------------------

                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: style.background,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  child: Icon(
                    style.icon,
                    color: style.iconColor,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                // -------------------------------------------------------------
                // MESSAGE CONTENT
                // -------------------------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.sender,

                              maxLines: 1,

                              overflow:
                                  TextOverflow
                                      .ellipsis,

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Text(
                            DateFormat(
                              'hh:mm a',
                            ).format(
                              message.date,
                            ),

                            style: TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey
                                  .shade500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        message.body,

                        maxLines: 2,

                        overflow:
                            TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 13.5,
                          color:
                              Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.sms_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 16),

            Text(
              _searchQuery.isEmpty
                  ? 'No messages found'
                  : 'No matches for "$_searchQuery"',

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),

            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),

              Text(
                'Your SMS inbox is empty.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ERROR STATE
  // ===========================================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.sms_failed_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 16),

            Text(
              _errorMessage ??
                  'Unable to read messages',

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadMessages,

              icon: const Icon(
                Icons.refresh,
              ),

              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SMS ICON STYLE
  // ===========================================================================

  _MessageStyle _styleFor(
    String body,
  ) {
    final lower =
        body.toLowerCase();

    // -------------------------------------------------------------------------
    // INCOME
    // -------------------------------------------------------------------------

    if (lower.contains('credited') ||
        lower.contains('credit') ||
        lower.contains('deposited') ||
        lower.contains('received')) {
      return _MessageStyle(
        icon:
            Icons.arrow_downward_rounded,

        iconColor:
            const Color(0xFF2E7D32),

        background:
            const Color(0xFF2E7D32)
                .withValues(
          alpha: 0.12,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // EXPENSE
    // -------------------------------------------------------------------------

    if (lower.contains('debited') ||
        lower.contains('spent') ||
        lower.contains('sent') ||
        lower.contains('debit') ||
        lower.contains('paid')) {
      return _MessageStyle(
        icon:
            Icons.arrow_upward_rounded,

        iconColor:
            const Color(0xFFD32F2F),

        background:
            const Color(0xFFD32F2F)
                .withValues(
          alpha: 0.12,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // OTP
    // -------------------------------------------------------------------------

    if (lower.contains('otp')) {
      return _MessageStyle(
        icon:
            Icons.lock_outline_rounded,

        iconColor:
            const Color(0xFFF9A825),

        background:
            const Color(0xFFF9A825)
                .withValues(
          alpha: 0.15,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // NORMAL SMS
    // -------------------------------------------------------------------------

    return _MessageStyle(
      icon:
          Icons.sms_outlined,

      iconColor:
          const Color(0xFF5C6BC0),

      background:
          const Color(0xFF5C6BC0)
              .withValues(
        alpha: 0.12,
      ),
    );
  }
}

// =============================================================================
// MESSAGE STYLE
// =============================================================================

class _MessageStyle {
  final IconData icon;
  final Color iconColor;
  final Color background;

  const _MessageStyle({
    required this.icon,
    required this.iconColor,
    required this.background,
  });
}
