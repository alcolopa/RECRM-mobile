import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../api/auth_provider.dart';
import '../../../providers/properties_provider.dart';
import '../../../theme.dart';
import '../../../models/property.dart';
import 'package:intl/intl.dart';
import 'add_property_screen.dart';
import 'property_detail_screen.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperties();
    });
  }

  void _loadProperties() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    // Extract organization ID from the first membership
    // (Assuming standard structure based on backend)
    String orgId = '';
    if (user != null &&
        user['memberships'] != null &&
        (user['memberships'] as List).isNotEmpty) {
      orgId = user['memberships'][0]['organizationId'] ?? '';
    } else if (user != null &&
        user['ownedOrganizations'] != null &&
        (user['ownedOrganizations'] as List).isNotEmpty) {
      orgId = user['ownedOrganizations'][0]['id'] ?? '';
    }

    if (orgId.isNotEmpty) {
      Provider.of<PropertiesProvider>(
        context,
        listen: false,
      ).fetchProperties(orgId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final canCreate = auth.hasPermission('PROPERTIES_CREATE');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPropertyScreen(),
                ),
              ),
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(LucideIcons.plus, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => _loadProperties(),
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              backgroundColor: AppTheme.backgroundColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                title: Text(
                  'Properties',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    LucideIcons.search,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.filter,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
              leading: IconButton(
                icon: const Icon(LucideIcons.menu, color: AppTheme.primaryColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Consumer<PropertiesProvider>(
              builder: (context, provider, child) {
                if (provider.status == PropertiesStatus.loading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }

                if (provider.status == PropertiesStatus.error) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load properties',
                            style: theme.textTheme.titleMedium,
                          ),
                          TextButton(
                            onPressed: _loadProperties,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final properties = provider.properties;

                if (properties.isEmpty &&
                    provider.status == PropertiesStatus.loaded) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No properties found.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final property = properties[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PropertyDetailScreen(property: property),
                          ),
                        ),
                        child: _buildPropertyCard(property, theme),
                      );
                    }, childCount: properties.length),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Property property, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLift,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          AspectRatio(
            aspectRatio: 16 / 9,
            child: property.images.isNotEmpty
                ? Image.network(
                    property.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.surfaceContainer,
                      child: const Center(
                        child: Icon(
                          LucideIcons.imageOff,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.surfaceContainer,
                    child: const Center(
                      child: Icon(
                        LucideIcons.image,
                        color: AppTheme.onSurfaceVariant,
                        size: 40,
                      ),
                    ),
                  ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (property.price != null)
                      Text(
                        currencyFormat.format(property.price),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${property.address}${property.city != null ? ', ${property.city}' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Specs Row
                Row(
                  children: [
                    if (property.bedrooms != null)
                      _buildSpecConfig(
                        LucideIcons.bedDouble,
                        '${property.bedrooms} Beds',
                        theme,
                      ),
                    if (property.bathrooms != null)
                      _buildSpecConfig(
                        LucideIcons.bath,
                        '${property.bathrooms} Baths',
                        theme,
                      ),
                    if (property.area != null)
                      _buildSpecConfig(
                        LucideIcons.maximize,
                        '${property.area} SqM',
                        theme,
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: property.status == 'AVAILABLE'
                            ? Colors.green.withValues(alpha: .1)
                            : Colors.orange.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        property.status.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: property.status == 'AVAILABLE'
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        property.listingType.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecConfig(IconData icon, String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
