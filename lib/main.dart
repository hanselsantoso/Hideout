import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/hideout_theme.dart';
import 'core/theme/hideout_tokens.dart';
import 'data/models/app_user.dart';
import 'data/repositories/auth_repository.dart';
import 'features/components/components_screen.dart';
import 'features/community/community_admin_screen.dart';
import 'features/auth/signin_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/community/community_apply_screen.dart';
import 'features/community/community_judges_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/decks/deck_builder_screen.dart';
import 'features/decks/my_decks_screen.dart';
import 'features/judge/judge_matches_screen.dart';
import 'features/judge/judge_scanner_screen.dart';
import 'features/judge/judge_score_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/matches/match_history_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/player/check_in_pass_screen.dart';
import 'features/public/public_communities_screen.dart';
import 'features/public/public_leaderboard_screen.dart';
import 'features/public/public_tournaments_screen.dart';
import 'features/player/my_tournaments_screen.dart';
import 'features/registration/tournament_registration_screen.dart';
import 'features/super_admin/community_approvals_screen.dart';
import 'features/super_admin/super_admin_console_screen.dart';
import 'features/tournament_admin/tournament_ops_screen.dart';
import 'features/tournament_admin/tournament_wizard_screen.dart';
import 'features/tournaments/tournament_detail_screen.dart';
import 'features/tournaments/tournaments_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 8));
  } catch (error) {
    debugPrint('Firebase bootstrap skipped: $error');
  }
  runApp(const ProviderScope(child: BeyTourneyApp()));
}

class BeyTourneyApp extends StatelessWidget {
  const BeyTourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BeyTourney HIDEOUT',
      theme: HDTTheme.dark,
      darkTheme: HDTTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (_) => const LandingScreen(),
        '/dashboard': (_) => const AppShell(),
        '/signin': (_) => const SignInScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/onboarding': (_) => _authRoute(const OnboardingScreen()),
        '/components': (_) => const ComponentsScreen(),
        '/public/tournaments': (_) => const PublicTournamentsScreen(),
        '/public/leaderboard': (_) => const PublicLeaderboardScreen(),
        '/communities': (_) => const PublicCommunitiesScreen(),
        '/me/decks': (_) => _roleRoute('/me/decks', const MyDecksScreen()),
        '/me/decks/new': (_) =>
            _roleRoute('/me/decks/new', const DeckBuilderScreen()),
        '/me/tournaments': (_) =>
            _roleRoute('/me/tournaments', const MyTournamentsScreen()),
        '/me/qr': (_) => _roleRoute('/me/qr', const CheckInPassScreen()),
        '/communities/new': (_) =>
            _roleRoute('/communities/new', const CommunityApplyScreen()),
        '/community/admin': (_) => _roleRoute(
              '/community/admin',
              const CommunityAdminScreen(),
              allowedRoles: _communityManagerAccess,
            ),
        '/community/judges': (_) => _roleRoute(
              '/community/judges',
              const CommunityJudgesScreen(),
              allowedRoles: _communityManagerAccess,
            ),
        '/super-admin/community-approvals': (_) => _roleRoute(
            '/super-admin/community-approvals',
            const CommunityApprovalsScreen(),
            allowedRoles: _superAdminAccess),
        '/super-admin/reports': (_) => _roleRoute('/super-admin/reports',
            const SuperAdminConsoleScreen(section: SuperAdminSection.reports),
            allowedRoles: _superAdminAccess),
        '/super-admin/components': (_) => _roleRoute(
            '/super-admin/components',
            const SuperAdminConsoleScreen(
                section: SuperAdminSection.components),
            allowedRoles: _superAdminAccess),
        '/super-admin/component-stats': (_) => _roleRoute(
            '/super-admin/component-stats',
            const SuperAdminConsoleScreen(
                section: SuperAdminSection.componentStats),
            allowedRoles: _superAdminAccess),
        '/super-admin/parts/new': (_) => _roleRoute('/super-admin/parts/new',
            const SuperAdminConsoleScreen(section: SuperAdminSection.newParts),
            allowedRoles: _superAdminAccess),
        '/admin/tournaments/new': (_) => _roleRoute(
              '/admin/tournaments/new',
              const TournamentWizardScreen(),
              allowedRoles: _communityManagerAccess,
            ),
        '/admin/tournaments/ops': (_) => _roleRoute(
              '/admin/tournaments/ops',
              const TournamentOpsScreen(),
              allowedRoles: _communityManagerAccess,
            ),
        '/tournaments': (_) =>
            _roleRoute('/tournaments', const TournamentsScreen()),
        '/tournaments/detail': (_) =>
            _roleRoute('/tournaments/detail', const TournamentDetailScreen()),
        '/tournaments/register': (_) => _roleRoute(
            '/tournaments/register', const TournamentRegistrationScreen()),
        '/leaderboard': (_) =>
            _roleRoute('/leaderboard', const LeaderboardScreen()),
        '/matches': (_) => _roleRoute('/matches', const MatchHistoryScreen()),
        '/notifications': (_) =>
            _roleRoute('/notifications', const NotificationsScreen()),
        '/juri/matches': (_) => _roleRoute(
              '/juri/matches',
              const JudgeMatchesScreen(),
              allowedRoles: _judgeAccess,
            ),
        '/juri/scan': (_) => _roleRoute(
              '/juri/scan',
              const JudgeScannerScreen(),
              allowedRoles: _judgeAccess,
            ),
        '/juri/score': (_) => _roleRoute(
              '/juri/score',
              const JudgeScoreScreen(),
              allowedRoles: _judgeAccess,
            ),
      },
    );
  }
}

const _playerAccess = {'player', 'judge', 'community_admin'};
const _judgeAccess = {'judge'};
const _communityManagerAccess = {'community_admin', 'super_admin'};
const _superAdminAccess = {'super_admin'};
const _anySignedInAccess = {
  'player',
  'judge',
  'community_admin',
  'super_admin',
};

Widget _authRoute(Widget child) {
  return _AuthzRoute(
    selectedRoute: null,
    allowedRoles: _anySignedInAccess,
    requireProfile: false,
    useRoleShell: false,
    child: child,
  );
}

Widget _roleRoute(
  String route,
  Widget child, {
  Set<String> allowedRoles = _playerAccess,
}) {
  return _AuthzRoute(
    selectedRoute: route,
    allowedRoles: allowedRoles,
    child: child,
  );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return _roleRoute(
      '/dashboard',
      const DashboardScreen(),
      allowedRoles: _playerAccess,
    );
  }
}

class _AuthzRoute extends ConsumerWidget {
  const _AuthzRoute({
    required this.selectedRoute,
    required this.allowedRoles,
    required this.child,
    this.requireProfile = true,
    this.useRoleShell = true,
  });

  final String? selectedRoute;
  final Set<String> allowedRoles;
  final Widget child;
  final bool requireProfile;
  final bool useRoleShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const _RouteStateScreen.loading(),
      error: (_, __) => const _RouteStateScreen(
        title: 'SESSION ERROR',
        message:
            'Sesi login belum bisa dibaca. Muat ulang halaman atau masuk ulang.',
        actionLabel: 'SIGN IN',
        actionRoute: '/signin',
      ),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const _RouteStateScreen(
            title: 'LOGIN REQUIRED',
            message: 'Halaman ini hanya untuk akun terdaftar.',
            actionLabel: 'SIGN IN',
            actionRoute: '/signin',
          );
        }
        if (!requireProfile) return child;
        final profile = ref.watch(currentUserProfileProvider);
        return profile.when(
          loading: () => const _RouteStateScreen.loading(),
          error: (_, __) => const _RouteStateScreen(
            title: 'PROFILE ERROR',
            message: 'Profil akun belum bisa dimuat. Coba masuk ulang.',
            actionLabel: 'SIGN IN',
            actionRoute: '/signin',
          ),
          data: (user) {
            if (user == null) {
              return const _RouteStateScreen(
                title: 'PROFILE MISSING',
                message:
                    'Akun sudah login, tetapi dokumen profil belum tersedia.',
                actionLabel: 'ONBOARDING',
                actionRoute: '/onboarding',
              );
            }
            if (!_hasRouteAccess(user, allowedRoles)) {
              final home = _defaultRouteFor(user);
              final expected = allowedRoles.map(_roleLabel).join(', ');
              return RoleShell(
                selectedRoute: home,
                child: _RouteStateScreen(
                  title: 'ACCESS DENIED',
                  message:
                      'Role akun ini tidak punya akses ke halaman tersebut. Akses diperlukan: $expected.',
                  actionLabel: 'GO TO MY MENU',
                  actionRoute: home,
                  embedded: true,
                ),
              );
            }
            if (!useRoleShell) return child;
            return RoleShell(
              selectedRoute: selectedRoute ?? _defaultRouteFor(user),
              child: child,
            );
          },
        );
      },
    );
  }
}

class _RouteStateScreen extends StatelessWidget {
  const _RouteStateScreen({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionRoute,
    this.embedded = false,
  });

  const _RouteStateScreen.loading()
      : title = 'LOADING',
        message = 'Mengecek sesi dan role akun...',
        actionLabel = null,
        actionRoute = null,
        embedded = false;

  final String title;
  final String message;
  final String? actionLabel;
  final String? actionRoute;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(HDTSpace.xl),
          decoration: hdtCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HDTText.display(size: 28)),
              const SizedBox(height: HDTSpace.sm),
              Text(message,
                  style: HDTText.body(color: HDTColors.text2, height: 1.5)),
              if (title == 'LOADING') ...[
                const SizedBox(height: HDTSpace.lg),
                const LinearProgressIndicator(),
              ],
              if (actionLabel != null && actionRoute != null) ...[
                const SizedBox(height: HDTSpace.lg),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, actionRoute!),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (embedded) return content;
    return Scaffold(backgroundColor: HDTColors.bg, body: content);
  }
}

bool _hasRouteAccess(AppUser user, Set<String> allowedRoles) {
  final capabilities = _capabilitiesFor(user);
  return allowedRoles.any(capabilities.contains);
}

String _defaultRouteFor(AppUser user) {
  final capabilities = _capabilitiesFor(user);
  if (capabilities.contains('super_admin')) return '/super-admin/reports';
  return '/dashboard';
}

String _roleLabel(String role) {
  return switch (role) {
    'super_admin' => 'super admin',
    'community_admin' => 'admin komunitas',
    'judge' => 'juri',
    _ => 'player',
  };
}

class RoleShell extends ConsumerWidget {
  const RoleShell({
    super.key,
    required this.selectedRoute,
    required this.child,
  });

  final String selectedRoute;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final user = profile.valueOrNull;
    final wide = MediaQuery.sizeOf(context).width >= 860;
    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: wide
          ? Row(
              children: [
                _RoleSidebar(
                  selectedRoute: selectedRoute,
                  user: user,
                  loadingProfile: profile.isLoading,
                ),
                Expanded(child: child),
              ],
            )
          : Column(
              children: [
                _MobileRoleNav(
                  selectedRoute: selectedRoute,
                  user: user,
                  loadingProfile: profile.isLoading,
                ),
                Expanded(child: child),
              ],
            ),
    );
  }
}

const _roleNavItems = [
  _RoleNavItem(
    label: 'Dashboard',
    route: '/dashboard',
    icon: Icons.dashboard_outlined,
    section: 'overview',
    roles: {'player', 'judge', 'community_admin'},
  ),
  _RoleNavItem(
    label: 'Jelajah Turnamen',
    route: '/tournaments',
    icon: Icons.emoji_events_outlined,
    section: 'turnamen',
    roles: {'player', 'judge', 'community_admin'},
  ),
  _RoleNavItem(
    label: 'My Tournaments',
    route: '/me/tournaments',
    icon: Icons.confirmation_number_outlined,
    section: 'turnamen',
    roles: {'player', 'judge', 'community_admin'},
  ),
  _RoleNavItem(
    label: 'My Decks',
    route: '/me/decks',
    icon: Icons.view_in_ar_outlined,
    section: 'koleksi',
    roles: {'player', 'judge', 'community_admin'},
  ),
  _RoleNavItem(
    label: 'QR Check-In',
    route: '/me/qr',
    icon: Icons.qr_code_2_outlined,
    section: 'turnamen',
    roles: {'player', 'judge', 'community_admin'},
  ),
  _RoleNavItem(
    label: 'Leaderboard',
    route: '/leaderboard',
    icon: Icons.bar_chart_outlined,
    section: 'komunitas',
    roles: {'player', 'judge', 'community_admin'},
  ),
  _RoleNavItem(
    label: 'My Matches',
    route: '/matches',
    icon: Icons.sports_martial_arts_outlined,
    section: 'turnamen',
    roles: {'player', 'judge', 'community_admin'},
  ),
  _RoleNavItem(
    label: 'Notifications',
    route: '/notifications',
    icon: Icons.notifications_outlined,
    section: 'akun',
    roles: {'player', 'judge', 'community_admin'},
  ),
  _RoleNavItem(
    label: 'Buka Komunitas',
    route: '/communities/new',
    icon: Icons.groups_2_outlined,
    section: 'komunitas',
    roles: {'player', 'judge'},
  ),
  _RoleNavItem(
    label: 'Jadwal Juri',
    route: '/juri/matches',
    icon: Icons.assignment_ind_outlined,
    section: 'panel_juri',
    roles: {'judge'},
  ),
  _RoleNavItem(
    label: 'Scan QR Player',
    route: '/juri/scan',
    icon: Icons.qr_code_scanner,
    section: 'panel_juri',
    roles: {'judge'},
  ),
  _RoleNavItem(
    label: 'Input Score',
    route: '/juri/score',
    icon: Icons.shield_outlined,
    section: 'panel_juri',
    roles: {'judge'},
  ),
  _RoleNavItem(
    label: 'Dashboard Komunitas',
    route: '/community/admin',
    icon: Icons.admin_panel_settings_outlined,
    section: 'panel_ketua',
    roles: {'community_admin'},
  ),
  _RoleNavItem(
    label: 'Tournament Ops',
    route: '/admin/tournaments/ops',
    icon: Icons.account_tree_outlined,
    section: 'panel_ketua',
    roles: {'community_admin'},
  ),
  _RoleNavItem(
    label: 'Buat Event Baru',
    route: '/admin/tournaments/new',
    icon: Icons.add_circle_outline,
    section: 'panel_ketua',
    roles: {'community_admin'},
  ),
  _RoleNavItem(
    label: 'Kelola Juri',
    route: '/community/judges',
    icon: Icons.verified_user_outlined,
    section: 'panel_ketua',
    roles: {'community_admin'},
  ),
  _RoleNavItem(
    label: 'Laporan Platform',
    route: '/super-admin/reports',
    icon: Icons.query_stats_outlined,
    section: 'platform',
    roles: {'super_admin'},
  ),
  _RoleNavItem(
    label: 'Pending Approval',
    route: '/super-admin/community-approvals',
    icon: Icons.fact_check_outlined,
    section: 'platform',
    roles: {'super_admin'},
  ),
  _RoleNavItem(
    label: 'Manajemen Komponen',
    route: '/super-admin/components',
    icon: Icons.category_outlined,
    section: 'platform',
    roles: {'super_admin'},
  ),
  _RoleNavItem(
    label: 'Review Statistik',
    route: '/super-admin/component-stats',
    icon: Icons.analytics_outlined,
    section: 'platform',
    roles: {'super_admin'},
  ),
  _RoleNavItem(
    label: 'Part Baru',
    route: '/super-admin/parts/new',
    icon: Icons.new_releases_outlined,
    section: 'platform',
    roles: {'super_admin'},
  ),
];

class _RoleSidebar extends ConsumerWidget {
  const _RoleSidebar({
    required this.selectedRoute,
    required this.user,
    required this.loadingProfile,
  });

  final String selectedRoute;
  final AppUser? user;
  final bool loadingProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _visibleRoleItems(user);
    final grouped = _groupNavItems(items);
    final mode = _modeConfigFor(user);
    return Container(
      width: 228,
      decoration: const BoxDecoration(
        color: HDTColors.s1,
        border: Border(right: BorderSide(color: HDTColors.s2)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarModeHeader(config: mode),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
                children: [
                  for (final entry in grouped.entries) ...[
                    _SidebarSectionHeader(
                      label: _sectionLabel(entry.key),
                      color: _sectionAccent(entry.key),
                      highlighted: _sectionHighlighted(entry.key),
                    ),
                    for (final item in entry.value)
                      _SidebarNavButton(
                        item: item,
                        active: _routeMatches(selectedRoute, item.route),
                        color: _navItemAccent(item, mode.color),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: _SidebarFooter(
                signedIn: user != null,
                onSignOut: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileRoleNav extends StatelessWidget {
  const _MobileRoleNav({
    required this.selectedRoute,
    required this.user,
    required this.loadingProfile,
  });

  final String selectedRoute;
  final AppUser? user;
  final bool loadingProfile;

  @override
  Widget build(BuildContext context) {
    final items = _visibleRoleItems(user);
    final mode = _modeConfigFor(user);
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: HDTColors.s1,
          border: Border(bottom: BorderSide(color: HDTColors.s2)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _MobileModeHeader(config: mode)),
                if (loadingProfile)
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: HDTSpace.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _MobileNavChip(
                        item: item,
                        active: _routeMatches(selectedRoute, item.route),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarModeHeader extends StatelessWidget {
  const _SidebarModeHeader({required this.config});

  final _SidebarModeConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: HDTSpace.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: config.color,
              borderRadius: HDTR.md,
            ),
            child: Text(
              config.badge,
              style: HDTText.display(size: 11, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MODE AKTIF',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.overline(size: 8, color: HDTColors.text3),
                ),
                Text(
                  config.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.display(size: 13, color: config.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileModeHeader extends StatelessWidget {
  const _MobileModeHeader({required this.config});

  final _SidebarModeConfig config;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: config.color, borderRadius: HDTR.md),
          child: Text(
            config.badge,
            style: HDTText.display(size: 11, color: Colors.white),
          ),
        ),
        const SizedBox(width: HDTSpace.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MODE AKTIF',
                style: HDTText.overline(size: 8, color: HDTColors.text3)),
            Text(config.label, style: HDTText.display(size: 14)),
          ],
        ),
      ],
    );
  }
}

class _SidebarSectionHeader extends StatelessWidget {
  const _SidebarSectionHeader({
    required this.label,
    required this.color,
    required this.highlighted,
  });

  final String label;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    if (highlighted) {
      return Container(
        margin: const EdgeInsets.fromLTRB(4, 18, 4, 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: HDTR.sm,
          border: Border(left: BorderSide(color: color, width: 2)),
        ),
        child: Row(
          children: [
            Icon(_sectionIcon(label), size: 10, color: color),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HDTText.overline(size: 8, color: color),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 7),
      child: Text(
        label.toUpperCase(),
        style: HDTText.overline(size: 8, color: HDTColors.text3),
      ),
    );
  }
}

class _SidebarNavButton extends StatelessWidget {
  const _SidebarNavButton({
    required this.item,
    required this.active,
    required this.color,
  });

  final _RoleNavItem item;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        borderRadius: HDTR.md,
        onTap: () => _goToRoleItem(context, item),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: .10) : Colors.transparent,
            borderRadius: HDTR.md,
          ),
          child: Row(
            children: [
              Container(
                width: 2,
                height: 14,
                decoration: BoxDecoration(
                  color: active ? color : Colors.transparent,
                  borderRadius: HDTR.full,
                ),
              ),
              const SizedBox(width: HDTSpace.sm),
              Icon(
                item.icon,
                size: 15,
                color: active ? color : HDTColors.text3,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.display(
                    size: 13,
                    color: active ? HDTColors.text : HDTColors.text2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNavChip extends StatelessWidget {
  const _MobileNavChip({
    required this.item,
    required this.active,
  });

  final _RoleNavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () => _goToRoleItem(context, item),
      avatar: Icon(
        item.icon,
        size: 16,
        color: active ? HDTColors.accentHover : HDTColors.text3,
      ),
      label: Text(item.label.toUpperCase()),
      labelStyle: HDTText.overline(
        size: 8,
        color: active ? HDTColors.text : HDTColors.text2,
      ),
      backgroundColor:
          active ? HDTColors.accent.withValues(alpha: .18) : HDTColors.s1,
      side: BorderSide(color: active ? HDTColors.accent : HDTColors.s2),
      shape: const RoundedRectangleBorder(borderRadius: HDTR.lg),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.signedIn,
    required this.onSignOut,
  });

  final bool signedIn;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: signedIn
            ? onSignOut
            : () => Navigator.pushNamed(context, '/signin'),
        icon: Icon(signedIn ? Icons.logout : Icons.login, size: 14),
        label: Text(signedIn ? 'SIGN OUT' : 'SIGN IN'),
        style: OutlinedButton.styleFrom(
          textStyle: HDTText.overline(size: 8),
          foregroundColor: HDTColors.text2,
          side: const BorderSide(color: HDTColors.s2),
          shape: const RoundedRectangleBorder(borderRadius: HDTR.md),
        ),
      ),
    );
  }
}

class _SidebarModeConfig {
  const _SidebarModeConfig({
    required this.label,
    required this.badge,
    required this.color,
  });

  final String label;
  final String badge;
  final Color color;
}

List<_RoleNavItem> _visibleRoleItems(AppUser? user) {
  final capabilities = _capabilitiesFor(user);
  return [
    for (final item in _roleNavItems)
      if (item.roles.any(capabilities.contains)) item,
  ];
}

Set<String> _capabilitiesFor(AppUser? user) {
  if (user == null) return {'player'};
  final capabilities = user.capabilities;
  if (capabilities.contains('super_admin')) {
    return {'super_admin'};
  }
  return {'player', ...capabilities};
}

_SidebarModeConfig _modeConfigFor(AppUser? user) {
  final capabilities = _capabilitiesFor(user);
  if (capabilities.contains('super_admin')) {
    return const _SidebarModeConfig(
      label: 'Super Admin',
      badge: 'SYS',
      color: HDTColors.warning,
    );
  }
  final hasCommunityAdmin = capabilities.contains('community_admin');
  final hasJudge = capabilities.contains('judge');
  if (hasCommunityAdmin && hasJudge) {
    return const _SidebarModeConfig(
      label: 'Player / Ketua / Juri',
      badge: 'MIX',
      color: HDTColors.info,
    );
  }
  if (hasCommunityAdmin) {
    return const _SidebarModeConfig(
      label: 'Player / Ketua',
      badge: 'KOM',
      color: HDTColors.accentHover,
    );
  }
  if (hasJudge) {
    return const _SidebarModeConfig(
      label: 'Player / Juri',
      badge: 'JUR',
      color: HDTColors.info,
    );
  }
  return const _SidebarModeConfig(
    label: 'Player',
    badge: 'PLY',
    color: HDTColors.accent,
  );
}

String _sectionLabel(String section) {
  switch (section) {
    case 'overview':
      return 'Overview';
    case 'turnamen':
      return 'Turnamen';
    case 'koleksi':
      return 'Koleksi';
    case 'komunitas':
      return 'Komunitas';
    case 'akun':
      return 'Akun';
    case 'panel_juri':
      return 'Panel Juri';
    case 'panel_ketua':
      return 'Panel Ketua';
    case 'platform':
      return 'Platform';
    default:
      return section;
  }
}

Color _sectionAccent(String section) {
  switch (section) {
    case 'panel_juri':
      return HDTColors.info;
    case 'panel_ketua':
      return HDTColors.accentHover;
    case 'platform':
      return HDTColors.warning;
    default:
      return HDTColors.text3;
  }
}

bool _sectionHighlighted(String section) {
  return section == 'panel_juri' ||
      section == 'panel_ketua' ||
      section == 'platform';
}

IconData _sectionIcon(String label) {
  switch (label.toLowerCase()) {
    case 'panel juri':
      return Icons.shield_outlined;
    case 'panel ketua':
      return Icons.admin_panel_settings_outlined;
    case 'platform':
      return Icons.fact_check_outlined;
    default:
      return Icons.circle;
  }
}

Color _navItemAccent(_RoleNavItem item, Color fallback) {
  switch (item.section) {
    case 'panel_juri':
      return HDTColors.info;
    case 'panel_ketua':
      return HDTColors.accentHover;
    case 'platform':
      return HDTColors.warning;
    default:
      return fallback;
  }
}

Map<String, List<_RoleNavItem>> _groupNavItems(List<_RoleNavItem> items) {
  final grouped = <String, List<_RoleNavItem>>{};
  for (final item in items) {
    grouped.putIfAbsent(item.section, () => []).add(item);
  }
  return grouped;
}

void _goToRoleItem(BuildContext context, _RoleNavItem item) {
  final current = ModalRoute.of(context)?.settings.name;
  if (_routeMatches(current, item.route)) return;
  Navigator.pushReplacementNamed(context, item.route);
}

bool _routeMatches(String? selected, String route) {
  if (selected == null) return false;
  if (selected == route) return true;
  if (route == '/tournaments') return selected.startsWith('/tournaments');
  return false;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const actions = [
      _QuickAction('Daftar Akun', '/signup', Icons.person_add_alt_1),
      _QuickAction('Onboarding', '/onboarding', Icons.route_outlined),
      _QuickAction('Buka Komunitas', '/communities/new', Icons.groups_outlined),
      _QuickAction(
          'Kelola Juri', '/community/judges', Icons.verified_user_outlined),
      _QuickAction('Approval Komunitas', '/super-admin/community-approvals',
          Icons.admin_panel_settings_outlined),
      _QuickAction(
          'Buat Turnamen', '/admin/tournaments/new', Icons.add_circle_outline),
      _QuickAction('Tournament Ops', '/admin/tournaments/ops',
          Icons.account_tree_outlined),
      _QuickAction('Registrasi Event', '/tournaments/register',
          Icons.confirmation_number_outlined),
      _QuickAction('QR Scanner', '/juri/scan', Icons.qr_code_scanner),
      _QuickAction('Input Skor', '/juri/score', Icons.shield_outlined),
    ];

    return Consumer(builder: (context, ref, _) {
      final profile = ref.watch(currentUserProfileProvider);
      return Scaffold(
        appBar: AppBar(
          title: const Text('HIDEOUT'),
          actions: [
            profile.when(
              data: (user) => user == null
                  ? TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text('LOGIN'),
                    )
                  : TextButton.icon(
                      onPressed: () =>
                          ref.read(authRepositoryProvider).signOut(),
                      icon: const Icon(Icons.logout),
                      label: Text(user.role.toUpperCase()),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                    child: SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )),
              ),
              error: (_, __) => TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text('LOGIN'),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/admin/tournaments/new'),
              child: const Text('BUAT EVENT'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(HDTSpace.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(HDTSpace.xl),
              decoration: hdtAccentCard(
                  accentColor: HDTColors.accent, highlighted: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BEYTOURNEY MVP',
                      style: HDTText.overline(color: HDTColors.accentHover)),
                  const SizedBox(height: HDTSpace.sm),
                  Text(
                      'Komunitas, bracket, deck, QR, dan scoring dalam satu app.',
                      style: HDTText.display(size: 28)),
                  const SizedBox(height: HDTSpace.md),
                  Text(
                    'Versi Flutter ini sekarang memakai Firebase project lama untuk auth, tournament, payment simulasi, QR, dan callable functions yang sudah tersedia.',
                    style: HDTText.body(
                        size: 13, color: HDTColors.text2, height: 1.5),
                  ),
                  const SizedBox(height: HDTSpace.md),
                  profile.when(
                    data: (user) => Text(
                      user == null
                          ? 'Belum login. Buat akun atau masuk untuk mengakses data Firebase.'
                          : 'Login sebagai ${user.displayName.isEmpty ? user.email : user.displayName} (${user.role})',
                      style: HDTText.mono(size: 11, color: HDTColors.text3),
                    ),
                    loading: () => Text('Mengecek sesi Firebase...',
                        style: HDTText.mono(size: 11, color: HDTColors.text3)),
                    error: (_, __) => Text(
                        'Sesi akun belum siap. Coba muat ulang halaman.',
                        style: HDTText.mono(size: 11, color: HDTColors.danger)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HDTSpace.lg),
            Wrap(
              spacing: HDTSpace.md,
              runSpacing: HDTSpace.md,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: 220,
                    child: _ActionCard(action: action),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ActionCard extends StatelessWidget {
  final _QuickAction action;
  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: HDTR.lg,
      onTap: () => Navigator.pushNamed(context, action.route),
      child: Container(
        padding: const EdgeInsets.all(HDTSpace.lg),
        decoration: hdtCard(),
        child: Row(
          children: [
            Icon(action.icon, color: HDTColors.accentHover),
            const SizedBox(width: HDTSpace.md),
            Expanded(
                child: Text(action.label.toUpperCase(),
                    style: HDTText.overline(color: HDTColors.text))),
            const Icon(Icons.chevron_right, color: HDTColors.text3),
          ],
        ),
      ),
    );
  }
}

class _RoleNavItem {
  final String label;
  final String route;
  final IconData icon;
  final String section;
  final Set<String> roles;

  const _RoleNavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.section,
    required this.roles,
  });
}

class _QuickAction {
  final String label;
  final String route;
  final IconData icon;
  const _QuickAction(this.label, this.route, this.icon);
}
