import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Bootstraps the authentication session before protected routing begins.
final class AuthBootstrapPage extends ConsumerStatefulWidget {
  const AuthBootstrapPage({super.key});

  @override
  ConsumerState<AuthBootstrapPage> createState() => _AuthBootstrapPageState();
}

final class _AuthBootstrapPageState extends ConsumerState<AuthBootstrapPage> {
  @override
  void initState() {
    super.initState();
    _scheduleInitialize();
  }

  void _scheduleInitialize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authControllerProvider.notifier).initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading =
        authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading;

    return Scaffold(
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : authState.status == AuthStatus.failure
            ? _FailureContent(
                message:
                    authState.errorMessage ?? 'Terjadi kesalahan autentikasi.',
                onRetry: _scheduleInitialize,
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

final class _FailureContent extends StatelessWidget {
  const _FailureContent({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    );
  }
}
