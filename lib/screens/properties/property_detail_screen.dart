import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../api/auth_provider.dart';
import '../../providers/properties_provider.dart';
import '../../models/property.dart';
import '../../theme.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final canDelete = auth.hasPermission('PROPERTIES_DELETE');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: property.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: property.images.length,
                      itemBuilder: (context, index) => Image.network(
                        property.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.surfaceContainer,
                          child: const Icon(LucideIcons.imageOff),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.surfaceContainer,
                      child: const Icon(
                        LucideIcons.image,
                        size: 60,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (canDelete)
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label Row
                  Row(
                    children: [
                      _buildBadge(property.status, theme, isStatus: true),
                      const SizedBox(width: 8),
                      _buildBadge(property.listingType, theme),
                      const SizedBox(width: 8),
                      _buildBadge(property.type, theme),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title & Price
                  Text(
                    property.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (property.price != null)
                    Text(
                      currencyFormat.format(property.price),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 16),
                  // Address
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          property.address,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 48),

                  // Specs Grid
                  _buildSpecsGrid(theme),

                  const Divider(height: 48),

                  // Description
                  Text(
                    'About this property',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    property.description ??
                        'No description available for this property.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, ThemeData theme, {bool isStatus = false}) {
    Color bgColor = AppTheme.surfaceContainer;
    Color textColor = AppTheme.onSurfaceVariant;

    if (isStatus) {
      if (label == 'AVAILABLE') {
        bgColor = Colors.green.withValues(alpha: .1);
        textColor = Colors.green.shade700;
      } else {
        bgColor = Colors.orange.withValues(alpha: .1);
        textColor = Colors.orange.shade700;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSpecsGrid(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSpecItem(
          LucideIcons.bedDouble,
          '${property.bedrooms ?? 0}',
          'Bedrooms',
          theme,
        ),
        _buildSpecItem(
          LucideIcons.bath,
          '${property.bathrooms ?? 0}',
          'Bathrooms',
          theme,
        ),
        _buildSpecItem(
          LucideIcons.maximize,
          '${property.area ?? property.sizeSqm ?? 0}',
          'SqM',
          theme,
        ),
      ],
    );
  }

  Widget _buildSpecItem(
    IconData icon,
    String value,
    String label,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.onSurfaceVariant, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text(
          'Are you sure you want to remove this listing? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<PropertiesProvider>(context, listen: false);
      final orgId = auth.currentOrganizationId;

      if (orgId != null) {
        try {
          await provider.deleteProperty(property.id, orgId);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Property removed')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
          }
        }
      }
    }
  }
}
