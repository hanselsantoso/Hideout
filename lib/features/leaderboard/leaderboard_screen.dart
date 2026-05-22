// ============================================================
// LEADERBOARD SCREEN  — Riverpod + Pagination
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../core/widgets/hdt_widgets.dart';

// ─── Model ──────────────────────────────────────────────────
class PlayerEntry {
  final String id, name, bjxId, region, community, topClass;
  final int elo, delta, win, loss;
  final Color color;

  const PlayerEntry({
    required this.id,
    required this.name,
    required this.bjxId,
    required this.region,
    required this.community,
    required this.topClass,
    required this.elo,
    required this.delta,
    required this.win,
    required this.loss,
    required this.color,
  });

  double get winRate => win / (win + loss);
}

// ─── Mock Data ───────────────────────────────────────────────
Color _c(int value) => Color(value);
final List<PlayerEntry> _players = [
  PlayerEntry(
      id: '1',
      name: 'KAEDE',
      bjxId: 'HDT-001',
      region: 'JKT',
      community: 'Senayan Spinners',
      topClass: 'RUSHER',
      elo: 3120,
      delta: 24,
      win: 142,
      loss: 38,
      color: _c(0xFF9B4FA3)),
  PlayerEntry(
      id: '2',
      name: 'RAYHAN',
      bjxId: 'HDT-008',
      region: 'BDG',
      community: 'Bandung Beydads',
      topClass: 'BALANCE',
      elo: 3084,
      delta: 18,
      win: 138,
      loss: 42,
      color: _c(0xFFE67E22)),
  PlayerEntry(
      id: '3',
      name: 'MIKA',
      bjxId: 'HDT-014',
      region: 'JKT',
      community: 'Senayan Spinners',
      topClass: 'STAMINA',
      elo: 3041,
      delta: -12,
      win: 130,
      loss: 44,
      color: _c(0xFF27AE60)),
  PlayerEntry(
      id: '4',
      name: 'BAYU',
      bjxId: 'HDT-022',
      region: 'SBY',
      community: 'Surabaya X-Force',
      topClass: 'DEFENDER',
      elo: 2998,
      delta: 31,
      win: 124,
      loss: 46,
      color: _c(0xFF3498DB)),
  PlayerEntry(
      id: '5',
      name: 'NADIA',
      bjxId: 'HDT-031',
      region: 'YGY',
      community: 'Jogja Jagged',
      topClass: 'RUSHER',
      elo: 2965,
      delta: 6,
      win: 121,
      loss: 49,
      color: _c(0xFFF4D03F)),
  PlayerEntry(
      id: '6',
      name: 'HARIMAU',
      bjxId: 'HDT-202',
      region: 'JKT',
      community: 'Senayan Spinners',
      topClass: 'BALANCE',
      elo: 2921,
      delta: 14,
      win: 118,
      loss: 52,
      color: _c(0xFF9B4FA3)),
  PlayerEntry(
      id: '7',
      name: 'GERHANA',
      bjxId: 'HDT-045',
      region: 'BDG',
      community: 'Bandung Beydads',
      topClass: 'STAMINA',
      elo: 2890,
      delta: -3,
      win: 110,
      loss: 54,
      color: _c(0xFF5DADE2)),
  PlayerEntry(
      id: '8',
      name: 'SAKURA',
      bjxId: 'HDT-051',
      region: 'JKT',
      community: 'Kemang Knights',
      topClass: 'RUSHER',
      elo: 2872,
      delta: 22,
      win: 108,
      loss: 55,
      color: _c(0xFFEC7063)),
  PlayerEntry(
      id: '9',
      name: 'ZAIDAN',
      bjxId: 'HDT-066',
      region: 'MDN',
      community: 'Medan Maelstrom',
      topClass: 'DEFENDER',
      elo: 2841,
      delta: 11,
      win: 102,
      loss: 58,
      color: _c(0xFF1ABC9C)),
  PlayerEntry(
      id: '10',
      name: 'INDRA',
      bjxId: 'HDT-078',
      region: 'SBY',
      community: 'Surabaya X-Force',
      topClass: 'BALANCE',
      elo: 2820,
      delta: -8,
      win: 98,
      loss: 60,
      color: _c(0xFF7D3C98)),
  PlayerEntry(
      id: '11',
      name: 'LUNA',
      bjxId: 'HDT-082',
      region: 'JKT',
      community: 'Senayan Spinners',
      topClass: 'STAMINA',
      elo: 2802,
      delta: 17,
      win: 96,
      loss: 61,
      color: _c(0xFF48C9B0)),
  PlayerEntry(
      id: '12',
      name: 'TARO',
      bjxId: 'HDT-090',
      region: 'YGY',
      community: 'Jogja Jagged',
      topClass: 'RUSHER',
      elo: 2780,
      delta: 4,
      win: 94,
      loss: 64,
      color: _c(0xFFF39C12)),
  PlayerEntry(
      id: '13',
      name: 'ARYA',
      bjxId: 'HDT-105',
      region: 'BDG',
      community: 'Bandung Beydads',
      topClass: 'DEFENDER',
      elo: 2756,
      delta: -19,
      win: 90,
      loss: 66,
      color: _c(0xFF566573)),
  PlayerEntry(
      id: '14',
      name: 'NAYA',
      bjxId: 'HDT-118',
      region: 'JKT',
      community: 'Kemang Knights',
      topClass: 'BALANCE',
      elo: 2734,
      delta: 9,
      win: 88,
      loss: 68,
      color: _c(0xFFBB8FCE)),
  PlayerEntry(
      id: '15',
      name: 'KRISNA',
      bjxId: 'HDT-129',
      region: 'SBY',
      community: 'Surabaya X-Force',
      topClass: 'RUSHER',
      elo: 2710,
      delta: 13,
      win: 84,
      loss: 70,
      color: _c(0xFFE74C3C)),
  PlayerEntry(
      id: '16',
      name: 'DERRA',
      bjxId: 'HDT-156',
      region: 'JKT',
      community: 'Kemang Knights',
      topClass: 'STAMINA',
      elo: 2689,
      delta: -5,
      win: 80,
      loss: 72,
      color: _c(0xFF5499C7)),
  PlayerEntry(
      id: '17',
      name: 'MARDIKA',
      bjxId: 'HDT-007',
      region: 'JKT',
      community: 'Senayan Spinners',
      topClass: 'DEFENDER',
      elo: 2672,
      delta: 8,
      win: 78,
      loss: 74,
      color: _c(0xFFA569BD)),
  PlayerEntry(
      id: '18',
      name: 'BILLY',
      bjxId: 'HDT-030',
      region: 'JKT',
      community: 'Kemang Knights',
      topClass: 'RUSHER',
      elo: 2651,
      delta: 16,
      win: 75,
      loss: 76,
      color: _c(0xFFF0B27A)),
  PlayerEntry(
      id: '19',
      name: 'KAGE',
      bjxId: 'HDT-044',
      region: 'BDG',
      community: 'Bandung Beydads',
      topClass: 'BALANCE',
      elo: 2635,
      delta: -7,
      win: 72,
      loss: 78,
      color: _c(0xFF717D7E)),
  PlayerEntry(
      id: '20',
      name: 'AVI',
      bjxId: 'HDT-091',
      region: 'JKT',
      community: 'Senayan Spinners',
      topClass: 'STAMINA',
      elo: 2618,
      delta: 12,
      win: 70,
      loss: 80,
      color: _c(0xFF58D68D)),
  PlayerEntry(
      id: '21',
      name: 'FATIMA',
      bjxId: 'HDT-217',
      region: 'JKT',
      community: 'Kemang Knights',
      topClass: 'RUSHER',
      elo: 2601,
      delta: 20,
      win: 67,
      loss: 81,
      color: _c(0xFFF1948A)),
  PlayerEntry(
      id: '22',
      name: 'NIRO',
      bjxId: 'HDT-077',
      region: 'JKT',
      community: 'Senayan Spinners',
      topClass: 'DEFENDER',
      elo: 2580,
      delta: 3,
      win: 65,
      loss: 83,
      color: _c(0xFF85C1E9)),
  PlayerEntry(
      id: '23',
      name: 'GHOZALI',
      bjxId: 'HDT-201',
      region: 'BDG',
      community: 'Bandung Beydads',
      topClass: 'BALANCE',
      elo: 2562,
      delta: -11,
      win: 62,
      loss: 85,
      color: _c(0xFFA9CCE3)),
  PlayerEntry(
      id: '24',
      name: 'ZINBLACK',
      bjxId: 'HDT-014',
      region: 'JKT',
      community: 'Cikini Cyclones',
      topClass: 'RUSHER',
      elo: 2545,
      delta: 25,
      win: 60,
      loss: 87,
      color: _c(0xFFF9E79F)),
  PlayerEntry(
      id: '25',
      name: 'ARUNA',
      bjxId: 'HDT-188',
      region: 'JKT',
      community: 'Cikini Cyclones',
      topClass: 'STAMINA',
      elo: 2528,
      delta: 10,
      win: 58,
      loss: 89,
      color: _c(0xFFA3E4D7)),
  PlayerEntry(
      id: '26',
      name: 'DEWI',
      bjxId: 'HDT-141',
      region: 'BALI',
      community: 'Bali Beachblades',
      topClass: 'DEFENDER',
      elo: 2510,
      delta: 4,
      win: 55,
      loss: 90,
      color: _c(0xFF48C9B0)),
  PlayerEntry(
      id: '27',
      name: 'RAKA',
      bjxId: 'HDT-155',
      region: 'SBY',
      community: 'Surabaya X-Force',
      topClass: 'BALANCE',
      elo: 2492,
      delta: -6,
      win: 53,
      loss: 92,
      color: _c(0xFF7FB3D3)),
  PlayerEntry(
      id: '28',
      name: 'ZULFAN',
      bjxId: 'HDT-169',
      region: 'MDN',
      community: 'Medan Maelstrom',
      topClass: 'RUSHER',
      elo: 2475,
      delta: 14,
      win: 51,
      loss: 93,
      color: _c(0xFF82E0AA)),
  PlayerEntry(
      id: '29',
      name: 'BUNGA',
      bjxId: 'HDT-174',
      region: 'YGY',
      community: 'Jogja Jagged',
      topClass: 'STAMINA',
      elo: 2458,
      delta: -2,
      win: 49,
      loss: 95,
      color: _c(0xFFF0A500)),
  PlayerEntry(
      id: '30',
      name: 'RAFA',
      bjxId: 'HDT-118',
      region: 'JKT',
      community: 'Kemang Knights',
      topClass: 'DEFENDER',
      elo: 2440,
      delta: 7,
      win: 47,
      loss: 97,
      color: _c(0xFFC0392B)),
];

// ─── State & Notifier ────────────────────────────────────────
class LeaderboardState {
  final String region;
  final String window;
  final String query;
  final int page;

  const LeaderboardState({
    this.region = 'ALL',
    this.window = '30D',
    this.query = '',
    this.page = 0,
  });

  LeaderboardState copyWith(
          {String? region, String? window, String? query, int? page}) =>
      LeaderboardState(
        region: region ?? this.region,
        window: window ?? this.window,
        query: query ?? this.query,
        page: page ?? this.page,
      );

  List<PlayerEntry> get list {
    return [..._players]
        .where((p) => region == 'ALL' || p.region == region)
        .where((p) =>
            query.isEmpty ||
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.bjxId.toLowerCase().contains(query.toLowerCase()))
        .toList()
      ..sort((a, b) => b.elo.compareTo(a.elo));
  }
}

class LeaderboardNotifier extends Notifier<LeaderboardState> {
  @override
  LeaderboardState build() => const LeaderboardState();
  void setRegion(String r) => state = state.copyWith(region: r, page: 0);
  void setWindow(String w) => state = state.copyWith(window: w, page: 0);
  void setQuery(String q) => state = state.copyWith(query: q, page: 0);
  void setPage(int p) => state = state.copyWith(page: p);
}

final leaderboardProvider =
    NotifierProvider<LeaderboardNotifier, LeaderboardState>(
        LeaderboardNotifier.new);

// ─── Screen ──────────────────────────────────────────────────
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  static const _perPage = 10;
  static const _regions = ['ALL', 'JKT', 'BDG', 'SBY', 'MDN', 'YGY', 'BALI'];
  static const _windows = ['7D', '30D', 'SEASON', 'ALL'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);
    final list = state.list;
    final podium = list.take(3).toList();
    final rest = list.skip(3).toList();
    final paginatedRest =
        rest.skip(state.page * _perPage).take(_perPage).toList();

    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: showAppBar
          ? AppBar(
              title: const Text('LEADERBOARD'),
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1), child: hdtDivider()),
            )
          : null,
      body: Column(
        children: [
          // ── Filters bar ──────────────────────────────────
          Container(
            color: const Color(0xEB0F1115),
            padding: const EdgeInsets.symmetric(
                horizontal: HDTSpace.lg, vertical: HDTSpace.sm),
            child: Column(
              children: [
                // Region filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _regions
                        .map((r) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: HDTFilterChip(
                                label: r,
                                selected: state.region == r,
                                onTap: () => notifier.setRegion(r),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: HDTSpace.sm),
                Row(children: [
                  // Window filter
                  ..._windows.map((w) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: HDTFilterChip(
                          label: w,
                          selected: state.window == w,
                          onTap: () => notifier.setWindow(w),
                        ),
                      )),
                  const Spacer(),
                  // Search
                  SizedBox(
                    width: 180,
                    child: HDTSearchField(
                      controller: TextEditingController(text: state.query),
                      placeholder: 'Search players...',
                      onChanged: notifier.setQuery,
                    ),
                  ),
                ]),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(HDTSpace.lg),
              children: [
                // ── Podium ─────────────────────────────────
                if (podium.length == 3) ...[
                  _PodiumRow(podium: podium),
                  const SizedBox(height: HDTSpace.lg),
                ],

                // ── Rest table ─────────────────────────────
                Container(
                  decoration: hdtCard(),
                  child: Column(
                    children: [
                      // header
                      _TableHeader(),
                      ...paginatedRest.asMap().entries.map((e) => _PlayerRow(
                            player: e.value,
                            rank: state.page * _perPage + e.key + 4,
                          )),
                      if (paginatedRest.isEmpty)
                        HDTEmptyState(
                            icon: Icons.people_outline, title: 'NO PLAYERS'),
                    ],
                  ),
                ),

                const SizedBox(height: HDTSpace.lg),
                HDTPagination(
                  total: rest.length,
                  page: state.page,
                  perPage: _perPage,
                  label: 'players',
                  onPage: notifier.setPage,
                ),
                const SizedBox(height: HDTSpace.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List<PlayerEntry> podium;
  const _PodiumRow({required this.podium});

  @override
  Widget build(BuildContext context) {
    final order = [podium[1], podium[0], podium[2]];
    final ranks = [2, 1, 3];
    final heights = [140.0, 170.0, 130.0];
    final medals = [
      const Color(0xFFBDC3C7),
      const Color(0xFFF4D03F),
      const Color(0xFFCD7F32)
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final p = order[i];
        final rank = ranks[i];
        final medal = medals[i];
        return Expanded(
          child: Container(
            height: heights[i],
            margin:
                EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 2 ? 0 : 6),
            padding: const EdgeInsets.all(HDTSpace.md),
            decoration: hdtAccentCard(
              accentColor: p.color,
              highlighted: rank == 1,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration:
                          BoxDecoration(color: medal, borderRadius: HDTR.sm),
                      child: Center(
                          child: Text('$rank',
                              style: HDTText.display(
                                  size: 14, color: HDTColors.bg))),
                    ),
                    if (rank == 1)
                      Icon(Icons.emoji_events, color: medal, size: 20),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.bjxId,
                        style: HDTText.mono(size: 9, color: HDTColors.text3)),
                    Text(p.name,
                        style: HDTText.display(size: rank == 1 ? 22 : 18)),
                    const SizedBox(height: 4),
                    Text('${p.elo}',
                        style: HDTText.display(
                            size: rank == 1 ? 28 : 22, color: medal)),
                    HDTEloChip(p.delta, size: 11),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: HDTSpace.lg, vertical: HDTSpace.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(children: [
        SizedBox(width: 36, child: Text('RANK', style: HDTText.overline())),
        const SizedBox(width: 12),
        Expanded(child: Text('PLAYER', style: HDTText.overline())),
        SizedBox(width: 60, child: Text('ELO', style: HDTText.overline())),
        SizedBox(width: 50, child: Text('Δ', style: HDTText.overline())),
        SizedBox(width: 50, child: Text('W/L', style: HDTText.overline())),
      ]),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final PlayerEntry player;
  final int rank;

  const _PlayerRow({required this.player, required this.rank});

  @override
  Widget build(BuildContext context) {
    final p = player;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: HDTSpace.lg, vertical: HDTSpace.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [p.color.withOpacity(0.06), Colors.transparent],
            stops: const [0, 0.4]),
        border: const Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(children: [
        // Rank
        SizedBox(
          width: 36,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                borderRadius: HDTR.sm, border: Border.all(color: HDTColors.s2)),
            child: Center(child: Text('$rank', style: HDTText.mono(size: 11))),
          ),
        ),
        const SizedBox(width: 12),
        // Avatar + name
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: p.color, borderRadius: HDTR.sm),
          child: Center(
              child: Text(p.name[0],
                  style: HDTText.display(size: 14, color: Colors.white))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: HDTText.display(size: 15)),
            Text('${p.bjxId} · ${p.community}',
                style: HDTText.mono(size: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        // ELO
        SizedBox(
            width: 60,
            child: Text('${p.elo}', style: HDTText.display(size: 16))),
        // Delta
        SizedBox(width: 50, child: HDTEloChip(p.delta)),
        // W/L
        SizedBox(
          width: 50,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${p.win}–${p.loss}', style: HDTText.mono(size: 11)),
            Text('${(p.winRate * 100).toStringAsFixed(0)}%',
                style: HDTText.mono(size: 10, color: HDTColors.text3)),
          ]),
        ),
      ]),
    );
  }
}
