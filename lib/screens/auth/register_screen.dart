import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../api/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _orgSlugController = TextEditingController();

  bool _isSlugAvailable = true;
  bool _isCheckingSlug = false;
  Timer? _debounce;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _orgNameController.addListener(_onOrgNameChanged);
    _orgSlugController.addListener(_onOrgSlugChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _orgNameController.removeListener(_onOrgNameChanged);
    _orgSlugController.removeListener(_onOrgSlugChanged);
    _orgNameController.dispose();
    _orgSlugController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onOrgNameChanged() {
    final name = _orgNameController.text;
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-');

    _orgSlugController.text = slug;
  }

  Future<void> _onOrgSlugChanged() async {
    final slug = _orgSlugController.text;
    if (slug.isEmpty) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isCheckingSlug = true);

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final available = await auth.checkSlugAvailability(slug);

      if (mounted) {
        setState(() {
          _isSlugAvailable = available;
          _isCheckingSlug = false;
        });
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isSlugAvailable) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register({
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'organizationName': _orgNameController.text,
      'organizationSlug': _orgSlugController.text,
    });
    if (success && mounted) {
      Navigator.pop(
        context,
      ); // Go back to login or it will auto-redirect if main.dart is wired
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join EstateHub',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start managing your portfolio at an elite level.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context, 'First Name'),
                              TextFormField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  errorText: auth.errors?['firstName'],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context, 'Last Name'),
                              TextFormField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  errorText: auth.errors?['lastName'],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildFieldLabel(context, 'Email Address'),
                    TextFormField(
                      controller: _emailController,
                      decoration:
                          InputDecoration(errorText: auth.errors?['email']),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildFieldLabel(context, 'Password'),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        errorText: auth.errors?['password'],
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),

                    Text(
                      'Organization Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildFieldLabel(context, 'Organization Name'),
                    TextFormField(
                      controller: _orgNameController,
                      decoration: InputDecoration(
                        errorText: auth.errors?['organizationName'],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Organization name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildFieldLabel(context, 'Organization Slug'),
                    TextFormField(
                      controller: _orgSlugController,
                      decoration: InputDecoration(
                        errorText:
                            auth.errors?['organizationSlug'] ??
                            (!_isSlugAvailable &&
                                    _orgSlugController.text.isNotEmpty
                                ? 'This slug is already taken'
                                : null),
                        suffixText: '.estatehub.com',
                        suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        suffixIcon: _isCheckingSlug
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (_isSlugAvailable &&
                                    _orgSlugController.text.isNotEmpty
                                ? Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  )
                                : null),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Slug is required';
                        }
                        if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
                          return 'Only lowercase, numbers and hyphens';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              if (auth.errors != null && auth.errors!.containsKey('message'))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    auth.errors!['message']!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.status == AuthStatus.authenticating
                      ? null
                      : _handleRegister,
                  child: auth.status == AuthStatus.authenticating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
