import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/leads_provider.dart';
import '../../api/auth_provider.dart';
import '../../widgets/form_inputs.dart';
import '../../models/lead.dart';

class LeadFormScreen extends StatefulWidget {
  final Lead? lead;

  const LeadFormScreen({super.key, this.lead});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _sourceController;
  late TextEditingController _budgetController;
  late TextEditingController _notesController;
  late TextEditingController _propertyTypeController;
  late TextEditingController _locationController;

  String _status = 'NEW';
  String _intent = 'SALE';
  String? _urgencyLevel;
  String? _assignedUserId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final lead = widget.lead;
    _firstNameController = TextEditingController(text: lead?.firstName);
    _lastNameController = TextEditingController(text: lead?.lastName);
    _emailController = TextEditingController(text: lead?.email);
    _phoneController = TextEditingController(text: lead?.phone);
    _sourceController = TextEditingController(text: lead?.source);
    _budgetController = TextEditingController(text: lead?.budget);
    _notesController = TextEditingController(text: lead?.notes);
    _propertyTypeController = TextEditingController(text: lead?.propertyType);
    _locationController = TextEditingController(text: lead?.preferredLocation);

    if (lead != null) {
      _status = lead.status;
      _intent = lead.intent;
      _urgencyLevel = lead.urgencyLevel;
      _assignedUserId = lead.assignedUserId;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sourceController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    _propertyTypeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      final provider = context.read<LeadsProvider>();

      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'status': _status,
        'source': _sourceController.text.trim().isEmpty
            ? null
            : _sourceController.text.trim(),
        'budget': _budgetController.text.trim().isEmpty
            ? null
            : _budgetController.text.trim(),
        'intent': _intent,
        'urgencyLevel': _urgencyLevel,
        'propertyType': _propertyTypeController.text.trim().isEmpty
            ? null
            : _propertyTypeController.text.trim(),
        'preferredLocation': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'assignedUserId': _assignedUserId,
        'organizationId': auth.currentOrganizationId,
      };

      if (widget.lead == null) {
        await provider.createLead(data);
      } else {
        await provider.updateLead(
          widget.lead!.id,
          auth.currentOrganizationId!,
          data,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving lead: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeadsProvider>();
    final auth = context.watch<AuthProvider>();
    final errors = provider.errors;

    final members = auth.organization?.memberships ?? [];
    final safeSelectedUserId = members.any((m) => m.userId == _assignedUserId)
        ? _assignedUserId
        : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.lead == null ? 'Add Lead' : 'Edit Lead'),
        backgroundColor: AppTheme.backgroundColor,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
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
              _buildSectionTitle('Basic Info'),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'First Name',
                      controller: _firstNameController,
                      errorText: errors?['firstName'],
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Last Name',
                      controller: _lastNameController,
                      errorText: errors?['lastName'],
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                errorText: errors?['email'],
                keyboardType: TextInputType.emailAddress,
                prefixIcon: LucideIcons.mail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone',
                controller: _phoneController,
                errorText: errors?['phone'],
                keyboardType: TextInputType.phone,
                prefixIcon: LucideIcons.phone,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Lead Status & Assignment'),
              CustomDropdown<String>(
                label: 'Status',
                value: _status,
                errorText: errors?['status'],
                items: const [
                  DropdownMenuItem(value: 'NEW', child: Text('New')),
                  DropdownMenuItem(
                    value: 'CONTACTED',
                    child: Text('Contacted'),
                  ),
                  DropdownMenuItem(
                    value: 'QUALIFIED',
                    child: Text('Qualified'),
                  ),
                  DropdownMenuItem(
                    value: 'PROPOSAL_SENT',
                    child: Text('Proposal Sent'),
                  ),
                  DropdownMenuItem(
                    value: 'NEGOTIATION',
                    child: Text('Negotiation'),
                  ),
                  DropdownMenuItem(value: 'LOST', child: Text('Lost')),
                  DropdownMenuItem(
                    value: 'CLOSED_WON',
                    child: Text('Closed Won'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 16),
              CustomDropdown<String?>(
                label: 'Assigned Agent',
                value: safeSelectedUserId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Unassigned')),
                  ...members.map(
                    (m) => DropdownMenuItem(
                      value: m.userId,
                      child: Text(m.user?.fullName ?? 'Unknown'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _assignedUserId = value),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Requirements'),
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Intent',
                      value: _intent,
                      errorText: errors?['intent'],
                      items: const [
                        DropdownMenuItem(value: 'SALE', child: Text('Sale')),
                        DropdownMenuItem(value: 'RENT', child: Text('Rent')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _intent = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Urgency',
                      value: _urgencyLevel,
                      errorText: errors?['urgencyLevel'],
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Not Set')),
                        DropdownMenuItem(value: 'LOW', child: Text('Low')),
                        DropdownMenuItem(
                          value: 'MEDIUM',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      ],
                      onChanged: (value) {
                        setState(() => _urgencyLevel = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Budget',
                      controller: _budgetController,
                      errorText: errors?['budget'],
                      prefixIcon: LucideIcons.dollarSign,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Property Type',
                      controller: _propertyTypeController,
                      errorText: errors?['propertyType'],
                      prefixIcon: LucideIcons.building,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Preferred Location',
                controller: _locationController,
                errorText: errors?['preferredLocation'],
                prefixIcon: LucideIcons.mapPin,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Source',
                controller: _sourceController,
                errorText: errors?['source'],
                prefixIcon: LucideIcons.share2,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Additional Info'),
              CustomTextField(
                label: 'Notes',
                controller: _notesController,
                errorText: errors?['notes'],
                maxLines: 4,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
