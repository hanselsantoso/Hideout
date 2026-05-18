// ============================================================
// MATCH HISTORY SCREEN
// Menampilkan riwayat match lengkap dengan:
// - Filter tanggal (preset + kustom)
// - Filter hasil (WIN/LOSS)
// - Statistik range
// - Expandable row → deck vs deck + game-by-game
// - Pagination
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../core/widgets/hdt_widgets.dart';

// ─── Model ──────────────────────────────────────────────────
class MatchRecord {
  final String id;
  final DateTime date;
  final String tournament;
  final String tournamentId;
  final String round;
  final String opponent;
  final String opponentId;
  final int opponentElo;
  final String score;
  final String result; // WIN | LOSS | DRAW
  final int eloChange;
  final String myDeck;
  final String myDeckClass;
  final String opponentDeck;
  final String opponentDeckClass;
  final List<String> games; // BURST | OVER | SPIN | LOSS (per game)
  final String duration;
  final String arena;
  final String city;

  const MatchRecord({
    required this.id,
    required this.date,
    required this.tournament,
    required this.tournamentId,
    required this.round,
    required this.opponent,
    required this.opponentId,
    required this.opponentElo,
    required this.score,
    required this.result,
    required this.eloChange,
    required this.myDeck,
    required this.myDeckClass,
    required this.opponentDeck,
    required this.opponentDeckClass,
    required this.games,
    required this.duration,
    required this.arena,
    required this.city,
  });
}

// ─── Mock Data ───────────────────────────────────────────────
final List<MatchRecord> _allMatches = [
  MatchRecord(
      id: 'M-0148',
      date: DateTime(2026, 5, 9),
      tournament: 'HIDEOUT Cup #3',
      tournamentId: 'bjx-cup-3',
      round: 'QF',
      opponent: 'MARDIKA',
      opponentId: 'HDT-007',
      opponentElo: 2812,
      score: '3-1',
      result: 'WIN',
      eloChange: 24,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'Cobalt Dragoon Mk.II',
      opponentDeckClass: 'DEFENDER',
      games: ['Burst', 'Over', 'Loss', 'Spin'],
      duration: '9:42',
      arena: 'A02',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0147',
      date: DateTime(2026, 5, 9),
      tournament: 'HIDEOUT Cup #3',
      tournamentId: 'bjx-cup-3',
      round: 'R16',
      opponent: 'FATIMA',
      opponentId: 'HDT-217',
      opponentElo: 2410,
      score: '3-0',
      result: 'WIN',
      eloChange: 16,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'PhantomFox Stamina',
      opponentDeckClass: 'STAMINA',
      games: ['Burst', 'Burst', 'Over'],
      duration: '7:15',
      arena: 'A04',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0146',
      date: DateTime(2026, 5, 9),
      tournament: 'HIDEOUT Cup #3',
      tournamentId: 'bjx-cup-3',
      round: 'R32',
      opponent: 'GHOZALI',
      opponentId: 'HDT-201',
      opponentElo: 2540,
      score: '3-2',
      result: 'WIN',
      eloChange: 20,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'VoidBastion Defense',
      opponentDeckClass: 'DEFENDER',
      games: ['Burst', 'Loss', 'Over', 'Loss', 'Spin'],
      duration: '14:08',
      arena: 'A01',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0144',
      date: DateTime(2026, 4, 26),
      tournament: 'Senayan Open',
      tournamentId: 'snyo-apr',
      round: 'SF',
      opponent: 'BILLY',
      opponentId: 'HDT-030',
      opponentElo: 2847,
      score: '2-3',
      result: 'LOSS',
      eloChange: -12,
      myDeck: 'HellsScythe Strike',
      myDeckClass: 'RUSHER',
      opponentDeck: 'DranSword Pro X',
      opponentDeckClass: 'RUSHER',
      games: ['Burst', 'Loss', 'Loss', 'Over', 'Loss'],
      duration: '10:30',
      arena: 'B01',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0143',
      date: DateTime(2026, 4, 26),
      tournament: 'Senayan Open',
      tournamentId: 'snyo-apr',
      round: 'QF',
      opponent: 'NIRO',
      opponentId: 'HDT-077',
      opponentElo: 2563,
      score: '3-1',
      result: 'WIN',
      eloChange: 19,
      myDeck: 'HellsScythe Strike',
      myDeckClass: 'RUSHER',
      opponentDeck: 'Cobalt Dragoon Std.',
      opponentDeckClass: 'DEFENDER',
      games: ['Over', 'Loss', 'Burst', 'Spin'],
      duration: '11:55',
      arena: 'B03',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0142',
      date: DateTime(2026, 4, 26),
      tournament: 'Senayan Open',
      tournamentId: 'snyo-apr',
      round: 'R16',
      opponent: 'LUNA',
      opponentId: 'HDT-082',
      opponentElo: 2802,
      score: '3-0',
      result: 'WIN',
      eloChange: 17,
      myDeck: 'HellsScythe Strike',
      myDeckClass: 'RUSHER',
      opponentDeck: 'SpinForce Phantom',
      opponentDeckClass: 'STAMINA',
      games: ['Burst', 'Over', 'Spin'],
      duration: '6:50',
      arena: 'A02',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0135',
      date: DateTime(2026, 3, 15),
      tournament: 'BDG Highland Open',
      tournamentId: 'bdg-highland',
      round: 'FINAL',
      opponent: 'KAGE',
      opponentId: 'HDT-044',
      opponentElo: 2611,
      score: '3-2',
      result: 'WIN',
      eloChange: 28,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'AeroStrike Balance',
      opponentDeckClass: 'BALANCE',
      games: ['Burst', 'Loss', 'Burst', 'Loss', 'Over'],
      duration: '16:42',
      arena: 'C01',
      city: 'Bandung'),
  MatchRecord(
      id: 'M-0134',
      date: DateTime(2026, 3, 15),
      tournament: 'BDG Highland Open',
      tournamentId: 'bdg-highland',
      round: 'SF',
      opponent: 'AVI',
      opponentId: 'HDT-091',
      opponentElo: 2702,
      score: '3-2',
      result: 'WIN',
      eloChange: 32,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'TerraGuard Heavy',
      opponentDeckClass: 'DEFENDER',
      games: ['Over', 'Loss', 'Burst', 'Loss', 'Spin'],
      duration: '18:11',
      arena: 'C02',
      city: 'Bandung'),
  MatchRecord(
      id: 'M-0122',
      date: DateTime(2026, 2, 14),
      tournament: 'Weekly Ranked #17',
      tournamentId: 'jkt-wkly-17',
      round: 'SF',
      opponent: 'ZINBLACK',
      opponentId: 'HDT-014',
      opponentElo: 2756,
      score: '2-3',
      result: 'LOSS',
      eloChange: -8,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'VoidReaper Burst',
      opponentDeckClass: 'RUSHER',
      games: ['Burst', 'Over', 'Loss', 'Loss', 'Loss'],
      duration: '13:04',
      arena: 'A01',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0115',
      date: DateTime(2026, 2, 7),
      tournament: 'Weekly Ranked #16',
      tournamentId: 'jkt-wkly-16',
      round: 'R16',
      opponent: 'DERRA',
      opponentId: 'HDT-156',
      opponentElo: 2589,
      score: '1-3',
      result: 'LOSS',
      eloChange: -14,
      myDeck: 'HellsScythe Strike',
      myDeckClass: 'RUSHER',
      opponentDeck: 'Cobalt Dragoon Pro',
      opponentDeckClass: 'DEFENDER',
      games: ['Over', 'Loss', 'Loss', 'Loss'],
      duration: '8:22',
      arena: 'A02',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0108',
      date: DateTime(2026, 1, 24),
      tournament: 'Weekly Ranked #14',
      tournamentId: 'jkt-wkly-14',
      round: 'QF',
      opponent: 'RAFA',
      opponentId: 'HDT-118',
      opponentElo: 2654,
      score: '3-1',
      result: 'WIN',
      eloChange: 22,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'PhantomFox Hyper',
      opponentDeckClass: 'STAMINA',
      games: ['Burst', 'Loss', 'Over', 'Spin'],
      duration: '10:48',
      arena: 'A01',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0104',
      date: DateTime(2026, 1, 10),
      tournament: 'New Year Open',
      tournamentId: 'nyo-2026',
      round: 'FINAL',
      opponent: 'RAYHAN',
      opponentId: 'HDT-008',
      opponentElo: 3084,
      score: '1-3',
      result: 'LOSS',
      eloChange: -5,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'DranSword Pro X',
      opponentDeckClass: 'RUSHER',
      games: ['Burst', 'Loss', 'Loss', 'Loss'],
      duration: '9:14',
      arena: 'A01',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0099',
      date: DateTime(2025, 12, 21),
      tournament: 'Year-End Rumble',
      tournamentId: 'yer-2025',
      round: 'QF',
      opponent: 'ZAIDAN',
      opponentId: 'HDT-066',
      opponentElo: 2841,
      score: '3-1',
      result: 'WIN',
      eloChange: 18,
      myDeck: 'VoidBastion Alpha',
      myDeckClass: 'DEFENDER',
      opponentDeck: 'AeroStrike Balance',
      opponentDeckClass: 'BALANCE',
      games: ['Over', 'Burst', 'Loss', 'Spin'],
      duration: '9:30',
      arena: 'B02',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0091',
      date: DateTime(2025, 11, 15),
      tournament: 'JKT Monthly Nov',
      tournamentId: 'jkt-nov-25',
      round: 'SF',
      opponent: 'KAEDE',
      opponentId: 'HDT-001',
      opponentElo: 3120,
      score: '0-3',
      result: 'LOSS',
      eloChange: -3,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'DranSword Custom S',
      opponentDeckClass: 'RUSHER',
      games: ['Loss', 'Loss', 'Loss'],
      duration: '5:40',
      arena: 'A01',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0085',
      date: DateTime(2025, 10, 18),
      tournament: 'East Coast Open',
      tournamentId: 'eco-oct-25',
      round: 'FINAL',
      opponent: 'INDRA',
      opponentId: 'HDT-078',
      opponentElo: 2820,
      score: '3-1',
      result: 'WIN',
      eloChange: 26,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'SpinForce Phantom',
      opponentDeckClass: 'STAMINA',
      games: ['Burst', 'Over', 'Loss', 'Spin'],
      duration: '10:05',
      arena: 'C01',
      city: 'Surabaya'),
  MatchRecord(
      id: 'M-0071',
      date: DateTime(2025, 8, 23),
      tournament: 'Bandung Summer Cup',
      tournamentId: 'bsc-2025',
      round: 'SF',
      opponent: 'RAYHAN',
      opponentId: 'HDT-008',
      opponentElo: 3084,
      score: '2-3',
      result: 'LOSS',
      eloChange: -7,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'DranSword Pro X',
      opponentDeckClass: 'RUSHER',
      games: ['Burst', 'Over', 'Loss', 'Loss', 'Loss'],
      duration: '11:50',
      arena: 'D01',
      city: 'Bandung'),
  MatchRecord(
      id: 'M-0062',
      date: DateTime(2025, 7, 12),
      tournament: 'JKT Monthly Jul',
      tournamentId: 'jkt-jul-25',
      round: 'R16',
      opponent: 'NIRO',
      opponentId: 'HDT-077',
      opponentElo: 2563,
      score: '3-0',
      result: 'WIN',
      eloChange: 14,
      myDeck: 'HellsScythe Strike',
      myDeckClass: 'RUSHER',
      opponentDeck: 'Cobalt Dragoon Std.',
      opponentDeckClass: 'DEFENDER',
      games: ['Burst', 'Spin', 'Over'],
      duration: '6:30',
      arena: 'A02',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0055',
      date: DateTime(2025, 6, 1),
      tournament: 'Springboard Series',
      tournamentId: 'sbs-jun-25',
      round: 'FINAL',
      opponent: 'MIKA',
      opponentId: 'HDT-014',
      opponentElo: 3041,
      score: '1-3',
      result: 'LOSS',
      eloChange: -4,
      myDeck: 'DranSword Alpha',
      myDeckClass: 'RUSHER',
      opponentDeck: 'DranSword Custom S',
      opponentDeckClass: 'RUSHER',
      games: ['Burst', 'Loss', 'Loss', 'Loss'],
      duration: '8:00',
      arena: 'B01',
      city: 'Jakarta'),
  MatchRecord(
      id: 'M-0041',
      date: DateTime(2025, 3, 8),
      tournament: 'Debut Match',
      tournamentId: 'debut-25',
      round: 'R32',
      opponent: 'DERRA',
      opponentId: 'HDT-156',
      opponentElo: 2589,
      score: '3-1',
      result: 'WIN',
      eloChange: 18,
      myDeck: 'Starter Dran',
      myDeckClass: 'RUSHER',
      opponentDeck: 'Starter Cobalt',
      opponentDeckClass: 'DEFENDER',
      games: ['Burst', 'Loss', 'Burst', 'Over'],
      duration: '10:12',
      arena: 'A04',
      city: 'Jakarta'),
];

// ─── State ───────────────────────────────────────────────────
class MatchHistoryState {
  final String query;
  final String resultFilter; // ALL | WIN | LOSS
  final HDTDatePreset preset;
  final DateTimeRange? customRange;
  final int page;
  final String? expandedId;

  const MatchHistoryState({
    this.query = '',
    this.resultFilter = 'ALL',
    this.preset = HDTDatePreset.all,
    this.customRange,
    this.page = 0,
    this.expandedId,
  });

  MatchHistoryState copyWith({
    String? query,
    String? resultFilter,
    HDTDatePreset? preset,
    DateTimeRange? customRange,
    bool clearCustomRange = false,
    int? page,
    String? expandedId,
    bool clearExpanded = false,
  }) =>
      MatchHistoryState(
        query: query ?? this.query,
        resultFilter: resultFilter ?? this.resultFilter,
        preset: preset ?? this.preset,
        customRange:
            clearCustomRange ? null : (customRange ?? this.customRange),
        page: page ?? this.page,
        expandedId: clearExpanded ? null : (expandedId ?? this.expandedId),
      );

  DateTimeRange? get effectiveRange => customRange ?? preset.range;

  List<MatchRecord> get filtered {
    final range = effectiveRange;
    return _allMatches.where((m) {
      if (resultFilter != 'ALL' && m.result != resultFilter) return false;
      if (query.isNotEmpty) {
        final lq = query.toLowerCase();
        if (!m.opponent.toLowerCase().contains(lq) &&
            !m.tournament.toLowerCase().contains(lq) &&
            !m.myDeck.toLowerCase().contains(lq) &&
            !m.opponentDeck.toLowerCase().contains(lq)) {
          return false;
        }
      }
      if (range != null) {
        if (m.date.isBefore(range.start) || m.date.isAfter(range.end))
          return false;
      }
      return true;
    }).toList();
  }
}

class MatchHistoryNotifier extends Notifier<MatchHistoryState> {
  static const perPage = 10;

  @override
  MatchHistoryState build() => const MatchHistoryState();

  void setQuery(String q) => state = state.copyWith(query: q, page: 0);
  void setResult(String r) => state = state.copyWith(resultFilter: r, page: 0);
  void setPreset(HDTDatePreset p) =>
      state = state.copyWith(preset: p, clearCustomRange: true, page: 0);
  void setCustomRange(DateTimeRange? r) => state =
      state.copyWith(customRange: r, preset: HDTDatePreset.all, page: 0);
  void setPage(int p) => state = state.copyWith(page: p, clearExpanded: true);
  void toggleExpand(String id) =>
      state = state.copyWith(expandedId: state.expandedId == id ? null : id);
  void reset() => state = const MatchHistoryState();
}

final matchHistoryProvider =
    NotifierProvider<MatchHistoryNotifier, MatchHistoryState>(
        MatchHistoryNotifier.new);

// ─── Screen ──────────────────────────────────────────────────
class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key});

  static const _perPage = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchHistoryProvider);
    final notifier = ref.read(matchHistoryProvider.notifier);
    final filtered = state.filtered;
    final paginated =
        filtered.skip(state.page * _perPage).take(_perPage).toList();

    // Stats
    final wins = filtered.where((m) => m.result == 'WIN').length;
    final losses = filtered.where((m) => m.result == 'LOSS').length;
    final total = filtered.length;
    final wr = total > 0 ? (wins / total * 100).round() : 0;
    final eloNet = filtered.fold<int>(0, (a, m) => a + m.eloChange);

    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        title: const Text('RIWAYAT MATCH'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: hdtDivider(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(HDTSpace.lg),
        children: [
          // ── Filter Panel ─────────────────────────────────
          _FilterPanel(state: state, notifier: notifier),
          const SizedBox(height: HDTSpace.lg),

          // ── Stats Grid ───────────────────────────────────
          _StatsGrid(
              total: total, wins: wins, losses: losses, wr: wr, eloNet: eloNet),
          const SizedBox(height: HDTSpace.lg),

          // ── Form Strip ───────────────────────────────────
          if (filtered.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(HDTSpace.md),
              decoration: hdtCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HDTOverlineLabel('HASIL PERTANDINGAN (RANGE)',
                      padding: const EdgeInsets.only(bottom: 8)),
                  HDTResultFormStrip(
                      results: filtered.map((m) => m.result).toList()),
                ],
              ),
            ),
          const SizedBox(height: HDTSpace.lg),

          // ── Match List ───────────────────────────────────
          ...paginated.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: HDTSpace.sm),
                child: _MatchRow(
                  match: m,
                  expanded: state.expandedId == m.id,
                  onToggle: () => notifier.toggleExpand(m.id),
                ),
              )),

          if (paginated.isEmpty)
            HDTEmptyState(
              icon: Icons.search_off,
              title: 'TIDAK ADA MATCH',
              subtitle: 'Ubah filter atau rentang tanggal',
              action: OutlinedButton(
                onPressed: notifier.reset,
                child: const Text('RESET FILTER'),
              ),
            ),

          const SizedBox(height: HDTSpace.lg),
          // ── Pagination ───────────────────────────────────
          HDTPagination(
            total: filtered.length,
            page: state.page,
            perPage: _perPage,
            label: 'match',
            onPage: notifier.setPage,
          ),
          const SizedBox(height: HDTSpace.xxl),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────

class _FilterPanel extends StatefulWidget {
  final MatchHistoryState state;
  final MatchHistoryNotifier notifier;
  const _FilterPanel({required this.state, required this.notifier});

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.state.query);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final n = widget.notifier;
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(),
      child: Column(
        children: [
          // Date range bar
          HDTDateRangeBar(
            selectedPreset: s.preset,
            customRange: s.customRange,
            onPreset: n.setPreset,
            onCustomRange: n.setCustomRange,
          ),
          const SizedBox(height: HDTSpace.md),
          // Search + result filter
          Row(
            children: [
              Expanded(
                child: HDTSearchField(
                  controller: _ctrl,
                  placeholder: 'Cari lawan, turnamen, atau deck…',
                  onChanged: n.setQuery,
                ),
              ),
              const SizedBox(width: HDTSpace.sm),
              ...['ALL', 'WIN', 'LOSS'].map((f) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: HDTFilterChip(
                      label: f,
                      selected: s.resultFilter == f,
                      onTap: () => n.setResult(f),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int total, wins, losses, wr, eloNet;
  const _StatsGrid(
      {required this.total,
      required this.wins,
      required this.losses,
      required this.wr,
      required this.eloNet});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: HDTSpace.sm,
      mainAxisSpacing: HDTSpace.sm,
      childAspectRatio: 2.2,
      children: [
        HDTStatCard(label: 'TOTAL MATCH', value: '$total'),
        HDTStatCard(
            label: 'MENANG', value: '$wins', valueColor: HDTColors.success),
        HDTStatCard(
            label: 'KALAH', value: '$losses', valueColor: HDTColors.danger),
        HDTStatCard(
          label: 'ELO NET',
          value: eloNet >= 0 ? '+$eloNet' : '$eloNet',
          valueColor: eloNet >= 0 ? HDTColors.success : HDTColors.danger,
        ),
      ],
    );
  }
}

class _MatchRow extends StatelessWidget {
  final MatchRecord match;
  final bool expanded;
  final VoidCallback onToggle;

  const _MatchRow(
      {required this.match, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final myWins = m.score.split('-').first;
    final oppWins = m.score.split('-').last;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: hdtCard(
        borderColor:
            expanded ? HDTColors.accent.withOpacity(0.4) : HDTColors.s2,
      ),
      child: Column(
        children: [
          // ── Row principale ─────────────────────────────
          InkWell(
            borderRadius: expanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8))
                : HDTR.lg,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(HDTSpace.md),
              child: Row(
                children: [
                  // Result + Score
                  Column(
                    children: [
                      HDTResultBadge(m.result),
                      const SizedBox(height: 4),
                      Text(m.score, style: HDTText.display(size: 16)),
                    ],
                  ),
                  const SizedBox(width: HDTSpace.md),
                  // Tournament + Round
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.tournament,
                            style: HDTText.body(size: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Row(children: [
                          Text('${m.round} · ${m.city}',
                              style: HDTText.mono(size: 10)),
                          const SizedBox(width: 6),
                          Text(_fmtDate(m.date),
                              style: HDTText.mono(
                                  size: 10, color: HDTColors.text3)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: HDTSpace.sm),
                  // Opponent
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('vs ${m.opponent}',
                            style: HDTText.display(size: 14), maxLines: 1),
                        Text(m.opponentId, style: HDTText.mono(size: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: HDTSpace.sm),
                  // ELO + expand icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      HDTEloChip(m.eloChange),
                      const SizedBox(height: 4),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: HDTColors.text3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Detail ────────────────────────────
          if (expanded) ...[
            hdtDivider(),
            Padding(
              padding: const EdgeInsets.all(HDTSpace.md),
              child: Column(
                children: [
                  // Deck vs Deck
                  Row(
                    children: [
                      // My Deck
                      Expanded(
                          child: _DeckCard(
                        label: 'DECK KAMU',
                        deckName: m.myDeck,
                        deckClass: m.myDeckClass,
                        playerId: 'HDT-202',
                        playerName: 'HANSEL',
                        elo: null,
                        highlight: true,
                      )),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: HDTSpace.md),
                        child: Column(
                          children: [
                            Text('VS',
                                style: HDTText.display(
                                    size: 14, color: HDTColors.text3)),
                            const SizedBox(height: 8),
                            // Score
                            Row(children: [
                              Text(myWins,
                                  style: HDTText.display(
                                      size: 22,
                                      color: m.result == 'WIN'
                                          ? HDTColors.success
                                          : HDTColors.danger)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text('–',
                                    style: HDTText.display(
                                        size: 18, color: HDTColors.text3)),
                              ),
                              Text(oppWins,
                                  style: HDTText.display(
                                      size: 22,
                                      color: m.result != 'WIN'
                                          ? HDTColors.success
                                          : HDTColors.danger)),
                            ]),
                          ],
                        ),
                      ),
                      // Opponent Deck
                      Expanded(
                          child: _DeckCard(
                        label: 'DECK LAWAN',
                        deckName: m.opponentDeck,
                        deckClass: m.opponentDeckClass,
                        playerId: m.opponentId,
                        playerName: m.opponent,
                        elo: m.opponentElo,
                        highlight: false,
                      )),
                    ],
                  ),
                  const SizedBox(height: HDTSpace.md),
                  // Game by game
                  Container(
                    padding: const EdgeInsets.all(HDTSpace.md),
                    decoration: hdtCard(bg: HDTColors.bg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HDTOverlineLabel('GAME BY GAME'),
                            const Spacer(),
                            Row(children: [
                              Icon(Icons.timer_outlined,
                                  size: 12, color: HDTColors.text3),
                              const SizedBox(width: 4),
                              Text(m.duration, style: HDTText.mono(size: 11)),
                              const SizedBox(width: 8),
                              Text('${m.arena} · ${m.city}',
                                  style: HDTText.mono(
                                      size: 10, color: HDTColors.text3)),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...m.games.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text('G${e.key + 1}',
                                        style: HDTText.mono(
                                            size: 10, color: HDTColors.text3)),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      color: e.value != 'Loss'
                                          ? HDTColors.success
                                          : HDTColors.danger,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  HDTGameBadge(e.value),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      color: e.value == 'Loss'
                                          ? HDTColors.success
                                          : HDTColors.danger,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      e.value != 'Loss' ? 'WIN' : 'LOSS',
                                      textAlign: TextAlign.right,
                                      style: HDTText.overline(
                                        size: 8,
                                        color: e.value != 'Loss'
                                            ? HDTColors.success
                                            : HDTColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: HDTSpace.sm),
                  // ID + actions
                  Row(
                    children: [
                      Text(m.id,
                          style:
                              HDTText.mono(size: 10, color: HDTColors.text3)),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.emoji_events_outlined, size: 14),
                        label: Text(m.tournament),
                        style: OutlinedButton.styleFrom(
                          textStyle: HDTText.overline(size: 9),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year.toString().substring(2)}';
  }
}

class _DeckCard extends StatelessWidget {
  final String label;
  final String deckName;
  final String deckClass;
  final String playerId;
  final String playerName;
  final int? elo;
  final bool highlight;

  const _DeckCard({
    required this.label,
    required this.deckName,
    required this.deckClass,
    required this.playerId,
    required this.playerName,
    required this.elo,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final color = HDTColors.fromDeckClass(deckClass);
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.md,
        border: Border.all(
            color: highlight ? color.withOpacity(0.4) : HDTColors.s2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HDTOverlineLabel(label),
              const Spacer(),
              HDTDeckClassBadge(deckClass),
            ],
          ),
          const SizedBox(height: 6),
          Text(deckName, style: HDTText.display(size: 14), maxLines: 2),
          const SizedBox(height: 4),
          Text('$playerId · $playerName',
              style: HDTText.mono(size: 10, color: HDTColors.text3)),
          if (elo != null) ...[
            const SizedBox(height: 2),
            Text('ELO $elo', style: HDTText.mono(size: 10, color: color)),
          ],
        ],
      ),
    );
  }
}
