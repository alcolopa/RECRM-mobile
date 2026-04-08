import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/leads_provider.dart';
import '../../api/auth_provider.dart';
import '../../widgets/status_badge.dart';
import 'lead_form_screen.dart';
import 'lead_detail_screen.dart';
import '../../models/lead.dart';
import '../../widgets/alphabet_index_bar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../utils/formatters.dart';

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  String _activeLetter = 'A';

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
                'Leads',
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
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search leads...',
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
          SliverFillRemaining(
            child: Stack(
              children: [
                _buildLeadsList(leadsProvider, filteredLeads),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AlphabetIndexBar(
                      letters: _getAlphabet(filteredLeads),
                      activeLetter: _activeLetter,
                      onLetterSelected: (letter) => _scrollToLetter(letter, filteredLeads),
                    ),
                  ),
                ),
              ],
            ),
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

  List<String> _getAlphabet(List<Lead> leads) {
    final letters = leads
        .map((l) => l.firstName[0].toUpperCase())
        .toSet()
        .toList();
    letters.sort();
    return letters;
  }

  void _scrollToLetter(String letter, List<Lead> leads) {
    final grouped = _groupLeads(leads);
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

  Map<String, List<Lead>> _groupLeads(List<Lead> leads) {
    final sorted = List<Lead>.from(leads);
    sorted.sort((a, b) => a.firstName.compareTo(b.firstName));

    final Map<String, List<Lead>> grouped = {};
    for (final lead in sorted) {
      final letter = lead.firstName[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(lead);
    }
    return grouped;
  }

  Widget _buildLeadsList(LeadsProvider provider, List<Lead> leads) {
    if (provider.status == LeadsStatus.loading && provider.leads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == LeadsStatus.error) {
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
      return const Center(child: Text('No leads found.'));
    }

    final grouped = _groupLeads(leads);
    final List<dynamic> flatList = [];
    grouped.forEach((letter, items) {
      flatList.add(letter);
      flatList.addAll(items);
    });

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        if (auth.currentOrganizationId != null) {
          await provider.fetchLeads(auth.currentOrganizationId!);
        }
      },
      child: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        padding: const EdgeInsets.fromLTRB(16, 0, 40, 80),
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

          final lead = item as Lead;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    lead.firstName[0].toUpperCase(),
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
                        lead.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: lead.status),
                  ],
                ),
                subtitle: Text(
                  lead.phone != null
                      ? AppFormatters.formatPhone(lead.phone!)
                      : (lead.email ?? ''),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeadDetailScreen(leadId: lead.id),
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
