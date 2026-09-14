import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_textfield.dart';
import '../models/auth_validator.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? message;

  const LoginScreen({this.message, super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final success = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.dashboard);
    } else {
      final state = ref.read(authProvider);
      setState(() => _error = state.error?.toString() ?? 'Unable to sign in.');
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(controller.text.trim()),
            child: const Text('Send email'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || email == null) return;

    final validationError = AuthValidator.validateEmail(email);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    try {
      await ref.read(authProvider.notifier).sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.electrical_services, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Sign in to ESMS',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.message ?? 'Manage your electrical shop securely.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: Colors.red[700])),
                      const SizedBox(height: 12),
                    ],
                    PrimaryTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      validator: AuthValidator.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    PrimaryTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      obscureText: _obscurePassword,
                      enabled: !isLoading,
                      validator: AuthValidator.validatePassword,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: isLoading
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    PrimaryButton(
                      text: 'Login',
                      onPressed: _login,
                      isLoading: isLoading,
                    ),
                    TextButton(
                      onPressed: isLoading ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.push(AppRoutes.setup),
                      child: const Text('Initial shop setup'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
