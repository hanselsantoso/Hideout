import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/tournament_repository.dart';

class JudgeScoreScreen extends ConsumerStatefulWidget {
  const JudgeScoreScreen({super.key});

  @override
  ConsumerState<JudgeScoreScreen> createState() => _JudgeScoreScreenState();
}

class _JudgeScoreScreenState extends ConsumerState<JudgeScoreScreen> {
  int _a = 0;
  int _b = 0;
  int _round = 1;
  bool _submitted = false;
  bool _busy = false;
  String? _battleId;
  String? _error;
  final _rounds = <_RoundLog>[];

  bool get _done => _a >= 4 || _b >= 4;
  bool get _canCancel => _rounds.isNotEmpty && !_submitted && !_busy;
  String _winner(_MatchContext match) =>
      _a > _b ? match.playerAName : match.playerBName;

  void _score(String side, String finish, int points) {
    if (_done || _submitted) return;
    setState(() {
      if (side == 'A') {
        _a += points;
      } else {
        _b += points;
      }
      _rounds.add(_RoundLog(_round, side, finish, points, _a, _b));
      _round++;
    });
  }

  void _cancelLastRound() {
    if (!_canCancel) return;
    setState(() {
      final last = _rounds.removeLast();
      if (last.side == 'A') {
        _a -= last.points;
      } else {
        _b -= last.points;
      }
      _round--;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Input round terakhir dibatalkan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = _MatchContext.fromRoute(context);
    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${match.arena.toUpperCase()} - ${match.matchCode}',
                style: HDTText.overline(size: 9)),
            Text('INPUT SKOR JURI', style: HDTText.display(size: 20)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/juri/matches'),
            icon: const Icon(Icons.assignment_ind_outlined, size: 16),
            label: const Text('MATCHES'),
          ),
          const SizedBox(width: HDTSpace.sm),
          TextButton.icon(
            onPressed: _canCancel ? _cancelLastRound : null,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('CANCEL LAST'),
          ),
          const SizedBox(width: HDTSpace.sm),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(HDTSpace.lg),
            children: [
              _scoreboard(match),
              if (_error != null) ...[
                const SizedBox(height: HDTSpace.md),
                _ErrorNotice(text: _error!),
              ],
              const SizedBox(height: HDTSpace.xl),
              if (_submitted)
                _SubmittedPanel(
                  winner: _winner(match),
                  score: '$_a - $_b',
                  battleId: _battleId,
                  persisted: match.canPersist,
                )
              else ...[
                _controls(match),
                const SizedBox(height: HDTSpace.xl),
                _roundLog(match),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _submitted
          ? null
          : Container(
              padding: const EdgeInsets.all(HDTSpace.lg),
              decoration: const BoxDecoration(
                color: HDTColors.bg,
                border: Border(top: BorderSide(color: HDTColors.s2)),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Row(children: [
                      OutlinedButton.icon(
                        onPressed: _canCancel ? _cancelLastRound : null,
                        icon: const Icon(Icons.replay_outlined, size: 16),
                        label: const Text('CANCEL / RELAUNCH'),
                      ),
                      const SizedBox(width: HDTSpace.md),
                      Text(
                        _done ? 'MATCH SELESAI' : 'FIRST TO 4 POINTS',
                        style: HDTText.overline(
                            size: 10,
                            color: _done ? HDTColors.success : HDTColors.text3),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed:
                            _done && !_busy ? () => _submit(match) : null,
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_outlined),
                        label:
                            Text(_busy ? 'SUBMITTING' : 'SUBMIT FINAL SCORE'),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _submit(_MatchContext match) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!match.canPersist) {
        setState(() => _submitted = true);
        return;
      }
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) {
        Navigator.pushNamed(context, '/signin');
        return;
      }
      final winnerId = _a > _b ? match.playerAId : match.playerBId;
      final winnerName = _a > _b ? match.playerAName : match.playerBName;
      final battleId =
          await ref.read(tournamentRepositoryProvider).submitMatchScore(
                tournamentId: match.tournamentId,
                roundId: match.roundId,
                matchId: match.matchId,
                judgeId: user.uid,
                playerAId: match.playerAId,
                playerAName: match.playerAName,
                playerBId: match.playerBId,
                playerBName: match.playerBName,
                winnerId: winnerId,
                winnerName: winnerName,
                scoreA: _a,
                scoreB: _b,
                rounds: _rounds.map((round) => round.toMap()).toList(),
              );
      if (!mounted) return;
      setState(() {
        _battleId = battleId;
        _submitted = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Skor belum tersimpan. Periksa koneksi, lalu coba submit ulang.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _scoreboard(_MatchContext match) {
    return Row(children: [
      Expanded(
        child: _PlayerScore(
          name: match.playerAName,
          id: match.playerAId,
          deck: match.playerADeckName,
          score: _a,
          color: HDTColors.info,
          winner: _done && _a > _b,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(HDTSpace.lg),
        child: Column(children: [
          Text('VS', style: HDTText.display(size: 24, color: HDTColors.text3)),
          const SizedBox(height: HDTSpace.xs),
          Text('BO5', style: HDTText.overline(size: 9)),
        ]),
      ),
      Expanded(
        child: _PlayerScore(
          name: match.playerBName,
          id: match.playerBId,
          deck: match.playerBDeckName,
          score: _b,
          color: HDTColors.warning,
          winner: _done && _b > _a,
        ),
      ),
    ]);
  }

  Widget _controls(_MatchContext match) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      return Wrap(
        spacing: HDTSpace.lg,
        runSpacing: HDTSpace.lg,
        children: [
          SizedBox(
            width: wide
                ? (constraints.maxWidth - HDTSpace.lg) / 2
                : constraints.maxWidth,
            child: _ScorePanel(
              title: '${match.playerAName.toUpperCase()} MENANG ROUND',
              color: HDTColors.info,
              onScore: (finish, points) => _score('A', finish, points),
            ),
          ),
          SizedBox(
            width: wide
                ? (constraints.maxWidth - HDTSpace.lg) / 2
                : constraints.maxWidth,
            child: _ScorePanel(
              title: '${match.playerBName.toUpperCase()} MENANG ROUND',
              color: HDTColors.warning,
              onScore: (finish, points) => _score('B', finish, points),
            ),
          ),
        ],
      );
    });
  }

  Widget _roundLog(_MatchContext match) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('ROUND LOG', style: HDTText.overline(size: 10))),
          TextButton.icon(
            onPressed: _canCancel ? _cancelLastRound : null,
            icon: const Icon(Icons.close, size: 14),
            label: const Text('CANCEL LAST'),
          ),
          const SizedBox(width: HDTSpace.sm),
          Text('ROUND $_round', style: HDTText.mono(size: 11)),
        ]),
        const SizedBox(height: HDTSpace.md),
        if (_rounds.isEmpty)
          Text('Belum ada skor.', style: HDTText.body(color: HDTColors.text3)),
        for (final log in _rounds.reversed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: HDTSpace.sm),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: HDTColors.s2)),
            ),
            child: Row(children: [
              Text('R${log.round}', style: HDTText.mono(size: 11)),
              const SizedBox(width: HDTSpace.md),
              Expanded(
                child: Text(
                  '${log.side == 'A' ? match.playerAName : match.playerBName} - ${log.finish} +${log.points}',
                  style: HDTText.body(size: 12),
                ),
              ),
              Text('${log.scoreA} - ${log.scoreB}',
                  style: HDTText.display(size: 14)),
            ]),
          ),
      ]),
    );
  }
}

class _RoundLog {
  const _RoundLog(
    this.round,
    this.side,
    this.finish,
    this.points,
    this.scoreA,
    this.scoreB,
  );
  final int round;
  final String side;
  final String finish;
  final int points;
  final int scoreA;
  final int scoreB;

  Map<String, dynamic> toMap() {
    return {
      'round': round,
      'side': side,
      'finish': finish,
      'points': points,
      'scoreA': scoreA,
      'scoreB': scoreB,
    };
  }
}

class _MatchContext {
  final String tournamentId;
  final String roundId;
  final String matchId;
  final String matchCode;
  final String arena;
  final String playerAId;
  final String playerAName;
  final String playerADeckName;
  final String playerBId;
  final String playerBName;
  final String playerBDeckName;

  const _MatchContext({
    required this.tournamentId,
    required this.roundId,
    required this.matchId,
    required this.matchCode,
    required this.arena,
    required this.playerAId,
    required this.playerAName,
    required this.playerADeckName,
    required this.playerBId,
    required this.playerBName,
    required this.playerBDeckName,
  });

  bool get canPersist =>
      tournamentId.isNotEmpty && roundId.isNotEmpty && matchId.isNotEmpty;

  factory _MatchContext.fromRoute(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    return _MatchContext(
      tournamentId: (args['tournamentId'] ?? '').toString(),
      roundId: (args['roundId'] ?? '').toString(),
      matchId: (args['matchId'] ?? '').toString(),
      matchCode: (args['matchCode'] ?? 'MATCH M-018').toString(),
      arena: (args['arena'] ?? 'Arena 02').toString(),
      playerAId: (args['playerAId'] ?? 'player-a').toString(),
      playerAName: (args['playerAName'] ?? 'HANSEL').toString(),
      playerADeckName: (args['playerADeckName'] ?? 'Phantom Reaper').toString(),
      playerBId: (args['playerBId'] ?? 'player-b').toString(),
      playerBName: (args['playerBName'] ?? 'MARDIKA').toString(),
      playerBDeckName: (args['playerBDeckName'] ?? 'Void Bastion').toString(),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  const _PlayerScore({
    required this.name,
    required this.id,
    required this.deck,
    required this.score,
    required this.color,
    required this.winner,
  });

  final String name;
  final String id;
  final String deck;
  final int score;
  final Color color;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(accentColor: color, highlighted: winner),
      child: Column(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: color, borderRadius: HDTR.md),
          child: Center(
              child: Text(name[0],
                  style: HDTText.display(size: 24, color: Colors.white))),
        ),
        const SizedBox(height: HDTSpace.md),
        Text(name, style: HDTText.display(size: 22)),
        Text(id, style: HDTText.mono(size: 11)),
        const SizedBox(height: HDTSpace.xs),
        Text(deck, style: HDTText.body(size: 12, color: HDTColors.text3)),
        const SizedBox(height: HDTSpace.md),
        Text('$score', style: HDTText.display(size: 60, color: color)),
        if (winner)
          Text('WINNER',
              style: HDTText.overline(size: 10, color: HDTColors.success)),
      ]),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.title,
    required this.color,
    required this.onScore,
  });

  final String title;
  final Color color;
  final void Function(String finish, int points) onScore;

  @override
  Widget build(BuildContext context) {
    final options = [
      ('SPIN', 1, Icons.sync),
      ('BURST', 2, Icons.bolt),
      ('OVER', 2, Icons.arrow_outward),
      ('XTREME', 3, Icons.auto_awesome),
    ];
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: HDTText.overline(size: 10, color: HDTColors.text)),
        const SizedBox(height: HDTSpace.md),
        Wrap(
          spacing: HDTSpace.sm,
          runSpacing: HDTSpace.sm,
          children: [
            for (final option in options)
              SizedBox(
                width: 132,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () => onScore(option.$1, option.$2),
                  icon: Icon(option.$3, color: color, size: 15),
                  label: Text('${option.$1} +${option.$2}'),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}

class _SubmittedPanel extends StatelessWidget {
  const _SubmittedPanel({
    required this.winner,
    required this.score,
    required this.persisted,
    this.battleId,
  });
  final String winner;
  final String score;
  final String? battleId;
  final bool persisted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration:
          hdtAccentCard(accentColor: HDTColors.success, highlighted: true),
      child: Column(children: [
        const Icon(Icons.check_circle_outline,
            size: 56, color: HDTColors.success),
        const SizedBox(height: HDTSpace.md),
        Text('SCORE SUBMITTED', style: HDTText.display(size: 32)),
        const SizedBox(height: HDTSpace.sm),
        Text(
            persisted
                ? '$winner menang $score. Battle log tersimpan: ${battleId ?? '-'}'
                : '$winner menang $score. Mode preview aktif, hasil belum disimpan ke match live.',
            textAlign: TextAlign.center,
            style: HDTText.body(color: HDTColors.text2, height: 1.5)),
        const SizedBox(height: HDTSpace.lg),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            '/juri/matches',
          ),
          icon: const Icon(Icons.assignment_ind_outlined, size: 16),
          label: const Text('BACK TO MATCHES'),
        ),
      ]),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String text;

  const _ErrorNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtAccentCard(accentColor: HDTColors.danger),
      child: Row(children: [
        const Icon(Icons.error_outline, color: HDTColors.danger),
        const SizedBox(width: HDTSpace.sm),
        Expanded(
          child:
              Text(text, style: HDTText.body(size: 12, color: HDTColors.text2)),
        ),
      ]),
    );
  }
}
