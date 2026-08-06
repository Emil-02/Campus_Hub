import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
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

    final displayName = user.fullName == null || user.fullName!.trim().isEmpty
        ? user.email
        : user.fullName!;
    final isVerified = user.emailVerified;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
          children: [
            _GreetingHeader(
              displayName: displayName,
              email: user.email,
              isVerified: isVerified,
            ),
            if (authState.status == AuthStatus.failure &&
                authState.errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: authState.errorMessage!),
            ],
            const SizedBox(height: 24),
            Text(
              'Menu',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _MenuCard(
              key: const ValueKey('home-menu-courses'),
              icon: Icons.menu_book_outlined,
              iconBackground: colorScheme.primaryContainer,
              iconColor: colorScheme.onPrimaryContainer,
              title: 'Mata Kuliah',
              subtitle: 'Kelola daftar mata kuliah',
              onTap: () => context.push(RoutePaths.courses),
            ),
            const SizedBox(height: 8),
            _MenuCard(
              key: const ValueKey('home-menu-schedules'),
              icon: Icons.calendar_month_outlined,
              title: 'Jadwal Kuliah',
              subtitle: 'Timetable mingguan & deteksi bentrok',
              onTap: () => context.push(RoutePaths.schedules),
            ),
            const SizedBox(height: 8),
            const _MenuCard(
              icon: Icons.task_alt_outlined,
              title: 'Tugas',
              subtitle: 'Segera hadir',
            ),
            const SizedBox(height: 8),
            const _MenuCard(
              icon: Icons.sticky_note_2_outlined,
              title: 'Catatan',
              subtitle: 'Segera hadir',
            ),
            const SizedBox(height: 8),
            _MenuCard(
              key: const ValueKey('home-menu-profile'),
              icon: Icons.person_outline,
              title: 'Profil',
              subtitle: 'Data diri, foto, dan password',
              onTap: () => context.push(RoutePaths.profile),
            ),
            const SizedBox(height: 32),
            if (!isVerified) ...[
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .resendVerificationEmail(),
                icon: const Icon(Icons.mark_email_unread_outlined),
                label: const Text('Kirim Ulang Verifikasi'),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
              ),
              onPressed: isLoading
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.displayName,
    required this.email,
    required this.isVerified,
  });

  final String displayName;
  final String email;
  final bool isVerified;

  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String get _todayLabel {
    final now = DateTime.now();
    final day = _days[now.weekday - 1];
    final month = _months[now.month - 1];
    return '$day, ${now.day} $month ${now.year}';
  }

  String get _initials {
    final parts = displayName
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: colorScheme.primary,
          child: Text(
            _initials,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $displayName',
                style: theme.textTheme.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _todayLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _VerificationChip(isVerified: isVerified),
            ],
          ),
        ),
      ],
    );
  }
}

final class _VerificationChip extends StatelessWidget {
  const _VerificationChip({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = isVerified
        ? colorScheme.secondaryContainer
        : colorScheme.errorContainer;
    final foreground = isVerified
        ? colorScheme.onSecondaryContainer
        : colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_outlined : Icons.error_outline,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Terverifikasi' : 'Belum terverifikasi',
            style: theme.textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

final class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
      ),
    );
  }
}

final class _MenuCard extends StatelessWidget {
  const _MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconBackground,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconBackground;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = onTap != null;
    final effectiveIconBackground = enabled
        ? (iconBackground ?? colorScheme.secondaryContainer)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final effectiveIconColor = enabled
        ? (iconColor ?? colorScheme.onSecondaryContainer)
        : colorScheme.outline;

    return Card(
      child: ListTile(
        onTap: onTap,
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: effectiveIconBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: effectiveIconColor),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: enabled
            ? const Icon(Icons.chevron_right)
            : Icon(Icons.lock_outline, size: 20, color: colorScheme.outline),
      ),
    );
  }
}
