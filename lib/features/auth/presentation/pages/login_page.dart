import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../utils/auth_form_validators.dart';

/// Public page for signing in with email or Google.
final class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

final class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
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
      appBar: AppBar(title: const Text('CampusMate')),
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
                      Text(
                        'Masuk',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const ValueKey('login-email'),
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
                        key: const ValueKey('login-password'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: isLoading ? null : (_) => _submit(),
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
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          key: const ValueKey('login-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        key: const ValueKey('login-submit'),
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Masuk'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const ValueKey('login-google'),
                        onPressed: isLoading ? null : _signInWithGoogle,
                        icon: const Icon(Icons.login),
                        label: const Text('Masuk dengan Google'),
                      ),
                      TextButton(
                        onPressed: () => context.go(RoutePaths.register),
                        child: const Text('Daftar'),
                      ),
                      TextButton(
                        onPressed: () => context.go(RoutePaths.forgotPassword),
                        child: const Text('Lupa Password'),
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
