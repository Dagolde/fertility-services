import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return LoadingOverlay(
              isLoading: authProvider.isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConfig.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildLoginForm(authProvider),
                    const SizedBox(height: 24),
                    _buildForgotPasswordLink(),
                    const SizedBox(height: 32),
                    _buildLoginButton(authProvider),
                    const SizedBox(height: 16),
                    _buildBiometricLogin(authProvider),
                    const SizedBox(height: 32),
                    _buildDivider(),
                    const SizedBox(height: 32),
                    _buildSignUpLink(),
                    if (authProvider.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorMessage(authProvider.errorMessage!),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthProvider authProvider) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            name: 'email',
            label: 'Email',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validators: [
              FormBuilderValidators.required(),
              FormBuilderValidators.email(),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            name: 'password',
            label: 'Password',
            hintText: 'Enter your password',
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validators: [
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(AppConfig.minPasswordLength),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              const Text('Remember me'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => context.push('/forgot-password'),
        child: const Text('Forgot Password?'),
      ),
    );
  }

  Widget _buildLoginButton(AuthProvider authProvider) {
    return CustomButton(
      text: 'Sign In',
      onPressed: () => _handleLogin(authProvider),
      isLoading: authProvider.isLoading,
    );
  }

  Widget _buildBiometricLogin(AuthProvider authProvider) {
    if (!authProvider.isBiometricEnabled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const Text(
          'Or sign in with',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _handleBiometricLogin(authProvider),
          icon: const Icon(Icons.fingerprint),
          label: const Text('Biometric'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'New to ${AppConfig.appName}?',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return OutlinedButton(
      onPressed: () => context.push('/register'),
      child: const Text('Create Account'),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).clearError();
            },
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      
      final success = await authProvider.login(
        formData['email'],
        formData['password'],
      );

      if (success && mounted) {
        // Navigate to home screen
        context.go('/home');
      }
    }
  }

  Future<void> _handleBiometricLogin(AuthProvider authProvider) async {
    final success = await authProvider.loginWithBiometrics();

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
