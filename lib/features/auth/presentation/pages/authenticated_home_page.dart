import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Temporary authenticated home until the dashboard batch is implemented.
final class AuthenticatedHomePage extends ConsumerWidget {
  const AuthenticatedHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = ref.watch(authUserProvider);
    final isLoading = authState.status == AuthStatus.loading;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final greeting = user.fullName == null || user.fullName!.trim().isEmpty
        ? user.email
        : user.fullName!;
    final isVerified = user.emailVerified;

    return Scaffold(
      appBar: AppBar(title: const Text('CampusMate')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Halo, $greeting'),
            const SizedBox(height: 8),
            Text(user.email),
            const SizedBox(height: 8),
            Text(isVerified ? 'Terverifikasi' : 'Belum terverifikasi'),
            if (authState.status == AuthStatus.failure &&
                authState.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                authState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            if (!isVerified)
              OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .resendVerificationEmail(),
                child: const Text('Kirim Ulang Verifikasi'),
              ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signOut(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
