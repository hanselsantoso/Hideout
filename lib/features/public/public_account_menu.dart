import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/route_access.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

class PublicSessionActions extends ConsumerWidget {
  const PublicSessionActions({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final profile = ref.watch(currentUserProfileProvider);
    final firebaseUser = auth.valueOrNull;
    final appUser = profile.valueOrNull;

    if (auth.isLoading && firebaseUser == null) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (firebaseUser == null) {
      return PublicAuthButtons(compact: compact);
    }

    return _PublicAccountMenu(
      user: appUser,
      fallbackName: firebaseUser.displayName,
      fallbackEmail: firebaseUser.email,
      compact: compact,
    );
  }
}

class PublicAuthButtons extends StatelessWidget {
  const PublicAuthButtons({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Sign in',
        onPressed: () => Navigator.pushNamed(context, '/signin'),
        icon: const Icon(Icons.login, size: 18),
      );
    }
    return Wrap(
      spacing: HDTSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/signin'),
          child: const Text('SIGN IN'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/signup'),
          child: const Text('REGISTER'),
        ),
      ],
    );
  }
}

class _PublicAccountMenu extends ConsumerWidget {
  const _PublicAccountMenu({
    required this.user,
    required this.fallbackName,
    required this.fallbackEmail,
    required this.compact,
  });

  final AppUser? user;
  final String? fallbackName;
  final String? fallbackEmail;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardRoute = user == null ? null : defaultRouteFor(user!);
    return PopupMenuButton<String>(
      tooltip: 'Account',
      color: HDTColors.s1,
      onSelected: (value) async {
        if (value == 'dashboard') {
          final route = dashboardRoute;
          if (route != null && context.mounted) {
            Navigator.pushNamed(context, route);
          }
          return;
        }
        if (value == 'logout') {
          await ref.read(authRepositoryProvider).signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'dashboard',
          enabled: dashboardRoute != null,
          child: Row(
            children: [
              const Icon(Icons.dashboard_outlined, size: 18),
              const SizedBox(width: HDTSpace.sm),
              Text(dashboardRoute == null ? 'Loading profile...' : 'Dashboard'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18),
              SizedBox(width: HDTSpace.sm),
              Text('Logout'),
            ],
          ),
        ),
      ],
      child: Container(
        height: compact ? 38 : 40,
        constraints: BoxConstraints(maxWidth: compact ? 150 : 220),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? HDTSpace.sm : HDTSpace.md,
        ),
        decoration: BoxDecoration(
          color: HDTColors.s1,
          borderRadius: HDTR.md,
          border: Border.all(color: HDTColors.s2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle_outlined, size: 18),
            if (!compact) ...[
              const SizedBox(width: HDTSpace.sm),
              Flexible(
                child: Text(
                  _accountLabel(user, fallbackName, fallbackEmail),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.overline(size: 9),
                ),
              ),
            ],
            const SizedBox(width: HDTSpace.xs),
            const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }
}

String _accountLabel(
    AppUser? user, String? fallbackName, String? fallbackEmail) {
  final displayName = user?.displayName.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName.toUpperCase();
  }
  final authName = fallbackName?.trim();
  if (authName != null && authName.isNotEmpty) {
    return authName.toUpperCase();
  }
  final email = (user?.email ?? fallbackEmail ?? '').trim();
  if (email.isNotEmpty) return email.split('@').first.toUpperCase();
  return 'ACCOUNT';
}
