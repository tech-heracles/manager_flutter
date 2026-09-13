import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../common_widgets/app_logo.dart';
import '../application/auth_controller.dart';
import '../application/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _companyStepDone = false;
  bool _lookingUp = false;
  String? _companyName;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continueFromEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _lookingUp = true);
    try {
      final result =
          await ref.read(companyRepositoryProvider).lookupCompanyForEmail(email);
      if (!mounted) return;

      if (!result.found) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found with that email.')),
        );
        return;
      }

      setState(() {
        _companyName = result.companyName;
        _companyStepDone = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not verify that email right now.')),
      );
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  void _backToEmail() {
    setState(() {
      _companyStepDone = false;
      _companyName = null;
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_friendlyError(error))),
          );
        },
      );
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo()),
                  const SizedBox(height: 20),
                  Text(
                    'Sign in',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _companyStepDone
                          ? _buildPasswordStep(isLoading)
                          : _buildEmailStep(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_companyStepDone)
                    TextButton(
                      onPressed: _lookingUp ? null : () => context.go('/signup'),
                      child: const Text("New here? Create a company"),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep() {
    return [
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email'),
        onSubmitted: (_) => _continueFromEmail(),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _lookingUp ? null : _continueFromEmail,
        child: _lookingUp
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Continue'),
      ),
    ];
  }

  List<Widget> _buildPasswordStep(bool isLoading) {
    return [
      InkWell(
        onTap: isLoading ? null : _backToEmail,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.arrow_back, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Signing in to: ${_companyName ?? "..."}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordController,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Password'),
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: isLoading ? null : _submit,
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Sign in'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: isLoading ? null : _forgotPassword,
        child: const Text('Forgot password?'),
      ),
    ];
  }

  void _submit() {
    ref.read(authControllerProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );
  }

  void _forgotPassword() {
    ref.read(authControllerProvider.notifier).sendPasswordReset(_emailController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('invalid-credential') || message.contains('wrong-password')) {
      return 'Incorrect password.';
    }
    return 'Something went wrong. Please try again.';
  }
}