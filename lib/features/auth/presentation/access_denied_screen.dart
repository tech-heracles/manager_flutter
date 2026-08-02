import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_controller.dart';

class AccessDeniedScreen extends ConsumerWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Your account does not have access to this app.\n'
                'This app is limited to admins and supervisors.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}