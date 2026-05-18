import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/tournament_summary.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/tournament_repository.dart';

const _demoRoster = [
  TournamentRegistrationSummary(
    id: 'demo-reg-001',
    tournamentId: 'demo-tourney',
    playerId: 'demo-player-001',
    playerName: 'Hansel',
    deckId: 'demo-deck-001',
    deckName: 'Cobalt Dragoon Rush',
    paymentStatus: 'paid',
    registrationStatus: 'active',
    registeredAt: null,
  ),
  TournamentRegistrationSummary(
    id: 'demo-reg-002',
    tournamentId: 'demo-tourney',
    playerId: 'demo-player-002',
    playerName: 'Mardika',
    deckId: 'demo-deck-002',
    deckName: 'Wizard Rod Balance',
    paymentStatus: 'paid',
    registrationStatus: 'active',
    registeredAt: null,
  ),
  TournamentRegistrationSummary(
    id: 'demo-reg-003',
    tournamentId: 'demo-tourney',
    playerId: 'demo-player-003',
    playerName: 'Nadia',
    deckId: 'demo-deck-003',
    deckName: 'Phoenix Wing Attack',
    paymentStatus: 'paid',
    registrationStatus: 'active',
    registeredAt: null,
  ),
  TournamentRegistrationSummary(
    id: 'demo-reg-004',
    tournamentId: 'demo-tourney',
    playerId: 'demo-player-004',
    playerName: 'Bayu',
    deckId: 'demo-deck-004',
    deckName: 'Hells Scythe Stamina',
    paymentStatus: 'paid',
    registrationStatus: 'active',
    registeredAt: null,
  ),
  TournamentRegistrationSummary(
    id: 'demo-reg-005',
    tournamentId: 'demo-tourney',
    playerId: 'demo-player-005',
    playerName: 'Raka',
    deckId: 'demo-deck-005',
    deckName: 'Dran Buster CX',
    paymentStatus: 'paid',
    registrationStatus: 'active',
    registeredAt: null,
  ),
  TournamentRegistrationSummary(
    id: 'demo-reg-006',
    tournamentId: 'demo-tourney',
    playerId: 'demo-player-006',
    playerName: 'Sinta',
    deckId: 'demo-deck-006',
    deckName: 'Knight Shield Defense',
    paymentStatus: 'paid',
    registrationStatus: 'active',
    registeredAt: null,
  ),
  TournamentRegistrationSummary(
    id: 'demo-reg-007',
    tournamentId: 'demo-tourney',
    playerId: 'demo-player-007',
    playerName: 'Dimas',
    deckId: 'demo-deck-007',
    deckName: 'Shark Edge Low Flat',
    paymentStatus: 'paid',
    registrationStatus: 'active',
    registeredAt: null,
  ),
  TournamentRegistrationSummary(
    id: 'demo-reg-008',
    tournamentId: 'demo-tourney',
    playerId: 'demo-player-008',
    playerName: 'Clara',
    deckId: 'demo-deck-008',
    deckName: 'Unicorn Sting Balance',
    paymentStatus: 'paid',
    registrationStatus: 'active',
    registeredAt: null,
  ),
];

const _demoBracketRounds = [
  BracketRoundSummary(
    id: 'round-1',
    index: 1,
    matches: [
      BracketMatchNode(
        id: 'm-001',
        tournamentId: 'demo-tourney',
        roundId: 'round-1',
        roundIndex: 1,
        bracketPosition: 1,
        matchCode: 'M-001',
        status: 'completed',
        playerAName: 'Hansel',
        playerBName: 'Mardika',
        winnerName: 'Hansel',
        finalScore: '4-2',
        bye: false,
      ),
      BracketMatchNode(
        id: 'm-002',
        tournamentId: 'demo-tourney',
        roundId: 'round-1',
        roundIndex: 1,
        bracketPosition: 2,
        matchCode: 'M-002',
        status: 'completed',
        playerAName: 'Nadia',
        playerBName: 'Bayu',
        winnerName: 'Nadia',
        finalScore: '4-1',
        bye: false,
      ),
      BracketMatchNode(
        id: 'm-003',
        tournamentId: 'demo-tourney',
        roundId: 'round-1',
        roundIndex: 1,
        bracketPosition: 3,
        matchCode: 'M-003',
        status: 'ready',
        playerAName: 'Raka',
        playerBName: 'Sinta',
        winnerName: null,
        finalScore: null,
        bye: false,
      ),
      BracketMatchNode(
        id: 'm-004',
        tournamentId: 'demo-tourney',
        roundId: 'round-1',
        roundIndex: 1,
        bracketPosition: 4,
        matchCode: 'M-004',
        status: 'completed',
        playerAName: 'Dimas',
        playerBName: 'Clara',
        winnerName: 'Clara',
        finalScore: 'BYE',
        bye: true,
      ),
    ],
  ),
  BracketRoundSummary(
    id: 'round-2',
    index: 2,
    matches: [
      BracketMatchNode(
        id: 'm-001',
        tournamentId: 'demo-tourney',
        roundId: 'round-2',
        roundIndex: 2,
        bracketPosition: 1,
        matchCode: 'R2-M001',
        status: 'ready',
        playerAName: 'Hansel',
        playerBName: 'Nadia',
        winnerName: null,
        finalScore: null,
        bye: false,
      ),
      BracketMatchNode(
        id: 'm-002',
        tournamentId: 'demo-tourney',
        roundId: 'round-2',
        roundIndex: 2,
        bracketPosition: 2,
        matchCode: 'R2-M002',
        status: 'waitingOpponent',
        playerAName: 'TBD',
        playerBName: 'Clara',
        winnerName: null,
        finalScore: null,
        bye: false,
      ),
    ],
  ),
  BracketRoundSummary(
    id: 'round-3',
    index: 3,
    matches: [
      BracketMatchNode(
        id: 'm-001',
        tournamentId: 'demo-tourney',
        roundId: 'round-3',
        roundIndex: 3,
        bracketPosition: 1,
        matchCode: 'FINAL',
        status: 'waitingOpponent',
        playerAName: 'TBD',
        playerBName: 'TBD',
        winnerName: null,
        finalScore: null,
        bye: false,
      ),
    ],
  ),
];

const _demoStageRules = _GroupStageRules(
  stageName: 'Stage 1',
  format: 'Group Round Robin',
  groupCount: 4,
  playersPerGroup: 8,
  advancePerGroup: 4,
  pointRule: 'Win +3 . Draw +1 . Loss +0',
  tiebreaker: 'Match Win % -> Point Diff -> Head-to-head -> Sudden Death',
);

const _demoStageGroups = [
  _StageGroup(
    name: 'Group A',
    status: 'ROUND 3 / 7',
    standings: [
      _GroupStanding('Hansel', 3, 0, 9, 8, true),
      _GroupStanding('Nadia', 2, 1, 6, 4, true),
      _GroupStanding('Raka', 2, 1, 6, 2, true),
      _GroupStanding('Clara', 1, 2, 3, -1, true),
      _GroupStanding('Bayu', 1, 2, 3, -3, false),
      _GroupStanding('Sinta', 0, 3, 0, -10, false),
    ],
    matches: [
      _GroupMatch('A-013', 'Hansel', 'Clara', 'Arena 01', 'NOW', 'ready'),
      _GroupMatch('A-014', 'Nadia', 'Raka', 'Arena 02', 'NEXT', 'queued'),
      _GroupMatch('A-015', 'Bayu', 'Sinta', 'Arena 03', '12:45', 'queued'),
    ],
  ),
  _StageGroup(
    name: 'Group B',
    status: 'ROUND 2 / 7',
    standings: [
      _GroupStanding('Dimas', 2, 0, 6, 6, true),
      _GroupStanding('Mardika', 2, 0, 6, 5, true),
      _GroupStanding('Taro', 1, 1, 3, 0, true),
      _GroupStanding('Putri', 1, 1, 3, -1, true),
      _GroupStanding('Gerhana', 0, 2, 0, -4, false),
      _GroupStanding('Kevin', 0, 2, 0, -6, false),
    ],
    matches: [
      _GroupMatch('B-009', 'Dimas', 'Putri', 'Arena 04', 'NOW', 'ready'),
      _GroupMatch('B-010', 'Mardika', 'Taro', 'Arena 05', 'NEXT', 'queued'),
      _GroupMatch('B-011', 'Gerhana', 'Kevin', 'Arena 06', '12:50', 'queued'),
    ],
  ),
];

const _demoRoundRobinPlayers = [
  'Hansel',
  'Nadia',
  'Raka',
  'Clara',
  'Bayu',
  'Sinta',
];

const _demoRoundRobinCells = [
  ['-', '4-2', '13:10', 'NOW', 'TBD', 'TBD'],
  ['2-4', '-', 'NEXT', 'TBD', '4-1', 'TBD'],
  ['TBD', 'NEXT', '-', '4-3', 'TBD', 'TBD'],
  ['NOW', 'TBD', '3-4', '-', 'TBD', '4-0'],
  ['TBD', '1-4', 'TBD', 'TBD', '-', '12:45'],
  ['TBD', 'TBD', 'TBD', '0-4', '12:45', '-'],
];

const _demoDoubleElimSections = [
  _DoubleElimSection(
    title: 'Upper Bracket',
    subtitle: 'Winner path',
    rounds: [
      _DoubleElimRound(
        title: 'UB R1',
        matches: [
          _DoubleElimMatch(
              'UB-01', 'Hansel', 'Nadia', 'Hansel', '4-2', 'completed'),
          _DoubleElimMatch('UB-02', 'Raka', 'Clara', null, null, 'ready'),
        ],
      ),
      _DoubleElimRound(
        title: 'UB Final',
        matches: [
          _DoubleElimMatch(
              'UBF', 'Hansel', 'Winner UB-02', null, null, 'waiting'),
        ],
      ),
    ],
  ),
  _DoubleElimSection(
    title: 'Lower Bracket',
    subtitle: 'One loss path',
    rounds: [
      _DoubleElimRound(
        title: 'LB R1',
        matches: [
          _DoubleElimMatch(
              'LB-01', 'Nadia', 'Loser UB-02', null, null, 'waiting'),
        ],
      ),
      _DoubleElimRound(
        title: 'LB Final',
        matches: [
          _DoubleElimMatch(
              'LBF', 'Winner LB-01', 'Loser UBF', null, null, 'waiting'),
        ],
      ),
    ],
  ),
  _DoubleElimSection(
    title: 'Grand Final',
    subtitle: 'Bracket reset enabled',
    rounds: [
      _DoubleElimRound(
        title: 'GF',
        matches: [
          _DoubleElimMatch(
              'GF-01', 'Winner UBF', 'Winner LBF', null, null, 'waiting'),
          _DoubleElimMatch(
              'GF-RESET', 'If Needed', 'Bracket Reset', null, null, 'locked'),
        ],
      ),
    ],
  ),
];

class _DoubleElimSection {
  const _DoubleElimSection({
    required this.title,
    required this.subtitle,
    required this.rounds,
  });

  final String title;
  final String subtitle;
  final List<_DoubleElimRound> rounds;
}

class _DoubleElimRound {
  const _DoubleElimRound({required this.title, required this.matches});

  final String title;
  final List<_DoubleElimMatch> matches;
}

class _DoubleElimMatch {
  const _DoubleElimMatch(
    this.code,
    this.playerA,
    this.playerB,
    this.winner,
    this.score,
    this.status,
  );

  final String code;
  final String playerA;
  final String playerB;
  final String? winner;
  final String? score;
  final String status;
}

List<BracketRoundSummary> _buildSingleEliminationPreview(
  List<TournamentRegistrationSummary> roster,
) {
  final players = _previewPlayerNames(roster);
  if (players.length < 2) return _demoBracketRounds;
  final bracketSize = _previewPowerOfTwo(players.length);
  final rounds = _previewRoundCount(bracketSize);
  final padded = [
    ...players,
    for (var i = players.length; i < bracketSize; i++) 'BYE',
  ];

  return [
    for (var round = 1; round <= rounds; round++)
      BracketRoundSummary(
        id: 'preview-round-$round',
        index: round,
        matches: [
          for (var i = 0; i < bracketSize ~/ math.pow(2, round); i++)
            _singlePreviewMatch(
              round: round,
              position: i + 1,
              playerA: round == 1 ? padded[i * 2] : 'TBD',
              playerB: round == 1 ? padded[(i * 2) + 1] : 'TBD',
            ),
        ],
      ),
  ];
}

BracketMatchNode _singlePreviewMatch({
  required int round,
  required int position,
  required String playerA,
  required String playerB,
}) {
  final hasBye = playerA == 'BYE' || playerB == 'BYE';
  final hasPlayers = playerA != 'TBD' && playerB != 'TBD';
  final winner = hasBye ? (playerA == 'BYE' ? playerB : playerA) : null;
  final code = round == 1
      ? 'M-${position.toString().padLeft(3, '0')}'
      : 'R$round-M${position.toString().padLeft(3, '0')}';
  return BracketMatchNode(
    id: 'preview-r$round-m$position',
    tournamentId: 'preview',
    roundId: 'preview-round-$round',
    roundIndex: round,
    bracketPosition: position,
    matchCode: code,
    status: hasBye
        ? 'completed'
        : hasPlayers
            ? 'ready'
            : 'waitingOpponent',
    playerAName: playerA,
    playerBName: playerB,
    winnerName: winner,
    finalScore: hasBye ? 'BYE' : null,
    bye: hasBye,
  );
}

List<_DoubleElimSection> _buildDoubleEliminationPreview(
  List<TournamentRegistrationSummary> roster,
) {
  final players = _previewPlayerNames(roster);
  if (players.length < 2) return _demoDoubleElimSections;
  final bracketSize = _previewPowerOfTwo(players.length);
  final upperRounds = _previewRoundCount(bracketSize);
  final padded = [
    ...players,
    for (var i = players.length; i < bracketSize; i++) 'BYE',
  ];

  final upper = [
    for (var round = 1; round <= upperRounds; round++)
      _DoubleElimRound(
        title: round == upperRounds ? 'UB Final' : 'UB R$round',
        matches: [
          for (var i = 0; i < bracketSize ~/ math.pow(2, round); i++)
            _DoubleElimMatch(
              round == upperRounds
                  ? 'UBF'
                  : 'UB-$round${(i + 1).toString().padLeft(2, '0')}',
              round == 1 ? padded[i * 2] : _winnerLabel('UB', round - 1, i),
              round == 1
                  ? padded[(i * 2) + 1]
                  : _winnerLabel('UB', round - 1, i + 1),
              null,
              null,
              round == 1 ? 'ready' : 'waiting',
            ),
        ],
      ),
  ];

  final lowerRounds = <_DoubleElimRound>[];
  var lowerRound = 1;
  for (var upperRound = 1; upperRound < upperRounds; upperRound++) {
    final matchCount = math.max(
      1,
      bracketSize ~/ math.pow(2, upperRound + 2),
    );
    for (var phase = 0; phase < 2; phase++) {
      lowerRounds.add(
        _DoubleElimRound(
          title: lowerRound == ((upperRounds - 1) * 2)
              ? 'LB Final'
              : 'LB R$lowerRound',
          matches: [
            for (var i = 0; i < matchCount; i++)
              _DoubleElimMatch(
                lowerRound == ((upperRounds - 1) * 2)
                    ? 'LBF'
                    : 'LB-$lowerRound${(i + 1).toString().padLeft(2, '0')}',
                phase == 0
                    ? _loserLabel('UB', upperRound, i)
                    : _winnerLabel('LB', lowerRound - 1, i),
                phase == 0
                    ? _loserLabel('UB', upperRound, i + matchCount)
                    : _loserLabel('UB', upperRound + 1, i),
                null,
                null,
                'waiting',
              ),
          ],
        ),
      );
      lowerRound++;
    }
  }

  return [
    _DoubleElimSection(
      title: 'Upper Bracket',
      subtitle: 'Winner path dari seed utama',
      rounds: upper,
    ),
    _DoubleElimSection(
      title: 'Lower Bracket',
      subtitle: 'Pemain gugur setelah kalah kedua',
      rounds: lowerRounds,
    ),
    const _DoubleElimSection(
      title: 'Grand Final',
      subtitle: 'Bracket reset enabled',
      rounds: [
        _DoubleElimRound(
          title: 'GF',
          matches: [
            _DoubleElimMatch(
              'GF-01',
              'Winner UBF',
              'Winner LBF',
              null,
              null,
              'waiting',
            ),
            _DoubleElimMatch(
              'GF-RESET',
              'If Needed',
              'Bracket Reset',
              null,
              null,
              'locked',
            ),
          ],
        ),
      ],
    ),
  ];
}

List<String> _previewPlayerNames(List<TournamentRegistrationSummary> roster) {
  final ready = roster.where((item) => item.readyForBracket).toList();
  final source = ready.length >= 2 ? ready : roster;
  return [
    for (final item in source)
      item.playerName.trim().isEmpty ? 'Player' : item.playerName.trim(),
  ];
}

int _previewPowerOfTwo(int value) {
  var size = 1;
  while (size < value) {
    size *= 2;
  }
  return size < 2 ? 2 : size;
}

int _previewRoundCount(int bracketSize) {
  var count = 0;
  var size = bracketSize;
  while (size > 1) {
    count++;
    size ~/= 2;
  }
  return count;
}

String _winnerLabel(String bracket, int round, int index) {
  return 'Winner $bracket R$round-${index + 1}';
}

String _loserLabel(String bracket, int round, int index) {
  return 'Loser $bracket R$round-${index + 1}';
}

class _GroupStageRules {
  const _GroupStageRules({
    required this.stageName,
    required this.format,
    required this.groupCount,
    required this.playersPerGroup,
    required this.advancePerGroup,
    required this.pointRule,
    required this.tiebreaker,
  });

  final String stageName;
  final String format;
  final int groupCount;
  final int playersPerGroup;
  final int advancePerGroup;
  final String pointRule;
  final String tiebreaker;
}

class _StageGroup {
  const _StageGroup({
    required this.name,
    required this.status,
    required this.standings,
    required this.matches,
  });

  final String name;
  final String status;
  final List<_GroupStanding> standings;
  final List<_GroupMatch> matches;
}

class _GroupStanding {
  const _GroupStanding(
    this.name,
    this.win,
    this.loss,
    this.points,
    this.diff,
    this.advancing,
  );

  final String name;
  final int win;
  final int loss;
  final int points;
  final int diff;
  final bool advancing;
}

class _GroupMatch {
  const _GroupMatch(
    this.code,
    this.playerA,
    this.playerB,
    this.arena,
    this.callTime,
    this.status,
  );

  final String code;
  final String playerA;
  final String playerB;
  final String arena;
  final String callTime;
  final String status;
}

class TournamentOpsScreen extends ConsumerStatefulWidget {
  const TournamentOpsScreen({super.key});

  @override
  ConsumerState<TournamentOpsScreen> createState() =>
      _TournamentOpsScreenState();
}

class _TournamentOpsScreenState extends ConsumerState<TournamentOpsScreen> {
  final _arena = TextEditingController(text: 'Arena 01');
  final Set<String> _selectedJudgeIds = {};
  String? _selectedTournamentId;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _arena.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
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
            Text('COMMUNITY ADMIN', style: HDTText.overline(size: 9)),
            Text('TOURNAMENT OPS', style: HDTText.display(size: 20)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/admin/tournaments/new'),
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('NEW'),
          ),
          const SizedBox(width: HDTSpace.sm),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const _PermissionNotice(
          text:
              'Belum bisa membaca sesi admin saat ini. Silakan coba refresh halaman.',
        ),
        data: (user) {
          if (user == null) {
            return _LoginRequired(
              onLogin: () => Navigator.pushNamed(context, '/signin'),
            );
          }
          if (!user.isCommunityAdminCompatible) {
            return _PermissionNotice(
              text:
                  'Role akun ini ${user.role}. Tournament ops hanya untuk admin komunitas atau admin platform.',
            );
          }
          return _content();
        },
      ),
    );
  }

  Widget _content() {
    final tournaments = ref.watch(liveTournamentsProvider);
    final judges = ref.watch(assignableJudgesProvider);
    return tournaments.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const _PermissionNotice(
        text:
            'Belum bisa membaca daftar tournament saat ini. Silakan coba refresh halaman.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            onCreate: () =>
                Navigator.pushNamed(context, '/admin/tournaments/new'),
          );
        }
        final selected = _selectedTournament(items);
        final registrations =
            ref.watch(tournamentRegistrationsProvider(selected.id));
        final bracket = ref.watch(tournamentBracketProvider(selected.id));
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          children: [
            _TournamentPicker(
              tournaments: items,
              selectedId: selected.id,
              onSelected: (id) => setState(() {
                _selectedTournamentId = id;
                _error = null;
              }),
            ),
            const SizedBox(height: HDTSpace.lg),
            registrations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => judges.when(
                loading: () => _opsPanel(
                  selected: selected,
                  roster: const [],
                  judges: const [],
                  bracket: bracket,
                  dataNotice:
                      'Roster belum bisa dimuat. Tampilan demo ditampilkan sementara.',
                ),
                error: (_, __) => _opsPanel(
                  selected: selected,
                  roster: const [],
                  judges: const [],
                  bracket: bracket,
                  dataNotice:
                      'Data live belum bisa dimuat. Tampilan demo ditampilkan sementara.',
                ),
                data: (judgeList) => _opsPanel(
                  selected: selected,
                  roster: const [],
                  judges: judgeList,
                  bracket: bracket,
                  dataNotice:
                      'Roster belum bisa dimuat. Tampilan demo ditampilkan sementara.',
                ),
              ),
              data: (roster) {
                return judges.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _opsPanel(
                    selected: selected,
                    roster: roster,
                    judges: const [],
                    bracket: bracket,
                    dataNotice:
                        'Daftar juri belum bisa dimuat. Tampilan demo tetap tersedia.',
                  ),
                  data: (judgeList) => _opsPanel(
                    selected: selected,
                    roster: roster,
                    judges: judgeList,
                    bracket: bracket,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  TournamentSummary _selectedTournament(List<TournamentSummary> tournaments) {
    final currentId = _selectedTournamentId;
    if (currentId != null) {
      for (final tournament in tournaments) {
        if (tournament.id == currentId) return tournament;
      }
    }
    return tournaments.first;
  }

  Widget _opsPanel({
    required TournamentSummary selected,
    required List<TournamentRegistrationSummary> roster,
    required List<AssignableJudge> judges,
    required AsyncValue<List<BracketRoundSummary>> bracket,
    String? dataNotice,
  }) {
    final demoRoster = roster.isEmpty;
    final visibleRoster = demoRoster ? _demoRoster : roster;
    final ready = visibleRoster.where((item) => item.readyForBracket).toList();
    final bracketSeedRoster = ready.length >= 2 ? ready : visibleRoster;
    final singlePreview = _buildSingleEliminationPreview(bracketSeedRoster);
    final doublePreview = _buildDoubleEliminationPreview(bracketSeedRoster);
    final selectedJudgeIds = _effectiveJudgeIds(judges);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminCommandHero(
          tournament: selected,
          totalRegistrations: visibleRoster.length,
          readyRegistrations: ready.length,
          judgeCount: judges.isEmpty ? 2 : judges.length,
          onCreateTournament: () =>
              Navigator.pushNamed(context, '/admin/tournaments/new'),
          onManageJudges: () =>
              Navigator.pushNamed(context, '/community/judges'),
        ),
        if (dataNotice != null) ...[
          const SizedBox(height: HDTSpace.md),
          _Notice(text: dataNotice, color: HDTColors.warning),
        ],
        if (_error != null) ...[
          const SizedBox(height: HDTSpace.md),
          _Notice(text: _error!, color: HDTColors.danger),
        ],
        const SizedBox(height: HDTSpace.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1060;
            final setupPanel = _RoundSetupPanel(
              arena: _arena,
              judges: judges,
              selectedJudgeIds: selectedJudgeIds,
              readyCount: ready.length,
              busy: _busy,
              demoMode: demoRoster,
              onJudgeSelected: (judge, selected) {
                setState(() {
                  selected
                      ? _selectedJudgeIds.add(judge.uid)
                      : _selectedJudgeIds.remove(judge.uid);
                });
              },
              onGenerate: !demoRoster &&
                      ready.length >= 2 &&
                      judges.isNotEmpty &&
                      !_busy
                  ? () => _generateMatches(
                        tournament: selected,
                        readyCount: ready.length,
                        judges: judges,
                      )
                  : null,
              onGenerateTopCut: !demoRoster && judges.isNotEmpty && !_busy
                  ? () => _generateTopCut(
                        tournament: selected,
                        judges: judges,
                      )
                  : null,
            );
            final bracketPanel = bracket.when(
              loading: () => const _BoardLoading(),
              error: (error, _) => _BracketBoard(
                rounds: singlePreview,
                demo: true,
              ),
              data: (rounds) => _BracketBoard(
                rounds: rounds.isEmpty ? singlePreview : rounds,
                demo: rounds.isEmpty,
              ),
            );
            const groupPanel = _GroupStageBoard(
              rules: _demoStageRules,
              groups: _demoStageGroups,
            );
            if (!wide) {
              return Column(
                children: [
                  setupPanel,
                  const SizedBox(height: HDTSpace.lg),
                  groupPanel,
                  const SizedBox(height: HDTSpace.lg),
                  const _RoundRobinMatrixBoard(
                    players: _demoRoundRobinPlayers,
                    cells: _demoRoundRobinCells,
                  ),
                  const SizedBox(height: HDTSpace.lg),
                  _DoubleEliminationBoard(sections: doublePreview),
                  const SizedBox(height: HDTSpace.lg),
                  bracketPanel,
                ],
              );
            }
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 360, child: setupPanel),
                    const SizedBox(width: HDTSpace.lg),
                    const Expanded(child: groupPanel),
                  ],
                ),
                const SizedBox(height: HDTSpace.lg),
                const _RoundRobinMatrixBoard(
                  players: _demoRoundRobinPlayers,
                  cells: _demoRoundRobinCells,
                ),
                const SizedBox(height: HDTSpace.lg),
                _DoubleEliminationBoard(sections: doublePreview),
                const SizedBox(height: HDTSpace.lg),
                bracketPanel,
              ],
            );
          },
        ),
        const SizedBox(height: HDTSpace.xl),
        _RosterList(roster: visibleRoster, demo: demoRoster),
      ],
    );
  }

  Set<String> _effectiveJudgeIds(List<AssignableJudge> judges) {
    if (_selectedJudgeIds.isNotEmpty) return _selectedJudgeIds;
    if (judges.isEmpty) return const {};
    return {judges.first.uid};
  }

  Future<void> _generateMatches({
    required TournamentSummary tournament,
    required int readyCount,
    required List<AssignableJudge> judges,
  }) async {
    final ids = _effectiveJudgeIds(judges);
    final namesById = {
      for (final judge in judges) judge.uid: judge.displayName
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final count = await ref
          .read(tournamentRepositoryProvider)
          .generateFirstRoundMatches(
            tournamentId: tournament.id,
            arenas: [
              JudgeArenaAssignment(
                name: _arena.text,
                judgeIds: ids.toList(),
                judgeNames: [for (final id in ids) namesById[id] ?? 'Judge'],
              ),
            ],
            matchPointTarget: 4,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$count match round robin dibuat dari $readyCount peserta aktif.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Belum bisa generate Round 1. Pastikan roster sudah paid active dan juri sudah dipilih.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generateTopCut({
    required TournamentSummary tournament,
    required List<AssignableJudge> judges,
  }) async {
    final ids = _effectiveJudgeIds(judges);
    final namesById = {
      for (final judge in judges) judge.uid: judge.displayName
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final count = await ref
          .read(tournamentRepositoryProvider)
          .generateDoubleEliminationTopCut(
            tournamentId: tournament.id,
            arenas: [
              JudgeArenaAssignment(
                name: _arena.text,
                judgeIds: ids.toList(),
                judgeNames: [for (final id in ids) namesById[id] ?? 'Judge'],
              ),
            ],
            matchPointTarget: 4,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count match upper bracket stage 2 dibuat.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Top cut belum bisa dibuat. Pastikan round robin sudah punya standing dan juri sudah dipilih.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _TournamentPicker extends StatelessWidget {
  const _TournamentPicker({
    required this.tournaments,
    required this.selectedId,
    required this.onSelected,
  });

  final List<TournamentSummary> tournaments;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final tournament = tournaments[index];
          final selected = tournament.id == selectedId;
          return InkWell(
            onTap: () => onSelected(tournament.id),
            borderRadius: HDTR.lg,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(HDTSpace.md),
              decoration: hdtAccentCard(
                accentColor: selected ? HDTColors.accent : HDTColors.s3,
                highlighted: selected,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tournament.status.toUpperCase(),
                      style: HDTText.overline(size: 8)),
                  const Spacer(),
                  Text(
                    tournament.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.display(size: 18),
                  ),
                  Text(
                    tournament.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.mono(size: 10, color: HDTColors.text3),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: HDTSpace.md),
        itemCount: tournaments.length,
      ),
    );
  }
}

class _AdminCommandHero extends StatelessWidget {
  const _AdminCommandHero({
    required this.tournament,
    required this.totalRegistrations,
    required this.readyRegistrations,
    required this.judgeCount,
    required this.onCreateTournament,
    required this.onManageJudges,
  });

  final TournamentSummary tournament;
  final int totalRegistrations;
  final int readyRegistrations;
  final int judgeCount;
  final VoidCallback onCreateTournament;
  final VoidCallback onManageJudges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.lg,
        border: Border.all(color: HDTColors.accent.withValues(alpha: .48)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COMMUNITY CONTROL ROOM', style: HDTText.overline(size: 11)),
              const SizedBox(height: HDTSpace.xs),
              Text(
                tournament.name.toUpperCase(),
                maxLines: wide ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: HDTText.display(size: wide ? 42 : 32),
              ),
              const SizedBox(height: HDTSpace.xs),
              Text(
                '${tournament.bracketType.toUpperCase()} . ${tournament.location.toUpperCase()} . ${tournament.status.toUpperCase()}',
                style: HDTText.mono(size: 12, color: HDTColors.text3),
              ),
            ],
          );
          final actions = Wrap(
            spacing: HDTSpace.sm,
            runSpacing: HDTSpace.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onManageJudges,
                icon: const Icon(Icons.verified_user_outlined, size: 16),
                label: const Text('MANAGE JURI'),
              ),
              ElevatedButton.icon(
                onPressed: onCreateTournament,
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('NEW TOURNEY'),
              ),
            ],
          );
          final metrics = Wrap(
            spacing: HDTSpace.md,
            runSpacing: HDTSpace.md,
            children: [
              _BigMetric('ROSTER', totalRegistrations.toString()),
              _BigMetric('READY', readyRegistrations.toString()),
              _BigMetric('JURI', judgeCount.toString()),
            ],
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: HDTSpace.lg),
                metrics,
                const SizedBox(height: HDTSpace.lg),
                actions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 5, child: title),
              const SizedBox(width: HDTSpace.xl),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    metrics,
                    const SizedBox(height: HDTSpace.lg),
                    actions,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoundSetupPanel extends StatelessWidget {
  const _RoundSetupPanel({
    required this.arena,
    required this.judges,
    required this.selectedJudgeIds,
    required this.readyCount,
    required this.busy,
    required this.demoMode,
    required this.onJudgeSelected,
    required this.onGenerate,
    required this.onGenerateTopCut,
  });

  final TextEditingController arena;
  final List<AssignableJudge> judges;
  final Set<String> selectedJudgeIds;
  final int readyCount;
  final bool busy;
  final bool demoMode;
  final void Function(AssignableJudge judge, bool selected) onJudgeSelected;
  final VoidCallback? onGenerate;
  final VoidCallback? onGenerateTopCut;

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
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HDTColors.accent.withValues(alpha: .18),
                  borderRadius: HDTR.md,
                  border: Border.all(color: HDTColors.accent),
                ),
                child: const Icon(Icons.account_tree_outlined, size: 20),
              ),
              const SizedBox(width: HDTSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STAGE 1 ROUND ROBIN',
                        style: HDTText.overline(size: 10)),
                    Text(
                      demoMode
                          ? '$readyCount demo player'
                          : '$readyCount paid active player',
                      style: HDTText.mono(size: 10, color: HDTColors.text3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: HDTSpace.lg),
          TextField(
            controller: arena,
            decoration: const InputDecoration(
              labelText: 'Arena untuk generated match',
              prefixIcon: Icon(Icons.stadium_outlined),
            ),
          ),
          const SizedBox(height: HDTSpace.md),
          if (judges.isEmpty)
            const _Notice(
              color: HDTColors.warning,
              text:
                  'Belum ada akun judge. Buka Manage Juri dan assign pemain menjadi juri terlebih dahulu.',
            )
          else
            Wrap(
              spacing: HDTSpace.sm,
              runSpacing: HDTSpace.sm,
              children: [
                for (final judge in judges)
                  FilterChip(
                    selected: selectedJudgeIds.contains(judge.uid),
                    label: Text(judge.displayName.toUpperCase()),
                    avatar: const Icon(Icons.verified_user_outlined, size: 14),
                    onSelected: (selected) => onJudgeSelected(judge, selected),
                  ),
              ],
            ),
          if (demoMode) ...[
            const SizedBox(height: HDTSpace.md),
            const _Notice(
              color: HDTColors.info,
              text:
                  'Mode demo aktif karena roster live belum tersedia. Generate bracket akan aktif setelah data paid active masuk.',
            ),
          ],
          const SizedBox(height: HDTSpace.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGenerate,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.playlist_add_check_circle_outlined),
              label: Text(busy ? 'GENERATING...' : 'GENERATE ROUND ROBIN'),
            ),
          ),
          const SizedBox(height: HDTSpace.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onGenerateTopCut,
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('GENERATE STAGE 2 TOP CUT'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardLoading extends StatelessWidget {
  const _BoardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      alignment: Alignment.center,
      decoration: hdtCard(),
      child: const CircularProgressIndicator(),
    );
  }
}

class _GroupStageBoard extends StatelessWidget {
  const _GroupStageBoard({
    required this.rules,
    required this.groups,
  });

  final _GroupStageRules rules;
  final List<_StageGroup> groups;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(HDTSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GROUP STAGE CONTROL', style: HDTText.overline(size: 10)),
                const SizedBox(height: HDTSpace.xs),
                Text(
                  '${rules.stageName.toUpperCase()} . ${rules.format.toUpperCase()}',
                  style: HDTText.display(size: 24),
                ),
                const SizedBox(height: HDTSpace.md),
                Wrap(
                  spacing: HDTSpace.sm,
                  runSpacing: HDTSpace.sm,
                  children: [
                    _RulePill('${rules.groupCount} GROUP'),
                    _RulePill('${rules.playersPerGroup} PLAYER/GROUP'),
                    _RulePill('TOP ${rules.advancePerGroup} ADVANCE'),
                    _RulePill(rules.pointRule),
                  ],
                ),
                const SizedBox(height: HDTSpace.md),
                Text(
                  'Tiebreaker: ${rules.tiebreaker}',
                  style: HDTText.mono(size: 10, color: HDTColors.text3),
                ),
              ],
            ),
          ),
          hdtDivider(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(HDTSpace.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < groups.length; i++) ...[
                  _StageGroupCard(group: groups[i]),
                  if (i != groups.length - 1)
                    const SizedBox(width: HDTSpace.md),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RulePill extends StatelessWidget {
  const _RulePill(this.text);

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
      child: Text(text.toUpperCase(), style: HDTText.overline(size: 8)),
    );
  }
}

class _StageGroupCard extends StatelessWidget {
  const _StageGroupCard({required this.group});

  final _StageGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.lg,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(HDTSpace.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(group.name.toUpperCase(),
                      style: HDTText.display(size: 20)),
                ),
                Text(group.status,
                    style:
                        HDTText.mono(size: 10, color: HDTColors.accentHover)),
              ],
            ),
          ),
          hdtDivider(),
          Padding(
            padding: const EdgeInsets.all(HDTSpace.md),
            child: Column(
              children: [
                _StandingHeader(),
                const SizedBox(height: HDTSpace.xs),
                for (var i = 0; i < group.standings.length; i++)
                  _StandingRow(rank: i + 1, standing: group.standings[i]),
              ],
            ),
          ),
          hdtDivider(),
          Padding(
            padding: const EdgeInsets.all(HDTSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT CALLS', style: HDTText.overline(size: 9)),
                const SizedBox(height: HDTSpace.sm),
                for (final match in group.matches) _GroupMatchRow(match: match),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 30, child: Text('#', style: HDTText.overline(size: 8))),
        Expanded(child: Text('PLAYER', style: HDTText.overline(size: 8))),
        SizedBox(width: 34, child: Text('W', style: HDTText.overline(size: 8))),
        SizedBox(width: 34, child: Text('L', style: HDTText.overline(size: 8))),
        SizedBox(
            width: 42, child: Text('PTS', style: HDTText.overline(size: 8))),
        SizedBox(
            width: 42, child: Text('DIFF', style: HDTText.overline(size: 8))),
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.rank, required this.standing});

  final int rank;
  final _GroupStanding standing;

  @override
  Widget build(BuildContext context) {
    final color = standing.advancing ? HDTColors.success : HDTColors.text3;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(rank.toString().padLeft(2, '0'),
                style: HDTText.mono(size: 10, color: color)),
          ),
          Expanded(
            child: Text(
              standing.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.body(size: 12, color: HDTColors.text),
            ),
          ),
          _StandingCell(standing.win.toString()),
          _StandingCell(standing.loss.toString()),
          _StandingCell(standing.points.toString()),
          _StandingCell(
              standing.diff > 0 ? '+${standing.diff}' : '${standing.diff}'),
        ],
      ),
    );
  }
}

class _StandingCell extends StatelessWidget {
  const _StandingCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Text(value, style: HDTText.mono(size: 10, color: HDTColors.text2)),
    );
  }
}

class _GroupMatchRow extends StatelessWidget {
  const _GroupMatchRow({required this.match});

  final _GroupMatch match;

  @override
  Widget build(BuildContext context) {
    final live = match.status == 'ready';
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.sm),
      decoration: BoxDecoration(
        color: live ? HDTColors.accent.withValues(alpha: .16) : HDTColors.s1,
        borderRadius: HDTR.sm,
        border: Border.all(color: live ? HDTColors.accent : HDTColors.s2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(match.code, style: HDTText.mono(size: 10)),
          ),
          Expanded(
            child: Text(
              '${match.playerA} vs ${match.playerB}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.body(size: 12),
            ),
          ),
          Text('${match.arena} . ${match.callTime}',
              style: HDTText.mono(
                  size: 9,
                  color: live ? HDTColors.accentHover : HDTColors.text3)),
        ],
      ),
    );
  }
}

class _RoundRobinMatrixBoard extends StatelessWidget {
  const _RoundRobinMatrixBoard({
    required this.players,
    required this.cells,
  });

  final List<String> players;
  final List<List<String>> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(HDTSpace.lg),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: HDTSpace.lg,
              runSpacing: HDTSpace.md,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ROUND ROBIN BRACKET',
                        style: HDTText.overline(size: 10)),
                    const SizedBox(height: HDTSpace.xs),
                    Text('ALL-PLAY-ALL MATRIX',
                        style: HDTText.display(size: 24)),
                  ],
                ),
                const Wrap(
                  spacing: HDTSpace.sm,
                  runSpacing: HDTSpace.sm,
                  children: [
                    _RulePill('1 MATCH PER PAIR'),
                    _RulePill('LIVE CELLS'),
                    _RulePill('AUTO STANDINGS'),
                  ],
                ),
              ],
            ),
          ),
          hdtDivider(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(HDTSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 132),
                    for (final player in players)
                      _MatrixHeaderCell(player: player),
                  ],
                ),
                for (var row = 0; row < players.length; row++)
                  Row(
                    children: [
                      _MatrixNameCell(player: players[row]),
                      for (var col = 0; col < players.length; col++)
                        _MatrixResultCell(value: cells[row][col]),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixHeaderCell extends StatelessWidget {
  const _MatrixHeaderCell({required this.player});

  final String player;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 38,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(left: 6, bottom: 6),
      decoration: const BoxDecoration(
        color: HDTColors.s2,
        borderRadius: HDTR.sm,
      ),
      child: Text(
        player.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: HDTText.overline(size: 8, color: HDTColors.text2),
      ),
    );
  }
}

class _MatrixNameCell extends StatelessWidget {
  const _MatrixNameCell({required this.player});

  final String player;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 42,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: HDTSpace.md),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.sm,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Text(
        player.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: HDTText.body(size: 12, weight: FontWeight.w700),
      ),
    );
  }
}

class _MatrixResultCell extends StatelessWidget {
  const _MatrixResultCell({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final isSelf = value == '-';
    final isLive = value == 'NOW';
    final isNext = value == 'NEXT';
    final isPending = value == 'TBD';
    final color = isSelf
        ? HDTColors.s2
        : isLive
            ? HDTColors.accent
            : isNext
                ? HDTColors.warning
                : isPending
                    ? HDTColors.s3
                    : HDTColors.success;
    return Container(
      width: 96,
      height: 42,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(left: 6, bottom: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isSelf ? .26 : .16),
        borderRadius: HDTR.sm,
        border: Border.all(color: color.withValues(alpha: .75)),
      ),
      child: Text(
        value,
        style: HDTText.mono(
          size: 10,
          color: isPending || isSelf ? HDTColors.text3 : color,
        ),
      ),
    );
  }
}

class _DoubleEliminationBoard extends StatelessWidget {
  const _DoubleEliminationBoard({required this.sections});

  final List<_DoubleElimSection> sections;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(HDTSpace.lg),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: HDTSpace.lg,
              runSpacing: HDTSpace.md,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DOUBLE ELIMINATION BRACKET',
                        style: HDTText.overline(size: 10)),
                    const SizedBox(height: HDTSpace.xs),
                    Text('UPPER / LOWER / GRAND FINAL',
                        style: HDTText.display(size: 24)),
                  ],
                ),
                const Wrap(
                  spacing: HDTSpace.sm,
                  runSpacing: HDTSpace.sm,
                  children: [
                    _RulePill('2 LIVES'),
                    _RulePill('LOWER DROP'),
                    _RulePill('BRACKET RESET'),
                  ],
                ),
              ],
            ),
          ),
          hdtDivider(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(HDTSpace.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  _DoubleElimSectionColumn(section: sections[i]),
                  if (i != sections.length - 1)
                    const SizedBox(width: HDTSpace.lg),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleElimSectionColumn extends StatelessWidget {
  const _DoubleElimSectionColumn({required this.section});

  final _DoubleElimSection section;

  @override
  Widget build(BuildContext context) {
    final accent = section.title.startsWith('Upper')
        ? HDTColors.success
        : section.title.startsWith('Lower')
            ? HDTColors.warning
            : HDTColors.accent;
    final treeWidth = _DoubleElimSectionTree.widthFor(section);
    return Container(
      width: math.max(330, treeWidth + (HDTSpace.md * 2)),
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.lg,
        border: Border.all(color: accent.withValues(alpha: .58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title.toUpperCase(),
              style: HDTText.display(size: 20, color: accent)),
          Text(section.subtitle,
              style: HDTText.mono(size: 10, color: HDTColors.text3)),
          const SizedBox(height: HDTSpace.md),
          _DoubleElimSectionTree(section: section, accent: accent),
        ],
      ),
    );
  }
}

class _DoubleElimSectionTree extends StatelessWidget {
  const _DoubleElimSectionTree({
    required this.section,
    required this.accent,
  });

  final _DoubleElimSection section;
  final Color accent;

  static const double cardW = 250;
  static const double cardH = 112;
  static const double colGap = 54;
  static const double baseGap = 22;
  static const double labelTop = 28;

  static double widthFor(_DoubleElimSection section) {
    if (section.rounds.isEmpty) return cardW;
    return (section.rounds.length * cardW) +
        ((section.rounds.length - 1) * colGap);
  }

  @override
  Widget build(BuildContext context) {
    final positions = _buildTreePositions(
      section.rounds.map((round) => round.matches.length).toList(),
      cardH: cardH,
      baseGap: baseGap,
      cardW: cardW,
      colGap: colGap,
    );
    return SizedBox(
      width: positions.width,
      height: positions.height + labelTop,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: labelTop,
            child: CustomPaint(
              painter: _BracketTreePainter(
                positions: positions,
                cardWidth: cardW,
                cardHeight: cardH,
                color: accent.withValues(alpha: .82),
              ),
            ),
          ),
          for (var r = 0; r < section.rounds.length; r++)
            Positioned(
              left: positions.xForRound(r),
              top: 0,
              width: cardW,
              child: Text(
                section.rounds[r].title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HDTText.overline(size: 9, color: accent),
              ),
            ),
          for (var r = 0; r < section.rounds.length; r++)
            for (var m = 0; m < section.rounds[r].matches.length; m++)
              Positioned(
                left: positions.xForRound(r),
                top: positions.yFor(r, m) + labelTop,
                width: cardW,
                height: cardH,
                child: _DoubleElimMatchTile(
                  match: section.rounds[r].matches[m],
                ),
              ),
        ],
      ),
    );
  }
}

class _DoubleElimMatchTile extends StatelessWidget {
  const _DoubleElimMatchTile({required this.match});

  final _DoubleElimMatch match;

  @override
  Widget build(BuildContext context) {
    final ready = match.status == 'ready';
    final done = match.status == 'completed';
    final locked = match.status == 'locked';
    final color = done
        ? HDTColors.success
        : ready
            ? HDTColors.accent
            : locked
                ? HDTColors.s3
                : HDTColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: HDTR.sm,
        border: Border.all(color: color.withValues(alpha: .72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(match.code,
                      style: HDTText.overline(size: 9, color: color))),
              Text(match.score ?? match.status.toUpperCase(),
                  style: HDTText.mono(size: 9, color: color)),
            ],
          ),
          const SizedBox(height: HDTSpace.sm),
          _ElimPlayerLine(
            name: match.playerA,
            winner: match.winner == match.playerA,
          ),
          const SizedBox(height: 6),
          _ElimPlayerLine(
            name: match.playerB,
            winner: match.winner == match.playerB,
          ),
        ],
      ),
    );
  }
}

class _ElimPlayerLine extends StatelessWidget {
  const _ElimPlayerLine({required this.name, required this.winner});

  final String name;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          winner ? Icons.arrow_upward : Icons.remove,
          size: 13,
          color: winner ? HDTColors.success : HDTColors.text3,
        ),
        const SizedBox(width: HDTSpace.sm),
        Expanded(
          child: Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HDTText.body(
              size: 12,
              color: winner ? HDTColors.text : HDTColors.text2,
            ),
          ),
        ),
      ],
    );
  }
}

class _BracketBoard extends StatelessWidget {
  const _BracketBoard({required this.rounds, this.demo = false});

  final List<BracketRoundSummary> rounds;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return const _Notice(
        color: HDTColors.warning,
        text:
            'Bracket belum dibuat. Generate Round 1 setelah peserta sudah paid active.',
      );
    }
    final completed = rounds
        .expand((round) => round.matches)
        .where((match) => match.completed)
        .length;
    final total = rounds.expand((round) => round.matches).length;
    final active = rounds
        .expand((round) => round.matches)
        .where((match) => !match.completed && !match.waiting)
        .length;
    final winnerMatches = rounds
        .expand((round) => round.matches)
        .where((match) => match.completed && match.winnerName != null)
        .toList();
    final champion =
        winnerMatches.isEmpty ? null : winnerMatches.last.winnerName;
    return Container(
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.lg,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(HDTSpace.lg),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: HDTSpace.lg,
              runSpacing: HDTSpace.md,
              children: [
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LIVE BRACKET', style: HDTText.overline(size: 10)),
                      Text(
                        demo
                            ? 'DEMO BRACKET FLOW'
                            : champion == null
                                ? 'SINGLE ELIMINATION FLOW'
                                : 'WINNER ${champion.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HDTText.display(size: 24),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: HDTSpace.sm,
                  runSpacing: HDTSpace.sm,
                  children: [
                    _MiniMetric('ROUND', rounds.length.toString()),
                    _MiniMetric('LIVE', active.toString()),
                    _MiniMetric('DONE', '$completed/$total'),
                    if (demo) const _MiniMetric('MODE', 'DEMO'),
                  ],
                ),
              ],
            ),
          ),
          hdtDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              HDTSpace.lg,
              HDTSpace.xl,
              HDTSpace.lg,
              HDTSpace.lg,
            ),
            child: _SingleEliminationTree(rounds: rounds),
          ),
        ],
      ),
    );
  }
}

class _SingleEliminationTree extends StatelessWidget {
  const _SingleEliminationTree({required this.rounds});

  final List<BracketRoundSummary> rounds;

  static const double cardW = 286;
  static const double cardH = 132;
  static const double colGap = 74;
  static const double baseGap = 26;

  @override
  Widget build(BuildContext context) {
    final positions = _buildTreePositions(
      rounds.map((round) => round.matches.length).toList(),
      cardH: cardH,
      baseGap: baseGap,
      cardW: cardW,
      colGap: colGap,
    );
    final width = positions.width;
    final height = positions.height + 42;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: 32,
              child: CustomPaint(
                painter: _BracketTreePainter(
                  positions: positions,
                  cardWidth: cardW,
                  cardHeight: cardH,
                  color: HDTColors.s3,
                ),
              ),
            ),
            for (var r = 0; r < rounds.length; r++)
              Positioned(
                left: positions.xForRound(r),
                top: 0,
                width: cardW,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rounds[r].label.toUpperCase(),
                        style: HDTText.display(size: 18),
                      ),
                    ),
                    Text(
                      '${rounds[r].matches.length}',
                      style: HDTText.mono(size: 10, color: HDTColors.text3),
                    ),
                  ],
                ),
              ),
            for (var r = 0; r < rounds.length; r++)
              for (var m = 0; m < rounds[r].matches.length; m++)
                Positioned(
                  left: positions.xForRound(r),
                  top: positions.yFor(r, m) + 32,
                  width: cardW,
                  height: cardH,
                  child: _BracketMatchTile(match: rounds[r].matches[m]),
                ),
          ],
        ),
      ),
    );
  }
}

_TreePositions _buildTreePositions(
  List<int> counts, {
  required double cardH,
  required double baseGap,
  required double cardW,
  required double colGap,
}) {
  final yByRound = <List<double>>[];
  final baseStep = cardH + baseGap;
  for (var r = 0; r < counts.length; r++) {
    final multiplier = math.pow(2, r).toDouble();
    final step = baseStep * multiplier;
    final offset = ((step - cardH) / 2).clamp(0.0, double.infinity).toDouble();
    yByRound.add([
      for (var i = 0; i < counts[r]; i++) offset + (step * i),
    ]);
  }
  final firstCount = counts.isEmpty ? 1 : counts.first;
  final height = math.max(cardH, (firstCount * baseStep) - baseGap);
  final width = counts.isEmpty
      ? cardW
      : (counts.length * cardW) + ((counts.length - 1) * colGap);
  return _TreePositions(
    yByRound: yByRound,
    cardW: cardW,
    colGap: colGap,
    width: width,
    height: height,
  );
}

class _TreePositions {
  const _TreePositions({
    required this.yByRound,
    required this.cardW,
    required this.colGap,
    required this.width,
    required this.height,
  });

  final List<List<double>> yByRound;
  final double cardW;
  final double colGap;
  final double width;
  final double height;

  double xForRound(int round) => round * (cardW + colGap);

  double yFor(int round, int match) => yByRound[round][match];
}

class _BracketTreePainter extends CustomPainter {
  const _BracketTreePainter({
    required this.positions,
    required this.cardWidth,
    required this.cardHeight,
    required this.color,
  });

  final _TreePositions positions;
  final double cardWidth;
  final double cardHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;
    for (var r = 1; r < positions.yByRound.length; r++) {
      final current = positions.yByRound[r];
      final previous = positions.yByRound[r - 1];
      for (var i = 0; i < current.length; i++) {
        final targetY = current[i] + (cardHeight / 2);
        final targetX = positions.xForRound(r);
        final elbowX = targetX - (positions.colGap / 2);
        for (final sourceIndex in [i * 2, (i * 2) + 1]) {
          if (sourceIndex >= previous.length) continue;
          final sourceX = positions.xForRound(r - 1) + cardWidth;
          final sourceY = previous[sourceIndex] + (cardHeight / 2);
          final path = Path()
            ..moveTo(sourceX, sourceY)
            ..lineTo(elbowX, sourceY)
            ..lineTo(elbowX, targetY)
            ..lineTo(targetX, targetY);
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BracketTreePainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.color != color ||
        oldDelegate.cardWidth != cardWidth ||
        oldDelegate.cardHeight != cardHeight;
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(
        horizontal: HDTSpace.md,
        vertical: HDTSpace.sm,
      ),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.sm,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HDTText.overline(size: 8)),
          const SizedBox(height: 2),
          Text(value, style: HDTText.display(size: 18)),
        ],
      ),
    );
  }
}

class _BracketMatchTile extends StatelessWidget {
  const _BracketMatchTile({required this.match});

  final BracketMatchNode match;

  @override
  Widget build(BuildContext context) {
    final color = match.completed
        ? HDTColors.success
        : match.waiting
            ? HDTColors.warning
            : HDTColors.accent;
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: color.withValues(alpha: .78)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(match.matchCode,
                    style: HDTText.overline(size: 9, color: color)),
              ),
              Text(match.bye ? 'BYE' : match.status.toUpperCase(),
                  style: HDTText.mono(size: 9, color: color)),
            ],
          ),
          const SizedBox(height: HDTSpace.sm),
          _BracketPlayerLine(
            label: 'A',
            name: match.playerAName,
            deck: match.playerADeckName,
            winner: match.winnerName == match.playerAName,
          ),
          const SizedBox(height: 6),
          _BracketPlayerLine(
            label: 'B',
            name: match.playerBName,
            deck: match.playerBDeckName,
            winner: match.winnerName == match.playerBName,
          ),
          if (match.completed) ...[
            const SizedBox(height: HDTSpace.sm),
            Text(
              'WINNER ${match.winnerName ?? '-'} . ${match.finalScore ?? '-'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.overline(size: 8, color: HDTColors.success),
            ),
            if (match.winnerDeckName != null &&
                match.winnerDeckName!.trim().isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                'DECK ${match.winnerDeckName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HDTText.mono(size: 9, color: HDTColors.text2),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BracketPlayerLine extends StatelessWidget {
  const _BracketPlayerLine({
    required this.label,
    required this.name,
    required this.deck,
    required this.winner,
  });

  final String label;
  final String name;
  final String deck;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: winner ? HDTColors.success : HDTColors.s2,
            borderRadius: HDTR.sm,
          ),
          child: Text(label, style: HDTText.overline(size: 8)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HDTText.body(
                  size: 12,
                  color: winner ? HDTColors.text : HDTColors.text2,
                ),
              ),
              if (deck != '-' && deck.trim().isNotEmpty)
                Text(
                  deck,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.mono(size: 9, color: HDTColors.text3),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RosterList extends StatelessWidget {
  const _RosterList({required this.roster, this.demo = false});

  final List<TournamentRegistrationSummary> roster;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    if (roster.isEmpty) {
      return const _Notice(
        color: HDTColors.warning,
        text: 'Belum ada peserta yang mendaftar di tournament ini.',
      );
    }
    return Container(
      decoration: hdtCard(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(HDTSpace.lg),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                        demo
                            ? 'DEMO REGISTRATION ROSTER'
                            : 'REGISTRATION ROSTER',
                        style: HDTText.overline(size: 10))),
                Text('${roster.length} PLAYER',
                    style: HDTText.mono(size: 11, color: HDTColors.text3)),
              ],
            ),
          ),
          for (final item in roster) _RosterRow(item: item),
        ],
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.item});

  final TournamentRegistrationSummary item;

  @override
  Widget build(BuildContext context) {
    final ready = item.readyForBracket;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HDTSpace.lg,
        vertical: HDTSpace.md,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: HDTColors.s2)),
      ),
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
            child: Text(
              item.playerName.isEmpty ? '?' : item.playerName[0].toUpperCase(),
              style: HDTText.display(size: 14),
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.playerName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.body(size: 13)),
                Text(item.deckName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
          _StatusPill(ready ? 'READY' : item.paymentStatus.toUpperCase(),
              ready: ready),
        ],
      ),
    );
  }
}

class _BigMetric extends StatelessWidget {
  const _BigMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HDTText.overline(size: 9)),
          const SizedBox(height: HDTSpace.xs),
          Text(value, style: HDTText.display(size: 30)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label, {required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final color = ready ? HDTColors.success : HDTColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: HDTR.sm,
        border: Border.all(color: color),
      ),
      child: Text(label, style: HDTText.overline(size: 8, color: color)),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtAccentCard(accentColor: color),
      child: Text(text, style: HDTText.body(size: 12, color: HDTColors.text2)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(HDTSpace.xl),
        decoration: hdtCard(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 40),
            const SizedBox(height: HDTSpace.md),
            Text('BELUM ADA TOURNAMENT', style: HDTText.display(size: 24)),
            const SizedBox(height: HDTSpace.sm),
            Text(
              'Buat tournament terlebih dahulu, lalu peserta bisa daftar dan roster akan muncul di sini.',
              textAlign: TextAlign.center,
              style: HDTText.body(size: 12, color: HDTColors.text2),
            ),
            const SizedBox(height: HDTSpace.lg),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('BUAT TOURNAMENT'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onLogin,
        child: const Text('LOGIN ADMIN KOMUNITAS'),
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(HDTSpace.xl),
        decoration: hdtCard(),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: HDTText.body(color: HDTColors.text2, height: 1.5),
        ),
      ),
    );
  }
}
