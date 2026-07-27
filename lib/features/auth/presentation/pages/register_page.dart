import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../utils/auth_form_validators.dart';

/// Public page for creating a CampusMate account.
final class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

final class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
        );
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
      appBar: AppBar(title: const Text('Daftar CampusMate')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const ValueKey('register-full-name'),
                        controller: _fullNameController,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          border: OutlineInputBorder(),
                        ),
                        validator: AuthFormValidators.fullName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('register-email'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: AuthFormValidators.email,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('register-password'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Tampilkan password'
                                : 'Sembunyikan password',
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: AuthFormValidators.password,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('register-confirm-password'),
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: isLoading ? null : (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmPassword
                                ? 'Tampilkan konfirmasi password'
                                : 'Sembunyikan konfirmasi password',
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            AuthFormValidators.confirmPassword(
                              value,
                              _passwordController.text,
                            ),
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          key: const ValueKey('register-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        key: const ValueKey('register-submit'),
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Daftar'),
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
      ),
    );
  }
}
