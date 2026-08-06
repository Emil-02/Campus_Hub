import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_provider.dart';

/// Form for changing the account password (T-069).
final class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

final class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    final error = await ref
        .read(profileControllerProvider.notifier)
        .changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error ?? 'Password berhasil diubah.')),
      );
    if (error == null) {
      context.pop();
    }
  }

  String? _validateNewPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Password baru harus diisi.';
    }
    if (text.length < 8) {
      return 'Password minimal 8 karakter.';
    }
    final hasUpper = text.contains(RegExp(r'[A-Z]'));
    final hasLower = text.contains(RegExp(r'[a-z]'));
    final hasDigit = text.contains(RegExp(r'\d'));
    if (!hasUpper || !hasLower || !hasDigit) {
      return 'Harus mengandung huruf besar, huruf kecil, dan angka.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('password-current'),
                    controller: _currentController,
                    obscureText: _obscureCurrent,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password lama',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureCurrent = !_obscureCurrent;
                          });
                        },
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Password lama harus diisi.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('password-new'),
                    controller: _newController,
                    obscureText: _obscureNew,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password baru',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureNew = !_obscureNew;
                          });
                        },
                        icon: Icon(
                          _obscureNew ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: _validateNewPassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('password-confirm'),
                    controller: _confirmController,
                    obscureText: _obscureNew,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: _isSubmitting ? null : (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi password baru',
                    ),
                    validator: (value) => value != _newController.text
                        ? 'Konfirmasi password tidak cocok.'
                        : null,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    key: const ValueKey('password-submit'),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ubah Password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
