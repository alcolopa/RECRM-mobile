import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/contacts_provider.dart';
import '../../api/auth_provider.dart';
import 'contact_form_screen.dart';
import 'contact_detail_screen.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentOrganizationId != null) {
        context.read<ContactsProvider>().fetchContacts(auth.currentOrganizationId!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      filled: true,
                      fillColor: AppTheme.surfaceLift,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLift,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.filter, size: 20),
                    onPressed: () {
                      _showFilterBottomSheet();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(contactsProvider, auth),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ContactFormScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  void _showFilterBottomSheet() {
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
            Text('Filter Contacts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildFilterOption('All Contacts', LucideIcons.users, true),
            _buildFilterOption('Leads', LucideIcons.target, false),
            _buildFilterOption('Buyers', LucideIcons.shoppingCart, false),
            _buildFilterOption('Sellers', LucideIcons.home, false),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, IconData icon, bool isSelected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.onSurfaceVariant),
      trailing: isSelected ? const Icon(LucideIcons.check, color: AppTheme.primaryColor) : null,
      onTap: () {
        setState(() {});
        Navigator.pop(context);
      },
    );
  }

  Widget _buildContent(ContactsProvider provider, AuthProvider auth) {
    if (provider.status == ContactsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == ContactsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(provider.errorMessage ?? 'Failed to load contacts'),
            TextButton(
              onPressed: () {
                if (auth.currentOrganizationId != null) {
                  provider.fetchContacts(auth.currentOrganizationId!);
                }
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final query = _searchController.text.toLowerCase();
    final filteredContacts = provider.contacts.where((c) {
      final nameMatches = c.fullName.toLowerCase().contains(query);
      final emailMatches = (c.email?.toLowerCase() ?? '').contains(query);
      final phoneMatches = c.phone.toLowerCase().contains(query);
      return nameMatches || emailMatches || phoneMatches;
    }).toList();

    if (filteredContacts.isEmpty) {
      return const Center(
        child: Text('No contacts found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (auth.currentOrganizationId != null) {
          await provider.fetchContacts(auth.currentOrganizationId!);
        }
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredContacts.length,
        itemBuilder: (context, index) {
          final contact = filteredContacts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.surfaceContainer),
            ),
            color: AppTheme.surfaceLift,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContactDetailScreen(contactId: contact.id),
                  ),
                );
              },
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      contact.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.mail, size: 14, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(contact.email ?? 'N/A', style: const TextStyle(color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.phone, size: 14, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(contact.phone, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
