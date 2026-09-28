import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../models/models.dart';
import '../auth/login_page.dart';
import '../pos/pos_page.dart';
import '../reports/report_page.dart';
import '../settings/settings_page.dart';
import 'dashboard_page.dart';
class HomePage extends StatefulWidget {
  final String username;
  final String role;

  const HomePage({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int index = 0;

  final posKey =
      GlobalKey<PosPageState>();

  Future<void> logout() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (_) => false,
    );
  }

  void selectPage(int v) {
    setState(() => index = v);

    // Refresh POS every time the transaction tab
    // is opened. This makes newly added stock
    // immediately visible without restarting app.
    if (v == 1) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        posKey.currentState?.load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        username: widget.username,
      ),
      PosPage(
        key: posKey,
        cashier: widget.username,
      ),
      ReportPage(
        role: widget.role,
      ),
      if (widget.role == 'Administrator')
        SettingsPage(
          username: widget.username,
        ),
    ];

    final titles = [
      'Dashboard',
      'Transaksi',
      'Laporan',
      if (widget.role == 'Administrator')
        'Pengaturan',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${titles[index]} • ${widget.role}',
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: selectPage,
        destinations: [
          const NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            selectedIcon:
                Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(
              Icons.point_of_sale_outlined,
            ),
            selectedIcon:
                Icon(Icons.point_of_sale),
            label: 'Transaksi',
          ),
          const NavigationDestination(
            icon: Icon(
              Icons.analytics_outlined,
            ),
            selectedIcon:
                Icon(Icons.analytics),
            label: 'Laporan',
          ),
          if (widget.role ==
              'Administrator')
            const NavigationDestination(
              icon: Icon(
                Icons.settings_outlined,
              ),
              selectedIcon:
                  Icon(Icons.settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}
