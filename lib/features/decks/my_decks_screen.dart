import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/bey_part.dart';
import '../../data/models/player_deck.dart';
import '../../data/repositories/deck_repository.dart';

class MyDecksScreen extends ConsumerWidget {
  const MyDecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(beyPartsCatalogProvider);
    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: SafeArea(
        child: catalog.when(
          data: (data) => _LoadedDecks(catalog: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text('Data deck gagal dibaca. Coba muat ulang halaman.',
                style: HDTText.body(color: HDTColors.danger)),
          ),
        ),
      ),
    );
  }
}

class _LoadedDecks extends ConsumerWidget {
  final BeyPartsCatalog catalog;

  const _LoadedDecks({required this.catalog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDecks = ref.watch(userDecksProvider);
    final savedDecks = userDecks.valueOrNull ?? const <PlayerDeck>[];
    final decks = savedDecks.isEmpty ? _demoDecks(catalog) : savedDecks;
    final syncLabel = userDecks.isLoading
        ? 'Syncing Firebase decks...'
        : savedDecks.isEmpty
            ? 'Demo decks shown until you save your first deck'
            : '${savedDecks.length} Firebase deck loaded';
    final totalParts = catalog.blades.length +
        catalog.assistBlades.length +
        catalog.ratchets.length +
        catalog.bits.length +
        catalog.lockChips.length +
        catalog.overBlades.length;

    return Column(
      children: [
        _Header(
          totalParts: totalParts,
          syncLabel: syncLabel,
          onBack: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          onNew: () => Navigator.pushNamed(context, '/me/decks/new'),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 1120
                  ? 3
                  : constraints.maxWidth >= 720
                      ? 2
                      : 1;
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 90),
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final deck in decks)
                        SizedBox(
                          width:
                              (constraints.maxWidth - ((cols - 1) * 14)) / cols,
                          child: _DeckCard(deck: deck),
                        ),
                      SizedBox(
                        width:
                            (constraints.maxWidth - ((cols - 1) * 14)) / cols,
                        child: _NewDeckCard(),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int totalParts;
  final String syncLabel;
  final VoidCallback onBack;
  final VoidCallback onNew;

  const _Header({
    required this.totalParts,
    required this.syncLabel,
    required this.onBack,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MY DECKS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.display(size: compact ? 24 : 28),
            ),
            Text(
              'BeyBrew part library: $totalParts parts loaded',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.mono(size: 11, color: HDTColors.text3),
            ),
            Text(
              syncLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.mono(size: 10, color: HDTColors.text3),
            ),
          ],
        );
        final random = OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.auto_awesome, size: 14),
          label: const Text('RANDOM'),
        );
        final newDeck = ElevatedButton.icon(
          onPressed: onNew,
          icon: const Icon(Icons.add, size: 15),
          label: const Text('NEW DECK'),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xEA0F1115),
            border: Border(bottom: BorderSide(color: HDTColors.s2)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: onBack,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(child: title),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: random),
                        const SizedBox(width: 8),
                        Expanded(child: newDeck),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(child: title),
                    random,
                    const SizedBox(width: 8),
                    newDeck,
                  ],
                ),
        );
      },
    );
  }
}

class _DeckCard extends StatelessWidget {
  final PlayerDeck deck;

  const _DeckCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    final stats = deck.stats;
    final issues = deck.issues;

    return InkWell(
      borderRadius: HDTR.lg,
      onTap: () => Navigator.pushNamed(context, '/me/decks/new'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: hdtCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deck.tier, style: HDTText.overline(size: 9)),
                      const SizedBox(height: 4),
                      Text(deck.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HDTText.display(size: 23)),
                    ],
                  ),
                ),
                _ClassBadge(label: deck.deckClass),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < deck.combos.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: i == deck.combos.length - 1 ? 0 : 8),
                      child: _ComboStack(
                        combo: deck.combos[i],
                        number: i + 1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < deck.combos.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '#${i + 1} ${deck.combos[i].compactLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.mono(size: 10, color: HDTColors.text3),
                ),
              ),
            const SizedBox(height: 14),
            hdtDivider(),
            const SizedBox(height: 13),
            _Bars(stats: stats),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  issues.isEmpty
                      ? Icons.verified_outlined
                      : Icons.warning_amber,
                  size: 14,
                  color: issues.isEmpty ? HDTColors.success : HDTColors.warning,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    issues.isEmpty ? 'Standard legal' : issues.first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.body(size: 11, color: HDTColors.text2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComboStack extends StatelessWidget {
  final DeckComboSnapshot combo;
  final int number;

  const _ComboStack({
    required this.combo,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    final parts = [
      combo.blade,
      combo.assistBlade,
      combo.lockChip,
      combo.ratchet,
      combo.bit,
    ].whereType<DeckPartSnapshot>().toList();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: hdtCard(bg: HDTColors.bg),
      child: Column(
        children: [
          for (final part in parts.take(4)) ...[
            _PartBubble(part: part),
            const SizedBox(height: 6),
          ],
          Text('#$number',
              style: HDTText.mono(size: 10, color: HDTColors.accentHover)),
        ],
      ),
    );
  }
}

class _PartBubble extends StatelessWidget {
  final DeckPartSnapshot? part;

  const _PartBubble({required this.part});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(part?.type ?? '');
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Center(
        child: part?.assetPath == null
            ? Text(
                part?.shortCode ?? '?',
                style: HDTText.display(size: 12, color: color),
              )
            : Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  part!.assetPath!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => Text(
                    part?.shortCode ?? '?',
                    style: HDTText.display(size: 12, color: color),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NewDeckCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: HDTR.lg,
      onTap: () => Navigator.pushNamed(context, '/me/decks/new'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 390),
        decoration: BoxDecoration(
          borderRadius: HDTR.lg,
          border: Border.all(color: HDTColors.s3, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: HDTColors.s2),
                ),
                child: const Icon(Icons.add, color: HDTColors.accentHover),
              ),
              const SizedBox(height: 14),
              Text('NEW DECK', style: HDTText.display(size: 20)),
              const SizedBox(height: 4),
              Text('Build 3 kombo dari part BeyBrew',
                  style: HDTText.body(size: 12, color: HDTColors.text3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassBadge extends StatelessWidget {
  final String label;

  const _ClassBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const BoxDecoration(
        color: HDTColors.accent,
        borderRadius: HDTR.sm,
      ),
      child: Text(label, style: HDTText.overline(size: 8, color: Colors.white)),
    );
  }
}

class _Bars extends StatelessWidget {
  final PartStats stats;

  const _Bars({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('ATK', stats.attack, HDTColors.accentHover),
      ('DEF', stats.defense, HDTColors.info),
      ('STA', stats.stamina, HDTColors.success),
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                SizedBox(
                    width: 34,
                    child: Text(row.$1, style: HDTText.overline(size: 8))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: HDTR.full,
                    child: LinearProgressIndicator(
                      value: (row.$2 / 180).clamp(0, 1).toDouble(),
                      minHeight: 4,
                      backgroundColor: HDTColors.bg,
                      valueColor: AlwaysStoppedAnimation(row.$3),
                    ),
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: Text('${row.$2}',
                      textAlign: TextAlign.right,
                      style: HDTText.mono(size: 9, color: row.$3)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

List<PlayerDeck> _demoDecks(BeyPartsCatalog catalog) {
  DeckComboDraft combo(
    String blade,
    String ratchet,
    String bit, {
    String? assist,
    String? lock,
  }) {
    return DeckComboDraft(
      bladeId: _findName(catalog, DeckSlot.blade, blade)?.id,
      ratchetId: _findName(catalog, DeckSlot.ratchet, ratchet)?.id,
      bitId: _findName(catalog, DeckSlot.bit, bit)?.id,
      assistBladeId: assist == null
          ? null
          : _findName(catalog, DeckSlot.assistBlade, assist)?.id,
      lockChipId:
          lock == null ? null : _findName(catalog, DeckSlot.lockChip, lock)?.id,
    );
  }

  return [
    PlayerDeck.fromDraft(
      id: 'demo-phantom-reaper',
      ownerId: 'demo',
      name: 'Phantom Reaper',
      catalog: catalog,
      drafts: [
        combo('Dran Sword', '3-60', 'Flat'),
        combo('Wizard Rod', '9-60', 'Ball'),
        combo('Phoenix Wing', '5-60', 'Point'),
      ],
    ),
    PlayerDeck.fromDraft(
      id: 'demo-cx-lockdown',
      ownerId: 'demo',
      name: 'CX Lockdown',
      catalog: catalog,
      drafts: [
        combo('Arc', '4-55', 'Low Orb', assist: 'Odd', lock: 'Wizard'),
        combo('Brave', '6-60', 'Vortex', assist: 'Slash', lock: 'Dran'),
        combo('Flame', '5-80', 'Wall Ball', assist: 'Bumper', lock: 'Cerberus'),
      ],
    ),
  ];
}

BeyPart? _findName(BeyPartsCatalog catalog, DeckSlot slot, String name) {
  return catalog
      .bySlot(slot)
      .where((part) => part.name.toLowerCase() == name.toLowerCase())
      .firstOrNull;
}

Color _typeColor(String type) {
  return switch (type.toLowerCase()) {
    'attack' => HDTColors.warning,
    'defense' => HDTColors.info,
    'stamina' => HDTColors.success,
    'balance' => HDTColors.accentHover,
    _ => HDTColors.text3,
  };
}
