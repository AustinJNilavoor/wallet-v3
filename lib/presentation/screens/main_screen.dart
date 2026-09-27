import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wallet/data/models/transaction.dart';

import 'package:wallet/presentation/screens/dashboard_screen.dart';
import 'package:wallet/presentation/screens/history_screen.dart';
import 'package:wallet/presentation/screens/input_screen.dart';
import 'package:wallet/presentation/screens/reports_screen.dart';
import 'package:wallet/presentation/screens/settings_screen.dart';
import 'package:wallet/services/permission_helper.dart';

import 'package:wallet/services/sms_transaction_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  int _currentIndex = 0;

  late PageController _pageController;

  // ===========================================================================
  // SMS
  // ===========================================================================

  final SmsQuery _smsQuery = SmsQuery();

  final SmsTransactionService _transactionService =
      const SmsTransactionService();

  /// True while the SMS dialog is currently displayed.
  bool _isSmsDialogOpen = false;

  /// True when the user explicitly dismissed the SMS dialog.
  ///
  /// This prevents the dialog from appearing again during the
  /// current app session.
  ///
  /// When the application is restarted, this value becomes false again.
  bool _smsDialogDismissed = false;

  /// Prevents multiple SMS processing operations at the same time.
  bool _isProcessingSms = false;

  // ===========================================================================
  // PAGES
  // ===========================================================================

  final List<Widget> _pages = const [
    DashboardScreen(),
    HistoryScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    // Wait until the Dashboard has been rendered before opening
    // the SMS dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRecentSmsDialog();
    });
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // TAB NAVIGATION
  // ===========================================================================

  void _onTabTapped(int index) {
    _pageController.jumpToPage(index);

    setState(() {
      _currentIndex = index;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // ===========================================================================
  // ADD MANUAL TRANSACTION
  // ===========================================================================

  void _onAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InputScreen()),
    );
  }

  // ===========================================================================
  // SHOW RECENT SMS DIALOG
  // ===========================================================================

  Future<void> _showRecentSmsDialog() async {
    // -------------------------------------------------------------------------
    // Don't show if the user explicitly dismissed it during this session.
    // -------------------------------------------------------------------------

    if (_smsDialogDismissed) {
      return;
    }

    // -------------------------------------------------------------------------
    // Don't open the same dialog multiple times.
    // -------------------------------------------------------------------------

    if (_isSmsDialogOpen) {
      return;
    }

    // -------------------------------------------------------------------------
    // Only show it on Dashboard.
    // -------------------------------------------------------------------------

    if (_currentIndex != 0) {
      return;
    }

    // -------------------------------------------------------------------------
    // Load latest SMS.
    // -------------------------------------------------------------------------

    final messages = await _getRecentTransactionSms();

    if (!mounted) {
      return;
    }

    // -------------------------------------------------------------------------
    // Nothing to show.
    // -------------------------------------------------------------------------

    if (messages.isEmpty) {
      return;
    }

    _isSmsDialogOpen = true;

    // -------------------------------------------------------------------------
    // Show custom dialog.
    //
    // barrierDismissible is false because we need to know when the user
    // taps outside the modal.
    // -------------------------------------------------------------------------

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          // ---------------------------------------------------------------
          // User tapped outside the modal.
          // ---------------------------------------------------------------
          onTap: () {
            Navigator.of(dialogContext).pop('dismissed');
          },

          child: Center(
            child: GestureDetector(
              // -------------------------------------------------------------
              // Consume taps inside the modal.
              //
              // Without this, tapping an SMS/card could also trigger the
              // outer GestureDetector.
              // -------------------------------------------------------------

              onTap: () {},

              child: Material(
                color: Colors.transparent,

                child: _RecentSmsDialog(
                  messages: messages,

                  onSmsSelected: (sms) async {

                    await _addSmsAsTransaction(sms, dialogContext);
                  },

                  onClose: () {
                    Navigator.of(dialogContext).pop('dismissed');
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    _isSmsDialogOpen = false;

    // -------------------------------------------------------------------------
    // User explicitly dismissed the modal.
    //
    // This includes:
    // - tapping outside
    // - pressing the close button
    //
    // It will not appear again until the app is restarted.
    // -------------------------------------------------------------------------

    if (result == 'dismissed') {
      _smsDialogDismissed = true;
    }
  }

  // ===========================================================================
  // GET RECENT TRANSACTION SMS
  // ===========================================================================

  Future<List<_RecentSms>> _getRecentTransactionSms() async {
    try {
      // -----------------------------------------------------------------------
      // SMS PERMISSION
      // -----------------------------------------------------------------------

      final hasPermission = await PermissionHelper.requestSmsPermission();

      if (!hasPermission) {
        return [];
      }

      // -----------------------------------------------------------------------
      // TRANSACTION BOX
      // -----------------------------------------------------------------------

      final transactionBox = Hive.box<Transaction>('transactions');

      // -----------------------------------------------------------------------
      // GET HASHES OF SMS THAT HAVE ALREADY BEEN ADDED
      // -----------------------------------------------------------------------

      final addedSmsHashes = transactionBox.values
          .map((transaction) => transaction.smsHash)
          .whereType<String>()
          .toSet();

      // -----------------------------------------------------------------------
      // DATE RANGE
      // -----------------------------------------------------------------------

      final now = DateTime.now();

      final todayStart = DateTime(now.year, now.month, now.day);

      final yesterdayStart = todayStart.subtract(const Duration(days: 1));

      // -----------------------------------------------------------------------
      // READ SMS
      // -----------------------------------------------------------------------

      final smsList = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 1000,
        sort: true,
      );

      final result = <_RecentSms>[];

      final seenIds = <String>{};

      // -----------------------------------------------------------------------
      // FILTER SMS
      // -----------------------------------------------------------------------

      for (int index = 0; index < smsList.length; index++) {
        final sms = smsList[index];

        final date = sms.date ?? DateTime.now();

        // ---------------------------------------------------------------------
        // Only today and yesterday.
        // ---------------------------------------------------------------------

        if (date.isBefore(yesterdayStart)) {
          continue;
        }

        // ---------------------------------------------------------------------
        // Ignore future SMS.
        // ---------------------------------------------------------------------

        if (date.isAfter(now)) {
          continue;
        }

        final body = (sms.body ?? '').trim();

        final sender = (sms.sender ?? 'Unknown').trim();

        // ---------------------------------------------------------------------
        // Ignore empty SMS.
        // ---------------------------------------------------------------------

        if (body.isEmpty) {
          continue;
        }

        // ---------------------------------------------------------------------
        // Generate SMS hash.
        // ---------------------------------------------------------------------

        final smsHash = SmsHashUtil.generate(
          sender: sender,
          body: body,
          date: date,
        );

        // ---------------------------------------------------------------------
        // IMPORTANT:
        //
        // If this SMS was already saved as a transaction, don't show it.
        // ---------------------------------------------------------------------

        if (addedSmsHashes.contains(smsHash)) {
          continue;
        }

        // ---------------------------------------------------------------------
        // Check whether this SMS is a transaction SMS.
        //
        // The keyword/transaction detection remains inside
        // SmsTransactionService.
        // ---------------------------------------------------------------------

        if (!_transactionService.isTransactionSms(body)) {
          continue;
        }

        // ---------------------------------------------------------------------
        // Create unique UI ID.
        // ---------------------------------------------------------------------

        final id = '${sender}_${date.millisecondsSinceEpoch}_$index';

        if (seenIds.contains(id)) {
          continue;
        }

        seenIds.add(id);

        // ---------------------------------------------------------------------
        // Add to result.
        // ---------------------------------------------------------------------

        result.add(_RecentSms(id: id, sender: sender, body: body, date: date));
      }

      // -----------------------------------------------------------------------
      // Newest first.
      // -----------------------------------------------------------------------

      result.sort((a, b) => b.date.compareTo(a.date));

      return result;
    } catch (e) {
      //TODO: Handle error appropriately, e.g., log it or show a message to the user.

      return [];
    }
  }

  // ===========================================================================
  // SMS -> TRANSACTION -> INPUT SCREEN
  // ===========================================================================

  Future<void> _addSmsAsTransaction(
    _RecentSms sms,
    BuildContext dialogContext,
  ) async {
    // -------------------------------------------------------------------------
    // Prevent multiple taps.
    // -------------------------------------------------------------------------

    if (_isProcessingSms) {
      return;
    }

    setState(() {
      _isProcessingSms = true;
    });

    try {
      // -----------------------------------------------------------------------
      // Convert SMS to Transaction.
      // -----------------------------------------------------------------------

      final result = _transactionService.createTransaction(
        sender: sms.sender,
        body: sms.body,
        date: sms.date,
      );

      // -----------------------------------------------------------------------
      // Conversion failed.
      // -----------------------------------------------------------------------

      if (!result.isSuccess) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'Unable to create transaction from SMS.',
            ),
          ),
        );

        return;
      }

      // -----------------------------------------------------------------------
      // Get generated transaction.
      // -----------------------------------------------------------------------

      final transaction = result.transaction!;

      // -----------------------------------------------------------------------
      // Close SMS dialog.
      //
      // IMPORTANT:
      // We DO NOT set _smsDialogDismissed here.
      //
      // This is a selection, not a dismissal.
      // Therefore the dialog can appear again after InputScreen.
      // -----------------------------------------------------------------------

      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop('sms_selected');
      }

      // -----------------------------------------------------------------------
      // Open InputScreen.
      //
      // InputScreen is responsible for displaying/editing/saving the
      // transaction.
      // -----------------------------------------------------------------------

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              InputScreen(editTransaction: transaction, isSmsTransaction: true),
        ),
      );

      // -----------------------------------------------------------------------
      // User returned from InputScreen.
      //
      // Reload SMS list and show the dialog again.
      //
      // The newly saved SMS will now be excluded because its smsHash
      // is stored in the Transaction.
      // -----------------------------------------------------------------------

      if (!mounted) {
        return;
      }

      if (!_smsDialogDismissed) {
        _isProcessingSms = false;
        await _showRecentSmsDialog();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to process this SMS.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingSms = false;

        });
      }
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,

      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (_currentIndex != 0) {
          _onTabTapped(0);
        }
      },

      child: Scaffold(
        // =====================================================================
        // PAGE CONTENT
        // =====================================================================

        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: _pages,
        ),

        // =====================================================================
        // BOTTOM NAVIGATION
        // =====================================================================
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,

          onTap: _onTabTapped,

          type: BottomNavigationBarType.fixed,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),

        // =====================================================================
        // ADD TRANSACTION
        // =====================================================================
        floatingActionButton: FloatingActionButton(
          onPressed: _onAddTransaction,

          child: const Icon(Icons.add),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

// =============================================================================
// RECENT SMS MODEL
// =============================================================================

class _RecentSms {
  final String id;

  final String sender;

  final String body;

  final DateTime date;

  const _RecentSms({
    required this.id,
    required this.sender,
    required this.body,
    required this.date,
  });
}

// =============================================================================
// CUSTOM SMS DIALOG
// =============================================================================

class _RecentSmsDialog extends StatelessWidget {
  final List<_RecentSms> messages;

  final Future<void> Function(_RecentSms sms) onSmsSelected;

  final VoidCallback onClose;

  const _RecentSmsDialog({
    required this.messages,
    required this.onSmsSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // SCREEN SIZE
    // -------------------------------------------------------------------------

    final screenSize = MediaQuery.sizeOf(context);

    // -------------------------------------------------------------------------
    // MAXIMUM MODAL SIZE
    // -------------------------------------------------------------------------

    const maxDialogWidth = 500.0;

    const maxDialogHeight = 650.0;

    // -------------------------------------------------------------------------
    // DYNAMIC SIZE
    // -------------------------------------------------------------------------

    final calculatedWidth = screenSize.width * 0.90;

    final calculatedHeight = screenSize.height * 0.75;

    final dialogWidth = calculatedWidth > maxDialogWidth
        ? maxDialogWidth
        : calculatedWidth;

    final dialogHeight = calculatedHeight > maxDialogHeight
        ? maxDialogHeight
        : calculatedHeight;

    // -------------------------------------------------------------------------
    // MODAL
    // -------------------------------------------------------------------------

    return Container(
      width: dialogWidth,

      height: dialogHeight,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),

            blurRadius: 30,

            spreadRadius: 2,

            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        children: [
          // ===================================================================
          // HEADER
          // ===================================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),

            child: Row(
              children: [
                // -------------------------------------------------------------
                // SMS ICON
                // -------------------------------------------------------------

                Container(
                  width: 44,
                  height: 44,

                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.10),

                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: const Icon(
                    Icons.sms_outlined,

                    color: Colors.blueGrey,

                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                // -------------------------------------------------------------
                // TITLE
                // -------------------------------------------------------------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Recent Transactions',

                        style: TextStyle(
                          fontSize: 18,

                          fontWeight: FontWeight.bold,

                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Transactions detected from SMS',

                        style: TextStyle(
                          fontSize: 12,

                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // -------------------------------------------------------------
                // CLOSE
                // -------------------------------------------------------------
                IconButton(
                  tooltip: 'Close',

                  onPressed: onClose,

                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ===================================================================
          // SMS COUNT
          // ===================================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),

            child: Row(
              children: [
                Text(
                  '${messages.length} transaction SMS',

                  style: TextStyle(
                    fontSize: 12,

                    fontWeight: FontWeight.w600,

                    color: Colors.grey.shade600,
                  ),
                ),

                const Spacer(),

                Text(
                  'Today & Yesterday',

                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // ===================================================================
          // SMS LIST
          // ===================================================================
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),

              itemCount: messages.length,

              separatorBuilder: (_, __) {
                return const SizedBox(height: 8);
              },

              itemBuilder: (context, index) {
                return _SmsDialogCard(
                  sms: messages[index],

                  onTap: () {
                    onSmsSelected(messages[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SMS CARD
// =============================================================================

class _SmsDialogCard extends StatelessWidget {
  final _RecentSms sms;

  final VoidCallback onTap;

  const _SmsDialogCard({required this.sms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final body = sms.body.toLowerCase();

    // -------------------------------------------------------------------------
    // Detect income/expense only for UI icon.
    //
    // Actual transaction type is still determined by
    // SmsTransactionService.
    // -------------------------------------------------------------------------

    final isIncome =
        body.contains('credited') ||
        body.contains('credit') ||
        body.contains('deposited') ||
        body.contains('received');

    final icon = isIncome
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    final iconColor = isIncome
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD32F2F);

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(14),

        child: Container(
          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: Colors.grey.shade50,

            borderRadius: BorderRadius.circular(14),

            border: Border.all(color: Colors.grey.shade200),
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // =================================================================
              // ICON
              // =================================================================

              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(11),
                ),

                child: Icon(icon, color: iconColor, size: 20),
              ),

              const SizedBox(width: 11),

              // =================================================================
              // SMS CONTENT
              // =================================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sms.sender,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontSize: 14,

                              fontWeight: FontWeight.w600,

                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          _formatDate(sms.date),

                          style: TextStyle(
                            fontSize: 10,

                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      sms.body,

                      maxLines: 3,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 12,

                        height: 1.35,

                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 3),

              // =================================================================
              // ARROW
              // =================================================================
              Icon(
                Icons.chevron_right_rounded,

                size: 20,

                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DATE FORMAT
  // ===========================================================================

  String _formatDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final smsDate = DateTime(date.year, date.month, date.day);

    if (smsDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'Yesterday';
  }
}
