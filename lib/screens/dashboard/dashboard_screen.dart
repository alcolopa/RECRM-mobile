import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/auth_provider.dart';
import '../../theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              title: Text(
                'Portfolio Insight',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(color: AppTheme.backgroundColor),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  LucideIcons.logOut,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                onPressed: () => auth.logout(),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),

                // Welcome Section
                Text(
                  'Good morning, ${user?['firstName'] ?? 'Consultant'}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),

                // Key Metrics - Intentional Asymmetry
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildMetricCard(
                        'Total Valuation',
                        '\$24.8M',
                        '+12% this month',
                        theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildMetricCard(
                        'Active Leads',
                        '14',
                        '4 New Today',
                        theme,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Recent Activity - Editorial Style
                Text(
                  'RECENT CURATIONS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),

                _buildActivityItem(
                  'Skyline Penthouse',
                  'New lead interaction recorded.',
                  '2m ago',
                  LucideIcons.building2,
                  theme,
                ),
                _buildActivityItem(
                  'Marquee Villa',
                  'Price adjustment proposal sent.',
                  '1h ago',
                  LucideIcons.banknote,
                  theme,
                ),
                _buildActivityItem(
                  'Riverside Manor',
                  'Viewing scheduled with Client #092.',
                  '3h ago',
                  LucideIcons.calendarDays,
                  theme,
                ),

                const SizedBox(height: 60),

                // Footer Quote - The Curator feel
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      '"Precision is the foundation of premium service."',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String sub,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLift,
        borderRadius: BorderRadius.circular(2), // Sharp, architectural corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String desc,
    String time,
    IconData icon,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                    Text(
                      time,
                      style: theme.textTheme.labelLarge?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
