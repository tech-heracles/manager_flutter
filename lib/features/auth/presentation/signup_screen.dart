import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../common_widgets/app_logo.dart';
import '../application/auth_providers.dart';
import '../application/signup_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _companyNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = ref.watch(authRepositoryProvider).currentUser != null;
    final signUpState = ref.watch(signUpControllerProvider);
    final isLoading = signUpState.isLoading;

    ref.listen<AsyncValue<void>>(signUpControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (context.mounted) context.go('/');
        },
        error: (error, _) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo()),
                  const SizedBox(height: 20),
                  Text(
                    isSignedIn ? 'Finish setting up your company' : 'Create your company',
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
                      children: [
                        TextField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(labelText: 'Company name'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(labelText: 'Your name'),
                        ),
                        if (!isSignedIn) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: isLoading ? null : () => _submit(isSignedIn),
                          child: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create company'),
                        ),
                      ],
                    ),
                  ),
                  if (!isSignedIn) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading ? null : () => context.go('/login'),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(bool isSignedIn) {
    final controller = ref.read(signUpControllerProvider.notifier);
    if (isSignedIn) {
      controller.completeCompanySetup(
        companyName: _companyNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
      );
    } else {
      controller.signUpAndCreateCompany(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        companyName: _companyNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
      );
    }
  }
}