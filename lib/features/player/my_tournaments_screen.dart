import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../core/widgets/hdt_widgets.dart';
import '../../data/repositories/auth_repository.dart';

enum PlayerTournamentStatus {
  pendingPayment,
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
  final String fee;
  final String registrationStatus;
  final String paymentStatus;
  final String ticketId;
  final String playerName;
  final String playerCode;
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
    required this.fee,
    required this.registrationStatus,
    required this.paymentStatus,
    required this.ticketId,
    this.playerName = 'PLAYER',
    this.playerCode = '',
    this.result,
    this.position,
    this.eloChange,
    this.prize,
  });

  Map<String, Object> toTournamentArgs() => {
        'tournamentId': id,
        'name': name,
        'community': community,
        'status': status == PlayerTournamentStatus.ongoing ? 'LIVE' : 'OPEN',
        'format': format,
        'tier': tier,
        'city': city,
        'venue': venue,
        'fee': fee,
        'date': date.toIso8601String(),
        'registered': registered,
        'capacity': capacity,
        'player': playerName,
        'bjxId': playerCode.isEmpty ? ticketId : playerCode,
        'deck': deck,
      };

  Map<String, Object> toPaymentArgs() => {
        ...toTournamentArgs(),
        'registrationId': ticketId,
        'resumePayment': true,
        'initialStep': 3,
      };

  Map<String, Object> toTicketArgs() => {
        'ticketId': ticketId,
        'tournamentName': name,
        'community': community,
        'player': playerName,
        'bjxId': playerCode.isEmpty ? ticketId : playerCode,
        'deck': deck,
        'venue': venue,
        'city': city,
        'date': date.toIso8601String(),
        'status': statusLabel,
      };

  String get statusLabel {
    return switch (status) {
      PlayerTournamentStatus.pendingPayment => 'PENDING PAYMENT',
      PlayerTournamentStatus.registered => 'REGISTERED',
      PlayerTournamentStatus.checkedIn => 'CHECKED IN',
      PlayerTournamentStatus.ongoing => 'ONGOING',
      PlayerTournamentStatus.completed => 'COMPLETED',
      PlayerTournamentStatus.eliminated => 'ELIMINATED',
    };
  }
}

final playerTournamentEntriesProvider =
    StreamProvider<List<PlayerTournamentEntry>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<PlayerTournamentEntry>>.value(const []);
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collectionGroup(FirestorePaths.registrations)
      .where('playerId', isEqualTo: user.uid)
      .limit(80)
      .snapshots()
      .asyncMap((snap) async {
    final rows = <PlayerTournamentEntry>[];
    for (final doc in snap.docs) {
      final tournamentRef = doc.reference.parent.parent;
      if (tournamentRef == null) continue;
      final tournamentSnap = await tournamentRef.get();
      rows.add(_entryFromLive(
        registrationId: doc.id,
        registration: doc.data(),
        tournamentId: tournamentRef.id,
        tournament: tournamentSnap.data() ?? const <String, dynamic>{},
      ));
    }
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  });
});

PlayerTournamentEntry _entryFromLive({
  required String registrationId,
  required String tournamentId,
  required Map<String, dynamic> registration,
  required Map<String, dynamic> tournament,
}) {
  final status = _statusFromLive(registration, tournament);
  final rank = _intFrom(registration['finalRank'] ?? registration['position']);
  final eloChange = _nullableInt(registration['eloChange']);
  return PlayerTournamentEntry(
    id: tournamentId,
    name: _text(tournament['name'], fallback: 'Tournament'),
    community: _text(
      tournament['communityName'] ?? tournament['community'],
      fallback: _text(tournament['communityId'], fallback: 'Community'),
    ),
    status: status,
    date: _dateFrom(tournament['startDate'] ?? tournament['date']),
    venue: _text(
      tournament['venue'] ?? tournament['location'],
      fallback: 'Venue TBA',
    ),
    city: _text(tournament['city'], fallback: ''),
    tier: _text(tournament['tier'], fallback: 'STANDARD').toUpperCase(),
    format: _text(
      tournament['bracketType'] ?? tournament['format'],
      fallback: 'Tournament',
    ),
    fee: _rupiah(_intFrom(tournament['registrationFee'])),
    registrationStatus:
        _text(registration['registrationStatus'], fallback: 'pending'),
    paymentStatus: _text(registration['paymentStatus'], fallback: 'pending'),
    registered: _intFrom(tournament['currentParticipantCount']),
    capacity: _intFrom(tournament['maxParticipants'], fallback: 0),
    color: _colorForStatus(status),
    deck: _text(registration['deckName'], fallback: 'Registered deck'),
    ticketId: registrationId,
    playerName: _text(registration['playerName'], fallback: 'Player'),
    playerCode: _text(
      registration['playerCode'] ?? registration['playerId'],
      fallback: registrationId,
    ),
    result: rank > 0 ? 'TOP $rank' : registration['result']?.toString(),
    position: rank > 0 ? rank : null,
    eloChange: eloChange,
    prize: registration['prize']?.toString(),
  );
}

PlayerTournamentStatus _statusFromLive(
  Map<String, dynamic> registration,
  Map<String, dynamic> tournament,
) {
  final registrationStatus =
      _text(registration['registrationStatus']).toLowerCase();
  final paymentStatus = _text(registration['paymentStatus']).toLowerCase();
  final checkInStatus = _text(registration['checkInStatus']).toLowerCase();
  final tournamentStatus = _text(tournament['status']).toLowerCase();
  if (registrationStatus == 'walkout' ||
      registrationStatus == 'walk_out' ||
      registrationStatus == 'eliminated') {
    return PlayerTournamentStatus.eliminated;
  }
  if (registrationStatus == 'pendingpayment' ||
      registrationStatus == 'pending_payment' ||
      paymentStatus == 'pending' ||
      paymentStatus == 'processing' ||
      paymentStatus == 'unpaid') {
    return PlayerTournamentStatus.pendingPayment;
  }
  if (tournamentStatus == 'completed') return PlayerTournamentStatus.completed;
  if (tournamentStatus == 'running' || tournamentStatus == 'live') {
    return PlayerTournamentStatus.ongoing;
  }
  if (checkInStatus == 'checkedin' || checkInStatus == 'checked_in') {
    return PlayerTournamentStatus.checkedIn;
  }
  return PlayerTournamentStatus.registered;
}

DateTime _dateFrom(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _rupiah(int value) {
  if (value <= 0) return 'FREE';
  final raw = value.toString();
  final parts = <String>[];
  for (var end = raw.length; end > 0; end -= 3) {
    final start = (end - 3).clamp(0, raw.length);
    parts.insert(0, raw.substring(start, end));
  }
  return 'Rp ${parts.join('.')}';
}

int _intFrom(Object? value, {int fallback = 0}) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}

Color _colorForStatus(PlayerTournamentStatus status) {
  return switch (status) {
    PlayerTournamentStatus.pendingPayment => HDTColors.warning,
    PlayerTournamentStatus.ongoing => HDTColors.accent,
    PlayerTournamentStatus.registered => HDTColors.info,
    PlayerTournamentStatus.checkedIn => HDTColors.success,
    PlayerTournamentStatus.completed => HDTColors.text3,
    PlayerTournamentStatus.eliminated => HDTColors.danger,
  };
}

class MyTournamentsScreen extends ConsumerStatefulWidget {
  const MyTournamentsScreen({super.key});

  @override
  ConsumerState<MyTournamentsScreen> createState() =>
      _MyTournamentsScreenState();
}

class _MyTournamentsScreenState extends ConsumerState<MyTournamentsScreen> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(playerTournamentEntriesProvider);
    return live.when(
      loading: () => const Scaffold(
        backgroundColor: HDTColors.bg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _MyTournamentsView(
        filter: _filter,
        tournaments: const [],
        notice:
            'Your tournaments could not be read from Firebase. Refresh or try again after the connection is stable.',
        onFilterChanged: (value) => setState(() => _filter = value),
      ),
      data: (items) => _MyTournamentsView(
        filter: _filter,
        tournaments: items,
        onFilterChanged: (value) => setState(() => _filter = value),
      ),
    );
  }
}

class _MyTournamentsView extends StatelessWidget {
  const _MyTournamentsView({
    required this.filter,
    required this.tournaments,
    required this.onFilterChanged,
    this.notice,
  });

  final String filter;
  final List<PlayerTournamentEntry> tournaments;
  final ValueChanged<String> onFilterChanged;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final filtered = filter == 'ALL'
        ? tournaments
        : tournaments.where((item) => item.statusLabel == filter).toList();
    final completed = tournaments
        .where((item) =>
            item.status == PlayerTournamentStatus.completed ||
            item.status == PlayerTournamentStatus.eliminated)
        .length;
    final wins = tournaments
        .where((item) => item.position != null && item.position == 1)
        .length;
    final top4 = tournaments
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
                            context, '/tournaments'),
                      ),
                      if (notice != null) ...[
                        const SizedBox(height: 12),
                        _Notice(text: notice!),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'TOTAL TOURNAMENTS',
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
                              'PENDING PAYMENT',
                              'ONGOING',
                              'REGISTERED',
                              'COMPLETED',
                              'ELIMINATED',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: HDTFilterChip(
                                  label: filter,
                                  selected: this.filter == filter,
                                  onTap: () => onFilterChanged(filter),
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
                          title: 'NO TOURNAMENTS YET',
                          subtitle:
                              'Register for a tournament first, or change the filter if your event is already listed.',
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

  const _Header({required this.onBack});

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
            child: Text('MY TOURNAMENTS',
                style: HDTText.overline(size: 10, color: HDTColors.text)),
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
            Text('MY TOURNAMENTS', style: HDTText.display(size: 34)),
            const SizedBox(height: 4),
            Text(
              'Riwayat, tiket aktif, dan check-in pass kamu.',
              style: HDTText.body(size: 13, color: HDTColors.text3),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: onFind,
          icon: const Icon(Icons.emoji_events_outlined, size: 14),
          label: const Text('SEARCH TOURNAMENTS'),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: hdtAccentCard(accentColor: HDTColors.warning),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: HDTColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: HDTText.body(size: 12, color: HDTColors.text2),
            ),
          ),
        ],
      ),
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

    return InkWell(
      borderRadius: HDTR.lg,
      onTap: () => Navigator.pushNamed(
        context,
        '/tournaments/detail',
        arguments: {
          ...tournament.toTournamentArgs(),
          'registrationId': tournament.ticketId,
        },
      ),
      child: Container(
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
                'Deck: ${tournament.deck} . ${tournament.registered}/${tournament.capacity} players',
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
                    Text('Result: ${tournament.result}',
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
    final pendingPayment =
        tournament.status == PlayerTournamentStatus.pendingPayment;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (pendingPayment)
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/tournaments/register',
              arguments: tournament.toPaymentArgs(),
            ),
            icon: const Icon(Icons.qr_code_2, size: 13),
            label: const Text('PAY QRIS'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(116, 34)),
          ),
        if (active)
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/tournaments/detail',
              arguments: {
                ...tournament.toTournamentArgs(),
                'registrationId': tournament.ticketId,
              },
            ),
            icon: const Icon(Icons.qr_code_2, size: 13),
            label: const Text('CHECK-IN'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(96, 34)),
          ),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(
            context,
            '/tournaments/detail',
            arguments: {
              ...tournament.toTournamentArgs(),
              'initialTab': 'bracket',
            },
          ),
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
    PlayerTournamentStatus.pendingPayment => (
        HDTColors.warning,
        HDTColors.warning.withValues(alpha: .14),
        'PENDING PAYMENT'
      ),
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
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
