import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../utils/auth_form_validators.dart';

/// Public page for requesting password reset instructions.
final class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

final class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authControllerProvider.notifier).clearPublicError();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_successMessage != null) {
      setState(() {
        _successMessage = null;
      });
    }

    final succeeded = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(email: _emailController.text.trim());
    if (!mounted) {
      return;
    }

    setState(() {
      _successMessage = succeeded
          ? 'Tautan reset password telah dikirim. Periksa email Anda.'
          : null;
    });
  }

  void _clearSuccessMessage(String _) {
    if (_successMessage != null) {
      setState(() {
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final errorMessage =
        authState.status == AuthStatus.failure && authState.user == null
        ? authState.errorMessage
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Masukkan email akun Anda untuk menerima tautan reset '
                      'password.',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const ValueKey('forgot-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      onChanged: _clearSuccessMessage,
                      onFieldSubmitted: isLoading ? null : (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: AuthFormValidators.email,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        key: const ValueKey('forgot-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _successMessage!,
                        key: const ValueKey('forgot-success'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: const ValueKey('forgot-submit'),
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kirim Tautan Reset'),
                    ),
                    TextButton(
                      onPressed: () => context.go(RoutePaths.login),
                      child: const Text('Kembali ke Login'),
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
