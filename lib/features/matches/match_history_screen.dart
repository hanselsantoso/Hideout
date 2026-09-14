// ============================================================
// MATCH HISTORY — data nyata dari Firestore + statistik + pagination
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../core/widgets/hdt_widgets.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/tournament_repository.dart';

class MatchHistoryRow {
  const MatchHistoryRow({
    required this.id,
    required this.tournamentName,
    required this.roundLabel,
    required this.opponentName,
    required this.score,
    required this.result,
    required this.date,
  });

  final String id;
  final String tournamentName;
  final String roundLabel;
  final String opponentName;
  final String score;
  final String result; // WIN | LOSS | DRAW
  final DateTime? date;

  bool get isWin => result == 'WIN';
  bool get isDraw => result == 'DRAW';
}

class MatchHistoryNotifier extends AsyncNotifier<List<MatchHistoryRow>> {
  @override
  Future<List<MatchHistoryRow>> build() async {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const <MatchHistoryRow>[];
    final rows =
        await ref.read(tournamentRepositoryProvider).fetchPlayerMatches(
              uid: user.uid,
            );
    return rows
        .map((row) => MatchHistoryRow(
              id: row.id,
              tournamentName: row.tournamentName,
              roundLabel: row.roundLabel,
              opponentName: row.opponentName,
              score: row.score,
              result: row.result,
              date: row.date,
            ))
        .toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final matchHistoryProvider =
    AsyncNotifierProvider<MatchHistoryNotifier, List<MatchHistoryRow>>(
        MatchHistoryNotifier.new);

class MatchHistoryScreen extends ConsumerStatefulWidget {
  const MatchHistoryScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  ConsumerState<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends ConsumerState<MatchHistoryScreen> {
  static const _perPage = 8;
  String _sort = 'newest';
  int _page = 0;

  List<MatchHistoryRow> _applySort(List<MatchHistoryRow> rows) {
    final copy = [...rows];
    return switch (_sort) {
      'oldest' =>
        copy..sort((a, b) => (a.date ?? DateTime(0))
            .compareTo(b.date ?? DateTime.fromMillisecondsSinceEpoch(0))),
      'opponent' => copy..sort((a, b) =>
          a.opponentName.toLowerCase().compareTo(b.opponentName.toLowerCase())),
      _ => copy..sort((a, b) => (b.date ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.date ?? DateTime.fromMillisecondsSinceEpoch(0))),
    };
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(matchHistoryProvider);
    final profile = ref.watch(currentUserProfileProvider);
    final rows = _applySort(history.valueOrNull ?? const <MatchHistoryRow>[]);
    final wins = rows.where((row) => row.isWin).length;
    final losses = rows.where((row) => row.result == 'LOSS').length;
    final draws = rows.where((row) => row.isDraw).length;
    final winRate = (wins + losses) == 0 ? 0.0 : wins / (wins + losses);
    final elo = profile.valueOrNull?.eloRating ?? 0;
    final paged = rows.skip(_page * _perPage).take(_perPage).toList();
    final totalPages = rows.isEmpty ? 1 : (rows.length / _perPage).ceil();
    final currentPage = _page.clamp(0, totalPages - 1).toInt();

    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('MY MATCHES'),
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1), child: hdtDivider()),
            )
          : null,
      body: history.isLoading && rows.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      HDTSpace.lg, HDTSpace.xl, HDTSpace.lg, 90),
                  children: [
                    _StatsHeader(
                      wins: wins,
                      losses: losses,
                      draws: draws,
                      winRate: winRate,
                      elo: elo,
                    ),
                    const SizedBox(height: HDTSpace.xl),
                    _ResultChart(rows: rows),
                    const SizedBox(height: HDTSpace.xl),
                    Row(
                      children: [
                        Expanded(
                          child: Text('MATCH HISTORY',
                              style: HDTText.overline(size: 10)),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sort,
                            dropdownColor: HDTColors.s1,
                            style: HDTText.overline(
                                size: 9, color: HDTColors.text),
                            items: const [
                              DropdownMenuItem(
                                  value: 'newest',
                                  child: Text('TERBARU',
                                      style: TextStyle(fontSize: 11))),
                              DropdownMenuItem(
                                  value: 'oldest',
                                  child: Text('TERLAMA',
                                      style: TextStyle(fontSize: 11))),
                              DropdownMenuItem(
                                  value: 'opponent',
                                  child: Text('LAWAN (A-Z)',
                                      style: TextStyle(fontSize: 11))),
                            ],
                            onChanged: (value) => setState(() {
                              _sort = value ?? 'newest';
                              _page = 0;
                            }),
                          ),
                        ),
                        const SizedBox(width: HDTSpace.sm),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: () =>
                              ref.read(matchHistoryProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: HDTSpace.md),
                    if (rows.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(HDTSpace.xl),
                        decoration: hdtCard(),
                        child: const HDTEmptyState(
                          icon: Icons.sports_martial_arts_outlined,
                          title: 'BELUM ADA MATCH',
                          subtitle:
                              'Selesaikan turnamen pertamamu, lalu history match akan muncul di sini.',
                        ),
                      )
                    else ...[
                      for (final row in paged) ...[
                        _MatchCard(row: row),
                        const SizedBox(height: HDTSpace.sm),
                      ],
                      const SizedBox(height: HDTSpace.md),
                      HDTPagination(
                        total: rows.length,
                        page: currentPage,
                        perPage: _perPage,
                        label: 'match',
                        onPage: (value) => setState(() => _page = value),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    required this.elo,
  });

  final int wins;
  final int losses;
  final int draws;
  final double winRate;
  final int elo;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: HDTSpace.md,
      runSpacing: HDTSpace.md,
      children: [
        SizedBox(
          width: 200,
          child: _StatTile(
            label: 'ELO RATING',
            value: '$elo',
            color: HDTColors.accentHover,
          ),
        ),
        SizedBox(
          width: 140,
          child: _StatTile(
            label: 'WIN',
            value: '$wins',
            color: HDTColors.success,
          ),
        ),
        SizedBox(
          width: 140,
          child: _StatTile(
            label: 'LOSS',
            value: '$losses',
            color: HDTColors.danger,
          ),
        ),
        SizedBox(
          width: 140,
          child: _StatTile(
            label: 'DRAW',
            value: '$draws',
            color: HDTColors.text2,
          ),
        ),
        SizedBox(
          width: 160,
          child: _StatTile(
            label: 'WIN RATE',
            value: '${(winRate * 100).round()}%',
            color: HDTColors.info,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HDTText.overline(size: 9)),
          const SizedBox(height: 6),
          Text(value,
              style: HDTText.display(size: 28, color: color)),
        ],
      ),
    );
  }
}

class _ResultChart extends StatelessWidget {
  const _ResultChart({required this.rows});

  final List<MatchHistoryRow> rows;

  @override
  Widget build(BuildContext context) {
    final recent = rows.take(12).toList().reversed.toList();
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('10 MATCH TERAKHIR', style: HDTText.overline(size: 10)),
          const SizedBox(height: HDTSpace.lg),
          SizedBox(
            height: 110,
            child: recent.isEmpty
                ? Center(
                    child: Text('Belum ada data untuk grafik.',
                        style: HDTText.body(size: 11, color: HDTColors.text3)))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < recent.length; i++) ...[
                        Expanded(
                          child: CustomPaint(
                            size: const Size(double.infinity, 110),
                            painter: _ResultBarPainter(
                              isWin: recent[i].isWin,
                              isDraw: recent[i].isDraw,
                              position: i,
                              total: recent.length,
                            ),
                          ),
                        ),
                        if (i != recent.length - 1) const SizedBox(width: 6),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: HDTSpace.sm),
          Row(
            children: [
              _Legend(color: HDTColors.success, label: 'WIN'),
              const SizedBox(width: 12),
              _Legend(color: HDTColors.danger, label: 'LOSS'),
              const SizedBox(width: 12),
              _Legend(color: HDTColors.text2, label: 'DRAW'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultBarPainter extends CustomPainter {
  const _ResultBarPainter({
    required this.isWin,
    required this.isDraw,
    required this.position,
    required this.total,
  });

  final bool isWin;
  final bool isDraw;
  final int position;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = isDraw ? size.height * 0.4 : size.height * 0.85;
    final color = isWin
        ? HDTColors.success
        : isDraw
            ? HDTColors.text3
            : HDTColors.danger;
    final paint = Paint()
      ..color = color.withValues(alpha: isWin || isDraw ? 0.85 : 0.75)
      ..style = PaintingStyle.fill;
    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height - barHeight,
        size.width * 0.76,
        barHeight,
      ),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(3),
      bottomRight: const Radius.circular(3),
    );
    canvas.drawRRect(rect, paint);
    if (position == total - 1) {
      final marker = Paint()..color = HDTColors.accentHover;
      canvas.drawCircle(
        Offset(size.width / 2, size.height - barHeight - 8),
        3,
        marker,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ResultBarPainter oldDelegate) => false;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: HDTR.sm),
        ),
        const SizedBox(width: 6),
        Text(label, style: HDTText.overline(size: 8, color: HDTColors.text3)),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.row});

  final MatchHistoryRow row;

  @override
  Widget build(BuildContext context) {
    final winColor = row.isWin
        ? HDTColors.success
        : row.isDraw
            ? HDTColors.text2
            : HDTColors.danger;
    final date = row.date == null
        ? 'TBA'
        : '${row.date!.day}/${row.date!.month}/${row.date!.year}';
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: winColor.withValues(alpha: .12),
              borderRadius: HDTR.md,
              border: Border.all(color: winColor.withValues(alpha: .4)),
            ),
            child: Text(
              row.result,
              style: HDTText.display(size: 13, color: winColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VS ${row.opponentName.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.display(size: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${row.tournamentName.toUpperCase()} . ${row.roundLabel.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.mono(size: 10, color: HDTColors.text3),
                ),
              ],
            ),
          ),
          const SizedBox(width: HDTSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(row.score.isEmpty ? '-' : row.score,
                  style: HDTText.display(size: 16, color: HDTColors.text)),
              const SizedBox(height: 4),
              Text(date, style: HDTText.mono(size: 10, color: HDTColors.text3)),
            ],
          ),
        ],
      ),
    );
  }
}
