import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../providers/payouts_provider.dart';
import '../../api/auth_provider.dart';
import '../../models/payout_stats.dart';

class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void _refresh() {
    final auth = context.read<AuthProvider>();
    final provider = context.read<PayoutsProvider>();
    if (auth.currentOrganizationId != null) {
      if (auth.hasPermission('PAYOUTS_VIEW_ALL')) {
        provider.fetchAdminStats(auth.currentOrganizationId!);
      } else {
        provider.fetchPersonalStats(auth.currentOrganizationId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<PayoutsProvider>();
    final isAdmin = auth.hasPermission('PAYOUTS_VIEW_ALL');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Financials',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: _refresh,
          ),
        ],
      ),
      body: provider.status == PayoutsStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.status == PayoutsStatus.error
          ? Center(child: Text('Error: ${provider.errorMessage}'))
          : isAdmin
          ? _buildAdminView(provider.adminStats!)
          : _buildAgentView(provider.personalStats!),
    );
  }

  Widget _buildAdminView(AdminPayoutStats stats) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildEditorialHeader('Organization Summary'),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Total Sales',
              '\$${stats.summary.totalSales.toStringAsFixed(0)}',
              AppTheme.primaryColor,
            ),
            _buildMetricCard(
              'Commissions',
              '\$${stats.summary.totalCommissions.toStringAsFixed(0)}',
              Colors.orange,
            ),
            _buildMetricCard(
              'Agent Payouts',
              '\$${stats.summary.agentPayouts.toStringAsFixed(0)}',
              Colors.blue,
            ),
            _buildMetricCard(
              'Net Profit',
              '\$${stats.summary.totalProfit.toStringAsFixed(0)}',
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildEditorialHeader('Agent Performance'),
        const SizedBox(height: 16),
        ...stats.agents.map((agent) => _buildAgentPayoutTile(agent)),
      ],
    );
  }

  Widget _buildAgentView(PersonalPayoutStats stats) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildEditorialHeader('Your Performance'),
        const SizedBox(height: 24),
        _buildMainMetric(
          'Total Sales',
          '\$${stats.totalSales.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Earned',
                '\$${stats.totalEarned.toStringAsFixed(0)}',
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Pending',
                '\$${stats.pendingPayout.toStringAsFixed(0)}',
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildEditorialHeader('Recent Deals'),
        const SizedBox(height: 16),
        ...stats.deals.map((deal) => _buildDealPayoutTile(deal)),
      ],
    );
  }

  Widget _buildEditorialHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Container(width: 40, height: 3, color: AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildMainMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLift,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLift,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPayoutTile(AgentPayoutStats agent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppTheme.surfaceLift,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.surfaceContainer),
      ),
      child: ExpansionTile(
        title: Text(
          agent.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Pending: \$${agent.pendingPayout.toStringAsFixed(0)}'),
        children: agent.deals
            .map((deal) => _buildDealPayoutTile(deal, agentId: agent.id))
            .toList(),
      ),
    );
  }

  Widget _buildDealPayoutTile(PayoutDeal deal, {String? agentId}) {
    return ListTile(
      title: Text(
        deal.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(deal.createdAt.toString().substring(0, 10)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${deal.agentCommission?.toStringAsFixed(0) ?? '0'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: deal.isPaid ? Colors.green : Colors.orange,
            ),
          ),
          Text(
            deal.isPaid ? 'PAID' : 'PENDING',
            style: TextStyle(
              fontSize: 10,
              color: deal.isPaid ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onTap: !deal.isPaid && agentId != null
          ? () => _markAsPaid(deal.id)
          : null,
    );
  }

  Future<void> _markAsPaid(String dealId) async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<PayoutsProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid?'),
        content: const Text(
          'Are you sure you want to mark this payout as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('MARK PAID'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.markAsPaid(dealId, auth.currentOrganizationId!);
    }
  }
}
