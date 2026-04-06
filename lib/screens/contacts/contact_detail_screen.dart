import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';
import '../../providers/contacts_provider.dart';
import '../../api/auth_provider.dart';
import 'contact_form_screen.dart';

class ContactDetailScreen extends StatelessWidget {
  final String contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final auth = context.watch<AuthProvider>();
    
    final contact = contactsProvider.contacts.firstWhere((c) => c.id == contactId, orElse: () => throw Exception('Contact not found'));

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
                MaterialPageRoute(builder: (context) => ContactFormScreen(contact: contact)),
              ),
            ),
          if (auth.hasPermission('CONTACTS_DELETE'))
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 20, color: AppTheme.errorColor),
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
              _buildInfoItem(LucideIcons.mail, 'Email', contact.email ?? 'N/A'),
              _buildInfoItem(LucideIcons.phone, 'Phone', contact.phone),
              if (contact.secondaryPhone != null)
                _buildInfoItem(LucideIcons.phoneCall, 'Secondary', contact.secondaryPhone!),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection(context, 'Classification', [
              _buildInfoItem(LucideIcons.user, 'Type', contact.type),
              _buildInfoItem(LucideIcons.activity, 'Status', contact.status),
              _buildInfoItem(LucideIcons.share2, 'Source', contact.leadSource ?? 'N/A'),
            ]),
            const SizedBox(height: 16),
            if (contact.tags.isNotEmpty)
              _buildTagsSection(context, contact.tags),
            const SizedBox(height: 16),
            _buildInfoSection(context, 'Notes', [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  contact.notes ?? 'No notes available.',
                  style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
                ),
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic contact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contact.fullName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                contact.type,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: contact.status == 'ACTIVE' ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                contact.status,
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  color: contact.status == 'ACTIVE' ? Colors.green : Colors.grey
                ),
              ),
            ),
          ],
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: contact.email != null ? () => launchUrl(Uri.parse('mailto:${contact.email}')) : null,
            icon: const Icon(LucideIcons.mail, size: 18),
            label: const Text('Email'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: AppTheme.primaryColor),
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> items) {
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
            side: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1)),
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
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
          children: tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLift,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1)),
            ),
            child: Text(tag, style: const TextStyle(fontSize: 12)),
          )).toList(),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, AuthProvider auth, ContactsProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this contact? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.deleteContact(contactId, auth.currentOrganizationId!);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting contact: $e')));
        }
      }
    }
  }
}
