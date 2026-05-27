import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/app_user.dart';
import '../../data/models/player_deck.dart';
import '../../data/models/tournament_summary.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/tournament_repository.dart';
import '../player/my_tournaments_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final name = profile.maybeWhen(
      data: (user) {
        if (user == null) return 'BLADE RUNNER';
        if (user.displayName.trim().isNotEmpty) {
          return user.displayName.trim().toUpperCase();
        }
        return user.email.split('@').first.toUpperCase();
      },
      orElse: () => 'BLADE RUNNER',
    );
    final capabilities = profile.valueOrNull?.capabilities ?? {'player'};
    final user = profile.valueOrNull;
    final decks =
        ref.watch(userDecksProvider).valueOrNull ?? const <PlayerDeck>[];
    final registrations =
        ref.watch(playerTournamentEntriesProvider).valueOrNull ??
            const <PlayerTournamentEntry>[];
    final notifications = ref.watch(userNotificationsProvider).valueOrNull ??
        const <AppNotification>[];
    final registeredIds = registrations.map((item) => item.id).toSet();
    final recommended = (ref.watch(liveTournamentsProvider).valueOrNull ??
            const <TournamentSummary>[])
        .where((item) => item.registrationOpen)
        .where((item) => !registeredIds.contains(item.id))
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 80),
          children: [
            _Header(
              name: name,
              capabilities: capabilities,
              user: user,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1040;
                if (!wide) {
                  return Column(
                    children: [
                      _NextUpCard(tournaments: registrations),
                      const SizedBox(height: 16),
                      _RankCard(user: user),
                      const SizedBox(height: 16),
                      _FormCard(user: user),
                      const SizedBox(height: 16),
                      _DecksCard(decks: decks),
                      const SizedBox(height: 16),
                      _ActiveTournamentsCard(tournaments: registrations),
                      const SizedBox(height: 16),
                      _NotificationsCard(notifications: notifications),
                      const SizedBox(height: 16),
                      _RecommendedCard(tournaments: recommended),
                      const SizedBox(height: 16),
                      _GoalCard(user: user),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _NextUpCard(tournaments: registrations),
                          const SizedBox(height: 16),
                          _RankCard(user: user),
                          const SizedBox(height: 16),
                          _FormCard(user: user),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _DecksCard(decks: decks),
                          const SizedBox(height: 16),
                          _ActiveTournamentsCard(tournaments: registrations),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _NotificationsCard(notifications: notifications),
                          const SizedBox(height: 16),
                          _RecommendedCard(tournaments: recommended),
                          const SizedBox(height: 16),
                          _GoalCard(user: user),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final Set<String> capabilities;
  final AppUser? user;

  const _Header({
    required this.name,
    required this.capabilities,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final hasJudge = capabilities.contains('judge');
    final hasCommunityAdmin = capabilities.contains('community_admin');
    final hasSuperAdmin = capabilities.contains('super_admin');
    final hasPlayer = capabilities.contains('player');
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WELCOME BACK', style: HDTText.overline(size: 11)),
            const SizedBox(height: 4),
            Text(name, style: HDTText.display(size: 40)),
            const SizedBox(height: 4),
            Text(
              [
                user?.email.split('@').first.toUpperCase() ?? 'PLAYER',
                user?.role.toUpperCase() ?? 'PLAYER',
                'ELO ${user?.eloRating ?? 1000}',
              ].join(' . '),
              style: HDTText.mono(size: 12, color: HDTColors.text3),
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (_) => false,
              ),
              icon: const Icon(Icons.home_outlined, size: 16),
              label: const Text('HOME'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(112, 42),
              ),
            ),
            if (hasJudge)
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/juri/matches'),
                icon: const Icon(Icons.sports_martial_arts_outlined, size: 16),
                label: const Text('JUDGE MATCHES'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 42),
                ),
              ),
            if (hasCommunityAdmin) ...[
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/community/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                label: const Text('COMMUNITY ADMIN'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(174, 42),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin/tournaments/ops'),
                icon: const Icon(Icons.account_tree_outlined, size: 16),
                label: const Text('TOURNEY OPS'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(148, 42),
                ),
              ),
            ],
            if (hasSuperAdmin)
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/super-admin/reports'),
                icon: const Icon(Icons.query_stats_outlined, size: 16),
                label: const Text('PLATFORM REPORTS'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(174, 42),
                ),
              ),
            if (hasPlayer)
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/me/decks/new'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('BUILD DECK'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(148, 42),
                  backgroundColor: HDTColors.accent,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.tournaments});

  final List<PlayerTournamentEntry> tournaments;

  @override
  Widget build(BuildContext context) {
    final active = tournaments
        .where((item) =>
            item.status == PlayerTournamentStatus.ongoing ||
            item.status == PlayerTournamentStatus.checkedIn ||
            item.status == PlayerTournamentStatus.registered)
        .toList();
    final next = active.isEmpty ? null : active.first;
    return _Panel(
      title: 'NEXT UP',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: HDTColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text('ACTIVE', style: HDTText.overline(color: HDTColors.accentHover)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(next?.community.toUpperCase() ?? 'NO ACTIVE ENTRY',
              style: HDTText.overline(size: 10)),
          const SizedBox(height: 8),
          Text(next?.name ?? 'Register for a tournament',
              style: HDTText.display(size: 32)),
          const SizedBox(height: 2),
          Text(
            next == null
                ? 'Live tournament data will appear here after registration.'
                : '${next.format} . ${next.registered}/${next.capacity} PLAYERS',
            style: HDTText.mono(size: 12, color: HDTColors.text3),
          ),
          const SizedBox(height: 24),
          _CountdownRow(target: next?.date),
          const SizedBox(height: 20),
          Text(
            next == null
                ? 'No venue selected yet'
                : '${next.venue}, ${next.city}',
            style: HDTText.body(size: 12, color: HDTColors.text2),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    next == null ? '/tournaments' : '/tournaments/detail',
                    arguments: next?.toTournamentArgs(),
                  ),
                  child: Text(next == null ? 'FIND EVENT' : 'VIEW EVENT'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: next == null
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            '/me/qr',
                            arguments: next.toTicketArgs(),
                          ),
                  child: const Text('QR PASS'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownRow extends StatelessWidget {
  const _CountdownRow({required this.target});

  final DateTime? target;

  @override
  Widget build(BuildContext context) {
    final remaining = target?.difference(DateTime.now());
    final duration =
        remaining == null || remaining.isNegative ? Duration.zero : remaining;
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return Row(
      children: [
        Expanded(
            child: _CountdownTile(label: 'DAYS', value: _padCounter(days, 2))),
        const SizedBox(width: 8),
        Expanded(
            child: _CountdownTile(label: 'HRS', value: _padCounter(hours, 2))),
        const SizedBox(width: 8),
        Expanded(
            child:
                _CountdownTile(label: 'MIN', value: _padCounter(minutes, 2))),
        const SizedBox(width: 8),
        Expanded(
            child:
                _CountdownTile(label: 'SEC', value: _padCounter(seconds, 2))),
      ],
    );
  }
}

class _CountdownTile extends StatelessWidget {
  final String label;
  final String value;

  const _CountdownTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: HDTText.display(size: 28, color: HDTColors.accentHover)),
          const SizedBox(height: 4),
          Text(label, style: HDTText.overline(size: 9)),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final elo = user?.eloRating ?? 1000;
    final matches = user?.totalMatches ?? 0;
    return _Panel(
      title: 'MY RANK',
      action: Text('LIVE PROFILE',
          style: HDTText.mono(size: 11, color: HDTColors.text3)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatInt(elo), style: HDTText.display(size: 54)),
                    const SizedBox(width: 8),
                    if (matches > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Text('$matches matches',
                            style:
                                HDTText.mono(size: 12, color: HDTColors.text3)),
                      ),
                  ],
                ),
                Text('ELO . FIREBASE USER PROFILE',
                    style: HDTText.overline(size: 10)),
                const SizedBox(height: 16),
                _RankLine(
                    label: 'WIN RATE',
                    total:
                        '${user?.totalWins ?? 0}W / ${user?.totalLosses ?? 0}L',
                    value: matches == 0 ? 0 : (user!.totalWins / matches)),
                const SizedBox(height: 12),
                const _RankLine(
                    label: 'GLOBAL RANK',
                    total: 'pending live match volume',
                    value: 0),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 136,
            height: 80,
            child: _Sparkline(
              data: matches == 0 ? const [] : [1000, elo.toDouble()],
              color: HDTColors.accentHover,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankLine extends StatelessWidget {
  final String label;
  final String total;
  final double value;

  const _RankLine(
      {required this.label, required this.total, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: HDTText.mono(size: 11, color: HDTColors.text2),
            children: [
              TextSpan(text: '$label '),
              TextSpan(
                  text: total,
                  style: HDTText.mono(size: 11, color: HDTColors.text3)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: HDTR.full,
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            backgroundColor: HDTColors.bg,
            valueColor: const AlwaysStoppedAnimation(HDTColors.accent),
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final wins = user?.totalWins ?? 0;
    final losses = user?.totalLosses ?? 0;
    final formWins = wins.clamp(0, 10).toInt();
    final formLosses = losses.clamp(0, 10 - formWins).toInt();
    final form = <String>[
      for (var i = 0; i < formWins; i++) 'W',
      for (var i = 0; i < formLosses; i++) 'L',
    ];
    return _Panel(
      title: 'RECENT FORM',
      action: Text('${wins}W-${losses}L LIVE',
          style: HDTText.mono(size: 11, color: HDTColors.text2)),
      child: form.isEmpty
          ? const _EmptyInline(
              icon: Icons.query_stats_outlined,
              title: 'No match form yet',
              subtitle: 'Finished judged matches will fill this strip.',
            )
          : Row(
              children: [
                for (final item in form) ...[
                  Expanded(child: _FormTile(result: item)),
                  if (item != form.last) const SizedBox(width: 8),
                ],
              ],
            ),
    );
  }
}

class _FormTile extends StatelessWidget {
  final String result;

  const _FormTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final win = result == 'W';
    final color = win ? HDTColors.success : HDTColors.danger;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          borderRadius: HDTR.md,
          border: Border.all(color: color.withValues(alpha: .32)),
        ),
        child: Text(result, style: HDTText.display(size: 14, color: color)),
      ),
    );
  }
}

class _DecksCard extends StatelessWidget {
  const _DecksCard({required this.decks});

  final List<PlayerDeck> decks;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'MY DECKS',
      action: InkWell(
        onTap: () => Navigator.pushNamed(context, '/me/decks/new'),
        child: Text('BUILD NEW',
            style: HDTText.overline(color: HDTColors.accentHover)),
      ),
      padding: EdgeInsets.zero,
      child: decks.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyInline(
                icon: Icons.inventory_2_outlined,
                title: 'No saved deck yet',
                subtitle: 'Create a deck before registering for beta events.',
              ),
            )
          : Column(
              children: [
                for (final deck in decks.take(4))
                  _DeckRow(
                    name: deck.name,
                    record:
                        '${deck.combos.length}/3 combos . ${deck.legal ? 'legal' : 'needs review'}',
                    wr: '${deck.stats.total}',
                    color: deck.legal ? HDTColors.success : HDTColors.warning,
                  ),
              ],
            ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  final String name;
  final String record;
  final String wr;
  final Color color;

  const _DeckRow({
    required this.name,
    required this.record,
    required this.wr,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: HDTColors.bg,
              borderRadius: HDTR.md,
              border: Border.all(color: HDTColors.s2),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 17, color: HDTColors.accentHover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.body(size: 14, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(record,
                    style: HDTText.mono(size: 11, color: HDTColors.text3)),
              ],
            ),
          ),
          Text(wr, style: HDTText.display(size: 22, color: color)),
        ],
      ),
    );
  }
}

class _ActiveTournamentsCard extends StatelessWidget {
  const _ActiveTournamentsCard({required this.tournaments});

  final List<PlayerTournamentEntry> tournaments;

  @override
  Widget build(BuildContext context) {
    final active = tournaments
        .where((item) =>
            item.status == PlayerTournamentStatus.ongoing ||
            item.status == PlayerTournamentStatus.checkedIn ||
            item.status == PlayerTournamentStatus.registered)
        .take(4)
        .toList();
    return _Panel(
      title: 'ACTIVE TOURNAMENTS',
      action: Text('${active.length}',
          style: HDTText.mono(size: 11, color: HDTColors.text3)),
      padding: EdgeInsets.zero,
      child: active.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyInline(
                icon: Icons.emoji_events_outlined,
                title: 'No active tournaments',
                subtitle: 'Paid registrations will appear here.',
              ),
            )
          : Column(
              children: [
                for (final entry in active)
                  _TournamentMiniRow(
                    status: entry.statusLabel,
                    name: entry.name,
                    date: _shortDate(entry.date),
                    paid: entry.status != PlayerTournamentStatus.registered,
                  ),
              ],
            ),
    );
  }
}

class _TournamentMiniRow extends StatelessWidget {
  final String status;
  final String name;
  final String date;
  final bool paid;

  const _TournamentMiniRow({
    required this.status,
    required this.name,
    required this.date,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    final live = status == 'LIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: live ? HDTColors.accent : Colors.transparent,
              borderRadius: HDTR.sm,
              border: live ? null : Border.all(color: HDTColors.s2),
            ),
            child: Text(
              status,
              style: HDTText.overline(
                size: 9,
                color: live ? Colors.white : HDTColors.text2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.body(size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(date,
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
          Text(
            paid ? 'PAID' : 'PENDING',
            style: HDTText.overline(
              size: 9,
              color: paid ? HDTColors.success : HDTColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'NOTIFICATIONS',
      action: const Icon(Icons.notifications_none,
          size: 15, color: HDTColors.text3),
      padding: EdgeInsets.zero,
      child: notifications.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyInline(
                icon: Icons.notifications_none,
                title: 'No notifications',
                subtitle: 'System and tournament alerts will appear here.',
              ),
            )
          : Column(
              children: [
                for (final item in notifications.take(4))
                  _NotificationRow(
                    unread: !item.read,
                    time: _relativeTime(item.createdAt),
                    text: item.title,
                  ),
              ],
            ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final bool unread;
  final String time;
  final String text;

  const _NotificationRow({
    required this.unread,
    required this.time,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: unread ? HDTColors.accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: HDTText.body(
                    size: 12,
                    color: unread ? HDTColors.text : HDTColors.text2,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$time ago',
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.tournaments});

  final List<TournamentSummary> tournaments;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'RECOMMENDED',
      action: const Icon(Icons.auto_awesome,
          size: 15, color: HDTColors.accentHover),
      padding: EdgeInsets.zero,
      child: tournaments.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyInline(
                icon: Icons.search_outlined,
                title: 'No open events',
                subtitle: 'Open registrations from Firebase will appear here.',
              ),
            )
          : Column(
              children: [
                for (final tournament in tournaments)
                  _RecommendedRow(
                    name: tournament.name,
                    community: 'OPEN REGISTRATION',
                    date: _shortDate(tournament.startDate),
                    fee: _formatRp(tournament.registrationFee),
                    elo: 'OPEN',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/tournaments/detail',
                      arguments: {
                        'tournamentId': tournament.id,
                        'name': tournament.name,
                        'community': 'Turney',
                        'status': 'REGISTRATION OPEN',
                        'format': tournament.bracketType,
                        'tier': 'STANDARD',
                        'city': '',
                        'venue': tournament.location,
                        'fee': _formatRp(tournament.registrationFee),
                        'date': tournament.startDate?.toIso8601String() ?? '',
                        'registered': tournament.currentParticipantCount,
                        'capacity': tournament.maxParticipants,
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RecommendedRow extends StatelessWidget {
  final String name;
  final String community;
  final String date;
  final String fee;
  final String elo;
  final VoidCallback? onTap;

  const _RecommendedRow({
    required this.name,
    required this.community,
    required this.date,
    required this.fee,
    required this.elo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: HDTColors.s2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(community, style: HDTText.overline(size: 9))),
                Text(date,
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
            const SizedBox(height: 5),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HDTText.body(size: 14, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(fee,
                    style: HDTText.mono(size: 11, color: HDTColors.text2)),
                const Spacer(),
                Text('ELO $elo',
                    style: HDTText.overline(
                        size: 9, color: HDTColors.accentHover)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events_outlined,
              size: 22, color: HDTColors.accentHover),
          const SizedBox(height: 14),
          Text(
              user?.isQrActivated == true
                  ? 'QR READY\nFOR BETA'
                  : 'SETUP\nIN PROGRESS',
              style: HDTText.display(size: 24, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            user?.isQrActivated == true
                ? 'This profile is ready to join live tournament trials.'
                : 'Complete registration and check-in data before event day.',
            style: HDTText.body(size: 12, color: HDTColors.text2, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  final EdgeInsets padding;

  const _Panel({
    required this.title,
    required this.child,
    this.action,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Expanded(child: Text(title, style: HDTText.overline(size: 10))),
                if (action != null) action!,
              ],
            ),
          ),
          hdtDivider(),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: HDTColors.text3, size: 20),
        const SizedBox(width: HDTSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HDTText.body(size: 13)),
              const SizedBox(height: HDTSpace.xs),
              Text(
                subtitle,
                style: HDTText.body(
                  size: 12,
                  color: HDTColors.text3,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _padCounter(int value, int width) {
  return value.clamp(0, 99).toString().padLeft(width, '0');
}

String _formatInt(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
}

String _formatRp(int value) {
  return 'Rp ${value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      )}';
}

String _shortDate(DateTime? date) {
  if (date == null) return 'TBA';
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC'
  ];
  final month = months[date.month - 1];
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$month ${date.day} . $hour:$minute';
}

String _relativeTime(DateTime? date) {
  if (date == null) return 'now';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

class _Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _Sparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SparklinePainter(data: data, color: color));
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  const _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1 : max - min;
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = size.width * (i / (data.length - 1));
      final y = size.height - ((data[i] - min) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
