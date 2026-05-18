import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../core/widgets/hdt_widgets.dart';
import '../../data/models/tournament_summary.dart';
import '../../data/repositories/tournament_repository.dart';

class TournamentEntry {
  final String id;
  final String name;
  final String community;
  final String status;
  final String format;
  final String tier;
  final String city;
  final String venue;
  final String entryFee;
  final DateTime date;
  final int registered;
  final int capacity;
  final Color color;
  final String? winnerName;
  final String? winnerDeckName;

  const TournamentEntry({
    required this.id,
    required this.name,
    required this.community,
    required this.status,
    required this.format,
    required this.tier,
    required this.city,
    required this.venue,
    required this.entryFee,
    required this.date,
    required this.registered,
    required this.capacity,
    required this.color,
    this.winnerName,
    this.winnerDeckName,
  });

  double get fillPct => capacity <= 0 ? 0 : registered / capacity;

  Map<String, Object> toRouteArgs() => {
        'tournamentId': id,
        'name': name,
        'community': community,
        'status': status,
        'format': format,
        'tier': tier,
        'city': city,
        'venue': venue,
        'fee': entryFee,
        'date': date.toIso8601String(),
        'registered': registered,
        'capacity': capacity,
        if (winnerName != null) 'winnerName': winnerName!,
        if (winnerDeckName != null) 'winnerDeckName': winnerDeckName!,
      };
}

final List<TournamentEntry> demoTournaments = [
  TournamentEntry(
    id: 'bjx-cup-3',
    name: 'HIDEOUT Cup #3. Spring Showdown',
    community: 'JKT Wolves',
    status: 'LIVE',
    date: DateTime(2026, 5, 9),
    venue: 'GBK Senayan',
    city: 'Jakarta',
    registered: 64,
    capacity: 64,
    entryFee: 'Rp 100.000',
    format: 'Swiss to Double Elim',
    tier: 'PREMIER',
    color: HDTColors.accent,
  ),
  TournamentEntry(
    id: 'bjx-cup-4',
    name: 'HIDEOUT Cup #4. Summer Open',
    community: 'JKT Wolves',
    status: 'REGISTRATION OPEN',
    date: DateTime(2026, 6, 14),
    venue: 'GBK Senayan',
    city: 'Jakarta',
    registered: 42,
    capacity: 64,
    entryFee: 'Rp 100.000',
    format: 'Single Elim',
    tier: 'STANDARD',
    color: HDTColors.info,
  ),
  TournamentEntry(
    id: 'sby-ec-1',
    name: 'East Coast Showdown',
    community: 'SBY Spin',
    status: 'LIVE',
    date: DateTime(2026, 5, 9),
    venue: 'Grand City Mall',
    city: 'Surabaya',
    registered: 48,
    capacity: 48,
    entryFee: 'Rp 75.000',
    format: 'Swiss',
    tier: 'STANDARD',
    color: Color(0xFFE94560),
  ),
  TournamentEntry(
    id: 'bdg-highland',
    name: 'Highland Open',
    community: 'BDG Grinders',
    status: 'UPCOMING',
    date: DateTime(2026, 5, 23),
    venue: 'Trans Studio',
    city: 'Bandung',
    registered: 22,
    capacity: 64,
    entryFee: 'Rp 75.000',
    format: 'Round Robin to Single Elim',
    tier: 'STANDARD',
    color: HDTColors.warning,
  ),
  TournamentEntry(
    id: 'ygy-sultanate',
    name: 'Sultanate Series Vol.2',
    community: 'Yogya Meta',
    status: 'REGISTRATION OPEN',
    date: DateTime(2026, 5, 30),
    venue: 'Jogja City Mall',
    city: 'Yogyakarta',
    registered: 18,
    capacity: 32,
    entryFee: 'Rp 60.000',
    format: 'Double Elim',
    tier: 'CASUAL',
    color: Color(0xFF16A085),
  ),
  TournamentEntry(
    id: 'jkt-wkly-19',
    name: 'Weekly Ranked #19',
    community: 'JKT Wolves',
    status: 'UPCOMING',
    date: DateTime(2026, 5, 16),
    venue: 'Senayan Hub',
    city: 'Jakarta',
    registered: 12,
    capacity: 32,
    entryFee: 'Rp 50.000',
    format: 'Swiss',
    tier: 'CASUAL',
    color: Color(0xFF5DADE2),
  ),
  TournamentEntry(
    id: 'mdn-burst-1',
    name: 'Medan Burst Open',
    community: 'Medan Burst',
    status: 'REGISTRATION OPEN',
    date: DateTime(2026, 6, 7),
    venue: 'Medan Fair',
    city: 'Medan',
    registered: 8,
    capacity: 32,
    entryFee: 'Rp 60.000',
    format: 'Single Elim',
    tier: 'CASUAL',
    color: Color(0xFF1ABC9C),
  ),
  TournamentEntry(
    id: 'snyo-apr',
    name: 'Senayan Open. April',
    community: 'JKT Wolves',
    status: 'COMPLETED',
    date: DateTime(2026, 4, 26),
    venue: 'GBK Senayan',
    city: 'Jakarta',
    registered: 48,
    capacity: 48,
    entryFee: 'Rp 100.000',
    format: 'Swiss to Double Elim',
    tier: 'STANDARD',
    color: HDTColors.success,
  ),
  TournamentEntry(
    id: 'bjx-cup-5',
    name: 'HIDEOUT Cup #5. Regional Qualifier',
    community: 'JKT Wolves',
    status: 'UPCOMING',
    date: DateTime(2026, 7, 12),
    venue: 'Trans Studio',
    city: 'Jakarta',
    registered: 6,
    capacity: 128,
    entryFee: 'Rp 150.000',
    format: 'Swiss to Double Elim',
    tier: 'PREMIER',
    color: Color(0xFFE67E22),
  ),
];

class TournamentState {
  final String query;
  final String tier;
  final String status;
  final String city;
  final int page;

  const TournamentState({
    this.query = '',
    this.tier = 'ALL',
    this.status = 'ALL',
    this.city = 'All Cities',
    this.page = 0,
  });

  TournamentState copyWith({
    String? query,
    String? tier,
    String? status,
    String? city,
    int? page,
  }) {
    return TournamentState(
      query: query ?? this.query,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      city: city ?? this.city,
      page: page ?? this.page,
    );
  }

  List<TournamentEntry> filteredFrom(List<TournamentEntry> source) {
    return source.where((t) {
      if (tier != 'ALL' && t.tier != tier) return false;
      if (status != 'ALL' && t.status != status) return false;
      if (city != 'All Cities' && t.city != city) return false;
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchName = t.name.toLowerCase().contains(q);
        final matchCommunity = t.community.toLowerCase().contains(q);
        if (!matchName && !matchCommunity) return false;
      }
      return true;
    }).toList();
  }
}

class TournamentNotifier extends Notifier<TournamentState> {
  @override
  TournamentState build() => const TournamentState();

  void setQuery(String value) => state = state.copyWith(query: value, page: 0);
  void setTier(String value) => state = state.copyWith(tier: value, page: 0);
  void setStatus(String value) =>
      state = state.copyWith(status: value, page: 0);
  void setCity(String value) => state = state.copyWith(city: value, page: 0);
  void setPage(int value) => state = state.copyWith(page: value);
}

final tournamentProvider =
    NotifierProvider<TournamentNotifier, TournamentState>(
        TournamentNotifier.new);

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen> {
  static const _perPage = 6;
  static const _tiers = ['ALL', 'PREMIER', 'STANDARD', 'CASUAL'];
  static const _statuses = [
    'ALL',
    'LIVE',
    'REGISTRATION OPEN',
    'UPCOMING',
    'COMPLETED',
  ];
  static const _cities = [
    'All Cities',
    'Jakarta',
    'Surabaya',
    'Bandung',
    'Yogyakarta',
    'Medan',
  ];

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentProvider);
    final notifier = ref.read(tournamentProvider.notifier);
    final backend = ref.watch(liveTournamentsProvider);
    final backendEntries =
        backend.valueOrNull?.map(_fromBackend).toList() ?? const [];
    final source = backendEntries.isEmpty ? demoTournaments : backendEntries;
    final filtered = state.filteredFrom(source);
    final paginated =
        filtered.skip(state.page * _perPage).take(_perPage).toList();
    final liveCount = source.where((t) => t.status == 'LIVE').length;

    if (_searchController.text != state.query) {
      _searchController.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 90),
          children: [
            _PageHeader(
                total: source.length,
                filtered: filtered.length,
                live: liveCount),
            const SizedBox(height: 24),
            _FilterPanel(
              controller: _searchController,
              state: state,
              tiers: _tiers,
              statuses: _statuses,
              cities: _cities,
              onQuery: notifier.setQuery,
              onTier: notifier.setTier,
              onStatus: notifier.setStatus,
              onCity: notifier.setCity,
            ),
            const SizedBox(height: 20),
            backend.when(
              data: (_) => _SourceHint(
                text: backendEntries.isEmpty
                    ? 'Demo tournament aktif karena Firebase belum memiliki event live.'
                    : '${backendEntries.length} tournament Firebase dimuat.',
              ),
              loading: () => const _SourceHint(
                  text: 'Mengambil tournament terbaru dari Firebase...'),
              error: (_, __) => const _SourceHint(
                  text: 'Firebase belum tersedia. Menampilkan data demo.'),
            ),
            const SizedBox(height: 14),
            if (paginated.isEmpty)
              const HDTEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'NO TOURNAMENTS FOUND',
                subtitle: 'Coba ubah filter atau reset pencarian.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1100
                      ? 3
                      : constraints.maxWidth >= 700
                          ? 2
                          : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 16) / columns;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final tournament in paginated)
                        SizedBox(
                          width: width,
                          child: _TournamentCard(tournament: tournament),
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            HDTPagination(
              total: filtered.length,
              page: state.page,
              perPage: _perPage,
              label: 'turnamen',
              onPage: notifier.setPage,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final int total;
  final int filtered;
  final int live;

  const _PageHeader({
    required this.total,
    required this.filtered,
    required this.live,
  });

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
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('TOURNAMENT BROWSER', style: HDTText.display(size: 36)),
                if (live > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: HDTColors.accent,
                      borderRadius: HDTR.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text('$live LIVE',
                            style: HDTText.overline(
                                size: 10, color: Colors.white)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$filtered turnamen ditemukan dari $total total.',
              style: HDTText.body(size: 13, color: HDTColors.text3),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, '/admin/tournaments/new'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('CREATE EVENT'),
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final TextEditingController controller;
  final TournamentState state;
  final List<String> tiers;
  final List<String> statuses;
  final List<String> cities;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onTier;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onCity;

  const _FilterPanel({
    required this.controller,
    required this.state,
    required this.tiers,
    required this.statuses,
    required this.cities,
    required this.onQuery,
    required this.onTier,
    required this.onStatus,
    required this.onCity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: hdtCard(),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final controls = [
                Expanded(
                  flex: narrow ? 0 : 1,
                  child: HDTSearchField(
                    controller: controller,
                    placeholder: 'Cari turnamen atau komunitas...',
                    onChanged: onQuery,
                  ),
                ),
                _SelectBox(value: state.tier, values: tiers, onChanged: onTier),
                _SelectBox(
                    value: state.status, values: statuses, onChanged: onStatus),
                _SelectBox(
                    value: state.city, values: cities, onChanged: onCity),
              ];

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    controls.first,
                    const SizedBox(height: 10),
                    for (final control in controls.skip(1)) ...[
                      control,
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  controls[0],
                  const SizedBox(width: 10),
                  controls[1],
                  const SizedBox(width: 10),
                  controls[2],
                  const SizedBox(width: 10),
                  controls[3],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final status in const [
                    'LIVE',
                    'REGISTRATION OPEN',
                    'UPCOMING'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: HDTFilterChip(
                        label: status,
                        selected: state.status == status,
                        onTap: () =>
                            onStatus(state.status == status ? 'ALL' : status),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _SelectBox({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: HDTColors.s1,
          iconEnabledColor: HDTColors.text3,
          style: HDTText.body(size: 12, color: HDTColors.text),
          borderRadius: HDTR.md,
          items: [
            for (final item in values)
              DropdownMenuItem(
                value: item,
                child: Text(_label(item)),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }

  String _label(String value) {
    if (value == 'ALL') return 'Semua';
    if (value == 'All Cities') return 'Semua Kota';
    return value;
  }
}

class _TournamentCard extends StatelessWidget {
  final TournamentEntry tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final pct = tournament.fillPct.clamp(0, 1).toDouble();
    final canRegister = tournament.status == 'REGISTRATION OPEN';

    return InkWell(
      borderRadius: HDTR.lg,
      onTap: () => Navigator.pushNamed(
        context,
        '/tournaments/detail',
        arguments: tournament.toRouteArgs(),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: hdtCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: tournament.color.withOpacity(.14),
                    borderRadius: HDTR.sm,
                    border:
                        Border.all(color: tournament.color.withOpacity(.35)),
                  ),
                  child: Icon(Icons.emoji_events_outlined,
                      size: 15, color: tournament.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      tournament.community.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HDTText.overline(size: 9),
                    ),
                  ),
                ),
                HDTTierBadge(tournament.tier),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                HDTStatusBadge(tournament.status),
                const SizedBox(width: 6),
                Text(_date(tournament.date),
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tournament.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: HDTText.display(size: 20, color: Colors.white),
            ),
            const SizedBox(height: 14),
            _MetaLine(
                icon: Icons.calendar_today_outlined,
                text: _longDate(tournament.date)),
            const SizedBox(height: 7),
            _MetaLine(
                icon: Icons.location_on_outlined,
                text: '${tournament.venue} . ${tournament.city}'),
            const SizedBox(height: 7),
            _MetaLine(icon: Icons.filter_alt_outlined, text: tournament.format),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.people_alt_outlined,
                    size: 13, color: HDTColors.text3),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${tournament.registered} / ${tournament.capacity} peserta',
                    style: HDTText.body(size: 11, color: HDTColors.text3),
                  ),
                ),
                Text(_capacityLabel(tournament),
                    style: HDTText.overline(
                      size: 9,
                      color: pct >= 1 ? HDTColors.danger : HDTColors.text3,
                    )),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: HDTR.full,
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: HDTColors.s2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  pct >= 1 ? HDTColors.danger : tournament.color,
                ),
              ),
            ),
            const SizedBox(height: 16),
            hdtDivider(),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(tournament.entryFee,
                    style: HDTText.mono(size: 13, color: HDTColors.text)),
                const Spacer(),
                if (canRegister)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/tournaments/register',
                      arguments: tournament.toRouteArgs(),
                    ),
                    child: const Text('DAFTAR'),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('DETAIL',
                          style: HDTText.overline(
                              size: 10, color: HDTColors.accentHover)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 16, color: HDTColors.accentHover),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capacityLabel(TournamentEntry t) {
    if (t.status == 'COMPLETED') return 'SELESAI';
    if (t.registered >= t.capacity) return 'SOLD OUT';
    return '${(t.fillPct * 100).round()}% FULL';
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: HDTColors.text3),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HDTText.body(size: 12, color: HDTColors.text3),
          ),
        ),
      ],
    );
  }
}

class _SourceHint extends StatelessWidget {
  final String text;

  const _SourceHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: HDTText.mono(size: 11, color: HDTColors.text3));
  }
}

TournamentEntry _fromBackend(TournamentSummary tournament) {
  return TournamentEntry(
    id: tournament.id,
    name: tournament.name,
    community: 'Firebase Community',
    status: switch (tournament.status) {
      'registrationOpen' => 'REGISTRATION OPEN',
      'inProgress' => 'LIVE',
      'running' => 'LIVE',
      'completed' => 'COMPLETED',
      'cancelled' => 'CANCELLED',
      _ => 'UPCOMING',
    },
    date: tournament.startDate ?? DateTime.now(),
    venue: tournament.location.isEmpty ? 'TBA' : tournament.location,
    city: _cityFromLocation(tournament.location),
    registered: tournament.currentParticipantCount,
    capacity: tournament.maxParticipants,
    entryFee: NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(tournament.registrationFee),
    format: tournament.bracketType,
    tier: 'STANDARD',
    color: HDTColors.info,
    winnerName: tournament.winnerName,
    winnerDeckName: tournament.winnerDeckName,
  );
}

String _cityFromLocation(String value) {
  if (value.trim().isEmpty) return 'Jakarta';
  final parts = value.split(',');
  return parts.length > 1 ? parts.last.trim() : parts.first.trim();
}

String _date(DateTime date) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MEI',
    'JUN',
    'JUL',
    'AGU',
    'SEP',
    'OKT',
    'NOV',
    'DES',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String _longDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
