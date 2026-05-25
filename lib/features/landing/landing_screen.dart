import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/auth/route_access.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../data/models/app_user.dart';
import '../../data/models/bey_part.dart';
import '../../data/models/tournament_summary.dart';
import '../../data/repositories/auth_repository.dart';
import '../public/public_account_menu.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: HDTColors.bg.withValues(alpha: 0.92),
            elevation: 0,
            toolbarHeight: 68,
            titleSpacing: 0,
            title: const _TopNav(),
          ),
          SliverToBoxAdapter(child: _HeroSection()),
          const SliverToBoxAdapter(child: _LiveTicker()),
          const SliverToBoxAdapter(
            child: _SectionShell(
              overline: 'SCHEDULE',
              title: 'UPCOMING TOURNAMENTS',
              actionLabel: 'BROWSE TOURNAMENTS',
              actionRoute: '/public/tournaments',
              child: _TournamentPreview(),
            ),
          ),
          const SliverToBoxAdapter(
            child: _SectionShell(
              overline: 'RANKED',
              title: 'HIDEOUT LEADERBOARD',
              actionLabel: 'VIEW FULL LEADERBOARD',
              actionRoute: '/public/leaderboard',
              child: _LeaderboardPreview(),
            ),
          ),
          const SliverToBoxAdapter(
            child: _SectionShell(
              overline: 'FEATURED',
              title: 'COMMUNITIES',
              actionLabel: 'OPEN NEW COMMUNITY',
              actionRoute: '/communities',
              child: _CommunityGrid(),
            ),
          ),
          const SliverToBoxAdapter(child: _PillarsBand()),
          const SliverToBoxAdapter(
            child: _SectionShell(
              overline: 'META',
              title: 'COMPONENT - WEEKLY RELEASE',
              subtitle: 'CURATED BY SUPER ADMIN OR AUTO TOP WIN RATE',
              actionLabel: 'BROWSE ALL PARTS',
              actionRoute: '/components',
              child: _ComponentMetaGrid(),
            ),
          ),
          const SliverToBoxAdapter(child: _CtaBand()),
          const SliverToBoxAdapter(child: _Footer()),
        ],
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HDTSpace.lg),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: HDTColors.accent,
              borderRadius: HDTR.md,
            ),
            child: const Icon(Icons.sports_martial_arts,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: HDTSpace.sm),
          Text('HIDEOUT', style: HDTText.display(size: 22)),
          if (compact) ...[
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: HDTColors.text),
              color: HDTColors.s1,
              onSelected: (value) => Navigator.pushNamed(context, value),
              itemBuilder: (context) => const [
                PopupMenuItem(
                    value: '/public/tournaments', child: Text('Tournaments')),
                PopupMenuItem(
                    value: '/public/leaderboard', child: Text('Leaderboard')),
                PopupMenuItem(
                    value: '/communities', child: Text('Communities')),
                PopupMenuItem(value: '/components', child: Text('Components')),
              ],
            ),
            const SizedBox(width: HDTSpace.sm),
            const PublicSessionActions(compact: true),
          ] else ...[
            const SizedBox(width: HDTSpace.xxxl),
            const _NavLink('TOURNAMENTS', '/public/tournaments'),
            const _NavLink('LEADERBOARD', '/public/leaderboard'),
            const _NavLink('COMMUNITIES', '/communities'),
            const _NavLink('COMPONENTS', '/components'),
            const Spacer(),
            const PublicSessionActions(),
          ],
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink(this.label, this.route);
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(label, style: HDTText.overline(size: 10)),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 920;
    return Container(
      constraints: const BoxConstraints(minHeight: 660),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              HDTSpace.xl,
              HDTSpace.xxxl,
              HDTSpace.xl,
              HDTSpace.xxxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: wide
                    ? Row(
                        children: [
                          const Expanded(flex: 7, child: _HeroCopy()),
                          const SizedBox(width: HDTSpace.xxxl),
                          Expanded(flex: 5, child: _ArenaVisual()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HeroCopy(),
                          const SizedBox(height: HDTSpace.xxxl),
                          SizedBox(height: 340, child: _ArenaVisual()),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends ConsumerWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleSize = MediaQuery.sizeOf(context).width < 520 ? 58.0 : 92.0;
    final auth = ref.watch(authStateProvider);
    final signedIn = auth.valueOrNull != null;
    final checkingSession = auth.isLoading && !signedIn;
    final user = ref.watch(currentUserProfileProvider).valueOrNull;
    final dashboardRoute = user == null ? '/dashboard' : defaultRouteFor(user);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LiveDot(),
            const SizedBox(width: HDTSpace.sm),
            Text('SEASON 3 - WEEK 11 / 33',
                style:
                    HDTText.overline(size: 11, color: HDTColors.accentHover)),
          ],
        ),
        const SizedBox(height: HDTSpace.xl),
        Text(
          'WHERE WOLVES\nPLAY.',
          style: HDTText.display(
            size: titleSize,
            color: HDTColors.text,
            letterSpacing: 0,
          ).copyWith(height: 0.92),
        ),
        const SizedBox(height: HDTSpace.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Indonesia Beyblade X community. Ranked ELO. Transparent brackets. Every match counts, every part has a track record.',
            style: HDTText.body(size: 16, color: HDTColors.text2, height: 1.6),
          ),
        ),
        const SizedBox(height: HDTSpace.xxl),
        Wrap(
          spacing: HDTSpace.md,
          runSpacing: HDTSpace.md,
          children: [
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: checkingSession
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          signedIn ? dashboardRoute : '/signup',
                        ),
                icon: Icon(
                    signedIn ? Icons.dashboard_outlined : Icons.arrow_forward),
                label: Text(checkingSession
                    ? 'CHECKING SESSION'
                    : signedIn
                        ? 'OPEN DASHBOARD'
                        : 'REGISTER NOW'),
              ),
            ),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/public/tournaments'),
                child: const Text('BROWSE TOURNAMENTS'),
              ),
            ),
          ],
        ),
        const SizedBox(height: HDTSpace.xxxl),
        const Wrap(
          spacing: 44,
          runSpacing: HDTSpace.lg,
          children: [
            _HeroStat(value: '12,450', label: 'PLAYERS'),
            _HeroStat(value: '47', label: 'COMMUNITIES'),
            _HeroStat(value: '2,847', label: 'MATCHES / WEEK'),
          ],
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: HDTText.display(size: 32)),
        const SizedBox(height: HDTSpace.xs),
        Text(label, style: HDTText.overline(size: 10)),
      ],
    );
  }
}

class _ArenaVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _ArenaPainter(),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(HDTSpace.lg),
            child: Text('ARENA.001 / LIVE',
                style: HDTText.mono(size: 10, color: HDTColors.text3)),
          ),
        ),
      ),
    );
  }
}

class _LiveTicker extends StatelessWidget {
  const _LiveTicker();

  static const fallbackItems = [
    'JKT WOLVES / HIDEOUT CUP #04 - ROUND 4',
    'SBY SPIN / EAST COAST SHOWDOWN - FINAL',
    'BDG GRINDERS / HIGHLAND OPEN - CHECK-IN',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: HDTColors.s1,
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(FirestorePaths.tournaments)
            .orderBy('startDate', descending: true)
            .limit(3)
            .snapshots(),
        builder: (context, snapshot) {
          final items = (snapshot.data?.docs ?? const [])
              .map(TournamentSummary.fromFirestore)
              .map(_tickerLabel)
              .where((item) => item.isNotEmpty)
              .toList();
          final labels = items.isEmpty ? fallbackItems : items;
          return Row(
            children: [
              Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: HDTSpace.lg),
                color: HDTColors.accent,
                child: Row(
                  children: [
                    const _LiveDot(color: Colors.white),
                    const SizedBox(width: HDTSpace.sm),
                    Text('LIVE NOW',
                        style: HDTText.overline(size: 11, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: HDTSpace.xl),
                  itemCount: labels.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: HDTSpace.xxxl),
                  itemBuilder: (context, index) => Center(
                    child: Text(
                      labels[index],
                      style: HDTText.mono(size: 12, color: HDTColors.text2),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.overline,
    required this.title,
    required this.actionLabel,
    required this.actionRoute,
    required this.child,
    this.subtitle,
  });

  final String overline;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final String actionRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: HDTSpace.xl, vertical: HDTSpace.xxxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: HDTSpace.xl,
                runSpacing: HDTSpace.md,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 620,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(overline, style: HDTText.overline(size: 11)),
                        const SizedBox(height: HDTSpace.sm),
                        Text(title, style: HDTText.display(size: 44)),
                        if (subtitle != null) ...[
                          const SizedBox(height: HDTSpace.xs),
                          Text(subtitle!,
                              style: HDTText.mono(
                                  size: 12, color: HDTColors.text3)),
                        ],
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, actionRoute),
                    icon: const Icon(Icons.chevron_right),
                    label: Text(actionLabel),
                  ),
                ],
              ),
              const SizedBox(height: HDTSpace.xl),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _TournamentPreview extends StatelessWidget {
  const _TournamentPreview();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.tournaments)
          .orderBy('startDate', descending: false)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        final rows = (snapshot.data?.docs ?? const [])
            .map(TournamentSummary.fromFirestore)
            .where((tournament) => tournament.status != 'completed')
            .take(3)
            .map(_TournamentSpotlight.fromSummary)
            .toList();
        final tournaments = rows.isEmpty ? _demoTournaments : rows;
        return LayoutBuilder(builder: (context, constraints) {
          final cols = constraints.maxWidth >= 980
              ? 3
              : constraints.maxWidth >= 640
                  ? 2
                  : 1;
          final width =
              (constraints.maxWidth - (cols - 1) * HDTSpace.md) / cols;
          return Wrap(
            spacing: HDTSpace.md,
            runSpacing: HDTSpace.md,
            children: [
              for (final tournament in tournaments)
                SizedBox(
                  width: width,
                  child: _TournamentSpotlightCard(tournament),
                ),
            ],
          );
        });
      },
    );
  }
}

class _TournamentSpotlightCard extends StatelessWidget {
  const _TournamentSpotlightCard(this.tournament);

  final _TournamentSpotlight tournament;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: HDTR.lg,
      onTap: () => Navigator.pushNamed(context, '/public/tournaments'),
      child: Container(
        padding: const EdgeInsets.all(HDTSpace.xl),
        decoration: hdtCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tournament.color,
                    borderRadius: HDTR.md,
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  tournament.status,
                  style: HDTText.overline(
                    size: 9,
                    color: tournament.isLive
                        ? HDTColors.accentHover
                        : HDTColors.text3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: HDTSpace.xl),
            Text(tournament.name, style: HDTText.display(size: 24)),
            const SizedBox(height: HDTSpace.sm),
            Text(
              tournament.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.body(size: 12, color: HDTColors.text2),
            ),
            const SizedBox(height: HDTSpace.xl),
            hdtDivider(),
            const SizedBox(height: HDTSpace.md),
            Row(
              children: [
                Expanded(
                  child: _MetaStat(
                    label: 'DATE',
                    value: tournament.dateLabel,
                  ),
                ),
                Expanded(
                  child: _MetaStat(
                    label: 'SLOTS',
                    value: tournament.capacityLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardPreview extends StatelessWidget {
  const _LeaderboardPreview();

  static const fallbackPlayers = [
    _Player('01', 'KAEDE', 'HDT-001', 'JKT', 2840, 4, 2, HDTColors.accent),
    _Player('02', 'HARRIS', 'HDT-202', 'BDG', 2760, 3, -1, HDTColors.info),
    _Player('03', 'GERHANA', 'HDT-045', 'SBY', 2698, 2, 4, HDTColors.warning),
    _Player('04', 'NADIA', 'HDT-088', 'JKT', 2634, 2, 0, HDTColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .orderBy('eloRating', descending: true)
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        final rows = (snapshot.data?.docs ?? const [])
            .map(AppUser.fromFirestore)
            .where((user) => user.displayName.trim().isNotEmpty)
            .toList();
        final players = rows.isEmpty
            ? fallbackPlayers
            : [
                for (var i = 0; i < rows.length; i++)
                  _Player.fromUser(rows[i], i),
              ];
        return Container(
          decoration: hdtCard(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(HDTSpace.md),
                color: HDTColors.bg,
                child: Row(
                  children: [
                    Expanded(
                        child: Text('PLAYER',
                            style: HDTText.overline(color: HDTColors.text3))),
                    SizedBox(
                        width: 90,
                        child: Text('POINTS',
                            textAlign: TextAlign.right,
                            style: HDTText.overline(color: HDTColors.text3))),
                    SizedBox(
                        width: 70,
                        child: Text('TREND',
                            textAlign: TextAlign.right,
                            style: HDTText.overline(color: HDTColors.text3))),
                  ],
                ),
              ),
              for (final player in players) _PlayerRow(player: player),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player});
  final _Player player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: HDTColors.s2))),
      child: Row(
        children: [
          SizedBox(
              width: 44,
              child: Text(player.rank,
                  style:
                      HDTText.display(size: 22, color: HDTColors.accentHover))),
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(color: player.color, borderRadius: HDTR.md),
            child: Center(
                child: Text(player.name[0],
                    style: HDTText.display(size: 18, color: Colors.white))),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: HDTText.body(size: 15)),
                Text('${player.id} - ${player.region}',
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
          SizedBox(
              width: 90,
              child: Text(player.points.toString(),
                  textAlign: TextAlign.right,
                  style: HDTText.display(size: 20))),
          SizedBox(
            width: 70,
            child: Text(
              player.trend > 0 ? '+${player.trend}' : '${player.trend}',
              textAlign: TextAlign.right,
              style: HDTText.mono(
                  size: 12,
                  color:
                      player.trend >= 0 ? HDTColors.success : HDTColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityGrid extends StatelessWidget {
  const _CommunityGrid();

  static const fallbackCommunities = [
    _Community('JKT WOLVES', 'Jakarta', '1,248', '2 LIVE', HDTColors.accent),
    _Community('SBY SPIN', 'Surabaya', '843', '1 LIVE', HDTColors.danger),
    _Community('BDG GRINDERS', 'Bandung', '712', 'OPEN', HDTColors.info),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.communities)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        final rows = (snapshot.data?.docs ?? const [])
            .map((doc) => _Community.fromFirestore(doc))
            .toList();
        final communities = rows.isEmpty ? fallbackCommunities : rows;
        return LayoutBuilder(builder: (context, constraints) {
          final cols = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 620
                  ? 2
                  : 1;
          final width =
              (constraints.maxWidth - (cols - 1) * HDTSpace.md) / cols;
          return Wrap(
            spacing: HDTSpace.md,
            runSpacing: HDTSpace.md,
            children: [
              for (final community in communities)
                SizedBox(
                  width: width,
                  child: _CommunityCard(community: community),
                ),
            ],
          );
        });
      },
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.community});
  final _Community community;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: HDTR.lg,
      onTap: () => Navigator.pushNamed(context, '/communities'),
      child: Container(
        padding: const EdgeInsets.all(HDTSpace.xl),
        decoration: hdtCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: community.color, borderRadius: HDTR.md),
                  child: const Icon(Icons.shield_outlined, color: Colors.white),
                ),
                const Spacer(),
                Text(community.status,
                    style: HDTText.overline(
                        color: community.status.contains('LIVE')
                            ? HDTColors.accentHover
                            : HDTColors.text3)),
              ],
            ),
            const SizedBox(height: HDTSpace.xl),
            Text(community.name, style: HDTText.display(size: 24)),
            const SizedBox(height: HDTSpace.xs),
            Text(community.region, style: HDTText.overline(size: 10)),
            const SizedBox(height: HDTSpace.xl),
            hdtDivider(),
            const SizedBox(height: HDTSpace.md),
            Row(
              children: [
                const Icon(Icons.groups_outlined,
                    size: 16, color: HDTColors.text3),
                const SizedBox(width: HDTSpace.sm),
                Text(community.members, style: HDTText.mono()),
                const Spacer(),
                Text('VIEW', style: HDTText.overline(size: 10)),
                const Icon(Icons.chevron_right,
                    size: 16, color: HDTColors.text3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarsBand extends StatelessWidget {
  const _PillarsBand();

  @override
  Widget build(BuildContext context) {
    const pillars = [
      _Pillar(Icons.local_fire_department_outlined, 'COMPETITIVE',
          'Every match produces ELO. Every deck has a track record. Players here want to win.'),
      _Pillar(Icons.groups_outlined, 'COMMUNITY-LED',
          'Every community uses its own rules, fees, and judges. The platform supports them without forcing one format.'),
      _Pillar(Icons.visibility_outlined, 'TRANSPARENT',
          'Bracketing, prizes, fees, and match results are open. No black boxes.'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: HDTColors.s1,
        border: Border.symmetric(horizontal: BorderSide(color: HDTColors.s2)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: HDTSpace.xl, vertical: HDTSpace.xxxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth >= 820 ? 3 : 1;
            final width =
                (constraints.maxWidth - (cols - 1) * HDTSpace.xl) / cols;
            return Wrap(
              spacing: HDTSpace.xl,
              runSpacing: HDTSpace.xl,
              children: [
                for (final pillar in pillars)
                  SizedBox(width: width, child: _PillarBlock(pillar: pillar)),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _PillarBlock extends StatelessWidget {
  const _PillarBlock({required this.pillar});
  final _Pillar pillar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              border: Border.all(color: HDTColors.accentDim),
              borderRadius: HDTR.md),
          child: Icon(pillar.icon, color: HDTColors.accentHover),
        ),
        const SizedBox(height: HDTSpace.lg),
        Text(pillar.title, style: HDTText.display(size: 24)),
        const SizedBox(height: HDTSpace.sm),
        Text(pillar.body,
            style: HDTText.body(color: HDTColors.text2, height: 1.6)),
      ],
    );
  }
}

class _ComponentMetaGrid extends ConsumerWidget {
  const _ComponentMetaGrid();

  static const parts = [
    _Part(
      'PHOENIX WING',
      'BLADE',
      'S',
      '1,204',
      '58.2%',
      HDTColors.danger,
      category: 'blades',
      assetPath: 'assets/beybrew/parts/BladePhoenixWing.png',
      shortCode: 'PW',
    ),
    _Part(
      'RUSH',
      'BIT',
      'A',
      '902',
      '54.9%',
      HDTColors.warning,
      category: 'bits',
      assetPath: 'assets/beybrew/parts/BitRush.png',
      shortCode: 'RU',
    ),
    _Part(
      '9-60',
      'RATCHET',
      'A',
      '744',
      '52.4%',
      HDTColors.info,
      category: 'ratchets',
      assetPath: 'assets/beybrew/parts/Ratchet9-60.png',
      shortCode: '9-60',
    ),
    _Part(
      'BALL',
      'BIT',
      'B',
      '488',
      '49.8%',
      HDTColors.success,
      category: 'bits',
      assetPath: 'assets/beybrew/parts/BitBall.png',
      shortCode: 'BA',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(beyPartsCatalogProvider).valueOrNull;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.componentStats)
          .limit(500)
          .snapshots(),
      builder: (context, statsSnapshot) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .doc(FirestorePaths.weeklyComponentReleaseDoc('current'))
              .snapshots(),
          builder: (context, releaseSnapshot) {
            final release = releaseSnapshot.data?.data() ?? const {};
            final selectedIds = ((release['selectedIds'] as List?) ?? const [])
                .map((item) => item.toString())
                .where((item) => item.isNotEmpty)
                .toList();
            final statDocs = statsSnapshot.data?.docs ?? const [];
            final byId = {
              for (final doc in statDocs) doc.id: doc,
            };
            final selectedParts = selectedIds
                .map((id) => byId[id])
                .whereType<QueryDocumentSnapshot<Map<String, dynamic>>>()
                .map((doc) => _Part.fromStat(doc, catalog))
                .toList();
            final autoParts = [...statDocs]..sort((a, b) {
                final winRate =
                    _statWinRate(b.data()).compareTo(_statWinRate(a.data()));
                if (winRate != 0) return winRate;
                return _intFrom(b.data()['appearances'])
                    .compareTo(_intFrom(a.data()['appearances']));
              });
            final statParts = selectedParts.isNotEmpty
                ? selectedParts
                : autoParts
                    .take(4)
                    .map((doc) => _Part.fromStat(doc, catalog))
                    .toList();
            final catalogParts = catalog == null
                ? parts
                : _catalogPreview(catalog).map(_Part.fromBeyPart).toList();
            return _ComponentMetaWrap(
              parts:
                  statParts.isEmpty ? catalogParts : statParts.take(4).toList(),
            );
          },
        );
      },
    );
  }
}

class _ComponentMetaWrap extends StatelessWidget {
  const _ComponentMetaWrap({required this.parts});

  final List<_Part> parts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 1000
          ? 4
          : constraints.maxWidth >= 700
              ? 2
              : 1;
      final width = (constraints.maxWidth - (cols - 1) * HDTSpace.md) / cols;
      return Wrap(
        spacing: HDTSpace.md,
        runSpacing: HDTSpace.md,
        children: [
          for (final part in parts)
            SizedBox(width: width, child: _PartCard(part)),
        ],
      );
    });
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard(this.part);
  final _Part part;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: part.tier == 'S' ? HDTColors.accent : null,
                    border: Border.all(color: HDTColors.accentHover),
                    borderRadius: HDTR.sm),
                child: Center(
                    child: Text(part.tier, style: HDTText.display(size: 14))),
              ),
              const Spacer(),
              Text(part.slot, style: HDTText.overline(size: 10)),
            ],
          ),
          const SizedBox(height: HDTSpace.lg),
          AspectRatio(
            aspectRatio: 1,
            child: _PartArtwork(part: part),
          ),
          const SizedBox(height: HDTSpace.lg),
          Text(part.name, style: HDTText.body(size: 15)),
          const SizedBox(height: HDTSpace.md),
          hdtDivider(),
          const SizedBox(height: HDTSpace.md),
          Row(
            children: [
              Expanded(child: _MetaStat(label: 'USAGE', value: part.usage)),
              Expanded(
                  child: _MetaStat(label: 'WIN RATE', value: part.winRate)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartArtwork extends StatelessWidget {
  const _PartArtwork({required this.part});

  final _Part part;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: part.imageUrl != null
          ? Image.network(
              part.imageUrl!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => _PartArtworkFallback(part: part),
            )
          : part.assetPath == null
              ? _PartArtworkFallback(part: part)
              : Image.asset(
                  part.assetPath!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) =>
                      _PartArtworkFallback(part: part),
                ),
    );
  }
}

class _PartArtworkFallback extends StatelessWidget {
  const _PartArtworkFallback({required this.part});

  final _Part part;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_partCategoryIcon(part.category), color: part.color, size: 34),
          const SizedBox(height: HDTSpace.sm),
          Text(
            part.shortCode ?? (part.slot.isEmpty ? '?' : part.slot[0]),
            style: HDTText.display(size: 20, color: part.color),
          ),
        ],
      ),
    );
  }
}

class _MetaStat extends StatelessWidget {
  const _MetaStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HDTText.overline(size: 9)),
        const SizedBox(height: HDTSpace.xs),
        Text(value, style: HDTText.display(size: 18)),
      ],
    );
  }
}

class _CtaBand extends ConsumerWidget {
  const _CtaBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final signedIn = auth.valueOrNull != null;
    final checkingSession = auth.isLoading && !signedIn;
    final user = ref.watch(currentUserProfileProvider).valueOrNull;
    final dashboardRoute = user == null ? '/dashboard' : defaultRouteFor(user);
    return Container(
      decoration: const BoxDecoration(
        color: HDTColors.s1,
        border: Border.symmetric(horizontal: BorderSide(color: HDTColors.s2)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: HDTSpace.xl, vertical: HDTSpace.xxxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Wrap(
            spacing: HDTSpace.xl,
            runSpacing: HDTSpace.lg,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 650,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(signedIn ? 'READY TO CONTINUE?' : 'READY TO PROVE IT?',
                        style: HDTText.display(size: 50)),
                    const SizedBox(height: HDTSpace.sm),
                    Text(
                      signedIn
                          ? 'Return to your dashboard, review your decks, and keep your tournament flow moving.'
                          : 'Create an account, build your first deck, and enter this week\'s bracket.',
                      style: HDTText.body(color: HDTColors.text2),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: HDTSpace.md,
                children: [
                  ElevatedButton(
                    onPressed: checkingSession
                        ? null
                        : () => Navigator.pushNamed(
                              context,
                              signedIn ? dashboardRoute : '/signup',
                            ),
                    child: Text(checkingSession
                        ? 'CHECKING'
                        : signedIn
                            ? 'OPEN DASHBOARD'
                            : 'REGISTER'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      signedIn ? '/public/tournaments' : '/signin',
                    ),
                    child: Text(signedIn ? 'BROWSE TOURNAMENTS' : 'SIGN IN'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(HDTSpace.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                        color: HDTColors.accent, borderRadius: HDTR.sm),
                    child: const Icon(Icons.sports_martial_arts,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: HDTSpace.sm),
                  Text('HIDEOUT', style: HDTText.display(size: 18)),
                  const Spacer(),
                  Text('2026 HIDEOUT PLATFORM - BUILT FOR GRINDERS',
                      style: HDTText.mono(size: 11, color: HDTColors.text3)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({this.color = HDTColors.accent});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = HDTColors.s2.withValues(alpha: 0.34)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArenaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.42;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = HDTColors.s3;
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = HDTColors.accentHover;

    for (var i = 4; i > 0; i--) {
      canvas.drawCircle(center, radius * i / 4, ring);
    }
    for (var i = 0; i < 8; i++) {
      final a = (math.pi * 2 / 8) * i;
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * radius * 0.36,
        center + Offset(math.cos(a), math.sin(a)) * radius,
        ring,
      );
    }
    _polygon(canvas, center, radius * 0.72, 6, accent);
    canvas.drawCircle(center, 7, Paint()..color = HDTColors.accentHover);
  }

  void _polygon(
      Canvas canvas, Offset center, double radius, int sides, Paint p) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 / sides) * i;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Player {
  const _Player(this.rank, this.name, this.id, this.region, this.points,
      this.trophies, this.trend, this.color);

  factory _Player.fromUser(AppUser user, int index) {
    final region = _regionFromUser(user);
    return _Player(
      (index + 1).toString().padLeft(2, '0'),
      user.displayName.toUpperCase(),
      user.uid.length > 8 ? user.uid.substring(0, 8).toUpperCase() : user.uid,
      region,
      user.eloRating,
      0,
      0,
      _rankColor(index),
    );
  }

  final String rank;
  final String name;
  final String id;
  final String region;
  final int points;
  final int trophies;
  final int trend;
  final Color color;
}

class _Community {
  const _Community(
      this.name, this.region, this.members, this.status, this.color);

  factory _Community.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _Community(
      (data['name'] ?? data['communityName'] ?? doc.id)
          .toString()
          .toUpperCase(),
      (data['city'] ?? data['region'] ?? 'Indonesia').toString(),
      _compactCount((data['memberCount'] as num?)?.round() ?? 0),
      (data['status'] ?? 'OPEN').toString().toUpperCase(),
      _communityColor(doc.id),
    );
  }

  final String name;
  final String region;
  final String members;
  final String status;
  final Color color;
}

class _TournamentSpotlight {
  const _TournamentSpotlight({
    required this.name,
    required this.status,
    required this.location,
    required this.dateLabel,
    required this.capacityLabel,
    required this.color,
  });

  factory _TournamentSpotlight.fromSummary(TournamentSummary tournament) {
    return _TournamentSpotlight(
      name: tournament.name.toUpperCase(),
      status: _statusLabel(tournament.status),
      location:
          tournament.location.trim().isEmpty ? 'TBA' : tournament.location,
      dateLabel: _dateLabel(tournament.startDate),
      capacityLabel:
          '${tournament.currentParticipantCount}/${tournament.maxParticipants}',
      color: _statusColor(tournament.status),
    );
  }

  final String name;
  final String status;
  final String location;
  final String dateLabel;
  final String capacityLabel;
  final Color color;

  bool get isLive => status == 'LIVE';
}

class _Pillar {
  const _Pillar(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

class _Part {
  const _Part(
    this.name,
    this.slot,
    this.tier,
    this.usage,
    this.winRate,
    this.color, {
    required this.category,
    this.assetPath,
    this.imageUrl,
    this.shortCode,
  });

  factory _Part.fromStat(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    BeyPartsCatalog? catalog,
  ) {
    final data = doc.data();
    final rawName = (data['name'] ?? doc.id).toString();
    final category =
        _normalizeCategory((data['category'] ?? 'blades').toString());
    final part = catalog?.find(doc.id) ??
        catalog?.findByName(rawName, category: category) ??
        catalog?.findByName(rawName);
    final wins = _intFrom(data['wins']);
    final losses = _intFrom(data['losses']);
    final played = _intFrom(data['appearances']);
    final winRate = wins + losses == 0 ? 0 : wins / (wins + losses) * 100;
    final total = part?.stats.total ?? 0;
    final image = data['image']?.toString();
    return _Part(
      (part?.name ?? rawName).toUpperCase(),
      _slotLabel(part?.category ?? category),
      total >= 15
          ? 'S'
          : total >= 10
              ? 'A'
              : 'B',
      played.toString(),
      '${winRate.toStringAsFixed(1)}%',
      _partColor((data['type'] ?? part?.type ?? 'balance').toString()),
      category: part?.category ?? category,
      assetPath: part?.assetPath ?? _assetPathFromImage(image),
      imageUrl: part?.imageUrl ?? _imageUrlFromImage(image),
      shortCode: part?.shortCode,
    );
  }

  factory _Part.fromBeyPart(BeyPart part) {
    final total = part.stats.total;
    return _Part(
      part.name.toUpperCase(),
      _slotLabel(part.category),
      total >= 15
          ? 'S'
          : total >= 10
              ? 'A'
              : 'B',
      '0',
      '0.0%',
      _partColor(part.type),
      category: part.category,
      assetPath: part.assetPath,
      imageUrl: part.imageUrl,
      shortCode: part.shortCode,
    );
  }

  final String name;
  final String slot;
  final String tier;
  final String usage;
  final String winRate;
  final Color color;
  final String category;
  final String? assetPath;
  final String? imageUrl;
  final String? shortCode;
}

List<BeyPart> _catalogPreview(BeyPartsCatalog catalog) {
  final preferred = [
    catalog.findByName('Phoenix Wing', category: 'blades'),
    catalog.findByName('Rush', category: 'bits'),
    catalog.findByName('9-60', category: 'ratchets'),
    catalog.findByName('Ball', category: 'bits'),
  ].whereType<BeyPart>().toList();

  if (preferred.length == 4) return preferred;

  final fallback = [
    ...catalog.blades.take(1),
    ...catalog.bits.take(1),
    ...catalog.ratchets.take(1),
    ...catalog.assistBlades.take(1),
  ].take(4).toList();
  return [...preferred, ...fallback]
      .fold<List<BeyPart>>([], (parts, part) {
        if (!parts.any((item) => item.id == part.id)) parts.add(part);
        return parts;
      })
      .take(4)
      .toList();
}

String? _assetPathFromImage(String? image) {
  final trimmed = image?.trim();
  return trimmed == null || trimmed.isEmpty || _isNetworkImage(trimmed)
      ? null
      : 'assets/beybrew/parts/$trimmed';
}

String? _imageUrlFromImage(String? image) {
  final trimmed = image?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return _isNetworkImage(trimmed) ? trimmed : null;
}

const _demoTournaments = [
  _TournamentSpotlight(
    name: 'HIDEOUT CUP #04',
    status: 'REGISTRATION OPEN',
    location: 'Jakarta',
    dateLabel: '24 MEI',
    capacityLabel: '28/32',
    color: HDTColors.accent,
  ),
  _TournamentSpotlight(
    name: 'EAST COAST SHOWDOWN',
    status: 'LIVE',
    location: 'Surabaya',
    dateLabel: '26 MEI',
    capacityLabel: '16/16',
    color: HDTColors.danger,
  ),
  _TournamentSpotlight(
    name: 'HIGHLAND OPEN',
    status: 'UPCOMING',
    location: 'Bandung',
    dateLabel: '31 MEI',
    capacityLabel: '12/24',
    color: HDTColors.info,
  ),
];

String _tickerLabel(TournamentSummary tournament) {
  final status = _statusLabel(tournament.status);
  final location = tournament.location.trim().isEmpty
      ? 'HIDEOUT'
      : tournament.location.split(',').first.trim().toUpperCase();
  return '$location / ${tournament.name.toUpperCase()} - $status';
}

String _statusLabel(String status) {
  return switch (status) {
    'registrationOpen' => 'REGISTRATION OPEN',
    'inProgress' || 'running' => 'LIVE',
    'completed' => 'COMPLETED',
    'cancelled' => 'CANCELLED',
    _ => 'UPCOMING',
  };
}

Color _statusColor(String status) {
  return switch (status) {
    'registrationOpen' => HDTColors.accent,
    'inProgress' || 'running' => HDTColors.danger,
    'completed' => HDTColors.success,
    'cancelled' => HDTColors.text3,
    _ => HDTColors.info,
  };
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'TBA';
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MEI',
    'JUN',
    'JUL',
    'AGU',
    'SEP',
    'OKT',
    'NOV',
    'DES',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String _compactCount(int value) {
  if (value >= 1000) {
    final count = value / 1000;
    return '${count.toStringAsFixed(count >= 10 ? 0 : 1)}K';
  }
  return value.toString();
}

String _regionFromUser(AppUser user) {
  final parts = user.email.split('@');
  if (parts.length > 1) return parts.last.split('.').first.toUpperCase();
  return 'ID';
}

Color _rankColor(int index) {
  return switch (index) {
    0 => HDTColors.accent,
    1 => HDTColors.info,
    2 => HDTColors.warning,
    _ => HDTColors.success,
  };
}

Color _communityColor(String seed) {
  final colors = [
    HDTColors.accent,
    HDTColors.danger,
    HDTColors.info,
    HDTColors.success,
    HDTColors.warning,
  ];
  return colors[seed.hashCode.abs() % colors.length];
}

IconData _partCategoryIcon(String category) {
  return switch (_normalizeCategory(category)) {
    'ratchets' => Icons.adjust,
    'bits' => Icons.radio_button_checked,
    'assist_blades' => Icons.extension_outlined,
    'over_blades' => Icons.layers_outlined,
    'lock_chips' => Icons.lock_outline,
    _ => Icons.hexagon_outlined,
  };
}

String _normalizeCategory(String category) {
  final value = category.trim().toLowerCase().replaceAll('-', '_');
  return switch (value) {
    'blade' || 'blades' => 'blades',
    'assist' || 'assist_blade' || 'assist_blades' => 'assist_blades',
    'over' || 'over_blade' || 'over_blades' => 'over_blades',
    'lock' || 'lock_chip' || 'lock_chips' => 'lock_chips',
    'ratchet' || 'ratchets' => 'ratchets',
    'bit' || 'bits' => 'bits',
    _ => value.isEmpty ? 'blades' : value,
  };
}

int _intFrom(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _statWinRate(Map<String, dynamic> stats) {
  final wins = _intFrom(stats['wins']);
  final losses = _intFrom(stats['losses']);
  if (wins + losses == 0) return 0;
  return wins / (wins + losses) * 100;
}

String _slotLabel(String category) {
  return switch (_normalizeCategory(category)) {
    'assist_blades' => 'ASSIST',
    'over_blades' => 'OVER',
    'lock_chips' => 'LOCK',
    'ratchets' => 'RATCHET',
    'bits' => 'BIT',
    _ => 'BLADE',
  };
}

Color _partColor(String type) {
  return switch (type.toLowerCase()) {
    'attack' => HDTColors.danger,
    'defense' => HDTColors.info,
    'stamina' => HDTColors.success,
    _ => HDTColors.warning,
  };
}

bool _isNetworkImage(String value) {
  final lower = value.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}
