import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lead.dart';
import 'form_inputs.dart';

class ConvertLeadDialog extends StatefulWidget {
  final Lead lead;

  const ConvertLeadDialog({super.key, required this.lead});

  @override
  State<ConvertLeadDialog> createState() => _ConvertLeadDialogState();
}

class _ConvertLeadDialogState extends State<ConvertLeadDialog> {
  String _contactType = 'BUYER';
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceLift,
      title: Text(
        'Convert to Contact',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convert ${widget.lead.fullName} into a verified contact. This action will move them from Leads to Contacts.',
              style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            CustomDropdown<String>(
              label: 'Contact Type',
              value: _contactType,
              items: const [
                DropdownMenuItem(value: 'BUYER', child: Text('Buyer')),
                DropdownMenuItem(value: 'SELLER', child: Text('Seller')),
                DropdownMenuItem(value: 'BOTH', child: Text('Both')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _contactType = value);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Conversion Notes',
              controller: _notesController,
              hint: 'e.g. Qualified after initial call...',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'type': _contactType,
              'notes': _notesController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('CONVERT'),
        ),
      ],
    );
  }
}
