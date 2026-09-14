import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/tournament_repository.dart';

final judgeCheckedInProvider =
    StreamProvider.family<bool, (String, String)>((ref, params) {
  return ref
      .watch(tournamentRepositoryProvider)
      .watchJudgeCheckedIn(tournamentId: params.$1, judgeId: params.$2);
});

final judgeTournamentNameProvider =
    StreamProvider.family<String, String>((ref, tournamentId) {
  return ref.watch(tournamentRepositoryProvider).watchTournamentName(
        tournamentId,
      );
});

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
            Text('JUDGE CONSOLE', style: HDTText.overline(size: 9)),
            Text('MATCH ASSIGNMENTS', style: HDTText.display(size: 20)),
          ],
        ),
      ),
      body: SafeArea(
        child: matches.when(
          data: (items) {
            final groups = <String, List<JudgeMatchSummary>>{};
            for (final match in items) {
              groups.putIfAbsent(match.tournamentId, () => []).add(match);
            }
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
                if (groups.isEmpty)
                  const _NoJudgeAssignmentsPanel()
                else
                  for (final entry in groups.entries) ...[
                    _JudgeTournamentSection(
                      tournamentId: entry.key,
                      matches: entry.value,
                    ),
                    const SizedBox(height: HDTSpace.lg),
                  ],
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
                    'Judge assignments could not be read. Refresh after the community lead assigns live matches.',
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

class _JudgeTournamentSection extends ConsumerWidget {
  const _JudgeTournamentSection({
    required this.tournamentId,
    required this.matches,
  });

  final String tournamentId;
  final List<JudgeMatchSummary> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final judgeId = user?.uid ?? '';
    final nameAsync = ref.watch(judgeTournamentNameProvider(tournamentId));
    final checkedInAsync =
        ref.watch(judgeCheckedInProvider((tournamentId, judgeId)));
    final regsAsync = ref.watch(tournamentRegistrationsProvider(tournamentId));
    final checkedIn = checkedInAsync.valueOrNull ?? false;
    final registrations =
        regsAsyncValue(regsAsync).where((r) => r.deckVerified).map((r) => r.id).toSet();
    final busy = ref.watch(_checkInBusyProvider);

    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOURNAMENT', style: HDTText.overline(size: 9)),
                    Text(
                      nameAsync.valueOrNull ?? tournamentId,
                      style: HDTText.display(size: 20),
                    ),
                  ],
                ),
              ),
              checkedIn
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: HDTSpace.sm, vertical: HDTSpace.xs),
                      decoration: BoxDecoration(
                        color: HDTColors.success.withValues(alpha: .15),
                        borderRadius: HDTR.sm,
                        border: Border.all(
                            color: HDTColors.success.withValues(alpha: .4)),
                      ),
                      child: Text('ATTENDED',
                          style: HDTText.overline(
                              size: 8, color: HDTColors.success)),
                    )
                  : ElevatedButton.icon(
                      onPressed: busy.contains(tournamentId) || judgeId.isEmpty
                          ? null
                          : () => _checkIn(context, ref, judgeId),
                      icon: const Icon(Icons.how_to_reg_outlined, size: 15),
                      label: const Text('CHECK IN (ABSEN)'),
                    ),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          Text(
            checkedIn
                ? 'Scan and scoring unlocked for this tournament.'
                : 'Check in (absen) on the event day to unlock SCAN and SCORE for this tournament.',
            style: HDTText.body(size: 11, color: HDTColors.text3),
          ),
          const SizedBox(height: HDTSpace.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 980 ? 2 : 1;
              final width =
                  (constraints.maxWidth - ((cols - 1) * HDTSpace.md)) / cols;
              return Wrap(
                spacing: HDTSpace.md,
                runSpacing: HDTSpace.md,
                children: [
                  for (final match in matches)
                    SizedBox(
                      width: width,
                      child: _MatchCard(
                        match: match,
                        judgeCheckedIn: checkedIn,
                        playerAVerified:
                            registrations.contains(match.playerARegistrationId),
                        playerBVerified:
                            registrations.contains(match.playerBRegistrationId),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Iterable<TournamentRegistrationSummary> regsAsyncValue(
          AsyncValue<List<TournamentRegistrationSummary>> regsAsync) =>
      regsAsync.valueOrNull ?? const [];

  Future<void> _checkIn(
      BuildContext context, WidgetRef ref, String judgeId) async {
    ref.read(_checkInBusyProvider.notifier).add(tournamentId);
    try {
      await ref.read(tournamentRepositoryProvider).checkInJudge(
            tournamentId: tournamentId,
            judgeId: judgeId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judge check-in recorded.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Check-in failed. Try again in a moment.')),
      );
    } finally {
      ref.read(_checkInBusyProvider.notifier).remove(tournamentId);
    }
  }
}

final _checkInBusyProvider =
    NotifierProvider<_CheckInBusyNotifier, Set<String>>(
        _CheckInBusyNotifier.new);

class _CheckInBusyNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void add(String value) => state = {...state, value};
  void remove(String value) => state = state.where((e) => e != value).toSet();
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
                      ? 'Matches assigned to the signed-in judge account.'
                      : 'No live assignments yet. Wait for the community lead to generate matches.',
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
                Text('JUDGE START GUIDE',
                    style: HDTText.overline(size: 10, color: HDTColors.info)),
                const SizedBox(height: HDTSpace.sm),
                Text('Work on assigned live matches',
                    style: HDTText.display(size: 24)),
                const SizedBox(height: HDTSpace.sm),
                Text(
                  'Check in (absen) on the event day, then call participants by arena, scan side A and B deck QR to verify decks, and input scores after each match finishes. Scan and scoring stay locked until you check in.',
                  style: HDTText.body(
                    size: 13,
                    color: HDTColors.text2,
                    height: 1.5,
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
          Text('NO ASSIGNMENTS YET', style: HDTText.overline(size: 10)),
          const SizedBox(height: HDTSpace.sm),
          Text('Judge matches appear after generation',
              style: HDTText.display(size: 25)),
          const SizedBox(height: HDTSpace.sm),
          Text(
            'The community lead must select this judge account in Tournament Ops and generate matches from the paid active roster. This page no longer shows sample matches so trial data stays clean.',
            style: HDTText.body(size: 13, color: HDTColors.text2, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final JudgeMatchSummary match;
  final bool judgeCheckedIn;
  final bool playerAVerified;
  final bool playerBVerified;

  const _MatchCard({
    required this.match,
    required this.judgeCheckedIn,
    required this.playerAVerified,
    required this.playerBVerified,
  });

  @override
  Widget build(BuildContext context) {
    final done = match.completed;
    final bothVerified = playerAVerified && playerBVerified;
    final canScore = !done &&
        judgeCheckedIn &&
        bothVerified &&
        match.status != 'waitingOpponent' &&
        match.playerARegistrationId != null &&
        match.playerBRegistrationId != null;
    String? scoreHint;
    if (!done && judgeCheckedIn && !bothVerified) {
      scoreHint = 'Verify both players with SCAN A and SCAN B first.';
    } else if (!done && !judgeCheckedIn) {
      scoreHint = 'Check in (absen) first to unlock actions.';
    }
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
                onPressed: !judgeCheckedIn || match.playerARegistrationId == null
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          '/juri/scan',
                          arguments:
                              match.scanArguments('A', judgeCheckedIn: true),
                        ),
                icon: const Icon(Icons.qr_code_scanner, size: 15),
                label: Text(playerAVerified ? 'RESCAN A' : 'SCAN A'),
              ),
              OutlinedButton.icon(
                onPressed: !judgeCheckedIn || match.playerBRegistrationId == null
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          '/juri/scan',
                          arguments:
                              match.scanArguments('B', judgeCheckedIn: true),
                        ),
                icon: const Icon(Icons.qr_code_scanner, size: 15),
                label: Text(playerBVerified ? 'RESCAN B' : 'SCAN B'),
              ),
              ElevatedButton.icon(
                onPressed: !canScore
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          '/juri/score',
                          arguments: match.scoreArguments(
                            judgeCheckedIn: judgeCheckedIn,
                            playerAVerified: playerAVerified,
                            playerBVerified: playerBVerified,
                          ),
                        ),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('SCORE'),
              ),
            ],
          ),
          if (scoreHint != null) ...[
            const SizedBox(height: HDTSpace.sm),
            Text(scoreHint,
                style: HDTText.body(size: 11, color: HDTColors.warning)),
          ],
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
