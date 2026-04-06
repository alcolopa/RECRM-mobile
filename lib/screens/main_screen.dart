import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../api/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'properties/properties_screen.dart';
import 'leads/leads_list_screen.dart';
import 'contacts/contacts_list_screen.dart';
import 'deals/deals_list_screen.dart';
import 'tasks/tasks_list_screen.dart';
import 'payouts/payouts_screen.dart';
import 'settings/organization_settings_screen.dart';

class TabItem {
  final String label;
  final IconData icon;
  final Widget screen;
  final String permission;

  TabItem({
    required this.label,
    required this.icon,
    required this.screen,
    required this.permission,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<TabItem> _getVisibleTabs(AuthProvider auth) {
    final allTabs = [
      TabItem(
        label: 'DASHBOARD',
        icon: LucideIcons.layoutDashboard,
        screen: const DashboardScreen(),
        permission: 'DASHBOARD_VIEW',
      ),
      TabItem(
        label: 'PROPERTIES',
        icon: LucideIcons.building2,
        screen: const PropertiesScreen(),
        permission: 'PROPERTIES_VIEW',
      ),
      TabItem(
        label: 'LEADS',
        icon: LucideIcons.target,
        screen: const LeadsListScreen(),
        permission: 'LEADS_VIEW',
      ),
      TabItem(
        label: 'CONTACTS',
        icon: LucideIcons.users,
        screen: const ContactsListScreen(),
        permission: 'CONTACTS_VIEW',
      ),
      TabItem(
        label: 'DEALS',
        icon: LucideIcons.briefcase,
        screen: const DealsListScreen(),
        permission: 'DEALS_VIEW',
      ),
    ];

    return allTabs.where((tab) => auth.hasPermission(tab.permission)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tabs = _getVisibleTabs(auth);

    // If current index is out of range due to permissions removal, reset to 0
    if (_currentIndex >= tabs.length && tabs.isNotEmpty) {
      _currentIndex = 0;
    }

    if (tabs.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have permission to view any modules.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          tabs[_currentIndex].label,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      drawer: _buildDrawer(context, auth),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          currentIndex: _currentIndex,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.0,
          ),
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: tabs
              .map(
                (tab) => BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Icon(tab.icon, size: 20),
                  ),
                  label: tab.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    final userName = user != null ? '${user['firstName']} ${user['lastName']}' : 'User';
    final userEmail = user != null ? user['email'] : '';

    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryColor),
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (auth.hasPermission('TASKS_VIEW'))
            ListTile(
              leading: const Icon(LucideIcons.checkCircle2),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TasksListScreen()),
                );
              },
            ),
          if (auth.hasPermission('PAYOUTS_VIEW'))
            ListTile(
              leading: const Icon(LucideIcons.dollarSign),
              title: const Text('Financials'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PayoutsScreen()),
                );
              },
            ),
          if (auth.hasPermission('ORG_SETTINGS_EDIT'))
            ListTile(
              leading: const Icon(LucideIcons.settings),
              title: const Text('Organization Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrganizationSettingsScreen()),
                );
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.user),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              // Navigation logic for Profile
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: AppTheme.errorColor),
            title: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
            onTap: () => auth.logout(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
