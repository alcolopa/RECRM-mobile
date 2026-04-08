import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/deals_provider.dart';
import '../../api/auth_provider.dart';
import '../../widgets/status_badge.dart';
import 'deal_form_screen.dart';

class DealDetailScreen extends StatelessWidget {
  final String dealId;

  const DealDetailScreen({super.key, required this.dealId});

  @override
  Widget build(BuildContext context) {
    final dealsProvider = context.watch<DealsProvider>();
    final auth = context.watch<AuthProvider>();

    final deal = dealsProvider.deals.firstWhere(
      (d) => d.id == dealId,
      orElse: () => throw Exception('Deal not found'),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Deal Details'),
        backgroundColor: AppTheme.backgroundColor,
        actions: [
          if (auth.hasPermission('DEALS_EDIT'))
            IconButton(
              icon: const Icon(LucideIcons.edit2, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DealFormScreen(deal: deal),
                ),
              ),
            ),
          if (auth.hasPermission('DEALS_DELETE'))
            IconButton(
              icon: const Icon(
                LucideIcons.trash2,
                size: 20,
                color: AppTheme.errorColor,
              ),
              onPressed: () => _confirmDelete(context, auth, dealsProvider),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, deal),
            const SizedBox(height: 24),
            _buildFinancialSection(context, deal),
            const SizedBox(height: 24),
            _buildInfoSection(context, 'Relationships', [
              _buildInfoItem(
                LucideIcons.building,
                'Property',
                deal.propertyId ?? 'N/A',
              ),
              _buildInfoItem(
                LucideIcons.users,
                'Contact',
                deal.contactId ?? 'N/A',
              ),
              if (deal.leadId != null)
                _buildInfoItem(LucideIcons.target, 'Lead', deal.leadId!),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection(context, 'Assignment', [
              _buildInfoItem(
                LucideIcons.user,
                'Assigned To',
                deal.assignedUserId ?? 'Unassigned',
              ),
              _buildInfoItem(
                LucideIcons.calendar,
                'Created',
                '${deal.createdAt.day}/${deal.createdAt.month}/${deal.createdAt.year}',
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic deal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                deal.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StatusBadge(status: deal.stage),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Deal ID: ${deal.id} • ${deal.type}',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSection(BuildContext context, dynamic deal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FINANCIALS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              _buildMetricRow(
                'Value',
                '\$${deal.value?.toStringAsFixed(2) ?? "0.00"}',
                isHighlight: true,
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCol(
                      'Property Price',
                      '\$${deal.propertyPrice?.toStringAsFixed(0) ?? "-"}',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricCol(
                      'Buyer Comm',
                      '${deal.buyerCommission ?? "-"}%',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricCol(
                      'Seller Comm',
                      '${deal.sellerCommission ?? "-"}%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 24 : 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppTheme.primaryColor : AppTheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1),
            ),
          ),
          color: AppTheme.surfaceLift,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: items),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AuthProvider auth,
    DealsProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this deal? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.deleteDeal(dealId, auth.currentOrganizationId!);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Deal deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting deal: $e')));
        }
      }
    }
  }
}
