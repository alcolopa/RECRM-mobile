import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/deals_provider.dart';
import '../../providers/properties_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/leads_provider.dart';
import '../../api/auth_provider.dart';
import '../../widgets/form_inputs.dart';
import '../../widgets/entity_selector.dart';
import '../../models/deal.dart';
import '../../models/property.dart';
import '../../models/contact.dart';
import '../../models/lead.dart';

class DealFormScreen extends StatefulWidget {
  final Deal? deal;

  const DealFormScreen({super.key, this.deal});

  @override
  State<DealFormScreen> createState() => _DealFormScreenState();
}

class _DealFormScreenState extends State<DealFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _valueController;
  late TextEditingController _propertyPriceController;
  late TextEditingController _rentPriceController;
  late TextEditingController _buyerCommissionController;
  late TextEditingController _sellerCommissionController;

  String _stage = 'DISCOVERY';
  String _type = 'SALE';

  String? _selectedPropertyId;
  String? _selectedContactId;
  String? _selectedLeadId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final deal = widget.deal;
    _titleController = TextEditingController(text: deal?.title);
    _valueController = TextEditingController(text: deal?.value?.toString());
    _propertyPriceController = TextEditingController(
      text: deal?.propertyPrice?.toString(),
    );
    _rentPriceController = TextEditingController(
      text: deal?.rentPrice?.toString(),
    );
    _buyerCommissionController = TextEditingController(
      text: deal?.buyerCommission?.toString(),
    );
    _sellerCommissionController = TextEditingController(
      text: deal?.sellerCommission?.toString(),
    );

    if (deal != null) {
      _stage = deal.stage;
      _type = deal.type;
      _selectedPropertyId = deal.propertyId;
      _selectedContactId = deal.contactId;
      _selectedLeadId = deal.leadId;
    }

    // Fetch related entities for selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentOrganizationId != null) {
        context.read<PropertiesProvider>().fetchProperties(
          auth.currentOrganizationId!,
        );
        context.read<ContactsProvider>().fetchContacts(
          auth.currentOrganizationId!,
        );
        context.read<LeadsProvider>().fetchLeads(auth.currentOrganizationId!);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _propertyPriceController.dispose();
    _rentPriceController.dispose();
    _buyerCommissionController.dispose();
    _sellerCommissionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      final provider = context.read<DealsProvider>();

      final data = {
        'title': _titleController.text.trim(),
        'value': _valueController.text.trim().isEmpty
            ? null
            : double.tryParse(_valueController.text.trim()),
        'stage': _stage,
        'type': _type,
        'propertyId': _selectedPropertyId,
        'contactId': _selectedContactId,
        'leadId': _selectedLeadId,
        'propertyPrice': _propertyPriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_propertyPriceController.text.trim()),
        'rentPrice': _rentPriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_rentPriceController.text.trim()),
        'buyerCommission': _buyerCommissionController.text.trim().isEmpty
            ? null
            : double.tryParse(_buyerCommissionController.text.trim()),
        'sellerCommission': _sellerCommissionController.text.trim().isEmpty
            ? null
            : double.tryParse(_sellerCommissionController.text.trim()),
        'organizationId': auth.currentOrganizationId,
      };

      if (widget.deal == null) {
        await provider.createDeal(data);
      } else {
        await provider.updateDeal(
          widget.deal!.id,
          auth.currentOrganizationId!,
          data,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving deal: $e')));
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
        title: Text(widget.deal == null ? 'Add Deal' : 'Edit Deal'),
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
              CustomTextField(
                label: 'Deal Title',
                controller: _titleController,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Type',
                      value: _type,
                      items: const [
                        DropdownMenuItem(value: 'SALE', child: Text('Sale')),
                        DropdownMenuItem(value: 'RENT', child: Text('Rent')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _type = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Stage',
                      value: _stage,
                      items: const [
                        DropdownMenuItem(
                          value: 'DISCOVERY',
                          child: Text('Discovery'),
                        ),
                        DropdownMenuItem(
                          value: 'PROPOSAL',
                          child: Text('Proposal'),
                        ),
                        DropdownMenuItem(
                          value: 'NEGOTIATION',
                          child: Text('Negotiation'),
                        ),
                        DropdownMenuItem(
                          value: 'CLOSED_WON',
                          child: Text('Closed Won'),
                        ),
                        DropdownMenuItem(
                          value: 'CLOSED_LOST',
                          child: Text('Closed Lost'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _stage = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'RELATIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Consumer<PropertiesProvider>(
                builder: (context, provider, _) => EntitySelector<Property>(
                  label: 'Property',
                  selectedValue: _selectedPropertyId != null
                      ? provider.properties
                            .where((p) => p.id == _selectedPropertyId)
                            .firstOrNull
                      : null,
                  displayLabel: (p) => p.title,
                  displaySubtitle: (p) => p.address,
                  items: provider.properties,
                  isLoading: provider.status == PropertiesStatus.loading,
                  onSelected: (p) => setState(() {
                    _selectedPropertyId = p.id;
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<ContactsProvider>(
                builder: (context, provider, _) => EntitySelector<Contact>(
                  label: 'Contact',
                  selectedValue: _selectedContactId != null
                      ? provider.contacts
                            .where((c) => c.id == _selectedContactId)
                            .firstOrNull
                      : null,
                  displayLabel: (c) => c.fullName,
                  displaySubtitle: (c) => c.email ?? c.phone,
                  items: provider.contacts,
                  isLoading: provider.status == ContactsStatus.loading,
                  onSelected: (c) => setState(() {
                    _selectedContactId = c.id;
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<LeadsProvider>(
                builder: (context, provider, _) => EntitySelector<Lead>(
                  label: 'Lead (Optional)',
                  selectedValue: _selectedLeadId != null
                      ? provider.leads
                            .where((l) => l.id == _selectedLeadId)
                            .firstOrNull
                      : null,
                  displayLabel: (l) => l.fullName,
                  displaySubtitle: (l) => l.email ?? l.phone ?? '',
                  items: provider.leads,
                  isLoading: provider.status == LeadsStatus.loading,
                  onSelected: (l) => setState(() {
                    _selectedLeadId = l.id;
                  }),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'FINANCIALS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Deal Value',
                controller: _valueController,
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.dollarSign,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Property Price',
                      controller: _propertyPriceController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Rent Price',
                      controller: _rentPriceController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Buyer Comm %',
                      controller: _buyerCommissionController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Seller Comm %',
                      controller: _sellerCommissionController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
