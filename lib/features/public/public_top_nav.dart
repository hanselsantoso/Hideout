import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

class PublicTopNav extends ConsumerWidget {
  const PublicTopNav({super.key, required this.activeRoute});

  final String activeRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 820;
    final profile = ref.watch(currentUserProfileProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HDTSpace.lg),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (_) => false,
            ),
            borderRadius: HDTR.md,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: HDTColors.accent,
                    borderRadius: HDTR.md,
                  ),
                  child: const Icon(
                    Icons.sports_martial_arts,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: HDTSpace.sm),
                Text('HIDEOUT', style: HDTText.display(size: 22)),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: HDTSpace.xxxl),
            _NavLink('TOURNAMENTS', '/public/tournaments',
                active: activeRoute == '/public/tournaments'),
            _NavLink('LEADERBOARD', '/public/leaderboard',
                active: activeRoute == '/public/leaderboard'),
            _NavLink('COMMUNITIES', '/communities',
                active: activeRoute == '/communities'),
            _NavLink('COMPONENTS', '/components',
                active: activeRoute == '/components'),
          ],
          const Spacer(),
          if (compact)
            PopupMenuButton<String>(
              tooltip: 'Navigation',
              onSelected: (route) => Navigator.pushNamed(context, route),
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: '/public/tournaments', child: Text('Tournaments')),
                PopupMenuItem(
                    value: '/public/leaderboard', child: Text('Leaderboard')),
                PopupMenuItem(
                    value: '/communities', child: Text('Communities')),
                PopupMenuItem(value: '/components', child: Text('Components')),
              ],
              icon: const Icon(Icons.menu),
            ),
          profile.when(
            data: (user) => user == null
                ? const _PublicAuthButtons()
                : _PublicProfileButtons(user: user),
            loading: () => const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const _PublicAuthButtons(),
          ),
        ],
      ),
    );
  }
}

class _PublicAuthButtons extends StatelessWidget {
  const _PublicAuthButtons();

  @override
  Widget build(BuildContext context) {
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

class _PublicProfileButtons extends ConsumerWidget {
  const _PublicProfileButtons({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: HDTSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, _dashboardRoute(user)),
          icon: const Icon(Icons.account_circle_outlined, size: 16),
          label: Text(_profileLabel(user)),
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: () async {
            await ref.read(authRepositoryProvider).signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            }
          },
          icon: const Icon(Icons.logout, size: 18),
        ),
      ],
    );
  }
}

String _profileLabel(AppUser user) {
  final name = user.displayName.trim().isNotEmpty
      ? user.displayName.trim()
      : user.email.split('@').first;
  return name.toUpperCase();
}

String _dashboardRoute(AppUser user) {
  if (user.capabilities.contains('super_admin')) return '/super-admin/reports';
  return '/dashboard';
}

class _NavLink extends StatelessWidget {
  const _NavLink(this.label, this.route, {required this.active});

  final String label;
  final String route;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (activeRouteOf(context) == route) return;
        Navigator.pushNamed(context, route);
      },
      child: Text(
        label,
        style: HDTText.overline(
          size: 10,
          color: active ? HDTColors.accentHover : HDTColors.text2,
        ),
      ),
    );
  }

  String? activeRouteOf(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }
}
