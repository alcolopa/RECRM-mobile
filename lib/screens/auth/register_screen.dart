import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/auth_provider.dart';
import '../../theme.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Future<void> _handleRegister() async {
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
      Navigator.pop(context); // Go back to login or it will auto-redirect if main.dart is wired
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);

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
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start managing your portfolio at an elite level.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('First Name'),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            errorText: auth.errors?['firstName'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Last Name'),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            errorText: auth.errors?['lastName'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildFieldLabel('Email Address'),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  errorText: auth.errors?['email'],
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              _buildFieldLabel('Password'),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  errorText: auth.errors?['password'],
                ),
                obscureText: true,
              ),
              const SizedBox(height: 40),

              Text(
                'Organization Details',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              _buildFieldLabel('Organization Name'),
              TextFormField(
                controller: _orgNameController,
                decoration: InputDecoration(
                  errorText: auth.errors?['organizationName'],
                ),
              ),
              const SizedBox(height: 24),

              _buildFieldLabel('Organization Slug'),
              TextFormField(
                controller: _orgSlugController,
                decoration: InputDecoration(
                  errorText: auth.errors?['organizationSlug'],
                  prefixText: '.estatehub.com',
                  prefixStyle: GoogleFonts.inter(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ),
              ),
              
              if (auth.errors != null && auth.errors!.containsKey('message'))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    auth.errors!['message']!,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.status == AuthStatus.authenticating ? null : _handleRegister,
                  child: auth.status == AuthStatus.authenticating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
