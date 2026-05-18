import 'package:flutter/material.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../core/widgets/hdt_widgets.dart';

enum PlayerTournamentStatus {
  registered,
  checkedIn,
  ongoing,
  completed,
  eliminated,
}

class PlayerTournamentEntry {
  final String id;
  final String name;
  final String community;
  final PlayerTournamentStatus status;
  final DateTime date;
  final String venue;
  final String city;
  final String tier;
  final String format;
  final int registered;
  final int capacity;
  final Color color;
  final String deck;
  final String ticketId;
  final String? result;
  final int? position;
  final int? eloChange;
  final String? prize;

  const PlayerTournamentEntry({
    required this.id,
    required this.name,
    required this.community,
    required this.status,
    required this.date,
    required this.venue,
    required this.city,
    required this.tier,
    required this.format,
    required this.registered,
    required this.capacity,
    required this.color,
    required this.deck,
    required this.ticketId,
    this.result,
    this.position,
    this.eloChange,
    this.prize,
  });

  Map<String, Object> toTournamentArgs() => {
        'tournamentId': id,
        'name': name,
        'community': community,
        'status': status == PlayerTournamentStatus.ongoing
            ? 'LIVE'
            : status == PlayerTournamentStatus.registered
                ? 'REGISTRATION OPEN'
                : 'COMPLETED',
        'format': format,
        'tier': tier,
        'city': city,
        'venue': venue,
        'fee': 'Rp 100.000',
        'date': date.toIso8601String(),
        'registered': registered,
        'capacity': capacity,
      };

  Map<String, Object> toTicketArgs() => {
        'ticketId': ticketId,
        'tournamentName': name,
        'community': community,
        'player': 'HANSEL',
        'bjxId': 'HDT-202',
        'deck': deck,
        'venue': venue,
        'city': city,
        'date': date.toIso8601String(),
        'status': statusLabel,
      };

  String get statusLabel {
    return switch (status) {
      PlayerTournamentStatus.registered => 'REGISTERED',
      PlayerTournamentStatus.checkedIn => 'CHECKED IN',
      PlayerTournamentStatus.ongoing => 'ONGOING',
      PlayerTournamentStatus.completed => 'COMPLETED',
      PlayerTournamentStatus.eliminated => 'ELIMINATED',
    };
  }
}

final playerTournamentDemo = [
  PlayerTournamentEntry(
    id: 'bjx-cup-3',
    name: 'HIDEOUT Cup #3. Spring Showdown',
    community: 'JKT Wolves',
    status: PlayerTournamentStatus.ongoing,
    date: DateTime(2026, 5, 9),
    venue: 'GBK Senayan',
    city: 'Jakarta',
    tier: 'PREMIER',
    format: 'Swiss to Double Elim',
    registered: 64,
    capacity: 64,
    color: HDTColors.accent,
    deck: 'Phantom Reaper',
    ticketId: 'HDT-CUP-3-0064',
  ),
  PlayerTournamentEntry(
    id: 'bjx-cup-4',
    name: 'HIDEOUT Cup #4. Summer Open',
    community: 'JKT Wolves',
    status: PlayerTournamentStatus.registered,
    date: DateTime(2026, 6, 14),
    venue: 'GBK Senayan',
    city: 'Jakarta',
    tier: 'STANDARD',
    format: 'Single Elim',
    registered: 42,
    capacity: 64,
    color: HDTColors.info,
    deck: 'Void Bastion',
    ticketId: 'HDT-CUP-4-0042',
  ),
  PlayerTournamentEntry(
    id: 'snyo-apr',
    name: 'Senayan Open. April',
    community: 'JKT Wolves',
    status: PlayerTournamentStatus.completed,
    date: DateTime(2026, 4, 26),
    venue: 'GBK Senayan',
    city: 'Jakarta',
    tier: 'STANDARD',
    format: 'Swiss to Double Elim',
    registered: 48,
    capacity: 48,
    color: HDTColors.success,
    deck: 'Phantom Reaper',
    ticketId: 'HDT-APR-0048',
    result: 'TOP 8',
    position: 6,
    eloChange: 42,
  ),
  PlayerTournamentEntry(
    id: 'bdg-h1',
    name: 'BDG Highland Open Vol.1',
    community: 'BDG Grinders',
    status: PlayerTournamentStatus.completed,
    date: DateTime(2026, 3, 15),
    venue: 'Trans Studio',
    city: 'Bandung',
    tier: 'STANDARD',
    format: 'Single Elim',
    registered: 32,
    capacity: 32,
    color: HDTColors.warning,
    deck: 'Shrike Mk.II',
    ticketId: 'BDG-H1-0016',
    result: 'CHAMPION',
    position: 1,
    eloChange: 88,
    prize: 'Rp 500.000 + DranSword 2-60S',
  ),
  PlayerTournamentEntry(
    id: 'wkly-17',
    name: 'Weekly Ranked #17',
    community: 'JKT Wolves',
    status: PlayerTournamentStatus.completed,
    date: DateTime(2026, 2, 14),
    venue: 'Senayan Hub',
    city: 'Jakarta',
    tier: 'CASUAL',
    format: 'Swiss',
    registered: 28,
    capacity: 32,
    color: HDTColors.info,
    deck: 'Void Bastion',
    ticketId: 'WKLY-17-0012',
    result: 'TOP 4',
    position: 3,
    eloChange: 30,
  ),
  PlayerTournamentEntry(
    id: 'wkly-16',
    name: 'Weekly Ranked #16',
    community: 'JKT Wolves',
    status: PlayerTournamentStatus.eliminated,
    date: DateTime(2026, 2, 7),
    venue: 'Senayan Hub',
    city: 'Jakarta',
    tier: 'CASUAL',
    format: 'Swiss',
    registered: 24,
    capacity: 32,
    color: HDTColors.danger,
    deck: 'Cobalt Rush',
    ticketId: 'WKLY-16-0012',
    result: 'TOP 16',
    position: 12,
    eloChange: -8,
  ),
];

class MyTournamentsScreen extends StatefulWidget {
  const MyTournamentsScreen({super.key});

  @override
  State<MyTournamentsScreen> createState() => _MyTournamentsScreenState();
}

class _MyTournamentsScreenState extends State<MyTournamentsScreen> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'ALL'
        ? playerTournamentDemo
        : playerTournamentDemo
            .where((item) => item.statusLabel == _filter)
            .toList();
    final completed = playerTournamentDemo
        .where((item) =>
            item.status == PlayerTournamentStatus.completed ||
            item.status == PlayerTournamentStatus.eliminated)
        .length;
    final wins = playerTournamentDemo
        .where((item) => item.position != null && item.position == 1)
        .length;
    final top4 = playerTournamentDemo
        .where((item) => item.position != null && item.position! <= 4)
        .length;

    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () =>
                  Navigator.pushReplacementNamed(context, '/dashboard'),
              onQr: () => Navigator.pushNamed(
                context,
                '/me/qr',
                arguments: playerTournamentDemo.first.toTicketArgs(),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 90),
                    children: [
                      _TitleBar(
                        onFind: () => Navigator.pushReplacementNamed(
                            context, '/dashboard'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'TOTAL TURNAMEN',
                              value: '$completed',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'CHAMPION',
                              value: '$wins',
                              color: HDTColors.accentHover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'TOP 4',
                              value: '$top4',
                              color: HDTColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final filter in const [
                              'ALL',
                              'ONGOING',
                              'REGISTERED',
                              'COMPLETED',
                              'ELIMINATED',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: HDTFilterChip(
                                  label: filter,
                                  selected: _filter == filter,
                                  onTap: () => setState(() => _filter = filter),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (final tournament in filtered) ...[
                        _TournamentRow(tournament: tournament),
                        const SizedBox(height: 12),
                      ],
                      if (filtered.isEmpty)
                        const HDTEmptyState(
                          icon: Icons.emoji_events_outlined,
                          title: 'BELUM ADA TURNAMEN',
                          subtitle:
                              'Ubah filter atau daftar tournament terlebih dahulu.',
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onQr;

  const _Header({required this.onBack, required this.onQr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xEA0F1115),
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: HDTR.md,
            onTap: onBack,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: HDTR.md,
                border: Border.all(color: HDTColors.s2),
              ),
              child: const Icon(Icons.chevron_left,
                  size: 18, color: HDTColors.text2),
            ),
          ),
          const SizedBox(width: 12),
          Text('DASHBOARD', style: HDTText.overline(size: 10)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 12, color: HDTColors.text3),
          const SizedBox(width: 8),
          Expanded(
            child: Text('TURNAMENKU',
                style: HDTText.overline(size: 10, color: HDTColors.text)),
          ),
          ElevatedButton.icon(
            onPressed: onQr,
            icon: const Icon(Icons.qr_code_2, size: 14),
            label: const Text('QR CHECK-IN'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(128, 34),
              textStyle: HDTText.overline(size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  final VoidCallback onFind;

  const _TitleBar({required this.onFind});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TURNAMEN SAYA', style: HDTText.display(size: 34)),
            const SizedBox(height: 4),
            Text(
              'Riwayat, tiket, QR check-in, dan deck yang sudah dikunci.',
              style: HDTText.body(size: 13, color: HDTColors.text3),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: onFind,
          icon: const Icon(Icons.emoji_events_outlined, size: 14),
          label: const Text('CARI TURNAMEN'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatCard({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HDTText.overline(size: 9)),
          const SizedBox(height: 4),
          Text(value, style: HDTText.display(size: 28, color: color)),
        ],
      ),
    );
  }
}

class _TournamentRow extends StatelessWidget {
  final PlayerTournamentEntry tournament;

  const _TournamentRow({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(tournament.status);
    final tier = _tierStyle(tournament.tier);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: hdtCard(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 680;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Badge(label: tournament.tier, color: tier.$1, bg: tier.$2),
                  _Badge(label: status.$3, color: status.$1, bg: status.$2),
                  if (tournament.position == 1)
                    const _Badge(
                      label: 'CHAMPION',
                      color: HDTColors.accentHover,
                      bg: HDTColors.accentDim,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tournament.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: HDTText.display(size: 18, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _Meta(
                    icon: Icons.calendar_today_outlined,
                    text: _shortDate(tournament.date),
                  ),
                  _Meta(
                    icon: Icons.location_on_outlined,
                    text: tournament.venue,
                  ),
                  _Meta(
                    icon: Icons.filter_alt_outlined,
                    text: tournament.format,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Deck: ${tournament.deck} . ${tournament.registered}/${tournament.capacity} peserta',
                style: HDTText.mono(size: 11, color: HDTColors.text3),
              ),
              if (tournament.result != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      'ELO ${tournament.eloChange! > 0 ? '+' : ''}${tournament.eloChange}',
                      style: HDTText.mono(
                        size: 12,
                        color: tournament.eloChange! > 0
                            ? HDTColors.success
                            : HDTColors.danger,
                      ),
                    ),
                    Text('Hasil: ${tournament.result}',
                        style: HDTText.body(size: 12, color: HDTColors.text3)),
                    if (tournament.prize != null)
                      Text('Prize: ${tournament.prize}',
                          style:
                              HDTText.body(size: 12, color: HDTColors.success)),
                  ],
                ),
              ],
            ],
          );

          final actions = _Actions(tournament: tournament);
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final PlayerTournamentEntry tournament;

  const _Actions({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final active = tournament.status == PlayerTournamentStatus.ongoing ||
        tournament.status == PlayerTournamentStatus.registered ||
        tournament.status == PlayerTournamentStatus.checkedIn;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (active)
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/me/qr',
              arguments: tournament.toTicketArgs(),
            ),
            icon: const Icon(Icons.qr_code_2, size: 13),
            label: const Text('QR'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(76, 34)),
          ),
        OutlinedButton(
          onPressed: () {},
          child: const Text('BRACKET'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(
            context,
            '/tournaments/detail',
            arguments: tournament.toTournamentArgs(),
          ),
          child: const Text('DETAIL'),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: HDTR.sm,
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(label.toUpperCase(),
          style: HDTText.overline(size: 8, color: color)),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: HDTColors.text3),
        const SizedBox(width: 5),
        Text(text, style: HDTText.body(size: 12, color: HDTColors.text3)),
      ],
    );
  }
}

(Color, Color, String) _statusStyle(PlayerTournamentStatus status) {
  return switch (status) {
    PlayerTournamentStatus.ongoing => (
        Colors.white,
        HDTColors.accent,
        'ONGOING'
      ),
    PlayerTournamentStatus.registered => (
        HDTColors.info,
        HDTColors.info.withValues(alpha: .16),
        'REGISTERED'
      ),
    PlayerTournamentStatus.checkedIn => (
        HDTColors.success,
        HDTColors.success.withValues(alpha: .15),
        'CHECKED IN'
      ),
    PlayerTournamentStatus.completed => (
        HDTColors.text3,
        HDTColors.s2,
        'COMPLETED'
      ),
    PlayerTournamentStatus.eliminated => (
        HDTColors.danger,
        HDTColors.danger.withValues(alpha: .12),
        'ELIMINATED'
      ),
  };
}

(Color, Color) _tierStyle(String tier) {
  return switch (tier) {
    'PREMIER' => (HDTColors.accentHover, HDTColors.accentDim),
    'STANDARD' => (HDTColors.info, HDTColors.info.withValues(alpha: .15)),
    _ => (HDTColors.text3, HDTColors.s2),
  };
}

String _shortDate(DateTime date) {
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
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
