import 'package:flutter/material.dart';
import 'package:wallet/presentation/screens/dashboard_screen.dart';
import 'package:wallet/presentation/screens/history_screen.dart';
import 'package:wallet/presentation/screens/input_screen.dart';
import 'package:wallet/presentation/screens/reports_screen.dart';
import 'package:wallet/presentation/screens/settings_screen.dart';
import 'package:wallet/services/sms/sms_sync_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late PageController _pageController;

  // SMS sync service
  final SmsSyncService _smsSyncService = SmsSyncService();

  bool _isSmsSyncing = false;

  final List<Widget> _pages = const [
    DashboardScreen(),
    HistoryScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    // Start SMS synchronization after the screen is loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSms();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Reads and processes SMS messages.
  ///
  /// This runs only when MainScreen is created/opened.
  /// It does not run while the application is closed.
  Future<void> _syncSms() async {
    if (_isSmsSyncing) {
      return;
    }

    _isSmsSyncing = true;

    try {
      final result = await _smsSyncService.sync();

      debugPrint(
        'SMS Sync completed: '
        'successful=${result.successful}, '
        'scanned=${result.scanned}, '
        'imported=${result.imported}, '
        'duplicates=${result.duplicates}, '
        'unmatched=${result.unmatched}, '
        'parsingFailed=${result.parsingFailed}',
      );

      if (!result.successful) {
        debugPrint(
          'SMS Sync failed: ${result.error}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('SMS Sync error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isSmsSyncing = false;
    }
  }

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

  void _onAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InputScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentIndex != 0) {
          _onTabTapped(0);
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: _pages,
        ),

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

        floatingActionButton: FloatingActionButton(
          onPressed: _onAddTransaction,
          child: const Icon(Icons.add),
        ),

        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}