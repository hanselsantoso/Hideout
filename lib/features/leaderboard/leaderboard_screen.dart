// ============================================================
// LEADERBOARD SCREEN  — Riverpod + Pagination
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../core/widgets/hdt_widgets.dart';
import '../../data/repositories/auth_repository.dart';

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

// ─── Real data ──────────────────────────────────────────────
final leaderboardPlayersProvider =
    StreamProvider<List<PlayerEntry>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirestorePaths.users)
      .orderBy('eloRating', descending: true)
      .limit(200)
      .snapshots()
      .map((snap) {
    return snap.docs
        .map((doc) {
          final data = doc.data();
          final roles = <String>{
            (data['role'] ?? 'player').toString(),
            ...((data['roles'] as Iterable?) ?? const [])
                .map((role) => role.toString()),
          };
          if (roles.contains('super_admin')) return null;
          if (data['isActive'] == false) return null;
          final win = (data['totalWins'] as num?)?.round() ?? 0;
          final loss = (data['totalLosses'] as num?)?.round() ?? 0;
          if (win + loss == 0) return null; // Belum pernah bertanding
          final uid = doc.id;
          final code = (data['playerCode'] ?? '').toString();
          final colorSeed = (uid.hashCode & 0xFFFFFF) | 0x404040;
          return PlayerEntry(
            id: uid,
            name: ((data['displayName'] ?? data['name'] ?? 'PLAYER')
                    .toString())
                .toUpperCase(),
            bjxId: code.isEmpty
                ? 'HDT-${uid.substring(0, uid.length >= 4 ? 4 : uid.length).toUpperCase()}'
                : code.toUpperCase(),
            region: (data['region'] ?? '').toString().toUpperCase(),
            community: '',
            topClass: '',
            elo: (data['eloRating'] as num?)?.round() ?? 0,
            delta: 0,
            win: win,
            loss: loss,
            color: Color(colorSeed),
          );
        })
        .whereType<PlayerEntry>()
        .toList();
  });
});

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
    final playersAsync = ref.watch(leaderboardPlayersProvider);
    final allPlayers = playersAsync.valueOrNull ?? const <PlayerEntry>[];
    final list = allPlayers
        .where((p) => state.region == 'ALL' || p.region == state.region)
        .where((p) =>
            state.query.isEmpty ||
            p.name.toLowerCase().contains(state.query.toLowerCase()) ||
            p.bjxId.toLowerCase().contains(state.query.toLowerCase()))
        .toList()
      ..sort((a, b) => b.elo.compareTo(a.elo));
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
                        const HDTEmptyState(
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
            colors: [p.color.withValues(alpha: 0.06), Colors.transparent],
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
