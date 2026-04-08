import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../api/auth_provider.dart';
import '../../providers/properties_provider.dart';
import '../../theme.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Form fields
  String _title = '';
  String _description = '';
  String _type = 'HOUSE';
  String _listingType = 'SALE';
  String _status = 'AVAILABLE';
  String _address = '';
  String _currency = 'USD';
  double? _price;
  int? _bedrooms;
  double? _bathrooms;
  double? _sizeSqm;

  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  final List<String> _propertyTypes = [
    'APARTMENT',
    'HOUSE',
    'VILLA',
    'OFFICE',
    'SHOP',
    'LAND',
    'WAREHOUSE',
    'BUILDING',
  ];

  final List<String> _listingTypes = ['SALE', 'RENT', 'LEASE'];

  final List<String> _propertyStatuses = [
    'AVAILABLE',
    'RESERVED',
    'SOLD',
    'RENTED',
    'OFF_MARKET',
  ];

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final propertiesProvider = Provider.of<PropertiesProvider>(
      context,
      listen: false,
    );
    final orgId = auth.currentOrganizationId;

    if (orgId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final propertyData = {
        'organizationId': orgId,
        'title': _title,
        'description': _description,
        'type': _type,
        'listingType': _listingType,
        'status': _status,
        'address': _address,
        'price': _price,
        'currency': _currency,
        'bedrooms': _bedrooms,
        'bathrooms': _bathrooms,
        'sizeSqm': _sizeSqm,
      };

      final newProperty = await propertiesProvider.createProperty(propertyData);

      // Upload images after creation
      for (final image in _selectedImages) {
        await propertiesProvider.uploadPropertyImage(
          newProperty.id,
          image.path,
          orgId,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Property',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(
                'SAVE',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Section
              Text(
                'Property Images',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLift,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.surfaceContainer,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.plus,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            image: DecorationImage(
                              image: FileImage(
                                File(_selectedImages[index].path),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.trash2,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Core Info
              _buildSectionTitle(theme, 'Core Information'),
              _buildTextField(
                label: 'Title',
                onSaved: (val) => _title = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              _buildTextField(
                label: 'Description',
                maxLines: 3,
                onSaved: (val) => _description = val ?? '',
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Type',
                      value: _type,
                      items: _propertyTypes,
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Listing',
                      value: _listingType,
                      items: _listingTypes,
                      onChanged: (val) => setState(() => _listingType = val!),
                    ),
                  ),
                ],
              ),
              _buildDropdown(
                label: 'Status',
                value: _status,
                items: _propertyStatuses,
                onChanged: (val) => setState(() => _status = val!),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'Location'),
              _buildTextField(
                label: 'Address',
                onSaved: (val) => _address = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'Specifications'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Bedrooms',
                      keyboardType: TextInputType.number,
                      onSaved: (val) => _bedrooms = int.tryParse(val ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Bathrooms',
                      keyboardType: TextInputType.number,
                      onSaved: (val) => _bathrooms = double.tryParse(val ?? ''),
                    ),
                  ),
                ],
              ),
              _buildTextField(
                label: 'Size (sqm)',
                keyboardType: TextInputType.number,
                onSaved: (val) => _sizeSqm = double.tryParse(val ?? ''),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'Pricing'),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      label: 'Price',
                      keyboardType: TextInputType.number,
                      onSaved: (val) => _price = double.tryParse(val ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Currency',
                      initialValue: 'USD',
                      onSaved: (val) => _currency = val ?? 'USD',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: AppTheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    int maxLines = 1,
    String? initialValue,
    TextInputType? keyboardType,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onSaved: onSaved,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
          filled: true,
          fillColor: AppTheme.surfaceLift,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
          filled: true,
          fillColor: AppTheme.surfaceLift,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
