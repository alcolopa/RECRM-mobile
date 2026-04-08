import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/deals_provider.dart';
import '../../api/auth_provider.dart';
import '../../widgets/status_badge.dart';
import 'deal_form_screen.dart';
import 'deal_detail_screen.dart';

class DealsListScreen extends StatefulWidget {
  const DealsListScreen({super.key});

  @override
  State<DealsListScreen> createState() => _DealsListScreenState();
}

class _DealsListScreenState extends State<DealsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentOrganizationId != null) {
        context.read<DealsProvider>().fetchDeals(auth.currentOrganizationId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dealsProvider = context.watch<DealsProvider>();
    final auth = context.watch<AuthProvider>();

    final filteredDeals = dealsProvider.deals.where((deal) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = deal.title.toLowerCase().contains(query);

      final matchesStage =
          _selectedStage == null || deal.stage == _selectedStage;

      return matchesQuery && matchesStage;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.menu, color: AppTheme.primaryColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              title: Text(
                'Deals',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search deals...',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        filled: true,
                        fillColor: AppTheme.surfaceLift,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLift,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        LucideIcons.filter,
                        size: 20,
                        color: _selectedStage != null
                            ? AppTheme.primaryColor
                            : AppTheme.onSurfaceVariant,
                      ),
                      onPressed: _showFilterMenu,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: _buildDealsList(dealsProvider, filteredDeals),
          ),
        ],
      ),
      floatingActionButton: auth.hasPermission('DEALS_CREATE')
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DealFormScreen()),
              ),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Stage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _filterOption(null, 'All Stages'),
            _filterOption('DISCOVERY', 'Discovery'),
            _filterOption('PROPOSAL', 'Proposal'),
            _filterOption('NEGOTIATION', 'Negotiation'),
            _filterOption('CLOSED_WON', 'Closed Won'),
            _filterOption('CLOSED_LOST', 'Closed Lost'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(String? value, String label) {
    final isSelected = _selectedStage == value;
    return ListTile(
      title: Text(label),
      trailing: isSelected
          ? const Icon(LucideIcons.check, color: AppTheme.primaryColor)
          : null,
      onTap: () {
        setState(() => _selectedStage = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildDealsList(DealsProvider provider, List deals) {
    if (provider.status == DealsStatus.loading && provider.deals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == DealsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertTriangle,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text('Error loading deals: ${provider.errorMessage}'),
            TextButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                if (auth.currentOrganizationId != null) {
                  provider.fetchDeals(auth.currentOrganizationId!);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (deals.isEmpty) {
      return const Center(child: Text('No deals found.'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        if (auth.currentOrganizationId != null) {
          await provider.fetchDeals(auth.currentOrganizationId!);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: deals.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final deal = deals[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1),
              ),
            ),
            color: AppTheme.surfaceLift,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      deal.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(status: deal.stage),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  if (deal.value != null)
                    Text(
                      '\$${deal.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Updated ${deal.updatedAt.day}/${deal.updatedAt.month}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DealDetailScreen(dealId: deal.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
