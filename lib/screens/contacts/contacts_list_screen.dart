import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/contacts_provider.dart';
import '../../api/auth_provider.dart';
import 'contact_form_screen.dart';
import 'contact_detail_screen.dart';
import '../../models/contact.dart';
import '../../widgets/alphabet_index_bar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../utils/formatters.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  String _activeLetter = 'A';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchContacts();
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _fetchContacts();
  }

  void _fetchContacts() {
    final auth = context.read<AuthProvider>();
    if (auth.currentOrganizationId != null) {
      String? type;
      if (_tabController.index == 1) type = 'BUYER';
      if (_tabController.index == 2) type = 'SELLER';
      
      context.read<ContactsProvider>().fetchContacts(
        auth.currentOrganizationId!,
        type: type,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final auth = context.watch<AuthProvider>();

    final filteredContacts = contactsProvider.contacts.where((contact) {
      final query = _searchQuery.toLowerCase();
      return contact.firstName.toLowerCase().contains(query) ||
          contact.lastName.toLowerCase().contains(query) ||
          (contact.email?.toLowerCase().contains(query) ?? false) ||
          contact.phone.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
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
                titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  'Contacts',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.filter, color: AppTheme.onSurfaceVariant),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
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
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.onSurfaceVariant,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'ALL'),
                    Tab(text: 'BUYERS'),
                    Tab(text: 'SELLERS'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Stack(
          children: [
            _buildContactsList(contactsProvider, filteredContacts),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: AlphabetIndexBar(
                  letters: _getAlphabet(filteredContacts),
                  activeLetter: _activeLetter,
                  onLetterSelected: (letter) => _scrollToLetter(letter, filteredContacts),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: auth.hasPermission('CONTACTS_CREATE')
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactFormScreen()),
              ),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

  List<String> _getAlphabet(List<Contact> contacts) {
    final letters = contacts
        .map((c) => c.firstName[0].toUpperCase())
        .toSet()
        .toList();
    letters.sort();
    return letters;
  }

  void _scrollToLetter(String letter, List<Contact> contacts) {
    final grouped = _groupContacts(contacts);
    int index = 0;
    for (final entry in grouped.entries) {
      if (entry.key == letter) {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _activeLetter = letter);
        break;
      }
      index += 1 + entry.value.length; // Header + items
    }
  }

  Map<String, List<Contact>> _groupContacts(List<Contact> contacts) {
    final sorted = List<Contact>.from(contacts);
    sorted.sort((a, b) => a.firstName.compareTo(b.firstName));

    final Map<String, List<Contact>> grouped = {};
    for (final contact in sorted) {
      final letter = contact.firstName[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(contact);
    }
    return grouped;
  }

  Widget _buildContactsList(ContactsProvider provider, List<Contact> contacts) {
    if (provider.status == ContactsStatus.loading && provider.contacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == ContactsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('Error loading contacts: ${provider.errorMessage}'),
            TextButton(
              onPressed: _fetchContacts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (contacts.isEmpty) {
      return const Center(child: Text('No contacts found.'));
    }

    final grouped = _groupContacts(contacts);
    final List<dynamic> flatList = [];
    grouped.forEach((letter, items) {
      flatList.add(letter);
      flatList.addAll(items);
    });

    return RefreshIndicator(
      onRefresh: () async => _fetchContacts(),
      child: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        padding: const EdgeInsets.fromLTRB(16, 16, 40, 80),
        itemCount: flatList.length,
        itemBuilder: (context, index) {
          final item = flatList[index];

          if (item is String) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            );
          }

          final contact = item as Contact;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    contact.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${contact.firstName} ${contact.lastName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        contact.status,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  contact.phone.isNotEmpty
                      ? AppFormatters.formatPhone(contact.phone)
                      : (contact.email ?? ''),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContactDetailScreen(contactId: contact.id),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 68, endIndent: 40),
            ],
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
