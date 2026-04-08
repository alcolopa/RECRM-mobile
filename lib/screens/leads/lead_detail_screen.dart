import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../providers/leads_provider.dart';
import '../../api/auth_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/convert_lead_dialog.dart';
import '../../models/lead.dart';
import '../../utils/formatters.dart';
import 'lead_form_screen.dart';

class LeadDetailScreen extends StatelessWidget {
  final String leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context) {
    final leadsProvider = context.watch<LeadsProvider>();
    final auth = context.watch<AuthProvider>();

    Lead? lead;
    try {
      lead = leadsProvider.leads.firstWhere((l) => l.id == leadId);
    } catch (_) {
      lead = null;
    }

    if (lead == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Find assigned user name if available
    String? assignedUserName;
    if (lead.assignedUserId != null && auth.organization?.memberships != null) {
      final membership =
          auth.organization!.memberships!.cast<dynamic>().firstWhere(
                (m) => m.userId == lead!.assignedUserId,
                orElse: () => null,
              );
      assignedUserName = membership?.user?.fullName;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Lead Details'),
        backgroundColor: AppTheme.backgroundColor,
        actions: [
          if (auth.hasPermission('LEADS_EDIT'))
            IconButton(
              icon: const Icon(LucideIcons.edit2, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeadFormScreen(lead: lead),
                ),
              ),
            ),
          if (auth.hasPermission('LEADS_DELETE'))
            IconButton(
              icon: const Icon(
                LucideIcons.trash2,
                size: 20,
                color: AppTheme.errorColor,
              ),
              onPressed: () => _confirmDelete(context, auth, leadsProvider),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, lead),
            const SizedBox(height: 24),
            _buildQuickActions(context, auth, lead),
            const SizedBox(height: 24),
            _buildInfoSection(context, 'Contact Information', [
              _buildInfoItem(LucideIcons.mail, 'Email', lead.email ?? 'N/A'),
              _buildInfoItem(
                LucideIcons.phone,
                'Phone',
                AppFormatters.formatPhone(lead.phone),
              ),
              if (assignedUserName != null)
                _buildInfoItem(
                  LucideIcons.userCheck,
                  'Assigned Agent',
                  assignedUserName,
                ),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection(context, 'Requirement Details', [
              _buildInfoItem(
                LucideIcons.dollarSign,
                'Budget',
                lead.budget ?? 'N/A',
              ),
              _buildInfoItem(LucideIcons.target, 'Intent', lead.intent),
              _buildInfoItem(
                LucideIcons.building,
                'Property Type',
                lead.propertyType ?? 'N/A',
              ),
              _buildInfoItem(
                LucideIcons.mapPin,
                'Preferred Location',
                lead.preferredLocation ?? 'N/A',
              ),
              _buildInfoItem(
                LucideIcons.zap,
                'Urgency',
                lead.urgencyLevel ?? 'N/A',
              ),
              _buildInfoItem(
                LucideIcons.share2,
                'Source',
                lead.source ?? 'N/A',
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection(context, 'System Info', [
              _buildInfoItem(
                LucideIcons.calendar,
                'Created',
                DateFormat('MMM d, yyyy').format(lead.createdAt),
              ),
              _buildInfoItem(
                LucideIcons.clock,
                'Last Updated',
                DateFormat('MMM d, yyyy').format(lead.updatedAt),
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection(context, 'Notes', [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  lead.notes ?? 'No notes available.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Lead lead) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                lead.fullName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            StatusBadge(status: lead.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Lead ID: ${lead.id}',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    AuthProvider auth,
    Lead lead,
  ) {
    if (lead.status == 'CLOSED_WON' || lead.convertedContactId != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.checkCircle2, color: Colors.green),
            SizedBox(width: 12),
            Text(
              'This lead has been successfully converted.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (auth.hasPermission('LEADS_EDIT') &&
            auth.hasPermission('CONTACTS_CREATE'))
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _convertLead(context, auth, lead),
              icon: const Icon(LucideIcons.userPlus, size: 18),
              label: const Text('Convert to Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AuthProvider auth,
    LeadsProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this lead? This action cannot be undone.',
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
        await provider.deleteLead(leadId, auth.currentOrganizationId!);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Lead deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting lead: $e')));
        }
      }
    }
  }

  Future<void> _convertLead(
    BuildContext context,
    AuthProvider auth,
    Lead lead,
  ) async {
    final provider = context.read<LeadsProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ConvertLeadDialog(lead: lead),
    );

    if (result != null) {
      try {
        await provider.convertLead(
          leadId,
          auth.currentOrganizationId!,
          result,
        );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lead converted to contact')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error converting lead: $e')));
        }
      }
    }
  }
}
