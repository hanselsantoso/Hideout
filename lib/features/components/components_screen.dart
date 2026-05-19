import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../data/models/bey_part.dart';
import '../public/public_top_nav.dart';

class ComponentsScreen extends ConsumerStatefulWidget {
  const ComponentsScreen({super.key});

  @override
  ConsumerState<ComponentsScreen> createState() => _ComponentsScreenState();
}

class _ComponentsScreenState extends ConsumerState<ComponentsScreen> {
  final _search = TextEditingController();
  String _category = 'all';
  String _type = 'all';
  String _sort = 'played_desc';
  int _page = 0;
  final int _pageSize = 24;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(beyPartsCatalogProvider);
    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        titleSpacing: 0,
        title: const PublicTopNav(activeRoute: '/components'),
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Data komponen belum bisa dibaca. Coba muat ulang halaman.',
            style: HDTText.body(color: HDTColors.danger),
          ),
        ),
        data: (data) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(FirestorePaths.componentStats)
              .limit(500)
              .snapshots(),
          builder: (context, snap) {
            final stats = <String, Map<String, dynamic>>{
              for (final doc in snap.data?.docs ?? const [])
                doc.id: Map<String, dynamic>.from(doc.data()),
            };
            return _LoadedComponents(
              catalog: data,
              statByPart: stats,
              search: _search,
              category: _category,
              type: _type,
              sort: _sort,
              page: _page,
              pageSize: _pageSize,
              onCategory: (value) => setState(() {
                _category = value;
                _page = 0;
              }),
              onType: (value) => setState(() {
                _type = value;
                _page = 0;
              }),
              onSort: (value) => setState(() {
                _sort = value;
                _page = 0;
              }),
              onPage: (value) => setState(() => _page = value),
              onSearch: () => setState(() => _page = 0),
            );
          },
        ),
      ),
    );
  }
}

class _LoadedComponents extends StatelessWidget {
  const _LoadedComponents({
    required this.catalog,
    required this.statByPart,
    required this.search,
    required this.category,
    required this.type,
    required this.sort,
    required this.page,
    required this.pageSize,
    required this.onCategory,
    required this.onType,
    required this.onSort,
    required this.onPage,
    required this.onSearch,
  });

  final BeyPartsCatalog catalog;
  final Map<String, Map<String, dynamic>> statByPart;
  final TextEditingController search;
  final String category;
  final String type;
  final String sort;
  final int page;
  final int pageSize;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onType;
  final ValueChanged<String> onSort;
  final ValueChanged<int> onPage;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final filteredParts = _allParts(catalog).where((part) {
      final matchesQuery = query.isEmpty ||
          part.name.toLowerCase().contains(query) ||
          (part.alias ?? '').toLowerCase().contains(query) ||
          part.line.toLowerCase().contains(query);
      final matchesCategory = category == 'all' || part.category == category;
      final matchesType = type == 'all' || part.type == type;
      return matchesQuery && matchesCategory && matchesType;
    }).toList()
      ..sort((a, b) => _compareParts(a, b, sort, statByPart));
    final totalPages =
        filteredParts.isEmpty ? 1 : (filteredParts.length / pageSize).ceil();
    final currentPage = page.clamp(0, totalPages - 1).toInt();
    final start = currentPage * pageSize;
    final end = start + pageSize > filteredParts.length
        ? filteredParts.length
        : start + pageSize;
    final visibleParts =
        filteredParts.isEmpty ? <BeyPart>[] : filteredParts.sublist(start, end);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
      children: [
        Text('ALL PARTS', style: HDTText.display(size: 48)),
        const SizedBox(height: HDTSpace.sm),
        Text(
          'Browse data BeyBrew bawaan dan part tambahan dari super admin. Stat deck dipakai saat user build deck, sedangkan performance berubah otomatis dari match.',
          style: HDTText.body(size: 14, color: HDTColors.text2, height: 1.5),
        ),
        const SizedBox(height: HDTSpace.xl),
        Wrap(
          spacing: HDTSpace.md,
          runSpacing: HDTSpace.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: search,
                onChanged: (_) => onSearch(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search part...',
                ),
              ),
            ),
            _FilterMenu(
              value: category,
              items: const {
                'all': 'All categories',
                'blades': 'Blade',
                'assist_blades': 'Assist Blade',
                'over_blades': 'Over Blade',
                'lock_chips': 'Lock Chip',
                'ratchets': 'Ratchet',
                'bits': 'Bit',
              },
              onChanged: onCategory,
            ),
            _FilterMenu(
              value: type,
              items: const {
                'all': 'All types',
                'attack': 'Attack',
                'defense': 'Defense',
                'stamina': 'Stamina',
                'balance': 'Balance',
              },
              onChanged: onType,
            ),
            _FilterMenu(
              value: sort,
              width: 220,
              items: const {
                'played_desc': 'Most played',
                'win_rate_desc': 'Highest win rate',
                'name_asc': 'Name A-Z',
                'category_asc': 'Category',
                'attack_desc': 'Highest attack',
                'total_desc': 'Highest total stat',
              },
              onChanged: onSort,
            ),
            Text('${filteredParts.length} parts',
                style: HDTText.mono(size: 11, color: HDTColors.text3)),
          ],
        ),
        const SizedBox(height: HDTSpace.xl),
        _PaginationSummary(
          start: filteredParts.isEmpty ? 0 : start + 1,
          end: end,
          total: filteredParts.length,
          page: currentPage,
          totalPages: totalPages,
          onPage: onPage,
        ),
        const SizedBox(height: HDTSpace.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 1160
                ? 4
                : constraints.maxWidth >= 850
                    ? 3
                    : constraints.maxWidth >= 560
                        ? 2
                        : 1;
            final width =
                (constraints.maxWidth - (cols - 1) * HDTSpace.md) / cols;
            return Wrap(
              spacing: HDTSpace.md,
              runSpacing: HDTSpace.md,
              children: visibleParts.isEmpty
                  ? [
                      SizedBox(
                        width: constraints.maxWidth,
                        child: const _EmptyComponents(),
                      ),
                    ]
                  : [
                      for (final part in visibleParts)
                        SizedBox(
                          width: width,
                          child: _ComponentCard(
                            part: part,
                            stats: statByPart[part.id] ?? const {},
                          ),
                        ),
                    ],
            );
          },
        ),
        const SizedBox(height: HDTSpace.xl),
        _PaginationSummary(
          start: filteredParts.isEmpty ? 0 : start + 1,
          end: end,
          total: filteredParts.length,
          page: currentPage,
          totalPages: totalPages,
          onPage: onPage,
          compact: true,
        ),
      ],
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 190,
  });

  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(),
        items: [
          for (final entry in items.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (next) => onChanged(next ?? value),
      ),
    );
  }
}

class _PaginationSummary extends StatelessWidget {
  const _PaginationSummary({
    required this.start,
    required this.end,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.onPage,
    this.compact = false,
  });

  final int start;
  final int end;
  final int total;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: HDTSpace.md,
      runSpacing: HDTSpace.sm,
      children: [
        SizedBox(
          width: compact ? 260 : 360,
          child: Text(
            total == 0
                ? 'Tidak ada part yang cocok.'
                : 'Showing $start-$end of $total parts',
            style: HDTText.mono(size: 11, color: HDTColors.text3),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'First page',
              onPressed: page <= 0 ? null : () => onPage(0),
              icon: const Icon(Icons.keyboard_double_arrow_left, size: 18),
            ),
            IconButton(
              tooltip: 'Previous page',
              onPressed: page <= 0 ? null : () => onPage(page - 1),
              icon: const Icon(Icons.chevron_left, size: 18),
            ),
            Container(
              width: 88,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HDTColors.s1,
                borderRadius: HDTR.sm,
                border: Border.all(color: HDTColors.s2),
              ),
              child: Text(
                '${page + 1} / $totalPages',
                style: HDTText.mono(size: 11, color: HDTColors.text2),
              ),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: page >= totalPages - 1 ? null : () => onPage(page + 1),
              icon: const Icon(Icons.chevron_right, size: 18),
            ),
            IconButton(
              tooltip: 'Last page',
              onPressed:
                  page >= totalPages - 1 ? null : () => onPage(totalPages - 1),
              icon: const Icon(Icons.keyboard_double_arrow_right, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyComponents extends StatelessWidget {
  const _EmptyComponents();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration: hdtCard(),
      child: Row(
        children: [
          const Icon(Icons.search_off_outlined, color: HDTColors.text3),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Text(
              'Tidak ada part yang cocok dengan filter ini.',
              style: HDTText.body(size: 13, color: HDTColors.text2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({required this.part, required this.stats});

  final BeyPart part;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final appearances = _intFrom(stats['appearances']);
    final wins = _intFrom(stats['wins']);
    final losses = _intFrom(stats['losses']);
    final winRate = wins + losses == 0 ? 0 : wins / (wins + losses) * 100;
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PartImage(part: part),
              const SizedBox(width: HDTSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(part.name, style: HDTText.display(size: 17)),
                    const SizedBox(height: 3),
                    Text(
                      '${_categoryLabel(part.category)} . ${part.type} . ${part.line.isEmpty ? 'No line' : part.line}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HDTText.mono(size: 10, color: HDTColors.text3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          Row(
            children: [
              _MiniStat('A', part.stats.attack, HDTColors.danger),
              _MiniStat('D', part.stats.defense, HDTColors.info),
              _MiniStat('S', part.stats.stamina, HDTColors.success),
              _MiniStat('X', part.stats.xDash, HDTColors.warning),
              _MiniStat('B', part.stats.burstResistance, HDTColors.accent),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          hdtDivider(),
          const SizedBox(height: HDTSpace.md),
          Row(
            children: [
              Expanded(
                child: _MetaValue(label: 'PLAYED', value: '$appearances'),
              ),
              Expanded(
                child: _MetaValue(
                  label: 'WIN RATE',
                  value: '${winRate.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartImage extends StatelessWidget {
  const _PartImage({required this.part});

  final BeyPart part;

  @override
  Widget build(BuildContext context) {
    final path = part.assetPath;
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: path == null
          ? _PartImageFallback(part: part)
          : Image.asset(
              path,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _PartImageFallback(part: part),
            ),
    );
  }
}

class _PartImageFallback extends StatelessWidget {
  const _PartImageFallback({required this.part});

  final BeyPart part;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_categoryIcon(part.category), size: 20, color: HDTColors.text3),
        const SizedBox(height: 3),
        Text(part.shortCode, style: HDTText.overline(size: 9)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        '$label$value',
        style: HDTText.mono(size: 10, color: color),
      ),
    );
  }
}

class _MetaValue extends StatelessWidget {
  const _MetaValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HDTText.overline(size: 8)),
        const SizedBox(height: 3),
        Text(value, style: HDTText.display(size: 18)),
      ],
    );
  }
}

List<BeyPart> _allParts(BeyPartsCatalog catalog) {
  return [
    ...catalog.blades,
    ...catalog.assistBlades,
    ...catalog.overBlades,
    ...catalog.lockChips,
    ...catalog.ratchets,
    ...catalog.bits,
  ];
}

int _compareParts(
  BeyPart a,
  BeyPart b,
  String sort,
  Map<String, Map<String, dynamic>> stats,
) {
  final aStats = stats[a.id] ?? const <String, dynamic>{};
  final bStats = stats[b.id] ?? const <String, dynamic>{};
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  return switch (sort) {
    'win_rate_desc' => _winRate(bStats).compareTo(_winRate(aStats)) == 0
        ? byName
        : _winRate(bStats).compareTo(_winRate(aStats)),
    'name_asc' => byName,
    'category_asc' =>
      a.category == b.category ? byName : a.category.compareTo(b.category),
    'attack_desc' => b.stats.attack == a.stats.attack
        ? byName
        : b.stats.attack.compareTo(a.stats.attack),
    'total_desc' => b.stats.total == a.stats.total
        ? byName
        : b.stats.total.compareTo(a.stats.total),
    _ => _intFrom(bStats['appearances']) == _intFrom(aStats['appearances'])
        ? byName
        : _intFrom(bStats['appearances']).compareTo(
            _intFrom(aStats['appearances']),
          ),
  };
}

double _winRate(Map<String, dynamic> stats) {
  final wins = _intFrom(stats['wins']);
  final losses = _intFrom(stats['losses']);
  if (wins + losses == 0) return 0;
  return wins / (wins + losses) * 100;
}

String _categoryLabel(String value) {
  return switch (value) {
    'assist_blades' => 'Assist Blade',
    'over_blades' => 'Over Blade',
    'lock_chips' => 'Lock Chip',
    'ratchets' => 'Ratchet',
    'bits' => 'Bit',
    _ => 'Blade',
  };
}

IconData _categoryIcon(String value) {
  return switch (value) {
    'assist_blades' => Icons.extension_outlined,
    'over_blades' => Icons.layers_outlined,
    'lock_chips' => Icons.lock_outline,
    'ratchets' => Icons.adjust,
    'bits' => Icons.radio_button_checked,
    _ => Icons.hexagon_outlined,
  };
}

int _intFrom(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
