import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme.dart';
import '../../api/auth_provider.dart';
import '../../api/organization_service.dart';
import '../../api/commission_service.dart';
import '../../models/organization.dart';
import '../../widgets/form_inputs.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  State<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState extends State<OrganizationSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _organizationService = OrganizationService();
  final _commissionService = CommissionService();
  final _imagePicker = ImagePicker();

  bool _isLoading = true;
  Organization? _org;
  CommissionConfig? _commissionConfig;
  List<Invitation> _invitations = [];
  List<CustomRole> _roles = [];

  // General Settings Controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;

  // Commission Controllers (needed to avoid jumps)
  final Map<String, TextEditingController> _commControllers = {};

  String _selectedAccentColor = 'EMERALD';
  String _selectedTheme = 'LIGHT';
  bool _isSavingGeneral = false;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _websiteController = TextEditingController();
    _addressController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    for (var ctrl in _commControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final orgId = auth.currentOrganizationId;
      if (orgId == null) return;

      final results = await Future.wait([
        _organizationService.getOrganization(orgId),
        _commissionService.getOrgCommission(orgId),
        _organizationService.getInvitations(orgId),
        _organizationService.getRoles(orgId),
      ]);

      if (!mounted) return;

      setState(() {
        _org = results[0] as Organization;
        _commissionConfig = results[1] as CommissionConfig;
        _invitations = results[2] as List<Invitation>;
        _roles = results[3] as List<CustomRole>;

        _nameController.text = _org?.name ?? '';
        _emailController.text = _org?.email ?? '';
        _phoneController.text = _org?.phone ?? '';
        _websiteController.text = _org?.website ?? '';
        _addressController.text = _org?.address ?? '';
        _selectedAccentColor = _org?.accentColor ?? 'EMERALD';
        _selectedTheme = _org?.defaultTheme ?? 'LIGHT';

        _initCommControllers();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading org settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load settings')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _initCommControllers() {
    if (_commissionConfig == null) return;
    _updateCommCtrl('rentBuyer', _commissionConfig!.rentBuyerValue);
    _updateCommCtrl('rentSeller', _commissionConfig!.rentSellerValue);
    _updateCommCtrl('rentAgent', _commissionConfig!.rentAgentValue);
    _updateCommCtrl('saleBuyer', _commissionConfig!.saleBuyerValue);
    _updateCommCtrl('saleSeller', _commissionConfig!.saleSellerValue);
    _updateCommCtrl('saleAgent', _commissionConfig!.saleAgentValue);
  }

  void _updateCommCtrl(String key, double? val) {
    if (!_commControllers.containsKey(key)) {
      _commControllers[key] = TextEditingController(
        text: val?.toString() ?? '',
      );
    } else if (_commControllers[key]!.text != (val?.toString() ?? '')) {
      _commControllers[key]!.text = val?.toString() ?? '';
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;

    setState(() => _isUploadingLogo = true);
    try {
      final logoUrl = await _organizationService.uploadLogo(
        _org!.id,
        image.path,
      );
      if (!mounted) return;
      context.read<AuthProvider>().updateOrganizationLogo(logoUrl);
      setState(() {
        _org = Organization(
          id: _org!.id,
          name: _org!.name,
          slug: _org!.slug,
          address: _org!.address,
          email: _org!.email,
          logo: logoUrl,
          phone: _org!.phone,
          website: _org!.website,
          ownerId: _org!.ownerId,
          accentColor: _org!.accentColor,
          defaultTheme: _org!.defaultTheme,
          memberships: _org!.memberships,
          subscription: _org!.subscription,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo updated successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to upload logo')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _saveGeneral(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingGeneral = true);
    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'website': _websiteController.text.trim(),
      'address': _addressController.text.trim(),
      'accentColor': _selectedAccentColor,
      'defaultTheme': _selectedTheme,
    };

    final success = await auth.updateOrganization(data);
    if (!mounted) return;
    setState(() => _isSavingGeneral = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errors?['message'] ?? 'Failed to save settings'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final auth = context.watch<AuthProvider>();
    final isOwner = auth.user?['role'] == 'OWNER';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Organization Settings',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            const Tab(text: 'General'),
            const Tab(text: 'Team'),
            if (isOwner) const Tab(text: 'Roles'),
            if (isOwner) const Tab(text: 'Commission'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(auth, isOwner),
          _buildTeamTab(isOwner),
          if (isOwner) _buildRolesTab(),
          if (isOwner) _buildCommissionTab(),
        ],
      ),
    );
  }

  // --- TAB: General ---

  Widget _buildGeneralTab(AuthProvider auth, bool isOwner) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogoSection(isOwner),
          const SizedBox(height: 32),
          _buildThemeSection(isOwner),
          const SizedBox(height: 32),
          _buildGeneralForm(auth, isOwner),
        ],
      ),
    );
  }

  Widget _buildLogoSection(bool isOwner) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLift,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.surfaceContainer),
              image: _org?.logo != null
                  ? DecorationImage(
                      image: NetworkImage(_org!.logo!),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: _org?.logo == null
                ? const Icon(
                    LucideIcons.building2,
                    size: 48,
                    color: AppTheme.onSurfaceVariant,
                  )
                : null,
          ),
          if (_isUploadingLogo)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          if (isOwner)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploadingLogo ? null : _pickAndUploadLogo,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.camera,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(bool isOwner) {
    final colors = [
      'EMERALD',
      'SAPPHIRE',
      'AMETHYST',
      'CITRINE',
      'ROSE',
      'SLATE',
    ];
    final colorMap = {
      'EMERALD': const Color(0xFF059669),
      'SAPPHIRE': const Color(0xFF2563EB),
      'AMETHYST': const Color(0xFF8B5CF6),
      'CITRINE': const Color(0xFFD97706),
      'ROSE': const Color(0xFFE11D48),
      'SLATE': const Color(0xFF475569),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Theme & Appearance'),
        const SizedBox(height: 16),
        Text(
          'Accent Color',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((c) {
            final isSelected = _selectedAccentColor == c;
            return GestureDetector(
              onTap: isOwner
                  ? () => setState(() => _selectedAccentColor = c)
                  : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorMap[c],
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        LucideIcons.check,
                        size: 20,
                        color: Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Default Public Theme',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildThemeOption('LIGHT', LucideIcons.sun, isOwner),
            const SizedBox(width: 12),
            _buildThemeOption('DARK', LucideIcons.moon, isOwner),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(String mode, IconData icon, bool isOwner) {
    final isSelected = _selectedTheme == mode;
    return Expanded(
      child: GestureDetector(
        onTap: isOwner ? () => setState(() => _selectedTheme = mode) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceLift,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.surfaceContainer,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                mode == 'LIGHT' ? 'Light' : 'Dark',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralForm(AuthProvider auth, bool isOwner) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildSectionTitle('Organization Details'),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Organization Name',
            controller: _nameController,
            enabled: isOwner,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Public Email',
            controller: _emailController,
            enabled: isOwner,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Phone Number',
            controller: _phoneController,
            enabled: isOwner,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Website',
            controller: _websiteController,
            enabled: isOwner,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Office Address',
            controller: _addressController,
            enabled: isOwner,
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          if (isOwner)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingGeneral ? null : () => _saveGeneral(auth),
                child: _isSavingGeneral
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
        ],
      ),
    );
  }

  // --- TAB: Team ---

  Widget _buildTeamTab(bool isOwner) {
    final memberships = _org?.memberships ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_org?.subscription != null) _buildSeatUsageCard(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Members (${memberships.length})'),
              if (isOwner)
                TextButton.icon(
                  onPressed: _showInviteDialog,
                  icon: const Icon(LucideIcons.userPlus, size: 16),
                  label: const Text('Invite'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...memberships.map((m) => _buildMemberCard(m, isOwner)),
          if (_invitations.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionTitle('Pending Invitations (${_invitations.length})'),
            const SizedBox(height: 12),
            ..._invitations.map((i) => _buildInvitationCard(i, isOwner)),
          ],
        ],
      ),
    );
  }

  Widget _buildSeatUsageCard() {
    final sub = _org!.subscription!;
    final progress = sub.usedSeats / sub.seats;
    final isFull = sub.usedSeats >= sub.seats;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLift,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seat Usage',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              Text(
                '${sub.usedSeats} / ${sub.seats}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isFull ? Colors.red : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? Colors.red : AppTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
          if (isFull) ...[
            const SizedBox(height: 8),
            const Text(
              'You have reached your seat limit. Increase seats to invite more members.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberCard(Membership m, bool isOwner) {
    final user = m.user;
    final name = user?.fullName ?? 'Unknown User';
    final role = m.role;
    final customRole = m.customRole?.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLift,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                ? NetworkImage(user.avatar!)
                : null,
            child: (user?.avatar == null || user!.avatar!.isEmpty)
                ? Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  customRole ?? role,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isOwner && m.role != 'OWNER')
            PopupMenuButton(
              icon: const Icon(LucideIcons.moreVertical),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'role', child: Text('Change Role')),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Remove Member',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'role') {
                  _showChangeRoleDialog(m);
                }
                if (val == 'remove') {
                  _confirmRemoveMember(m);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(Invitation i, bool isOwner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLift,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.surfaceContainer,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.mail, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.email,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Pending • ${i.customRole?.name ?? i.role}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isOwner)
            PopupMenuButton(
              icon: const Icon(LucideIcons.moreVertical),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'resend',
                  child: Text('Resend Invite'),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Text(
                    'Cancel Invite',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'resend') {
                  _resendInvitation(i);
                }
                if (val == 'cancel') {
                  _cancelInvitation(i);
                }
              },
            ),
        ],
      ),
    );
  }

  // --- TAB: Roles ---

  Widget _buildRolesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Custom Roles'),
              TextButton.icon(
                onPressed: () => _showRoleDialog(null),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Role'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._roles.map((r) => _buildRoleCard(r)),
        ],
      ),
    );
  }

  Widget _buildRoleCard(CustomRole r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLift,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.shield, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${r.permissions.length} Permissions',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!r.isSystem)
            IconButton(
              icon: const Icon(LucideIcons.edit3, size: 18),
              onPressed: () => _showRoleDialog(r),
            ),
        ],
      ),
    );
  }

  // --- TAB: Commission ---

  Widget _buildCommissionTab() {
    if (_commissionConfig == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Organization Defaults'),
          const SizedBox(height: 16),
          _buildCommissionSection('Sales', isRent: false),
          const SizedBox(height: 24),
          _buildCommissionSection('Rentals', isRent: true),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveCommission,
              child: const Text('Save Commission Configuration'),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildCommissionSection(String title, {required bool isRent}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLift,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildCommissionInputRow(
            'Buyer Side',
            val: isRent
                ? _commissionConfig!.rentBuyerValue
                : _commissionConfig!.saleBuyerValue,
            type: isRent
                ? _commissionConfig!.rentBuyerType
                : _commissionConfig!.saleBuyerType,
            key: isRent ? 'rentBuyer' : 'saleBuyer',
            onChanged: (v, t) => _updateCommission(isRent, 'buyer', v, t),
          ),
          const SizedBox(height: 12),
          _buildCommissionInputRow(
            'Seller Side',
            val: isRent
                ? _commissionConfig!.rentSellerValue
                : _commissionConfig!.saleSellerValue,
            type: isRent
                ? _commissionConfig!.rentSellerType
                : _commissionConfig!.saleSellerType,
            key: isRent ? 'rentSeller' : 'saleSeller',
            onChanged: (v, t) => _updateCommission(isRent, 'seller', v, t),
          ),
          const SizedBox(height: 12),
          _buildCommissionInputRow(
            'Agent Share',
            val: isRent
                ? _commissionConfig!.rentAgentValue
                : _commissionConfig!.saleAgentValue,
            type: isRent
                ? _commissionConfig!.rentAgentType
                : _commissionConfig!.saleAgentType,
            key: isRent ? 'rentAgent' : 'saleAgent',
            onChanged: (v, t) => _updateCommission(isRent, 'agent', v, t),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionInputRow(
    String label, {
    required double? val,
    required String type,
    required String key,
    required Function(double?, String) onChanged,
  }) {
    final ctrl =
        _commControllers[key] ??
        TextEditingController(text: val?.toString() ?? '');
    _commControllers[key] = ctrl;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 40,
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              controller: ctrl,
              decoration: InputDecoration(
                hintText: '0.00',
                suffixText: type == 'PERCENTAGE'
                    ? '%'
                    : (type == 'MULTIPLIER' ? 'x' : '\$'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (s) => onChanged(double.tryParse(s), type),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: type,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'PERCENTAGE', child: Text('%')),
            DropdownMenuItem(value: 'FIXED', child: Text('\$')),
            DropdownMenuItem(value: 'MULTIPLIER', child: Text('x')),
          ],
          onChanged: (v) => v != null ? onChanged(val, v) : null,
        ),
      ],
    );
  }

  void _updateCommission(bool isRent, String side, double? val, String type) {
    setState(() {
      final config = _commissionConfig!;
      if (isRent) {
        _commissionConfig = CommissionConfig(
          id: config.id,
          organizationId: config.organizationId,
          rentBuyerValue: side == 'buyer' ? val : config.rentBuyerValue,
          rentBuyerType: side == 'buyer' ? type : config.rentBuyerType,
          rentSellerValue: side == 'seller' ? val : config.rentSellerValue,
          rentSellerType: side == 'seller' ? type : config.rentSellerType,
          rentAgentValue: side == 'agent' ? val : config.rentAgentValue,
          rentAgentType: side == 'agent' ? type : config.rentAgentType,
          saleBuyerValue: config.saleBuyerValue,
          saleBuyerType: config.saleBuyerType,
          saleSellerValue: config.saleSellerValue,
          saleSellerType: config.saleSellerType,
          saleAgentValue: config.saleAgentValue,
          saleAgentType: config.saleAgentType,
        );
      } else {
        _commissionConfig = CommissionConfig(
          id: config.id,
          organizationId: config.organizationId,
          rentBuyerValue: config.rentBuyerValue,
          rentBuyerType: config.rentBuyerType,
          rentSellerValue: config.rentSellerValue,
          rentSellerType: config.rentSellerType,
          rentAgentValue: config.rentAgentValue,
          rentAgentType: config.rentAgentType,
          saleBuyerValue: side == 'buyer' ? val : config.saleBuyerValue,
          saleBuyerType: side == 'buyer' ? type : config.saleBuyerType,
          saleSellerValue: side == 'seller' ? val : config.saleSellerValue,
          saleSellerType: side == 'seller' ? type : config.saleSellerType,
          saleAgentValue: side == 'agent' ? val : config.saleAgentValue,
          saleAgentType: side == 'agent' ? type : config.saleAgentType,
        );
      }
      _initCommControllers();
    });
  }

  Future<void> _saveCommission() async {
    try {
      await _commissionService.updateOrgCommission(
        _org!.id,
        _commissionConfig!.toJson(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission configuration saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save commission settings')),
        );
      }
    }
  }

  // --- Dialogs & Helpers ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: AppTheme.onSurface,
      ),
    );
  }

  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    String? selectedCustomRoleId = _roles.isNotEmpty ? _roles.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Invite Team Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(label: 'Email Address', controller: emailCtrl),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCustomRoleId,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _roles
                    .map(
                      (r) => DropdownMenuItem(value: r.id, child: Text(r.name)),
                    )
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedCustomRoleId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailCtrl.text.isEmpty || selectedCustomRoleId == null) {
                  return;
                }
                try {
                  await _organizationService.inviteMember(
                    _org!.id,
                    emailCtrl.text.trim(),
                    'AGENT',
                    selectedCustomRoleId!,
                  );
                  _loadData();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Failed to send invite')),
                    );
                  }
                }
              },
              child: const Text('SEND INVITE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(Membership m) {
    String? selectedCustomRoleId = m.customRoleId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Member Role'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedCustomRoleId,
            decoration: const InputDecoration(labelText: 'New Role'),
            items: _roles
                .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                .toList(),
            onChanged: (v) => setDialogState(() => selectedCustomRoleId = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCustomRoleId == null) {
                  return;
                }
                try {
                  await _organizationService.updateMemberRole(
                    _org!.id,
                    m.id,
                    selectedCustomRoleId!,
                  );
                  _loadData();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Failed to update role')),
                    );
                  }
                }
              },
              child: const Text('UPDATE'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(Membership m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text(
          'Are you sure you want to remove ${m.user?.fullName} from the organization?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _organizationService.removeMember(_org!.id, m.id);
                _loadData();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Failed to remove member')),
                  );
                }
              }
            },
            child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resendInvitation(Invitation i) async {
    try {
      await _organizationService.resendInvitation(_org!.id, i.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation resent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend invitation')),
        );
      }
    }
  }

  void _cancelInvitation(Invitation i) async {
    try {
      await _organizationService.cancelInvitation(_org!.id, i.id);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel invitation')),
        );
      }
    }
  }

  void _showRoleDialog(CustomRole? role) {
    final nameCtrl = TextEditingController(text: role?.name);
    List<String> selectedPerms = List.from(role?.permissions ?? []);

    final allPermissions = [
      'LEADS_VIEW',
      'LEADS_CREATE',
      'LEADS_EDIT',
      'LEADS_DELETE',
      'CONTACTS_VIEW',
      'CONTACTS_CREATE',
      'CONTACTS_EDIT',
      'CONTACTS_DELETE',
      'PROPERTIES_VIEW',
      'PROPERTIES_CREATE',
      'PROPERTIES_EDIT',
      'PROPERTIES_DELETE',
      'DEALS_VIEW',
      'DEALS_CREATE',
      'DEALS_EDIT',
      'DEALS_DELETE',
      'TEAM_VIEW',
      'TEAM_INVITE',
      'TEAM_EDIT_ROLES',
      'TEAM_REMOVE_MEMBER',
      'ORG_SETTINGS_EDIT',
      'DASHBOARD_VIEW',
      'PAYOUTS_VIEW',
      'TASKS_VIEW',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(role == null ? 'Create Role' : 'Edit Role'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(label: 'Role Name', controller: nameCtrl),
                const SizedBox(height: 16),
                const Text(
                  'Permissions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: allPermissions
                        .map(
                          (p) => CheckboxListTile(
                            title: Text(
                              p.replaceAll('_', ' '),
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: selectedPerms.contains(p),
                            onChanged: (v) {
                              setDialogState(() {
                                if (v!) {
                                  selectedPerms.add(p);
                                } else {
                                  selectedPerms.remove(p);
                                }
                              });
                            },
                            dense: true,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (role != null)
              TextButton(
                onPressed: () async {
                  try {
                    await _organizationService.deleteRole(_org!.id, role.id);
                    _loadData();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Failed to delete role')),
                      );
                    }
                  }
                },
                child: const Text(
                  'DELETE',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) {
                  return;
                }
                try {
                  if (role == null) {
                    await _organizationService.createRole(
                      _org!.id,
                      nameCtrl.text.trim(),
                      selectedPerms,
                    );
                  } else {
                    await _organizationService.updateRole(
                      _org!.id,
                      role.id,
                      nameCtrl.text.trim(),
                      selectedPerms,
                    );
                  }
                  _loadData();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Failed to save role')),
                    );
                  }
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}
