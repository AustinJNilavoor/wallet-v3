import 'package:flutter/material.dart';
import 'package:wallet/presentation/screens/dashboard_screen.dart';
import 'package:wallet/presentation/screens/history_screen.dart';
import 'package:wallet/presentation/screens/input_screen.dart';
import 'package:wallet/presentation/screens/reports_screen.dart';
import 'package:wallet/presentation/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = const [
    DashboardScreen(),
    HistoryScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

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
      MaterialPageRoute(builder: (context) => const InputScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0, // Only allow system pop if on Dashboard
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // If the system already handled it, do nothing

        // If not on Dashboard, switch back to index 0
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
