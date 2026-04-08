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
    final theme = Theme.of(context);
    final user = auth.user;
    final userName = user != null
        ? '${user['firstName']} ${user['lastName']}'
        : 'Consultant';
    final userEmail = user != null ? user['email'] : '';
    final initials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'C';

    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(28, 64, 28, 32),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4), // Archictectural corner
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.0),
            child: Divider(height: 1, color: AppTheme.surfaceContainer),
          ),
          const SizedBox(height: 24),

          // Menu Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (auth.hasPermission('TASKS_VIEW'))
                  _buildDrawerItem(
                    context,
                    icon: LucideIcons.calendarCheck,
                    label: 'Workflow Tasks',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TasksListScreen(),
                        ),
                      );
                    },
                  ),
                if (auth.hasPermission('PAYOUTS_VIEW'))
                  _buildDrawerItem(
                    context,
                    icon: LucideIcons.banknote,
                    label: 'Financial Performance',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PayoutsScreen(),
                        ),
                      );
                    },
                  ),
                if (auth.hasPermission('ORG_SETTINGS_EDIT'))
                  _buildDrawerItem(
                    context,
                    icon: LucideIcons.building,
                    label: 'Organization Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrganizationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Divider(height: 1, color: AppTheme.surfaceContainer),
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.userCircle,
                  label: 'Personal Curation',
                  onTap: () {
                    Navigator.pop(context);
                    // Add Profile implementation
                  },
                ),
              ],
            ),
          ),

          // Footer Section
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.logOut,
                  label: 'Sign Out',
                  isDestructive: true,
                  onTap: () => auth.logout(),
                ),
                const SizedBox(height: 12),
                Text(
                  'ESTATEHUB v1.0',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2.0,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? AppTheme.errorColor
        : isSelected
            ? AppTheme.primaryColor
            : AppTheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        leading: Icon(icon, size: 20, color: color.withValues(alpha: isSelected ? 1 : 0.7)),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        tileColor: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : null,
      ),
    );
  }
}
