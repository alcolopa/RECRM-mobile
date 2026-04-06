import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/contacts_provider.dart';
import '../../api/auth_provider.dart';
import '../../widgets/form_inputs.dart';
import '../../models/contact.dart';

class ContactFormScreen extends StatefulWidget {
  final Contact? contact;

  const ContactFormScreen({super.key, this.contact});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _secondaryPhoneController;
  late TextEditingController _sourceController;
  late TextEditingController _notesController;
  late TextEditingController _tagsController;

  String _type = 'BUYER';
  String _status = 'ACTIVE';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    _firstNameController = TextEditingController(text: contact?.firstName);
    _lastNameController = TextEditingController(text: contact?.lastName);
    _emailController = TextEditingController(text: contact?.email);
    _phoneController = TextEditingController(text: contact?.phone);
    _secondaryPhoneController = TextEditingController(text: contact?.secondaryPhone);
    _sourceController = TextEditingController(text: contact?.leadSource);
    _notesController = TextEditingController(text: contact?.notes);
    _tagsController = TextEditingController(text: contact?.tags.join(', '));

    if (contact != null) {
      _type = contact.type;
      _status = contact.status;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      final provider = context.read<ContactsProvider>();

      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'secondaryPhone': _secondaryPhoneController.text.trim().isEmpty ? null : _secondaryPhoneController.text.trim(),
        'type': _type,
        'status': _status,
        'leadSource': _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim(),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'tags': _tagsController.text.trim().isEmpty 
            ? [] 
            : _tagsController.text.split(',').map((t) => t.trim()).toList(),
        'organizationId': auth.currentOrganizationId,
      };

      if (widget.contact == null) {
        await provider.createContact(data);
      } else {
        await provider.updateContact(widget.contact!.id, auth.currentOrganizationId!, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving contact: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
        backgroundColor: AppTheme.backgroundColor,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'First Name',
                      controller: _firstNameController,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Last Name',
                      controller: _lastNameController,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: LucideIcons.mail,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Phone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: LucideIcons.phone,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Secondary Phone',
                      controller: _secondaryPhoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: LucideIcons.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Type',
                      value: _type,
                      items: const [
                        DropdownMenuItem(value: 'BUYER', child: Text('Buyer')),
                        DropdownMenuItem(value: 'SELLER', child: Text('Seller')),
                        DropdownMenuItem(value: 'TENANT', child: Text('Tenant')),
                        DropdownMenuItem(value: 'LANDLORD', child: Text('Landlord')),
                        DropdownMenuItem(value: 'BOTH', child: Text('Both')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _type = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Status',
                      value: _status,
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                        DropdownMenuItem(value: 'LEAD', child: Text('Lead')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Lead Source',
                controller: _sourceController,
                prefixIcon: LucideIcons.share2,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Tags (comma separated)',
                controller: _tagsController,
                prefixIcon: LucideIcons.tag,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Notes',
                controller: _notesController,
                maxLines: 4,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
