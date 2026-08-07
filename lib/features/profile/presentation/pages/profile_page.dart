import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_state.dart';

/// Profile overview with the settings list (design system §25).
final class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

final class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(profileControllerProvider.notifier).loadProfile();
      }
    });
  }

  Future<void> _pickAvatar() async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil foto'),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    if (fromCamera == null || !mounted) {
      return;
    }

    try {
      final file = await ref
          .read(imageServiceProvider)
          .pickAvatar(fromCamera: fromCamera);
      if (file == null || !mounted) {
        return;
      }
      final uploaded = await ref
          .read(profileControllerProvider.notifier)
          .uploadAvatar(file);
      _showSnackBar(
        uploaded
            ? 'Foto profil diperbarui.'
            : ref.read(profileControllerProvider).errorMessage ??
                  'Gagal mengunggah foto.',
      );
    } catch (_) {
      _showSnackBar('Tidak dapat mengambil gambar.');
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda harus login kembali untuk mengakses data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final email = authState.user?.email ?? '';
    final isBusy =
        profileState.isMutating || authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: switch (profileState.status) {
        ProfileStatus.initial || ProfileStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        ProfileStatus.failure when profileState.profile == null => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profileState.errorMessage ?? 'Terjadi kesalahan. Coba lagi.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(profileControllerProvider.notifier)
                      .loadProfile(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        _ => _ProfileContent(
          profile: profileState.profile!,
          email: email,
          isBusy: isBusy,
          errorMessage: profileState.status == ProfileStatus.failure
              ? profileState.errorMessage
              : null,
          onChangeAvatar: _pickAvatar,
          onLogout: _confirmLogout,
        ),
      },
    );
  }
}

final class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.profile,
    required this.email,
    required this.isBusy,
    required this.errorMessage,
    required this.onChangeAvatar,
    required this.onLogout,
  });

  final ProfileEntity profile;
  final String email;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onChangeAvatar;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final academicParts = <String>[
      if (profile.degreeLevel != null) profile.degreeLevel!,
      if (profile.studyProgram != null) profile.studyProgram!,
      if (profile.semester != null) 'Semester ${profile.semester}',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: colorScheme.primary,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(
                        _initials(
                          profile.fullName.isEmpty ? email : profile.fullName,
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: colorScheme.primaryContainer,
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: const ValueKey('profile-change-avatar'),
                    customBorder: const CircleBorder(),
                    onTap: isBusy ? null : onChangeAvatar,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 20,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.fullName.isEmpty ? email : profile.fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (profile.university != null || academicParts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            [
              if (profile.university != null) profile.university!,
              if (academicParts.isNotEmpty) academicParts.join(' • '),
            ].join('\n'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('profile-menu-courses'),
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Kelola Mata Kuliah'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.courses),
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('profile-menu-edit'),
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Profil'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.editProfile),
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('profile-menu-password'),
                leading: const Icon(Icons.lock_outline),
                title: const Text('Ubah Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.changePassword),
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const ValueKey('profile-theme-toggle'),
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Mode Gelap'),
                value: ref.watch(themeModeProvider) == ThemeMode.dark,
                onChanged: (enabled) => ref
                    .read(themeModeProvider.notifier)
                    .setDarkEnabled(enabled),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          key: const ValueKey('profile-logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
          ),
          onPressed: isBusy ? null : onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }

  static String _initials(String source) {
    final parts = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    final first = parts.first.characters.first;
    if (parts.length == 1) {
      return first.toUpperCase();
    }
    return (first + parts[1].characters.first).toUpperCase();
  }
}
