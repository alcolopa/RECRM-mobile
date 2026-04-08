import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../providers/contacts_provider.dart';
import '../../api/auth_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';
import '../../models/contact.dart';
import 'contact_form_screen.dart';

class ContactDetailScreen extends StatelessWidget {
  final String contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final auth = context.watch<AuthProvider>();

    Contact? contact;
    try {
      contact = contactsProvider.contacts.firstWhere((c) => c.id == contactId);
    } catch (_) {
      contact = null;
    }

    if (contact == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contact Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Find assigned agent name if available
    String? assignedAgentName;
    if (contact.assignedAgentId != null && auth.organization?.memberships != null) {
      final membership = auth.organization!.memberships!.cast<dynamic>().firstWhere(
        (m) => m.userId == contact!.assignedAgentId,
        orElse: () => null,
      );
      assignedAgentName = membership?.user?.fullName;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Contact Details'),
        backgroundColor: AppTheme.backgroundColor,
        actions: [
          if (auth.hasPermission('CONTACTS_EDIT'))
            IconButton(
              icon: const Icon(LucideIcons.edit2, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactFormScreen(contact: contact),
                ),
              ),
            ),
          if (auth.hasPermission('CONTACTS_DELETE'))
            IconButton(
              icon: const Icon(
                LucideIcons.trash2,
                size: 20,
                color: AppTheme.errorColor,
              ),
              onPressed: () => _confirmDelete(context, auth, contactsProvider),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, contact),
            const SizedBox(height: 24),
            _buildQuickActions(context, contact),
            const SizedBox(height: 24),
            _buildInfoSection(context, 'Communication', [
              _buildInfoItem(
                LucideIcons.mail,
                'Email',
                contact.email ?? 'N/A',
              ),
              _buildInfoItem(
                LucideIcons.phone,
                'Phone',
                AppFormatters.formatPhone(contact.phone),
              ),
              if (contact.secondaryPhone != null)
                _buildInfoItem(
                  LucideIcons.phoneCall,
                  'Secondary',
                  AppFormatters.formatPhone(contact.secondaryPhone),
                ),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection(context, 'Classification', [
              _buildInfoItem(LucideIcons.user, 'Type', contact.type),
              _buildInfoItem(LucideIcons.activity, 'Status', contact.status),
              _buildInfoItem(
                LucideIcons.share2,
                'Source',
                contact.leadSource ?? 'N/A',
              ),
              if (assignedAgentName != null)
                _buildInfoItem(
                  LucideIcons.userCheck,
                  'Assigned Agent',
                  assignedAgentName,
                ),
            ]),
            const SizedBox(height: 16),
            if (contact.tags.isNotEmpty) _buildTagsSection(context, contact.tags),
            const SizedBox(height: 16),
            if (contact.buyerProfile != null)
              _buildProfileSection(context, 'Buyer Profile', contact.buyerProfile!),
            if (contact.sellerProfile != null)
              _buildProfileSection(context, 'Seller Profile', contact.sellerProfile!),
            const SizedBox(height: 16),
            _buildInfoSection(context, 'Engagement', [
              _buildInfoItem(
                LucideIcons.calendar,
                'Last Contacted',
                contact.lastContactedAt != null
                    ? DateFormat('MMM d, yyyy').format(contact.lastContactedAt!)
                    : 'Never',
              ),
              _buildInfoItem(
                LucideIcons.clock,
                'Created',
                DateFormat('MMM d, yyyy').format(contact.createdAt),
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection(context, 'Notes', [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  contact.notes ?? 'No notes available.',
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

  Widget _buildHeader(BuildContext context, Contact contact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                contact.fullName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            StatusBadge(status: contact.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Contact ID: ${contact.id}',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic contact) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => launchUrl(Uri.parse('tel:${contact.phone}')),
            icon: const Icon(LucideIcons.phone, size: 18),
            label: const Text('Call'),
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
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: contact.email != null
                ? () => launchUrl(Uri.parse('mailto:${contact.email}'))
                : null,
            icon: const Icon(LucideIcons.mail, size: 18),
            label: const Text('Email'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: AppTheme.primaryColor),
              foregroundColor: AppTheme.primaryColor,
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

  Widget _buildProfileSection(
    BuildContext context,
    String title,
    Map<String, dynamic> profile,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _buildInfoSection(
        context,
        title,
        profile.entries.map((e) {
          return _buildInfoItem(
            LucideIcons.info,
            _formatKey(e.key),
            e.value.toString(),
          );
        }).toList(),
      ),
    );
  }

  String _formatKey(String key) {
    if (key.isEmpty) return key;
    final formatted = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  Widget _buildTagsSection(BuildContext context, List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TAGS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLift,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(tag, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AuthProvider auth,
    ContactsProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this contact? This action cannot be undone.',
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
        await provider.deleteContact(contactId, auth.currentOrganizationId!);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Contact deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting contact: $e')));
        }
      }
    }
  }
}
