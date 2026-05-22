import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/tournament_summary.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/tournament_repository.dart';

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
      subtitle: 'Winner path from the main seed',
      rounds: upper,
    ),
    _DoubleElimSection(
      title: 'Lower Bracket',
      subtitle: 'Players are eliminated after their second loss',
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
  String? _registrationBusyId;
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
              'Admin session could not be read right now. Please refresh the page.',
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
                  'This account role is ${user.role}. Tournament ops is only for community admins or platform admins.',
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
            'Tournament list could not be read right now. Please refresh the page.',
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
                      'Roster could not be loaded. Refresh the page before changing tournament setup.',
                ),
                error: (_, __) => _opsPanel(
                  selected: selected,
                  roster: const [],
                  judges: const [],
                  bracket: bracket,
                  dataNotice:
                      'Live data could not be loaded. Refresh the page before changing tournament setup.',
                ),
                data: (judgeList) => _opsPanel(
                  selected: selected,
                  roster: const [],
                  judges: judgeList,
                  bracket: bracket,
                  dataNotice:
                      'Roster could not be loaded. Refresh the page before changing tournament setup.',
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
                        'Judge list could not be loaded. Match generation becomes active after live judge data is available.',
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
    final visibleRoster = roster;
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
          judgeCount: judges.length,
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
              demoMode: false,
              onJudgeSelected: (judge, selected) {
                setState(() {
                  selected
                      ? _selectedJudgeIds.add(judge.uid)
                      : _selectedJudgeIds.remove(judge.uid);
                });
              },
              onGenerate: ready.length >= 2 && judges.isNotEmpty && !_busy
                  ? () => _generateMatches(
                        tournament: selected,
                        readyCount: ready.length,
                        judges: judges,
                      )
                  : null,
              onGenerateTopCut: judges.isNotEmpty && !_busy
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
            final groupSetupPanel = _InteractiveGroupSetupPanel(
              key: ValueKey(
                'groups-${selected.id}-${visibleRoster.map((item) => item.id).join('|')}',
              ),
              roster: visibleRoster,
              demoMode: false,
              busy: _busy,
              onSave: (groups) => _saveGroupDraft(
                tournament: selected,
                groups: groups,
              ),
            );
            final stagedModules = _StagedOpsModules(
              bracketPanel: bracketPanel,
              doublePreview: doublePreview,
            );
            if (!wide) {
              return Column(
                children: [
                  setupPanel,
                  const SizedBox(height: HDTSpace.lg),
                  groupSetupPanel,
                  const SizedBox(height: HDTSpace.lg),
                  const _OpsModuleShelf(),
                  stagedModules,
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
                    Expanded(child: groupSetupPanel),
                  ],
                ),
                const SizedBox(height: HDTSpace.lg),
                const _OpsModuleShelf(),
                stagedModules,
              ],
            );
          },
        ),
        const SizedBox(height: HDTSpace.xl),
        _RosterList(
          roster: visibleRoster,
          demo: false,
          busyRegistrationId: _registrationBusyId,
          onActivate: (registration) => _activateRegistration(
            tournament: selected,
            registration: registration,
          ),
          onWalkOut: (registration) => _markWalkOut(
            tournament: selected,
            registration: registration,
          ),
        ),
      ],
    );
  }

  Set<String> _effectiveJudgeIds(List<AssignableJudge> judges) {
    if (_selectedJudgeIds.isNotEmpty) return _selectedJudgeIds;
    if (judges.isEmpty) return const {};
    return {judges.first.uid};
  }

  Future<void> _saveGroupDraft({
    required TournamentSummary tournament,
    required List<TournamentGroupDraft> groups,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(tournamentRepositoryProvider).saveTournamentGroupDraft(
            tournamentId: tournament.id,
            groups: groups,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Group draft saved. Round robin generation will use this setup.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _activateRegistration({
    required TournamentSummary tournament,
    required TournamentRegistrationSummary registration,
  }) async {
    setState(() {
      _registrationBusyId = registration.id;
      _error = null;
    });
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .activateTournamentRegistration(
            tournamentId: tournament.id,
            registrationId: registration.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${registration.playerName} is now paid active.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _registrationBusyId = null);
    }
  }

  Future<void> _markWalkOut({
    required TournamentSummary tournament,
    required TournamentRegistrationSummary registration,
  }) async {
    setState(() {
      _registrationBusyId = registration.id;
      _error = null;
    });
    try {
      await ref.read(tournamentRepositoryProvider).markRegistrationWalkOut(
            tournamentId: tournament.id,
            registrationId: registration.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${registration.playerName} marked as WO.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _registrationBusyId = null);
    }
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
            '$count round robin matches created from $readyCount active participants.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Round 1 could not be generated. Make sure the roster is paid active and judges are selected.';
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
        SnackBar(
            content: Text('$count upper bracket stage 2 matches created.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Top cut could not be created. Make sure round robin has standings and judges are selected.';
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
                label: const Text('MANAGE JUDGES'),
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
              _BigMetric('JUDGES', judgeCount.toString()),
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
              labelText: 'Arena for generated matches',
              prefixIcon: Icon(Icons.stadium_outlined),
            ),
          ),
          const SizedBox(height: HDTSpace.md),
          if (judges.isEmpty)
            const _Notice(
              color: HDTColors.warning,
              text:
                  'No judge accounts yet. Open Manage Judges and assign players as judges first.',
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
                  'Demo mode is active because the live roster is not available yet. Bracket generation becomes active after paid active data arrives.',
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

class _InteractiveGroupSetupPanel extends StatefulWidget {
  const _InteractiveGroupSetupPanel({
    super.key,
    required this.roster,
    required this.demoMode,
    required this.busy,
    required this.onSave,
  });

  final List<TournamentRegistrationSummary> roster;
  final bool demoMode;
  final bool busy;
  final Future<void> Function(List<TournamentGroupDraft> groups)? onSave;

  @override
  State<_InteractiveGroupSetupPanel> createState() =>
      _InteractiveGroupSetupPanelState();
}

class _InteractiveGroupSetupPanelState
    extends State<_InteractiveGroupSetupPanel> {
  final _groupCount = TextEditingController();
  late List<_GroupDraftState> _groups;
  late List<TournamentRegistrationSummary> _bench;
  late String _rosterKey;

  @override
  void initState() {
    super.initState();
    _resetDraft();
  }

  @override
  void didUpdateWidget(covariant _InteractiveGroupSetupPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextKey = _keyFor(widget.roster);
    if (nextKey != _rosterKey) _resetDraft();
  }

  @override
  void dispose() {
    _groupCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assigned = _groups.fold<int>(
      0,
      (count, group) => count + group.players.length,
    );
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(accentColor: HDTColors.info),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: HDTSpace.md,
            runSpacing: HDTSpace.md,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GROUP BUILDER DRAFT',
                        style:
                            HDTText.overline(size: 10, color: HDTColors.info)),
                    const SizedBox(height: HDTSpace.xs),
                    Text('Set groups without power-of-two limits',
                        style: HDTText.display(size: 25)),
                    const SizedBox(height: HDTSpace.sm),
                    Text(
                      'Community leads can create 3, 4, 5, or any other number of groups, rename groups, move players with drag-and-drop, and place WO players on the bench.',
                      style: HDTText.body(
                        size: 12,
                        color: HDTColors.text2,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: HDTSpace.sm,
                runSpacing: HDTSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 112,
                    child: TextField(
                      controller: _groupCount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Count',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _applyGroupCount,
                    icon: const Icon(Icons.grid_view_outlined, size: 16),
                    label: const Text('APPLY'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _autoFill,
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                    label: const Text('AUTO FILL'),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.busy || widget.onSave == null
                        ? null
                        : _saveDraft,
                    icon: widget.busy
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 16),
                    label: Text(widget.busy ? 'SAVING...' : 'SAVE GROUPS'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          Wrap(
            spacing: HDTSpace.sm,
            runSpacing: HDTSpace.sm,
            children: [
              _RulePill('${_groups.length} GROUP'),
              _RulePill('$assigned ASSIGNED'),
              _RulePill('${_bench.length} BENCH / WO'),
              if (widget.demoMode) const _RulePill('PREVIEW ONLY'),
            ],
          ),
          if (widget.demoMode) ...[
            const SizedBox(height: HDTSpace.md),
            const _Notice(
              color: HDTColors.info,
              text:
                  'Live roster is not available yet, so this builder is preview-only. After paid active players arrive, the save button becomes active.',
            ),
          ],
          const SizedBox(height: HDTSpace.lg),
          _BenchDropZone(
            players: _bench,
            onAccept: (player) => setState(() => _moveToBench(player)),
          ),
          const SizedBox(height: HDTSpace.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 1100
                  ? 3
                  : constraints.maxWidth >= 720
                      ? 2
                      : 1;
              final width =
                  (constraints.maxWidth - ((cols - 1) * HDTSpace.md)) / cols;
              return Wrap(
                spacing: HDTSpace.md,
                runSpacing: HDTSpace.md,
                children: [
                  for (var i = 0; i < _groups.length; i++)
                    SizedBox(
                      width: width,
                      child: _GroupDropCard(
                        index: i,
                        group: _groups[i],
                        onNameChanged: (value) => _groups[i].name = value,
                        onAccept: (player) =>
                            setState(() => _moveToGroup(player, i)),
                        onBench: (player) =>
                            setState(() => _moveToBench(player)),
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

  void _resetDraft() {
    final players = _eligiblePlayers();
    final count = math.min(4, math.max(1, players.length));
    _groupCount.text = count.toString();
    _groups = [
      for (var i = 0; i < count; i++)
        _GroupDraftState(name: _draftGroupName(i)),
    ];
    _bench = [...players];
    _rosterKey = _keyFor(widget.roster);
    _autoFill(notify: false);
  }

  List<TournamentRegistrationSummary> _eligiblePlayers() {
    final ready = widget.roster.where((item) => item.readyForBracket).toList();
    return ready.isEmpty ? [...widget.roster] : ready;
  }

  String _keyFor(List<TournamentRegistrationSummary> roster) {
    return roster
        .map((item) => '${item.id}:${item.registrationStatus}')
        .join('|');
  }

  void _applyGroupCount() {
    final requested = int.tryParse(_groupCount.text.trim());
    if (requested == null) return;
    final nextCount = requested.clamp(1, 32).toInt();
    setState(() {
      _groupCount.text = nextCount.toString();
      if (nextCount > _groups.length) {
        for (var i = _groups.length; i < nextCount; i++) {
          _groups.add(_GroupDraftState(name: _draftGroupName(i)));
        }
      } else if (nextCount < _groups.length) {
        final removed = _groups.sublist(nextCount);
        for (final group in removed) {
          for (final player in group.players) {
            if (!_bench.any((item) => item.id == player.id)) {
              _bench.add(player);
            }
          }
        }
        _groups = _groups.take(nextCount).toList();
      }
    });
  }

  void _autoFill({bool notify = true}) {
    final players = _eligiblePlayers();
    for (final group in _groups) {
      group.players.clear();
    }
    _bench = [];
    for (var i = 0; i < players.length; i++) {
      _groups[i % _groups.length].players.add(players[i]);
    }
    if (notify && mounted) setState(() {});
  }

  void _moveToGroup(TournamentRegistrationSummary player, int groupIndex) {
    _bench.removeWhere((item) => item.id == player.id);
    for (final group in _groups) {
      group.players.removeWhere((item) => item.id == player.id);
    }
    _groups[groupIndex].players.add(player);
  }

  void _moveToBench(TournamentRegistrationSummary player) {
    for (final group in _groups) {
      group.players.removeWhere((item) => item.id == player.id);
    }
    if (!_bench.any((item) => item.id == player.id)) _bench.add(player);
  }

  Future<void> _saveDraft() async {
    final onSave = widget.onSave;
    if (onSave == null) return;
    await onSave([
      for (final group in _groups)
        TournamentGroupDraft(
          name: group.name,
          players: [...group.players],
        ),
    ]);
  }
}

String _draftGroupName(int index) {
  if (index < 26) return 'Group ${String.fromCharCode(65 + index)}';
  return 'Group ${index + 1}';
}

class _GroupDraftState {
  _GroupDraftState({required this.name});

  String name;
  final List<TournamentRegistrationSummary> players = [];
}

class _BenchDropZone extends StatelessWidget {
  const _BenchDropZone({
    required this.players,
    required this.onAccept,
  });

  final List<TournamentRegistrationSummary> players;
  final ValueChanged<TournamentRegistrationSummary> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TournamentRegistrationSummary>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, rejected) {
        final active = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(HDTSpace.md),
          decoration: BoxDecoration(
            color: active
                ? HDTColors.warning.withValues(alpha: .16)
                : HDTColors.bg.withValues(alpha: .72),
            borderRadius: HDTR.md,
            border: Border.all(
              color: active ? HDTColors.warning : HDTColors.s2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BENCH / WO', style: HDTText.overline(size: 9)),
              const SizedBox(height: HDTSpace.sm),
              if (players.isEmpty)
                Text(
                  'Drop players here if they walk out or have not been placed in a group.',
                  style: HDTText.body(size: 12, color: HDTColors.text3),
                )
              else
                Wrap(
                  spacing: HDTSpace.sm,
                  runSpacing: HDTSpace.sm,
                  children: [
                    for (final player in players) _DraggablePlayerChip(player),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupDropCard extends StatelessWidget {
  const _GroupDropCard({
    required this.index,
    required this.group,
    required this.onNameChanged,
    required this.onAccept,
    required this.onBench,
  });

  final int index;
  final _GroupDraftState group;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<TournamentRegistrationSummary> onAccept;
  final ValueChanged<TournamentRegistrationSummary> onBench;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TournamentRegistrationSummary>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, rejected) {
        final active = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 260),
          padding: const EdgeInsets.all(HDTSpace.md),
          decoration: BoxDecoration(
            color: active
                ? HDTColors.info.withValues(alpha: .18)
                : HDTColors.bg.withValues(alpha: .82),
            borderRadius: HDTR.md,
            border: Border.all(color: active ? HDTColors.info : HDTColors.s2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: HDTColors.info.withValues(alpha: .14),
                      borderRadius: HDTR.sm,
                      border: Border.all(color: HDTColors.info),
                    ),
                    child:
                        Text('${index + 1}', style: HDTText.display(size: 15)),
                  ),
                  const SizedBox(width: HDTSpace.sm),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('group-name-$index-${group.name}'),
                      initialValue: group.name,
                      onChanged: onNameChanged,
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HDTSpace.md),
              Text('${group.players.length} players',
                  style: HDTText.mono(size: 10, color: HDTColors.text3)),
              const SizedBox(height: HDTSpace.sm),
              if (group.players.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Drop players here',
                      style: HDTText.body(size: 12, color: HDTColors.text3),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: HDTSpace.sm,
                  runSpacing: HDTSpace.sm,
                  children: [
                    for (final player in group.players)
                      _DraggablePlayerChip(
                        player,
                        trailing: IconButton(
                          tooltip: 'Move to bench / WO',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onBench(player),
                          icon: const Icon(Icons.logout, size: 14),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggablePlayerChip extends StatelessWidget {
  const _DraggablePlayerChip(this.player, {this.trailing});

  final TournamentRegistrationSummary player;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final chip = _PlayerDraftChip(player: player, trailing: trailing);
    return Draggable<TournamentRegistrationSummary>(
      data: player,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: _PlayerDraftChip(player: player, dragging: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: chip),
      child: chip,
    );
  }
}

class _PlayerDraftChip extends StatelessWidget {
  const _PlayerDraftChip({
    required this.player,
    this.dragging = false,
    this.trailing,
  });

  final TournamentRegistrationSummary player;
  final bool dragging;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      padding: const EdgeInsets.symmetric(
        horizontal: HDTSpace.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: dragging ? HDTColors.s1 : HDTColors.s2.withValues(alpha: .72),
        borderRadius: HDTR.sm,
        border: Border.all(
          color: dragging ? HDTColors.info : HDTColors.s3,
        ),
        boxShadow: dragging
            ? [
                BoxShadow(
                  color: HDTColors.info.withValues(alpha: .24),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, size: 16, color: HDTColors.text3),
          const SizedBox(width: HDTSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.playerName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.body(size: 12),
                ),
                Text(
                  player.deckName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.mono(size: 9, color: HDTColors.text3),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _OpsModuleShelf extends StatelessWidget {
  const _OpsModuleShelf();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
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
                Text('BRACKET & GROUPING MODULES',
                    style: HDTText.overline(size: 10)),
                const SizedBox(height: HDTSpace.sm),
                Text(
                  'Legacy bracketing elements are kept as internal modules',
                  style: HDTText.display(size: 23),
                ),
                const SizedBox(height: HDTSpace.sm),
                Text(
                  'For the initial trial, the ops screen focuses on group setup, roster, judge assignments, and match generation. The large bracket view will return after the tournament flow is stable.',
                  style: HDTText.body(
                    size: 12,
                    color: HDTColors.text2,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const Wrap(
            spacing: HDTSpace.sm,
            runSpacing: HDTSpace.sm,
            children: [
              _RulePill('GROUP BUILDER ACTIVE'),
              _RulePill('BRACKET UI STAGED'),
              _RulePill('ROUND ROBIN READY'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StagedOpsModules extends StatelessWidget {
  const _StagedOpsModules({
    required this.bracketPanel,
    required this.doublePreview,
  });

  final Widget bracketPanel;
  final List<_DoubleElimSection> doublePreview;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: true,
      child: Column(
        children: [
          const _GroupStageBoard(
            rules: _demoStageRules,
            groups: _demoStageGroups,
          ),
          const _RoundRobinMatrixBoard(
            players: _demoRoundRobinPlayers,
            cells: _demoRoundRobinCells,
          ),
          _DoubleEliminationBoard(sections: doublePreview),
          bracketPanel,
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
    final matches = sections.expand((section) => section.rounds).expand(
          (round) => round.matches,
        );
    final total = matches.length;
    final completed = matches
        .where((match) => match.status == 'completed' || match.winner != null)
        .length;
    final live = matches.where((match) => match.status == 'ready').length;
    final locked = matches.where((match) => match.status == 'locked').length;
    return Container(
      decoration: hdtCard(bg: HDTColors.s1, borderColor: HDTColors.s3),
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
                    const SizedBox(height: HDTSpace.xs),
                    Text(
                      'Winner path, elimination path, and reset match are read in one board.',
                      style: HDTText.body(size: 12, color: HDTColors.text3),
                    ),
                  ],
                ),
                Wrap(
                  spacing: HDTSpace.sm,
                  runSpacing: HDTSpace.sm,
                  children: [
                    _MiniMetric('MATCH', '$completed/$total'),
                    _MiniMetric('LIVE', live.toString()),
                    _MiniMetric('LOCKED', locked.toString()),
                  ],
                ),
              ],
            ),
          ),
          hdtDivider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              HDTSpace.lg,
              HDTSpace.lg,
              HDTSpace.lg,
              0,
            ),
            child: _DoubleElimFlowLegend(),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              HDTSpace.lg,
              HDTSpace.lg,
              HDTSpace.lg,
              HDTSpace.xl,
            ),
            child: _EsportsDoubleElimMap(sections: sections),
          ),
        ],
      ),
    );
  }
}

class _EsportsDoubleElimMap extends StatelessWidget {
  const _EsportsDoubleElimMap({required this.sections});

  final List<_DoubleElimSection> sections;

  static const double laneX = 44;
  static const double upperY = 86;
  static const double laneGap = 86;
  static const double finalGap = 86;
  static const double boardMinWidth = 1060;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox(
        width: boardMinWidth,
        height: 260,
        child: Center(
            child: _Notice(
                color: HDTColors.warning,
                text: 'Bracket is not available yet.')),
      );
    }
    final upper = _findDoubleElimSection(sections, 'Upper') ?? sections.first;
    final lower = _findDoubleElimSection(sections, 'Lower') ?? sections.first;
    final grand = _findDoubleElimSection(sections, 'Grand');
    final upperPositions = _DoubleElimSectionTree.positionsFor(upper);
    final lowerPositions = _DoubleElimSectionTree.positionsFor(lower);
    final upperHeight = upperPositions.height + _DoubleElimSectionTree.labelTop;
    final lowerHeight = lowerPositions.height + _DoubleElimSectionTree.labelTop;
    final laneWidth = math.max(upperPositions.width, lowerPositions.width);
    final finalX = laneX + laneWidth + finalGap;
    final grandMatches =
        grand?.rounds.expand((round) => round.matches).toList() ??
            const <_DoubleElimMatch>[];
    final grandHeight = grandMatches.isEmpty
        ? _DoubleElimSectionTree.cardH
        : (grandMatches.length * _DoubleElimSectionTree.cardH) +
            ((grandMatches.length - 1) * HDTSpace.md);
    final lowerY = upperY + upperHeight + laneGap;
    final finalY = math.max(
      upperY,
      upperY + ((upperHeight + laneGap + lowerHeight - grandHeight) / 2),
    );
    final boardWidth = math.max(
      boardMinWidth,
      finalX + _DoubleElimSectionTree.cardW + laneX,
    );
    final boardHeight = lowerY + lowerHeight + 80;

    return SizedBox(
      width: boardWidth,
      height: boardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
              child: CustomPaint(painter: _BracketBackdropPainter())),
          Positioned.fill(
            child: CustomPaint(
              painter: _DoubleElimFinalConnectorPainter(
                upperOut: _laneOutputPoint(upperPositions, laneX, upperY),
                lowerOut: _laneOutputPoint(lowerPositions, laneX, lowerY),
                finalIn: Offset(
                  finalX,
                  finalY + (_DoubleElimSectionTree.cardH / 2),
                ),
                upperColor: _doubleElimAccent(upper.title),
                lowerColor: _doubleElimAccent(lower.title),
                finalColor: _doubleElimAccent(grand?.title ?? 'Grand'),
              ),
            ),
          ),
          Positioned(
            left: laneX,
            top: 28,
            child: _BracketLaneHeader(
              title: upper.title,
              subtitle: upper.subtitle,
              accent: _doubleElimAccent(upper.title),
              icon: _doubleElimIcon(upper.title),
            ),
          ),
          Positioned(
            left: laneX,
            top: upperY,
            child: _DoubleElimSectionTree(
              section: upper,
              accent: _doubleElimAccent(upper.title),
              positions: upperPositions,
            ),
          ),
          Positioned(
            left: laneX,
            top: lowerY - 45,
            child: SizedBox(
              width: boardWidth - (laneX * 2),
              child: hdtDivider(),
            ),
          ),
          Positioned(
            left: laneX,
            top: lowerY - 18,
            child: _BracketLaneHeader(
              title: lower.title,
              subtitle: lower.subtitle,
              accent: _doubleElimAccent(lower.title),
              icon: _doubleElimIcon(lower.title),
            ),
          ),
          Positioned(
            left: laneX,
            top: lowerY,
            child: _DoubleElimSectionTree(
              section: lower,
              accent: _doubleElimAccent(lower.title),
              positions: lowerPositions,
            ),
          ),
          if (grand != null) ...[
            Positioned(
              left: finalX,
              top: finalY - 48,
              child: _BracketLaneHeader(
                title: grand.title,
                subtitle: grand.subtitle,
                accent: _doubleElimAccent(grand.title),
                icon: _doubleElimIcon(grand.title),
                alignRight: true,
              ),
            ),
            Positioned(
              left: finalX,
              top: finalY,
              width: _DoubleElimSectionTree.cardW,
              child: _GrandFinalStack(
                matches: grandMatches,
                accent: _doubleElimAccent(grand.title),
              ),
            ),
          ],
          Positioned(
            right: 26,
            bottom: 22,
            child: _BracketPrizePanel(
              accent: _doubleElimAccent(grand?.title ?? 'Grand'),
              completed: grandMatches
                  .where((match) =>
                      match.status == 'completed' || match.winner != null)
                  .length,
              total: grandMatches.length,
            ),
          ),
        ],
      ),
    );
  }

  Offset _laneOutputPoint(_TreePositions positions, double x, double y) {
    final lastRound =
        positions.yByRound.isEmpty ? 0 : positions.yByRound.length - 1;
    final lastY =
        positions.yByRound.isEmpty || positions.yByRound[lastRound].isEmpty
            ? 0.0
            : positions.yByRound[lastRound].first;
    return Offset(
      x + positions.xForRound(lastRound) + _DoubleElimSectionTree.cardW,
      y +
          _DoubleElimSectionTree.labelTop +
          lastY +
          (_DoubleElimSectionTree.cardH / 2),
    );
  }
}

class _BracketLaneHeader extends StatelessWidget {
  const _BracketLaneHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    this.alignRight = false,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 330,
      child: Row(
        textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .16),
              borderRadius: HDTR.md,
              border: Border.all(color: accent.withValues(alpha: .42)),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: alignRight
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.display(size: 20, color: accent)),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.mono(size: 10, color: HDTColors.text3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrandFinalStack extends StatelessWidget {
  const _GrandFinalStack({
    required this.matches,
    required this.accent,
  });

  final List<_DoubleElimMatch> matches;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return SizedBox(
        height: _DoubleElimSectionTree.cardH,
        child: _BracketPlaceholderTile(accent: accent),
      );
    }
    return Column(
      children: [
        for (final match in matches) ...[
          SizedBox(
            height: _DoubleElimSectionTree.cardH,
            child: _DoubleElimMatchTile(match: match, accent: accent),
          ),
          if (match != matches.last) const SizedBox(height: HDTSpace.md),
        ],
      ],
    );
  }
}

class _BracketPlaceholderTile extends StatelessWidget {
  const _BracketPlaceholderTile({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.lg,
        border: Border.all(color: accent.withValues(alpha: .48)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .14),
            blurRadius: 18,
          ),
        ],
      ),
      child: Text('[W]', style: HDTText.display(size: 22, color: accent)),
    );
  }
}

class _BracketPrizePanel extends StatelessWidget {
  const _BracketPrizePanel({
    required this.accent,
    required this.completed,
    required this.total,
  });

  final Color accent;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg.withValues(alpha: .72),
        borderRadius: HDTR.lg,
        border: Border.all(color: accent.withValues(alpha: .34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GRAND PATH', style: HDTText.overline(size: 8, color: accent)),
          const SizedBox(height: HDTSpace.xs),
          Text('$completed/$total',
              style: HDTText.display(size: 24, color: HDTColors.text)),
          Text(
            'Final match progress',
            style: HDTText.mono(size: 9, color: HDTColors.text3),
          ),
        ],
      ),
    );
  }
}

class _BracketBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF11131A),
          Color(0xFF151022),
          Color(0xFF0E151A),
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      bgPaint,
    );

    final gridPaint = Paint()
      ..color = HDTColors.text3.withValues(alpha: .08)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 56) {
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x + size.height, size.height),
        gridPaint,
      );
    }

    final borderPaint = Paint()
      ..color = HDTColors.accentHover.withValues(alpha: .18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(1),
        const Radius.circular(8),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BracketBackdropPainter oldDelegate) => false;
}

class _DoubleElimFinalConnectorPainter extends CustomPainter {
  const _DoubleElimFinalConnectorPainter({
    required this.upperOut,
    required this.lowerOut,
    required this.finalIn,
    required this.upperColor,
    required this.lowerColor,
    required this.finalColor,
  });

  final Offset upperOut;
  final Offset lowerOut;
  final Offset finalIn;
  final Color upperColor;
  final Color lowerColor;
  final Color finalColor;

  @override
  void paint(Canvas canvas, Size size) {
    _drawPath(canvas, upperOut, finalIn, upperColor);
    _drawPath(canvas, lowerOut, finalIn, lowerColor);
    final finalPaint = Paint()
      ..color = finalColor.withValues(alpha: .5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(finalIn.dx, finalIn.dy - 34),
      Offset(finalIn.dx, finalIn.dy + 34),
      finalPaint,
    );
  }

  void _drawPath(Canvas canvas, Offset from, Offset to, Color color) {
    final elbowX = from.dx + ((to.dx - from.dx) * .52);
    final paint = Paint()
      ..color = color.withValues(alpha: .62)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(elbowX, from.dy)
      ..lineTo(elbowX, to.dy)
      ..lineTo(to.dx, to.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DoubleElimFinalConnectorPainter oldDelegate) {
    return oldDelegate.upperOut != upperOut ||
        oldDelegate.lowerOut != lowerOut ||
        oldDelegate.finalIn != finalIn ||
        oldDelegate.upperColor != upperColor ||
        oldDelegate.lowerColor != lowerColor ||
        oldDelegate.finalColor != finalColor;
  }
}

class _DoubleElimSectionTree extends StatelessWidget {
  const _DoubleElimSectionTree({
    required this.section,
    required this.accent,
    this.positions,
  });

  final _DoubleElimSection section;
  final Color accent;
  final _TreePositions? positions;

  static const double cardW = 270;
  static const double cardH = 128;
  static const double colGap = 70;
  static const double baseGap = 30;
  static const double labelTop = 34;

  static _TreePositions positionsFor(_DoubleElimSection section) {
    return _buildTreePositions(
      section.rounds.map((round) => round.matches.length).toList(),
      cardH: cardH,
      baseGap: baseGap,
      cardW: cardW,
      colGap: colGap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPositions = positions ?? positionsFor(section);
    return SizedBox(
      width: resolvedPositions.width,
      height: resolvedPositions.height + labelTop,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: labelTop,
            child: CustomPaint(
              painter: _BracketTreePainter(
                positions: resolvedPositions,
                cardWidth: cardW,
                cardHeight: cardH,
                color: accent.withValues(alpha: .58),
              ),
            ),
          ),
          for (var r = 0; r < section.rounds.length; r++)
            Positioned(
              left: resolvedPositions.xForRound(r),
              top: 0,
              width: cardW,
              child: Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: HDTSpace.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .1),
                  borderRadius: HDTR.full,
                  border: Border.all(color: accent.withValues(alpha: .28)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.linear_scale, size: 13, color: accent),
                    const SizedBox(width: HDTSpace.xs),
                    Expanded(
                      child: Text(
                        section.rounds[r].title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HDTText.overline(size: 8, color: accent),
                      ),
                    ),
                    Text(
                      '${section.rounds[r].matches.length}M',
                      style: HDTText.mono(size: 8, color: accent),
                    ),
                  ],
                ),
              ),
            ),
          for (var r = 0; r < section.rounds.length; r++)
            for (var m = 0; m < section.rounds[r].matches.length; m++)
              Positioned(
                left: resolvedPositions.xForRound(r),
                top: resolvedPositions.yFor(r, m) + labelTop,
                width: cardW,
                height: cardH,
                child: _DoubleElimMatchTile(
                  match: section.rounds[r].matches[m],
                  accent: accent,
                ),
              ),
        ],
      ),
    );
  }
}

class _DoubleElimMatchTile extends StatelessWidget {
  const _DoubleElimMatchTile({
    required this.match,
    required this.accent,
  });

  final _DoubleElimMatch match;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = _doubleElimStatusColor(match);
    final scoreA = _scoreSide(match.score, 0);
    final scoreB = _scoreSide(match.score, 1);
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            accent.withValues(alpha: .18),
            HDTColors.s1,
          ],
        ),
        borderRadius: HDTR.md,
        border: Border.all(color: color.withValues(alpha: .52)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(match.code,
                      style: HDTText.overline(size: 9, color: color))),
              _BracketStatusPill(_doubleElimStatusLabel(match), color),
            ],
          ),
          const SizedBox(height: HDTSpace.sm),
          _ElimPlayerLine(
            seed: 'A',
            name: match.playerA,
            score: scoreA,
            winner: match.winner == match.playerA,
            accent: color,
          ),
          const SizedBox(height: 6),
          _ElimPlayerLine(
            seed: 'B',
            name: match.playerB,
            score: scoreB,
            winner: match.winner == match.playerB,
            accent: color,
          ),
        ],
      ),
    );
  }
}

class _ElimPlayerLine extends StatelessWidget {
  const _ElimPlayerLine({
    required this.seed,
    required this.name,
    required this.score,
    required this.winner,
    required this.accent,
  });

  final String seed;
  final String name;
  final String score;
  final bool winner;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: HDTSpace.sm),
      decoration: BoxDecoration(
        color: winner ? HDTColors.success.withValues(alpha: .12) : HDTColors.bg,
        borderRadius: HDTR.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: winner ? HDTColors.success : accent.withValues(alpha: .16),
              borderRadius: HDTR.sm,
            ),
            child: Text(
              winner ? 'W' : seed,
              style: HDTText.overline(
                size: 7,
                color: winner ? HDTColors.bg : accent,
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
                size: 12,
                color: winner ? HDTColors.text : HDTColors.text2,
                weight: winner ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Container(
            width: 28,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: winner
                  ? HDTColors.success.withValues(alpha: .18)
                  : HDTColors.s2,
              borderRadius: HDTR.sm,
              border: Border.all(
                color: winner
                    ? HDTColors.success.withValues(alpha: .46)
                    : HDTColors.s3,
              ),
            ),
            child: Text(
              score,
              style: HDTText.mono(
                size: 10,
                color: winner ? HDTColors.success : HDTColors.text3,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleElimFlowLegend extends StatelessWidget {
  const _DoubleElimFlowLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: HDTSpace.sm,
      runSpacing: HDTSpace.sm,
      children: [
        _FlowLegendItem(
          icon: Icons.trending_up,
          color: HDTColors.success,
          title: 'Upper',
          body: 'Winning stays on the champion path',
        ),
        _FlowLegendItem(
          icon: Icons.restart_alt,
          color: HDTColors.warning,
          title: 'Lower',
          body: 'One loss still stays alive',
        ),
        _FlowLegendItem(
          icon: Icons.emoji_events_outlined,
          color: HDTColors.accentHover,
          title: 'Final',
          body: 'Reset is active if lower wins',
        ),
      ],
    );
  }
}

class _FlowLegendItem extends StatelessWidget {
  const _FlowLegendItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 214,
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: HDTR.md,
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: HDTSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(),
                    style: HDTText.overline(size: 8, color: color)),
                Text(
                  body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.body(size: 11, color: HDTColors.text3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BracketStatusPill extends StatelessWidget {
  const _BracketStatusPill(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: HDTR.full,
        border: Border.all(color: color.withValues(alpha: .38)),
      ),
      child: Text(text, style: HDTText.mono(size: 8, color: color)),
    );
  }
}

Color _doubleElimAccent(String title) {
  if (title.startsWith('Upper')) return HDTColors.success;
  if (title.startsWith('Lower')) return HDTColors.warning;
  return HDTColors.accentHover;
}

IconData _doubleElimIcon(String title) {
  if (title.startsWith('Upper')) return Icons.trending_up;
  if (title.startsWith('Lower')) return Icons.restart_alt;
  return Icons.emoji_events_outlined;
}

Color _doubleElimStatusColor(_DoubleElimMatch match) {
  if (match.status == 'completed' || match.winner != null) {
    return HDTColors.success;
  }
  if (match.status == 'ready') return HDTColors.accentHover;
  if (match.status == 'locked') return HDTColors.s3;
  return HDTColors.warning;
}

String _doubleElimStatusLabel(_DoubleElimMatch match) {
  if (match.score != null && match.score!.trim().isNotEmpty) {
    return match.score!;
  }
  return match.status.toUpperCase();
}

_DoubleElimSection? _findDoubleElimSection(
  List<_DoubleElimSection> sections,
  String prefix,
) {
  for (final section in sections) {
    if (section.title.startsWith(prefix)) return section;
  }
  return null;
}

String _scoreSide(String? score, int side) {
  if (score == null || score.trim().isEmpty) return '0';
  final parts = score.split(RegExp(r'[-:]'));
  if (parts.length != 2) return score.toUpperCase() == 'BYE' ? '-' : '0';
  final value = parts[side].trim();
  return value.isEmpty ? '0' : value;
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
            'Bracket has not been created. Generate Round 1 after participants are paid active.',
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
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
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
  const _RosterList({
    required this.roster,
    this.demo = false,
    this.busyRegistrationId,
    this.onActivate,
    this.onWalkOut,
  });

  final List<TournamentRegistrationSummary> roster;
  final bool demo;
  final String? busyRegistrationId;
  final ValueChanged<TournamentRegistrationSummary>? onActivate;
  final ValueChanged<TournamentRegistrationSummary>? onWalkOut;

  @override
  Widget build(BuildContext context) {
    if (roster.isEmpty) {
      return const _Notice(
        color: HDTColors.warning,
        text: 'No participants have registered for this tournament yet.',
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
          for (final item in roster)
            _RosterRow(
              item: item,
              busy: busyRegistrationId == item.id,
              onActivate: onActivate,
              onWalkOut: onWalkOut,
            ),
        ],
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.item,
    required this.busy,
    required this.onActivate,
    required this.onWalkOut,
  });

  final TournamentRegistrationSummary item;
  final bool busy;
  final ValueChanged<TournamentRegistrationSummary>? onActivate;
  final ValueChanged<TournamentRegistrationSummary>? onWalkOut;

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
          Wrap(
            spacing: HDTSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusPill(_statusLabel(item), ready: ready),
              if (!ready && onActivate != null)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => onActivate!(item),
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('PAID ACTIVE'),
                ),
              if (item.registrationStatus != 'walkOut' && onWalkOut != null)
                TextButton.icon(
                  onPressed: busy ? null : () => onWalkOut!(item),
                  icon: const Icon(Icons.logout, size: 14),
                  label: const Text('WO'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(TournamentRegistrationSummary item) {
    if (item.readyForBracket) return 'READY';
    if (item.registrationStatus == 'walkOut') return 'WO';
    return item.paymentStatus.toUpperCase();
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
            Text('NO TOURNAMENT YET', style: HDTText.display(size: 24)),
            const SizedBox(height: HDTSpace.sm),
            Text(
              'Create a tournament first, then participants can register and the roster will appear here.',
              textAlign: TextAlign.center,
              style: HDTText.body(size: 12, color: HDTColors.text2),
            ),
            const SizedBox(height: HDTSpace.lg),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('CREATE TOURNAMENT'),
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
        child: const Text('COMMUNITY ADMIN LOGIN'),
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
