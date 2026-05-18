import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/repositories/tournament_repository.dart';

class JudgeMatchesScreen extends ConsumerWidget {
  const JudgeMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(assignedJudgeMatchesProvider);
    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('JURI CONSOLE', style: HDTText.overline(size: 9)),
            Text('MATCH ASSIGNMENTS', style: HDTText.display(size: 20)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/juri/scan'),
            icon: const Icon(Icons.qr_code_scanner, size: 16),
            label: const Text('SCAN'),
          ),
          const SizedBox(width: HDTSpace.sm),
        ],
      ),
      body: SafeArea(
        child: matches.when(
          data: (items) {
            final list = items.isEmpty ? _demoMatches : items;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              children: [
                _HeroSummary(
                  liveCount: list.where((match) => !match.completed).length,
                  demo: items.isEmpty,
                ),
                const SizedBox(height: HDTSpace.lg),
                _JudgeSchedulePanel(matches: list, demo: items.isEmpty),
                const SizedBox(height: HDTSpace.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 980 ? 2 : 1;
                    final width =
                        (constraints.maxWidth - ((cols - 1) * HDTSpace.md)) /
                            cols;
                    return Wrap(
                      spacing: HDTSpace.md,
                      runSpacing: HDTSpace.md,
                      children: [
                        for (final match in list)
                          SizedBox(
                            width: width,
                            child: _MatchCard(match: match),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _HeroSummary(liveCount: _demoMatches.length, demo: true),
              const SizedBox(height: HDTSpace.md),
              const _Notice(
                text:
                    'Match live untuk akun juri ini belum tersedia. Sementara sistem menampilkan assignment demo agar alur scan dan scoring tetap bisa dipreview.',
                color: HDTColors.warning,
              ),
              const SizedBox(height: HDTSpace.lg),
              const _JudgeSchedulePanel(matches: _demoMatches, demo: true),
              const SizedBox(height: HDTSpace.lg),
              for (final match in _demoMatches) ...[
                _MatchCard(match: match),
                const SizedBox(height: HDTSpace.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _JudgeSchedulePanel extends StatelessWidget {
  const _JudgeSchedulePanel({
    required this.matches,
    required this.demo,
  });

  final List<JudgeMatchSummary> matches;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final rows = demo
        ? const [
            _JudgeScheduleRow(
              title: 'HIDEOUT CUP #04',
              time: 'Hari H . 10:00',
              arena: 'Arena 02',
              status: 'READY',
            ),
            _JudgeScheduleRow(
              title: 'East Coast Showdown',
              time: 'Hari H . 13:30',
              arena: 'Arena 03',
              status: 'STANDBY',
            ),
          ]
        : [
            for (final match in matches.take(4))
              _JudgeScheduleRow(
                title: match.matchCode,
                time: match.completed ? 'Selesai' : 'Hari H . Live queue',
                arena: match.arena,
                status: match.status.toUpperCase(),
              ),
          ];
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: HDTColors.success.withValues(alpha: .12),
                  borderRadius: HDTR.md,
                  border: Border.all(
                    color: HDTColors.success.withValues(alpha: .55),
                  ),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: HDTColors.success,
                ),
              ),
              const SizedBox(width: HDTSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('JADWAL JURI', style: HDTText.display(size: 22)),
                    Text(
                      demo
                          ? 'Contoh jadwal assignment sampai data live tersedia.'
                          : 'Turnamen dan arena yang assigned ke akun juri ini.',
                      style: HDTText.body(size: 12, color: HDTColors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

class _JudgeScheduleRow extends StatelessWidget {
  const _JudgeScheduleRow({
    required this.title,
    required this.time,
    required this.arena,
    required this.status,
  });

  final String title;
  final String time;
  final String arena;
  final String status;

  @override
  Widget build(BuildContext context) {
    final live = status == 'READY' || status == 'INPROGRESS';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: HDTSpace.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: HDTText.body(size: 13)),
                Text('$time . ${arena.toUpperCase()}',
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
          Text(
            status,
            style: HDTText.overline(
              size: 8,
              color: live ? HDTColors.success : HDTColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  final int liveCount;
  final bool demo;

  const _HeroSummary({required this.liveCount, required this.demo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(
        accentColor: demo ? HDTColors.warning : HDTColors.accent,
        highlighted: true,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: HDTColors.bg,
              borderRadius: HDTR.md,
              border: Border.all(color: HDTColors.s2),
            ),
            child: Icon(
              demo ? Icons.cloud_off_outlined : Icons.sports_martial_arts,
              color: demo ? HDTColors.warning : HDTColors.accentHover,
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$liveCount MATCH READY',
                    style: HDTText.display(size: 26)),
                Text(
                  demo
                      ? 'Assignment demo aktif sampai match live juri tersedia.'
                      : 'Match yang assigned ke akun juri login.',
                  style: HDTText.body(size: 12, color: HDTColors.text2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final JudgeMatchSummary match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final done = match.completed;
    final canScore = !done &&
        match.status != 'waitingOpponent' &&
        match.playerARegistrationId != null &&
        match.playerBRegistrationId != null;
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(
        accentColor: done ? HDTColors.success : HDTColors.accent,
        highlighted: !done,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(match.arena.toUpperCase(),
                        style: HDTText.overline(size: 9)),
                    Text(match.matchCode, style: HDTText.display(size: 24)),
                  ],
                ),
              ),
              _StatusPill(done ? 'COMPLETED' : match.status.toUpperCase()),
            ],
          ),
          const SizedBox(height: HDTSpace.lg),
          _PlayerLine(
            side: 'A',
            name: match.playerAName,
            deck: match.playerADeck,
          ),
          const SizedBox(height: HDTSpace.sm),
          _PlayerLine(
            side: 'B',
            name: match.playerBName,
            deck: match.playerBDeck,
          ),
          if (done) ...[
            const SizedBox(height: HDTSpace.md),
            hdtDivider(),
            const SizedBox(height: HDTSpace.md),
            Text(
              'WINNER ${match.winnerName ?? '-'} . ${match.finalScore ?? '-'}',
              style: HDTText.overline(size: 10, color: HDTColors.success),
            ),
          ],
          const SizedBox(height: HDTSpace.lg),
          Wrap(
            spacing: HDTSpace.sm,
            runSpacing: HDTSpace.sm,
            children: [
              OutlinedButton.icon(
                onPressed: match.playerARegistrationId == null
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          '/juri/scan',
                          arguments: match.scanArguments('A'),
                        ),
                icon: const Icon(Icons.qr_code_scanner, size: 15),
                label: const Text('SCAN A'),
              ),
              OutlinedButton.icon(
                onPressed: match.playerBRegistrationId == null
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          '/juri/scan',
                          arguments: match.scanArguments('B'),
                        ),
                icon: const Icon(Icons.qr_code_scanner, size: 15),
                label: const Text('SCAN B'),
              ),
              ElevatedButton.icon(
                onPressed: !canScore
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          '/juri/score',
                          arguments: match.scoreArguments,
                        ),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('SCORE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerLine extends StatelessWidget {
  final String side;
  final String name;
  final String deck;

  const _PlayerLine({
    required this.side,
    required this.name,
    required this.deck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(bg: HDTColors.bg),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: HDTColors.s2,
              borderRadius: HDTR.sm,
            ),
            child: Text(side, style: HDTText.display(size: 15)),
          ),
          const SizedBox(width: HDTSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toUpperCase(), style: HDTText.body(size: 13)),
                Text(deck,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill(this.label);

  @override
  Widget build(BuildContext context) {
    final done = label == 'COMPLETED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: (done ? HDTColors.success : HDTColors.accent)
            .withValues(alpha: .14),
        borderRadius: HDTR.sm,
        border: Border.all(color: done ? HDTColors.success : HDTColors.accent),
      ),
      child: Text(
        label,
        style: HDTText.overline(
          size: 8,
          color: done ? HDTColors.success : HDTColors.accentHover,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final Color color;

  const _Notice({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtAccentCard(accentColor: color),
      child: Text(text, style: HDTText.body(size: 12, color: HDTColors.text2)),
    );
  }
}

const _demoMatches = [
  JudgeMatchSummary(
    id: 'demo-m-018',
    tournamentId: '',
    roundId: '',
    matchCode: 'M-018',
    status: 'ready',
    arena: 'Arena 02',
    playerAId: 'hdt-202',
    playerAName: 'Hansel',
    playerADeck: 'Phantom Reaper',
    playerARegistrationId: 'DEMO-QR-TICKET',
    playerBId: 'hdt-007',
    playerBName: 'Mardika',
    playerBDeck: 'Void Bastion',
    playerBRegistrationId: 'DEMO-QR-TICKET',
  ),
  JudgeMatchSummary(
    id: 'demo-m-019',
    tournamentId: '',
    roundId: '',
    matchCode: 'M-019',
    status: 'assigned',
    arena: 'Arena 03',
    playerAId: 'hdt-091',
    playerAName: 'Nadia',
    playerADeck: 'CX Lockdown',
    playerARegistrationId: 'DEMO-QR-TICKET',
    playerBId: 'hdt-044',
    playerBName: 'Bayu',
    playerBDeck: 'Cobalt Rush',
    playerBRegistrationId: 'DEMO-QR-TICKET',
  ),
];
