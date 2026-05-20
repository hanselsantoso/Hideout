import 'package:flutter/material.dart';

import '../../core/theme/hideout_tokens.dart';
import 'tournaments_screen.dart';

const _publicStageRule = (
  stage: 'Stage 1',
  format: 'Group Round Robin',
  advance: 'Top 4 per group advance',
  points: 'Win +3 . Draw +1 . Loss +0',
  tiebreaker: 'Match Win % -> Point Diff -> Head-to-head -> Sudden Death',
);

const _publicGroups = [
  _PublicGroup(
    'Group A',
    'Round 3 / 7',
    [
      _PublicStanding('Hansel', '3-0', 9, '+8', true),
      _PublicStanding('Nadia', '2-1', 6, '+4', true),
      _PublicStanding('Raka', '2-1', 6, '+2', true),
      _PublicStanding('Clara', '1-2', 3, '-1', true),
      _PublicStanding('Bayu', '1-2', 3, '-3', false),
    ],
    [
      _PublicCall('A-013', 'Hansel vs Clara', 'Arena 01', 'NOW'),
      _PublicCall('A-014', 'Nadia vs Raka', 'Arena 02', 'NEXT'),
    ],
  ),
  _PublicGroup(
    'Group B',
    'Round 2 / 7',
    [
      _PublicStanding('Dimas', '2-0', 6, '+6', true),
      _PublicStanding('Mardika', '2-0', 6, '+5', true),
      _PublicStanding('Taro', '1-1', 3, '0', true),
      _PublicStanding('Putri', '1-1', 3, '-1', true),
      _PublicStanding('Gerhana', '0-2', 0, '-4', false),
    ],
    [
      _PublicCall('B-009', 'Dimas vs Putri', 'Arena 04', 'NOW'),
      _PublicCall('B-010', 'Mardika vs Taro', 'Arena 05', 'NEXT'),
    ],
  ),
];

const _publicDoubleElimRounds = [
  _PublicElimRound(
    'Upper',
    [
      _PublicElimMatch('UB-01', 'Hansel', 'Nadia', 'Hansel', '4-2'),
      _PublicElimMatch('UB-02', 'Raka', 'Clara', null, 'NOW'),
    ],
  ),
  _PublicElimRound(
    'Lower',
    [
      _PublicElimMatch('LB-01', 'Nadia', 'Loser UB-02', null, 'WAITING'),
    ],
  ),
  _PublicElimRound(
    'Grand Final',
    [
      _PublicElimMatch('GF-01', 'Winner Upper', 'Winner Lower', null, 'TBD'),
    ],
  ),
];

class _PublicGroup {
  const _PublicGroup(this.name, this.status, this.standings, this.calls);

  final String name;
  final String status;
  final List<_PublicStanding> standings;
  final List<_PublicCall> calls;
}

class _PublicStanding {
  const _PublicStanding(
      this.name, this.record, this.points, this.diff, this.advancing);

  final String name;
  final String record;
  final int points;
  final String diff;
  final bool advancing;
}

class _PublicCall {
  const _PublicCall(this.code, this.players, this.arena, this.time);

  final String code;
  final String players;
  final String arena;
  final String time;
}

class _PublicElimRound {
  const _PublicElimRound(this.name, this.matches);

  final String name;
  final List<_PublicElimMatch> matches;
}

class _PublicElimMatch {
  const _PublicElimMatch(
      this.code, this.playerA, this.playerB, this.winner, this.status);

  final String code;
  final String playerA;
  final String playerB;
  final String? winner;
  final String status;
}

class TournamentDetailScreen extends StatelessWidget {
  const TournamentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tournament =
        _fromArguments(ModalRoute.of(context)?.settings.arguments);
    final isLive = tournament.status == 'LIVE';
    final canRegister = tournament.status == 'REGISTRATION OPEN';

    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _TopBar(tournament: tournament),
            _Hero(tournament: tournament, isLive: isLive),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 90),
              child: Column(
                children: [
                  const _Tabs(),
                  const SizedBox(height: 24),
                  if (tournament.status == 'COMPLETED') ...[
                    _WinnerAnnouncementPanel(tournament: tournament),
                    const SizedBox(height: 20),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 980;
                      if (!wide) {
                        return Column(
                          children: [
                            const _AboutAndSchedule(),
                            const SizedBox(height: 20),
                            _ActionPanel(
                              tournament: tournament,
                              isLive: isLive,
                              canRegister: canRegister,
                            ),
                            const SizedBox(height: 20),
                            const _RulesPanel(),
                            const SizedBox(height: 20),
                            const _PrizesPanel(),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(flex: 2, child: _AboutAndSchedule()),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _ActionPanel(
                                  tournament: tournament,
                                  isLive: isLive,
                                  canRegister: canRegister,
                                ),
                                const SizedBox(height: 20),
                                const _RulesPanel(),
                                const SizedBox(height: 20),
                                const _PrizesPanel(),
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
          ],
        ),
      ),
    );
  }
}

class _WinnerAnnouncementPanel extends StatelessWidget {
  const _WinnerAnnouncementPanel({required this.tournament});

  final TournamentEntry tournament;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(
        accentColor: HDTColors.success,
        highlighted: true,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: HDTSpace.lg,
        runSpacing: HDTSpace.md,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WINNER ANNOUNCEMENT',
                    style:
                        HDTText.overline(size: 10, color: HDTColors.success)),
                const SizedBox(height: HDTSpace.sm),
                Text(
                    '${tournament.winnerName ?? 'Champion'} . ${tournament.winnerDeckName ?? 'Registered Deck'}',
                    style: HDTText.display(size: 30)),
                const SizedBox(height: HDTSpace.sm),
                Text(
                  'Pemenang stage 2 sudah terkunci dari grand final. Deck yang tampil di sini adalah deck terverifikasi dari QR dan match record terakhir.',
                  style: HDTText.body(
                      size: 13, color: HDTColors.text2, height: 1.45),
                ),
              ],
            ),
          ),
          const _WinnerDeckBadge(),
        ],
      ),
    );
  }
}

class _WinnerDeckBadge extends StatelessWidget {
  const _WinnerDeckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.success),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: HDTColors.success, size: 30),
          const SizedBox(height: HDTSpace.sm),
          Text('CHAMPION DECK',
              textAlign: TextAlign.center,
              style: HDTText.overline(size: 9, color: HDTColors.success)),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final TournamentEntry tournament;

  const _TopBar({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: HDTColors.s1,
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          Text('HIDEOUT', style: HDTText.display(size: 22)),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: HDTColors.s2,
          ),
          Expanded(
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Text('TOURNAMENTS',
                      style: HDTText.mono(size: 10, color: HDTColors.text3)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    size: 13, color: HDTColors.text3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tournament.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.mono(size: 10, color: HDTColors.text),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_outlined, size: 14),
            label: const Text('SHARE'),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final TournamentEntry tournament;
  final bool isLive;

  const _Hero({required this.tournament, required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tournament.color.withValues(alpha: .22),
            HDTColors.bg,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tournament.color.withValues(alpha: .18),
              borderRadius: HDTR.md,
              border:
                  Border.all(color: tournament.color.withValues(alpha: .45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: tournament.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(isLive ? 'LIVE NOW' : tournament.status,
                    style: HDTText.overline(
                        size: 10, color: HDTColors.accentHover)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Text(
              tournament.name.toUpperCase(),
              style: HDTText.display(size: 58, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final item in const ['W', 'J', 'S']) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _avatarColor(item),
                  child: Text(item,
                      style: HDTText.display(size: 11, color: Colors.white)),
                ),
                const SizedBox(width: 4),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hosted by ${tournament.community}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.body(size: 14, color: HDTColors.text2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 760 ? 5 : 2;
              final stats = [
                _HeroStat(Icons.people_alt_outlined, 'PARTICIPANTS',
                    '${tournament.registered} / ${tournament.capacity}'),
                const _HeroStat(
                    Icons.payments_outlined, 'PRIZE POOL', 'Rp 8.500.000'),
                _HeroStat(Icons.shield_outlined, 'FORMAT', tournament.format),
                _HeroStat(Icons.calendar_today_outlined, 'DATE',
                    _longDate(tournament.date)),
                _HeroStat(
                    Icons.location_on_outlined, 'LOCATION', tournament.venue),
              ];
              final itemWidth =
                  (constraints.maxWidth - (cols - 1).toDouble()) / cols;
              return Wrap(
                spacing: 1,
                runSpacing: 1,
                children: [
                  for (final stat in stats)
                    SizedBox(width: itemWidth, child: stat),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroStat(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: HDTColors.text3),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.overline(size: 9),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HDTText.body(size: 15, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    const tabs = [
      'OVERVIEW',
      'BRACKET',
      'RULES',
      'PARTICIPANTS',
      'PRIZES',
      'SCHEDULE'
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: tab == 'OVERVIEW'
                        ? HDTColors.accent
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tab,
                style: HDTText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: tab == 'OVERVIEW' ? Colors.white : HDTColors.text3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AboutAndSchedule extends StatelessWidget {
  const _AboutAndSchedule();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Panel(
          title: 'ABOUT THE TOURNAMENT',
          child: Text(
            'Welcome to the third installment of the Hideout Championship Cup. Event ini memakai format kompetitif dengan verifikasi deck sebelum match pertama. Admin komunitas dapat mengatur bracket, regulasi komponen, dan stage sesuai kebutuhan event.',
            style:
                TextStyle(color: HDTColors.text2, height: 1.55, fontSize: 14),
          ),
        ),
        SizedBox(height: 20),
        _PublicFormatPanel(),
        SizedBox(height: 20),
        _SchedulePanel(),
      ],
    );
  }
}

class _PublicFormatPanel extends StatelessWidget {
  const _PublicFormatPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'FORMAT, GROUPS & LIVE RESULTS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PublicRulePill('STAGE 1 . GROUP ROUND ROBIN'),
              _PublicRulePill('TOP 4 / GROUP ADVANCE'),
              _PublicRulePill('ALL RULES PUBLIC'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_publicStageRule.points}. Tiebreaker: ${_publicStageRule.tiebreaker}.',
            style: HDTText.body(size: 12, color: HDTColors.text2, height: 1.45),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _publicGroups.length; i++) ...[
                  _PublicGroupCard(group: _publicGroups[i]),
                  if (i != _publicGroups.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _PublicDoubleElimPreview(),
        ],
      ),
    );
  }
}

class _PublicRulePill extends StatelessWidget {
  const _PublicRulePill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.sm,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Text(text, style: HDTText.overline(size: 8)),
    );
  }
}

class _PublicGroupCard extends StatelessWidget {
  const _PublicGroupCard({required this.group});

  final _PublicGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.lg,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(group.name.toUpperCase(),
                    style: HDTText.display(size: 18)),
              ),
              Text(group.status,
                  style: HDTText.mono(size: 9, color: HDTColors.accentHover)),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < group.standings.length; i++)
            _PublicStandingRow(rank: i + 1, standing: group.standings[i]),
          const SizedBox(height: 12),
          Text('NEXT CALL', style: HDTText.overline(size: 8)),
          const SizedBox(height: 8),
          for (final call in group.calls) _PublicCallRow(call: call),
        ],
      ),
    );
  }
}

class _PublicStandingRow extends StatelessWidget {
  const _PublicStandingRow({required this.rank, required this.standing});

  final int rank;
  final _PublicStanding standing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(rank.toString().padLeft(2, '0'),
                style: HDTText.mono(
                    size: 9,
                    color: standing.advancing
                        ? HDTColors.success
                        : HDTColors.text3)),
          ),
          Expanded(
            child: Text(
              standing.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.body(size: 12),
            ),
          ),
          Text('${standing.record} . ${standing.points}PT . ${standing.diff}',
              style: HDTText.mono(size: 9, color: HDTColors.text3)),
        ],
      ),
    );
  }
}

class _PublicCallRow extends StatelessWidget {
  const _PublicCallRow({required this.call});

  final _PublicCall call;

  @override
  Widget build(BuildContext context) {
    final live = call.time == 'NOW';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: live ? HDTColors.accent.withValues(alpha: .14) : HDTColors.s1,
        borderRadius: HDTR.sm,
        border: Border.all(color: live ? HDTColors.accent : HDTColors.s2),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 42, child: Text(call.code, style: HDTText.mono(size: 9))),
          Expanded(
            child: Text(call.players,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HDTText.body(size: 12)),
          ),
          Text('${call.arena} . ${call.time}',
              style: HDTText.mono(
                  size: 8,
                  color: live ? HDTColors.accentHover : HDTColors.text3)),
        ],
      ),
    );
  }
}

class _PublicDoubleElimPreview extends StatelessWidget {
  const _PublicDoubleElimPreview();

  @override
  Widget build(BuildContext context) {
    final totalMatches = _publicDoubleElimRounds.fold<int>(
      0,
      (total, round) => total + round.matches.length,
    );
    final liveMatches = _publicDoubleElimRounds
        .expand((round) => round.matches)
        .where((match) => match.status == 'NOW')
        .length;
    final completedMatches = _publicDoubleElimRounds
        .expand((round) => round.matches)
        .where((match) => match.winner != null)
        .length;
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(bg: HDTColors.bg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: HDTSpace.lg,
            runSpacing: HDTSpace.md,
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DOUBLE ELIMINATION TOP CUT',
                        style: HDTText.overline(size: 9)),
                    const SizedBox(height: HDTSpace.xs),
                    Text('UPPER / LOWER / GRAND FINAL',
                        style: HDTText.display(size: 22)),
                  ],
                ),
              ),
              Wrap(
                spacing: HDTSpace.sm,
                runSpacing: HDTSpace.sm,
                children: [
                  _PublicBracketMetric(
                      'MATCH', '$completedMatches/$totalMatches'),
                  _PublicBracketMetric('LIVE', liveMatches.toString()),
                  const _PublicBracketMetric('RESET', 'ON'),
                ],
              ),
            ],
          ),
          const SizedBox(height: HDTSpace.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: HDTSpace.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _publicDoubleElimRounds.length; i++) ...[
                  _PublicElimRoundCard(round: _publicDoubleElimRounds[i]),
                  if (i != _publicDoubleElimRounds.length - 1) ...[
                    const SizedBox(width: HDTSpace.sm),
                    _PublicBracketConnector(
                      label: i == 0 ? 'LOSER DROP' : 'WINNER FLOW',
                    ),
                    const SizedBox(width: HDTSpace.sm),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicElimRoundCard extends StatelessWidget {
  const _PublicElimRoundCard({required this.round});

  final _PublicElimRound round;

  @override
  Widget build(BuildContext context) {
    final accent = _publicBracketAccent(round.name);
    return Container(
      width: 274,
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.lg,
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: HDTR.md,
                ),
                child: Icon(
                  _publicBracketIcon(round.name),
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: HDTSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(round.name.toUpperCase(),
                        style: HDTText.display(size: 17, color: accent)),
                    Text(
                      _publicBracketSubtitle(round.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HDTText.mono(size: 9, color: HDTColors.text3),
                    ),
                  ],
                ),
              ),
              _PublicTinyPill('${round.matches.length}M', accent),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          for (final match in round.matches) ...[
            _PublicElimMatchCard(match: match),
            if (match != round.matches.last)
              const SizedBox(height: HDTSpace.sm),
          ],
        ],
      ),
    );
  }
}

class _PublicElimMatchCard extends StatelessWidget {
  const _PublicElimMatchCard({required this.match});

  final _PublicElimMatch match;

  @override
  Widget build(BuildContext context) {
    final live = match.status == 'NOW';
    final done = match.winner != null;
    final color = done
        ? HDTColors.success
        : live
            ? HDTColors.accent
            : HDTColors.text3;
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: color.withValues(alpha: .48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.code,
                  style: HDTText.overline(size: 9, color: color),
                ),
              ),
              _PublicStatusPill(match.status, color),
            ],
          ),
          const SizedBox(height: HDTSpace.sm),
          _PublicElimPlayer(
            seed: 'A',
            name: match.playerA,
            winner: match.winner == match.playerA,
          ),
          const SizedBox(height: 6),
          _PublicElimPlayer(
            seed: 'B',
            name: match.playerB,
            winner: match.winner == match.playerB,
          ),
          if (done) ...[
            const SizedBox(height: HDTSpace.sm),
            hdtDivider(),
            const SizedBox(height: HDTSpace.sm),
            Text(
              'WINNER ${match.winner!.toUpperCase()} . ${match.status}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.overline(size: 8, color: HDTColors.success),
            ),
          ],
        ],
      ),
    );
  }
}

class _PublicElimPlayer extends StatelessWidget {
  const _PublicElimPlayer({
    required this.seed,
    required this.name,
    required this.winner,
  });

  final String seed;
  final String name;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: HDTSpace.sm),
      decoration: BoxDecoration(
        color:
            winner ? HDTColors.success.withValues(alpha: 0.12) : HDTColors.s1,
        borderRadius: HDTR.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: winner ? HDTColors.success : HDTColors.s2,
              borderRadius: HDTR.sm,
            ),
            child: Text(
              winner ? 'W' : seed,
              style: HDTText.overline(
                size: 7,
                color: winner ? HDTColors.bg : HDTColors.text3,
              ),
            ),
          ),
          const SizedBox(width: HDTSpace.sm),
          Expanded(
            child: Text(
              name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.body(
                size: 11,
                color: winner ? HDTColors.text : HDTColors.text2,
                weight: winner ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicBracketMetric extends StatelessWidget {
  const _PublicBracketMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: HDTSpace.sm,
        vertical: HDTSpace.xs,
      ),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HDTText.overline(size: 7)),
          Text(value, style: HDTText.display(size: 16)),
        ],
      ),
    );
  }
}

class _PublicBracketConnector extends StatelessWidget {
  const _PublicBracketConnector({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 122,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          hdtDivider(),
          const SizedBox(height: HDTSpace.sm),
          const Icon(Icons.arrow_forward, size: 16, color: HDTColors.text3),
          const SizedBox(height: HDTSpace.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: HDTText.overline(size: 7, color: HDTColors.text3),
          ),
        ],
      ),
    );
  }
}

class _PublicStatusPill extends StatelessWidget {
  const _PublicStatusPill(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: HDTR.full,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: HDTText.mono(size: 8, color: color)),
    );
  }
}

class _PublicTinyPill extends StatelessWidget {
  const _PublicTinyPill(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: HDTR.full,
      ),
      child: Text(text, style: HDTText.mono(size: 8, color: color)),
    );
  }
}

Color _publicBracketAccent(String name) {
  if (name.startsWith('Upper')) return HDTColors.success;
  if (name.startsWith('Lower')) return HDTColors.warning;
  return HDTColors.accentHover;
}

IconData _publicBracketIcon(String name) {
  if (name.startsWith('Upper')) return Icons.trending_up;
  if (name.startsWith('Lower')) return Icons.restart_alt;
  return Icons.emoji_events_outlined;
}

String _publicBracketSubtitle(String name) {
  if (name.startsWith('Upper')) return 'winner path';
  if (name.startsWith('Lower')) return 'second chance path';
  return 'reset if needed';
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        '10:00',
        'Check-in & Deck Verification Opens',
        'Present your QR code at the registration desk.'
      ),
      ('11:00', 'Bracket Generation', 'Seeding based on current ELO.'),
      ('11:30', 'Round 1 Matches Begin', 'Simultaneous across 4 arenas.'),
      ('14:00', 'Lunch Break', '1 hour intermission.'),
      ('15:00', 'Quarterfinals', 'Best of 5 format.'),
      ('17:30', 'Grand Finals', 'Best of 7 format.'),
    ];

    return _Panel(
      title: 'SCHEDULE',
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 62,
                    child: Text(item.$1,
                        style: HDTText.mono(
                            size: 13, color: HDTColors.accentHover)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2,
                            style: HDTText.body(
                                size: 14, weight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(item.$3,
                            style:
                                HDTText.body(size: 12, color: HDTColors.text3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final TournamentEntry tournament;
  final bool isLive;
  final bool canRegister;

  const _ActionPanel({
    required this.tournament,
    required this.isLive,
    required this.canRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: hdtAccentCard(
        accentColor: tournament.color,
        highlighted: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(isLive ? 'TOURNAMENT LIVE' : tournament.status,
                    style: HDTText.overline(
                        size: 10, color: HDTColors.accentHover)),
              ),
              Text(isLive ? 'ROUND 3 ONGOING' : tournament.entryFee,
                  style: HDTText.mono(size: 10, color: HDTColors.text3)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            canRegister ? 'REGISTRATION OPEN' : 'REGISTRATION CLOSED',
            style: HDTText.display(size: 22, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            canRegister
                ? 'Pilih deck, pastikan komponen valid, lalu lanjutkan checkout. Untuk MVP pembayaran dianggap lunas.'
                : 'Tournament sedang berjalan atau belum dibuka. Kamu tetap bisa melihat bracket dan jadwal event.',
            style: HDTText.body(size: 13, color: HDTColors.text2, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (canRegister) {
                  Navigator.pushNamed(
                    context,
                    '/tournaments/register',
                    arguments: tournament.toRouteArgs(),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Live bracket, group standings, rules, dan next call tersedia di halaman ini.',
                    ),
                  ),
                );
              },
              icon: Icon(canRegister
                  ? Icons.confirmation_number_outlined
                  : Icons.emoji_events_outlined),
              label: Text(canRegister ? 'REGISTER NOW' : 'VIEW LIVE INFO'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/juri/scan'),
              icon: const Icon(Icons.play_circle_outline, size: 16),
              label: const Text('WATCH ARENA 1'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesPanel extends StatelessWidget {
  const _RulesPanel();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      title: 'ELIGIBILITY & RULES',
      child: Column(
        children: [
          _RuleRow(
            icon: Icons.warning_amber_outlined,
            color: HDTColors.warning,
            title: 'Banned Components',
            text: 'Cobalt Dragoon, Wizard Rod, 9-60 Ratchet',
          ),
          SizedBox(height: 16),
          _RuleRow(
            icon: Icons.shield_outlined,
            color: HDTColors.text3,
            title: 'Stage Advance',
            text:
                'Group round-robin: top 4 per group advance to final bracket.',
          ),
          SizedBox(height: 16),
          _RuleRow(
            icon: Icons.timeline_outlined,
            color: HDTColors.info,
            title: 'Live Transparency',
            text:
                'Players can monitor standings, result history, next call, arena, and public rules.',
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _RuleRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: HDTText.body(size: 14, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(text, style: HDTText.body(size: 12, color: HDTColors.text3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrizesPanel extends StatelessWidget {
  const _PrizesPanel();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      title: 'PRIZE DISTRIBUTION',
      child: Column(
        children: [
          _PrizeRow(
              place: '1ST PLACE',
              value: 'Rp 4.000.000',
              color: HDTColors.warning),
          SizedBox(height: 8),
          _PrizeRow(
              place: '2ND PLACE',
              value: 'Rp 2.500.000',
              color: Color(0xFFBDC3C7)),
          SizedBox(height: 8),
          _PrizeRow(
              place: '3RD PLACE',
              value: 'Rp 1.000.000',
              color: Color(0xFFD35400)),
        ],
      ),
    );
  }
}

class _PrizeRow extends StatelessWidget {
  final String place;
  final String value;
  final Color color;

  const _PrizeRow({
    required this.place,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: HDTR.md,
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_outlined, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(place,
                style: HDTText.body(
                    size: 13, weight: FontWeight.w700, color: color)),
          ),
          Text(value, style: HDTText.mono(size: 13, color: Colors.white)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: HDTText.display(size: 24, color: Colors.white)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

TournamentEntry _fromArguments(Object? args) {
  final fallback = demoTournaments.first;
  if (args is! Map) return fallback;

  DateTime parsedDate = fallback.date;
  final rawDate = args['date'];
  if (rawDate is String) {
    parsedDate = DateTime.tryParse(rawDate) ?? fallback.date;
  }

  return TournamentEntry(
    id: (args['tournamentId'] ?? fallback.id).toString(),
    name: (args['name'] ?? fallback.name).toString(),
    community: (args['community'] ?? fallback.community).toString(),
    status: (args['status'] ?? fallback.status).toString(),
    format: (args['format'] ?? fallback.format).toString(),
    tier: (args['tier'] ?? fallback.tier).toString(),
    city: (args['city'] ?? fallback.city).toString(),
    venue: (args['venue'] ?? fallback.venue).toString(),
    entryFee: (args['fee'] ?? fallback.entryFee).toString(),
    date: parsedDate,
    registered: args['registered'] is int
        ? args['registered'] as int
        : fallback.registered,
    capacity:
        args['capacity'] is int ? args['capacity'] as int : fallback.capacity,
    color: fallback.color,
    winnerName: args['winnerName']?.toString(),
    winnerDeckName: args['winnerDeckName']?.toString(),
  );
}

Color _avatarColor(String value) {
  return switch (value) {
    'W' => const Color(0xFFE94560),
    'J' => HDTColors.info,
    _ => HDTColors.warning,
  };
}

String _longDate(DateTime date) {
  const months = [
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  if (date.month < 5 || date.month > 12) {
    return '${date.day}/${date.month}/${date.year}';
  }
  return '${months[date.month - 5]} ${date.day}, ${date.year}';
}
