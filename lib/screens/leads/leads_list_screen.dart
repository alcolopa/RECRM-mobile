import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/leads_provider.dart';
import '../../api/auth_provider.dart';
import '../../widgets/status_badge.dart';
import 'lead_form_screen.dart';
import 'lead_detail_screen.dart';

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentOrganizationId != null) {
        context.read<LeadsProvider>().fetchLeads(auth.currentOrganizationId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leadsProvider = context.watch<LeadsProvider>();
    final auth = context.watch<AuthProvider>();

    final filteredLeads = leadsProvider.leads.where((lead) {
      final query = _searchQuery.toLowerCase();
      return lead.firstName.toLowerCase().contains(query) ||
             lead.lastName.toLowerCase().contains(query) ||
             (lead.email?.toLowerCase().contains(query) ?? false) ||
             (lead.phone?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Leads...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _buildLeadsList(leadsProvider, filteredLeads),
          ),
        ],
      ),
      floatingActionButton: auth.hasPermission('LEADS_CREATE')
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeadFormScreen()),
              ),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

  Widget _buildLeadsList(LeadsProvider provider, List leads) {
    if (provider.status == LeadsStatus.loading && provider.leads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == LeadsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('Error loading leads: ${provider.errorMessage}'),
            TextButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                if (auth.currentOrganizationId != null) {
                  provider.fetchLeads(auth.currentOrganizationId!);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (leads.isEmpty) {
      return const Center(
        child: Text('No leads found.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        if (auth.currentOrganizationId != null) {
          await provider.fetchLeads(auth.currentOrganizationId!);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: leads.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lead = leads[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1)),
            ),
            color: AppTheme.surfaceLift,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(status: lead.status),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  if (lead.email != null)
                    Row(
                      children: [
                        const Icon(LucideIcons.mail, size: 14, color: AppTheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(lead.email!, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  const SizedBox(height: 4),
                  if (lead.phone != null)
                    Row(
                      children: [
                        const Icon(LucideIcons.phone, size: 14, color: AppTheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(lead.phone!, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Created: ${lead.createdAt.day}/${lead.createdAt.month}/${lead.createdAt.year}',
                    style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeadDetailScreen(leadId: lead.id)),
              ),
            ),
          );
        },
      ),
    );
  }
}
