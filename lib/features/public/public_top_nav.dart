import 'package:flutter/material.dart';

import '../../core/theme/hideout_tokens.dart';

class PublicTopNav extends StatelessWidget {
  const PublicTopNav({super.key, required this.activeRoute});

  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 820;
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
                PopupMenuItem(value: '/communities', child: Text('Communities')),
                PopupMenuItem(value: '/components', child: Text('Components')),
              ],
              icon: const Icon(Icons.menu),
            ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signin'),
            child: const Text('SIGN IN'),
          ),
          const SizedBox(width: HDTSpace.sm),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            child: const Text('REGISTER'),
          ),
        ],
      ),
    );
  }
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
