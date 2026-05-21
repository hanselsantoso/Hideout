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
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              children: [
                _HeroSummary(
                  liveCount: items.where((match) => !match.completed).length,
                  hasAssignments: items.isNotEmpty,
                ),
                const SizedBox(height: HDTSpace.lg),
                const _JudgeGuidePanel(),
                const SizedBox(height: HDTSpace.lg),
                _JudgeSchedulePanel(matches: items),
                const SizedBox(height: HDTSpace.lg),
                if (items.isEmpty)
                  const _NoJudgeAssignmentsPanel()
                else
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
                          for (final match in items)
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
            children: const [
              _HeroSummary(liveCount: 0, hasAssignments: false),
              SizedBox(height: HDTSpace.md),
              _Notice(
                text:
                    'Assignment juri belum bisa dibaca. Refresh setelah ketua komunitas assign match live.',
                color: HDTColors.warning,
              ),
              SizedBox(height: HDTSpace.lg),
              _JudgeGuidePanel(),
              SizedBox(height: HDTSpace.lg),
              _NoJudgeAssignmentsPanel(),
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
  });

  final List<JudgeMatchSummary> matches;

  @override
  Widget build(BuildContext context) {
    final rows = [
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
                      'Turnamen dan arena yang assigned ke akun juri ini.',
                      style: HDTText.body(size: 12, color: HDTColors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          if (rows.isEmpty)
            Text(
              'Belum ada match live untuk akun ini.',
              style: HDTText.body(size: 12, color: HDTColors.text3),
            )
          else
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
  final bool hasAssignments;

  const _HeroSummary({
    required this.liveCount,
    required this.hasAssignments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(
        accentColor: hasAssignments ? HDTColors.accent : HDTColors.info,
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
              hasAssignments
                  ? Icons.sports_martial_arts
                  : Icons.assignment_outlined,
              color: hasAssignments ? HDTColors.accentHover : HDTColors.info,
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
                  hasAssignments
                      ? 'Match yang assigned ke akun juri login.'
                      : 'Belum ada assignment live. Tunggu ketua komunitas generate match.',
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

class _JudgeGuidePanel extends StatelessWidget {
  const _JudgeGuidePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(accentColor: HDTColors.info),
      child: Wrap(
        spacing: HDTSpace.lg,
        runSpacing: HDTSpace.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: HDTColors.info.withValues(alpha: .14),
              borderRadius: HDTR.md,
              border: Border.all(color: HDTColors.info),
            ),
            child:
                const Icon(Icons.rule_folder_outlined, color: HDTColors.info),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PANDUAN AWAL JURI',
                    style: HDTText.overline(size: 10, color: HDTColors.info)),
                const SizedBox(height: HDTSpace.sm),
                Text('Kerjakan match live yang di-assign',
                    style: HDTText.display(size: 24)),
                const SizedBox(height: HDTSpace.sm),
                Text(
                  'Panggil peserta sesuai arena, scan QR deck sisi A dan B, bandingkan deck dengan data registrasi, tolak jika tidak sama, lalu input skor setelah match selesai.',
                  style: HDTText.body(
                    size: 13,
                    color: HDTColors.text2,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/juri/scan'),
            icon: const Icon(Icons.qr_code_scanner, size: 16),
            label: const Text('BUKA SCANNER'),
          ),
        ],
      ),
    );
  }
}

class _NoJudgeAssignmentsPanel extends StatelessWidget {
  const _NoJudgeAssignmentsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BELUM ADA ASSIGNMENT', style: HDTText.overline(size: 10)),
          const SizedBox(height: HDTSpace.sm),
          Text('Match juri akan muncul setelah generate',
              style: HDTText.display(size: 25)),
          const SizedBox(height: HDTSpace.sm),
          Text(
            'Ketua komunitas perlu memilih akun juri ini di Tournament Ops dan generate match dari roster paid active. Halaman ini tidak lagi menampilkan match contoh agar trial data tetap bersih.',
            style: HDTText.body(size: 13, color: HDTColors.text2, height: 1.5),
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
