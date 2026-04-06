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

  String _status = 'NEW';
  String _intent = 'SALE';
  String? _urgencyLevel;

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

    if (lead != null) {
      _status = lead.status;
      _intent = lead.intent;
      _urgencyLevel = lead.urgencyLevel;
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
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'status': _status,
        'source': _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim(),
        'budget': _budgetController.text.trim().isEmpty ? null : _budgetController.text.trim(),
        'intent': _intent,
        'urgencyLevel': _urgencyLevel,
        'propertyType': _propertyTypeController.text.trim().isEmpty ? null : _propertyTypeController.text.trim(),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'organizationId': auth.currentOrganizationId,
      };

      if (widget.lead == null) {
        await provider.createLead(data);
      } else {
        await provider.updateLead(widget.lead!.id, auth.currentOrganizationId!, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving lead: $e')),
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
        title: Text(widget.lead == null ? 'Add Lead' : 'Edit Lead'),
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
              CustomTextField(
                label: 'Phone',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: LucideIcons.phone,
              ),
              const SizedBox(height: 16),
              CustomDropdown<String>(
                label: 'Status',
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'NEW', child: Text('New')),
                  DropdownMenuItem(value: 'CONTACTED', child: Text('Contacted')),
                  DropdownMenuItem(value: 'QUALIFIED', child: Text('Qualified')),
                  DropdownMenuItem(value: 'PROPOSAL_SENT', child: Text('Proposal Sent')),
                  DropdownMenuItem(value: 'NEGOTIATION', child: Text('Negotiation')),
                  DropdownMenuItem(value: 'LOST', child: Text('Lost')),
                  DropdownMenuItem(value: 'CLOSED_WON', child: Text('Closed Won')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Intent',
                      value: _intent,
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
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Not Set')),
                        DropdownMenuItem(value: 'LOW', child: Text('Low')),
                        DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
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
                      prefixIcon: LucideIcons.dollarSign,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Property Type',
                      controller: _propertyTypeController,
                      prefixIcon: LucideIcons.building,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Source',
                controller: _sourceController,
                prefixIcon: LucideIcons.share2,
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
