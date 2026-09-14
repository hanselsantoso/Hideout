import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/bey_part.dart';
import '../../data/models/player_deck.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/deck_repository.dart';

class DeckBuilderScreen extends ConsumerStatefulWidget {
  const DeckBuilderScreen({super.key});

  @override
  ConsumerState<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends ConsumerState<DeckBuilderScreen> {
  final _nameController = TextEditingController(text: 'Phantom Reaper');
  var _activeCombo = 0;
  var _activeSlot = DeckSlot.blade;
  var _saving = false;
  String? _editingDeckId;
  bool _routeArgsApplied = false;
  bool _deckLoadedFromArgs = false;
  var _combos = const [
    DeckComboDraft(),
    DeckComboDraft(),
    DeckComboDraft(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsApplied) return;
    _routeArgsApplied = true;
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final deckId = (args['deckId'] ?? '').toString();
    if (deckId.isNotEmpty) _editingDeckId = deckId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(beyPartsCatalogProvider);
    if (_editingDeckId != null && !_deckLoadedFromArgs) {
      final decks = ref.watch(userDecksProvider).valueOrNull;
      PlayerDeck? deck;
      for (final candidate in decks ?? const <PlayerDeck>[]) {
        if (candidate.id == _editingDeckId) {
          deck = candidate;
          break;
        }
      }
      if (deck != null) {
        _deckLoadedFromArgs = true;
        _combos = deck.toDrafts();
        _nameController.text = deck.name;
      }
    }

    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: SafeArea(
        child: catalog.when(
          data: _buildLoaded,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _DeckError(),
        ),
      ),
    );
  }

  Widget _buildLoaded(BeyPartsCatalog catalog) {
    final issues = validateDeck(catalog, _combos);
    final deckStats = _deckStats(catalog);

    return Column(
      children: [
        _TopBar(
          nameController: _nameController,
          valid: issues.isEmpty,
          saving: _saving,
          onBack: () => Navigator.maybePop(context),
          onSave: () => _saveDeck(catalog, issues),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final content = _DeckCanvas(
                catalog: catalog,
                combos: _combos,
                activeCombo: _activeCombo,
                activeSlot: _activeSlot,
                onSlot: (combo, slot) {
                  setState(() {
                    _activeCombo = combo;
                    _activeSlot = slot;
                  });
                  if (!wide) {
                    _showPartPicker(catalog, combo, slot);
                  }
                },
                onClear: _clearSlot,
              );
              final side = _PartLibrary(
                catalog: catalog,
                activeSlot: _activeSlot,
                selectedId: _combos[_activeCombo].valueFor(_activeSlot),
                blockedIds: _selectedIdsExcept(
                  _combos[_activeCombo].valueFor(_activeSlot),
                ),
                onPick: (part) => _pickPart(catalog, part),
              );

              if (!wide) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
                  children: [
                    _DeckSummary(stats: deckStats, issues: issues),
                    const SizedBox(height: 16),
                    content,
                    const SizedBox(height: 16),
                    _MobilePickerHint(
                      slot: _activeSlot,
                      onOpen: () => _showPartPicker(
                        catalog,
                        _activeCombo,
                        _activeSlot,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 7,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(28, 28, 18, 90),
                      children: [
                        _DeckSummary(stats: deckStats, issues: issues),
                        const SizedBox(height: 18),
                        content,
                      ],
                    ),
                  ),
                  Container(width: 1, color: HDTColors.s2),
                  SizedBox(
                    width: 390,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 28, 28, 90),
                      children: [side],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  PartStats _deckStats(BeyPartsCatalog catalog) {
    var stats = const PartStats();
    for (final combo in _combos) {
      stats = stats + comboStats(catalog, combo);
    }
    return PartStats(
      attack: (stats.attack / 3).round(),
      defense: (stats.defense / 3).round(),
      stamina: (stats.stamina / 3).round(),
      xDash: (stats.xDash / 3).round(),
      burstResistance: (stats.burstResistance / 3).round(),
    );
  }

  Set<String> _selectedIdsExcept(String? current) {
    final selected = _combos.expand((combo) => combo.selectedIds()).toSet();
    if (current != null) selected.remove(current);
    return selected;
  }

  void _clearSlot(int comboIndex, DeckSlot slot) {
    setState(() {
      _combos = [
        for (var i = 0; i < _combos.length; i++)
          if (i == comboIndex)
            _combos[i].copyWithSlot(slot, null)
          else
            _combos[i],
      ];
    });
  }

  void _pickPart(BeyPartsCatalog catalog, BeyPart part) {
    _pickPartFor(catalog, _activeCombo, _activeSlot, part);
  }

  void _pickPartFor(
    BeyPartsCatalog catalog,
    int comboIndex,
    DeckSlot slot,
    BeyPart part,
  ) {
    var next = _combos[comboIndex].copyWithSlot(slot, part.id);
    if (slot == DeckSlot.bit) {
      final integrated = catalog.integratedRatchetForBit(part);
      if (integrated != null) {
        next = next.copyWithSlot(DeckSlot.ratchet, integrated.id);
      }
    }
    if (slot == DeckSlot.blade) {
      final integrated = catalog.integratedRatchetForBlade(part);
      if (integrated != null) {
        next = next.copyWithSlot(DeckSlot.ratchet, integrated.id);
      }
    }
    setState(() {
      _combos = [
        for (var i = 0; i < _combos.length; i++)
          if (i == comboIndex) next else _combos[i],
      ];
      _activeCombo = comboIndex;
      _activeSlot = _nextSlot(catalog, next, slot);
    });
  }

  Future<void> _showPartPicker(
    BeyPartsCatalog catalog,
    int comboIndex,
    DeckSlot slot,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: .84,
          minChildSize: .5,
          maxChildSize: .94,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: _PartLibrary(
                catalog: catalog,
                activeSlot: slot,
                selectedId: _combos[comboIndex].valueFor(slot),
                blockedIds: _selectedIdsExcept(
                  _combos[comboIndex].valueFor(slot),
                ),
                modal: true,
                scrollController: scrollController,
                onPick: (part) {
                  _pickPartFor(catalog, comboIndex, slot, part);
                  Navigator.pop(sheetContext);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveDeck(BeyPartsCatalog catalog, List<String> issues) async {
    if (_saving) return;
    if (issues.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deck is not valid yet: ${issues.first}')),
      );
      return;
    }
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to save a deck.')),
      );
      Navigator.pushNamed(context, '/signin');
      return;
    }

    setState(() => _saving = true);
    try {
      final deckId = await ref.read(deckRepositoryProvider).saveDeck(
            ownerId: user.uid,
            name: _nameController.text,
            catalog: catalog,
            combos: _combos,
            deckId: _editingDeckId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deck saved to Firebase: $deckId')),
      );
      Navigator.pushReplacementNamed(context, '/me/decks');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck could not be saved. Try again in a moment.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  DeckSlot _nextSlot(
      BeyPartsCatalog catalog, DeckComboDraft combo, DeckSlot slot) {
    final blade = combo.bladeId == null ? null : catalog.find(combo.bladeId!);
    final isCx = blade?.isCx ?? false;
    final order = isCx
        ? const [
            DeckSlot.blade,
            DeckSlot.assistBlade,
            DeckSlot.lockChip,
            DeckSlot.overBlade,
            DeckSlot.ratchet,
            DeckSlot.bit,
          ]
        : const [DeckSlot.blade, DeckSlot.ratchet, DeckSlot.bit];
    final index = order.indexOf(slot);
    return order[(index + 1).clamp(0, order.length - 1)];
  }
}

class _MobilePickerHint extends StatelessWidget {
  final DeckSlot slot;
  final VoidCallback onOpen;

  const _MobilePickerHint({required this.slot, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onOpen,
      icon: const Icon(Icons.tune, size: 15),
      label: Text('Choose ${slot.label} with search & filter'),
    );
  }
}

class _TopBar extends StatelessWidget {
  final TextEditingController nameController;
  final bool valid;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onSave;

  const _TopBar({
    required this.nameController,
    required this.valid,
    required this.saving,
    required this.onBack,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final nameField = TextField(
          controller: nameController,
          style: HDTText.display(size: compact ? 20 : 24),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Deck name',
            hintStyle: HDTText.display(
                size: compact ? 20 : 24, color: HDTColors.text3),
          ),
        );
        final status = Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: (valid ? HDTColors.success : HDTColors.warning)
                .withValues(alpha: .14),
            borderRadius: HDTR.sm,
            border: Border.all(
              color: valid ? HDTColors.success : HDTColors.warning,
            ),
          ),
          child: Text(
            valid ? 'VALID' : 'NEEDS CHECK',
            style: HDTText.overline(
              size: 8,
              color: valid ? HDTColors.success : HDTColors.warning,
            ),
          ),
        );
        final save = ElevatedButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: 15),
          label: Text(saving ? 'SAVING' : 'SAVE'),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xEA0F1115),
            border: Border(bottom: BorderSide(color: HDTColors.s2)),
          ),
          child: compact
              ? Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: onBack,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(child: nameField),
                        status,
                      ],
                    ),
                    SizedBox(width: double.infinity, child: save),
                  ],
                )
              : Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(child: nameField),
                    status,
                    const SizedBox(width: 10),
                    save,
                  ],
                ),
        );
      },
    );
  }
}

class _DeckSummary extends StatelessWidget {
  final PartStats stats;
  final List<String> issues;

  const _DeckSummary({required this.stats, required this.issues});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: hdtCard(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final profile = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DECK PROFILE', style: HDTText.overline(size: 10)),
              const SizedBox(height: 6),
              Text(
                'Standard format: no duplicate parts. CX unlocks Assist + Lock Chip + optional Over Blade.',
                style: HDTText.body(size: 12, color: HDTColors.text2),
              ),
            ],
          );
          final statPills = Row(
            mainAxisAlignment:
                compact ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              _StatPill(
                  label: 'ATK',
                  value: stats.attack,
                  color: HDTColors.accentHover,
                  compact: compact),
              _StatPill(
                  label: 'DEF',
                  value: stats.defense,
                  color: HDTColors.info,
                  compact: compact),
              _StatPill(
                  label: 'STA',
                  value: stats.stamina,
                  color: HDTColors.success,
                  compact: compact),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                profile,
                const SizedBox(height: 12),
                statPills,
              ] else
                Row(
                  children: [
                    Expanded(child: profile),
                    statPills,
                  ],
                ),
              if (issues.isNotEmpty) ...[
                const SizedBox(height: 14),
                hdtDivider(),
                const SizedBox(height: 12),
                for (final issue in issues.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined,
                            size: 14, color: HDTColors.warning),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(issue,
                              style: HDTText.body(
                                  size: 12, color: HDTColors.text2)),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool compact;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      margin: EdgeInsets.only(left: compact ? 0 : 8, right: compact ? 8 : 0),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        children: [
          Text(label, style: HDTText.overline(size: 8)),
          Text('$value', style: HDTText.display(size: 20, color: color)),
        ],
      ),
    );
  }
}

class _DeckCanvas extends StatelessWidget {
  final BeyPartsCatalog catalog;
  final List<DeckComboDraft> combos;
  final int activeCombo;
  final DeckSlot activeSlot;
  final void Function(int combo, DeckSlot slot) onSlot;
  final void Function(int combo, DeckSlot slot) onClear;

  const _DeckCanvas({
    required this.catalog,
    required this.combos,
    required this.activeCombo,
    required this.activeSlot,
    required this.onSlot,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 760 ? 3 : 1;
        final width = (constraints.maxWidth - ((cols - 1) * 12)) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < combos.length; i++)
              SizedBox(
                width: width,
                child: _ComboCard(
                  index: i,
                  catalog: catalog,
                  combo: combos[i],
                  active: activeCombo == i,
                  activeSlot: activeCombo == i ? activeSlot : null,
                  onSlot: (slot) => onSlot(i, slot),
                  onClear: (slot) => onClear(i, slot),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ComboCard extends StatelessWidget {
  final int index;
  final BeyPartsCatalog catalog;
  final DeckComboDraft combo;
  final bool active;
  final DeckSlot? activeSlot;
  final ValueChanged<DeckSlot> onSlot;
  final ValueChanged<DeckSlot> onClear;

  const _ComboCard({
    required this.index,
    required this.catalog,
    required this.combo,
    required this.active,
    required this.activeSlot,
    required this.onSlot,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final blade = combo.bladeId == null ? null : catalog.find(combo.bladeId!);
    final isCx = blade?.isCx ?? false;
    final slots = isCx
        ? const [
            DeckSlot.blade,
            DeckSlot.assistBlade,
            DeckSlot.lockChip,
            DeckSlot.overBlade,
            DeckSlot.ratchet,
            DeckSlot.bit,
          ]
        : const [DeckSlot.blade, DeckSlot.ratchet, DeckSlot.bit];
    final stats = comboStats(catalog, combo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: hdtCard(
        borderColor: active ? HDTColors.accent : HDTColors.s2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('KOMBO ${index + 1}',
                    style: HDTText.overline(
                        size: 10, color: HDTColors.accentHover)),
              ),
              if (isCx)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: HDTColors.accentDim,
                    borderRadius: HDTR.sm,
                    border: Border.all(color: HDTColors.accent),
                  ),
                  child: Text('CX / 4P',
                      style: HDTText.overline(
                          size: 8, color: HDTColors.accentHover)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (final slot in slots) ...[
            _SlotTile(
              slot: slot,
              partId: combo.valueFor(slot),
              catalog: catalog,
              active: activeSlot == slot,
              onTap: () => onSlot(slot),
              onClear: () => onClear(slot),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          hdtDivider(),
          const SizedBox(height: 12),
          _Bars(stats: stats),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final DeckSlot slot;
  final String? partId;
  final BeyPartsCatalog catalog;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _SlotTile({
    required this.slot,
    required this.partId,
    required this.catalog,
    required this.active,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final part = partId == null ? null : catalog.find(partId!);
    return InkWell(
      borderRadius: HDTR.md,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? HDTColors.accentDim : HDTColors.bg,
          borderRadius: HDTR.md,
          border: Border.all(color: active ? HDTColors.accent : HDTColors.s2),
        ),
        child: Row(
          children: [
            _PartIcon(part: part, slot: slot, size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.label.toUpperCase(),
                      style: HDTText.overline(size: 8)),
                  const SizedBox(height: 3),
                  Text(
                    part?.name ?? 'Choose ${slot.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.body(
                      size: 13,
                      color: part == null ? HDTColors.text3 : HDTColors.text,
                      weight: FontWeight.w600,
                    ),
                  ),
                  if (part != null)
                    Text(
                      '${part.line.isEmpty ? part.type : part.line} . A${part.stats.attack} D${part.stats.defense} S${part.stats.stamina}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HDTText.mono(size: 10, color: HDTColors.text3),
                    ),
                ],
              ),
            ),
            if (part != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 14),
              )
            else
              const Icon(Icons.add, size: 16, color: HDTColors.text3),
          ],
        ),
      ),
    );
  }
}

class _PartLibrary extends StatefulWidget {
  final BeyPartsCatalog catalog;
  final DeckSlot activeSlot;
  final String? selectedId;
  final Set<String> blockedIds;
  final ValueChanged<BeyPart> onPick;
  final bool modal;
  final ScrollController? scrollController;

  const _PartLibrary({
    required this.catalog,
    required this.activeSlot,
    required this.selectedId,
    required this.blockedIds,
    required this.onPick,
    this.modal = false,
    this.scrollController,
  });

  @override
  State<_PartLibrary> createState() => _PartLibraryState();
}

class _PartLibraryState extends State<_PartLibrary> {
  final _search = TextEditingController();
  var _typeFilter = 'All';
  var _lineFilter = 'All';
  var _sortBy = 'Name';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PartLibrary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSlot != widget.activeSlot) {
      _search.clear();
      _typeFilter = 'All';
      _lineFilter = 'All';
      _sortBy = 'Name';
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final baseParts = widget.catalog.bySlot(widget.activeSlot);
    final typeOptions = _options(baseParts.map((part) => part.type));
    final lineOptions = _options(baseParts.map((part) => part.line));
    final parts = baseParts.where((part) {
      final matchesQuery = query.isEmpty ||
          part.name.toLowerCase().contains(query) ||
          (part.alias ?? '').toLowerCase().contains(query) ||
          part.source.any((item) => item.toLowerCase().contains(query));
      final matchesType = _typeFilter == 'All' || part.type == _typeFilter;
      final matchesLine = _lineFilter == 'All' || part.line == _lineFilter;
      return matchesQuery && matchesType && matchesLine;
    }).toList()
      ..sort(_sortParts);

    return Container(
      decoration: hdtCard(bg: widget.modal ? const Color(0xFF151820) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.modal)
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: HDTColors.s3,
                  borderRadius: HDTR.full,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SELECT ${widget.activeSlot.label.toUpperCase()}',
                          style: HDTText.overline(
                              size: 10, color: HDTColors.accentHover)),
                      const SizedBox(height: 3),
                      Text('${parts.length} parts from BeyBrew',
                          style:
                              HDTText.mono(size: 11, color: HDTColors.text3)),
                    ],
                  ),
                ),
                _SourceBadge(),
              ],
            ),
          ),
          hdtDivider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: HDTText.body(size: 13),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 16),
                hintText: 'Search part...',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterDropdown(
                  label: 'Line',
                  value: _lineFilter,
                  values: lineOptions,
                  onChanged: (value) => setState(() => _lineFilter = value),
                ),
                _FilterDropdown(
                  label: 'Type',
                  value: _typeFilter,
                  values: typeOptions,
                  onChanged: (value) => setState(() => _typeFilter = value),
                ),
                _FilterDropdown(
                  label: 'Sort',
                  value: _sortBy,
                  values: const ['Name', 'Attack', 'Defense', 'Stamina'],
                  onChanged: (value) => setState(() => _sortBy = value),
                ),
              ],
            ),
          ),
          if (widget.modal)
            Expanded(child: _PartList(parts: parts, widget: widget))
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 340 ? 2 : 1;
                  final width =
                      (constraints.maxWidth - ((cols - 1) * 8)) / cols;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final part in parts)
                        SizedBox(
                          width: width,
                          child: _PartOption(
                            part: part,
                            slot: widget.activeSlot,
                            selected: widget.selectedId == part.id,
                            blocked: widget.blockedIds.contains(part.id),
                            onPick: () => widget.onPick(part),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  int _sortParts(BeyPart a, BeyPart b) {
    final byStat = switch (_sortBy) {
      'Attack' => b.stats.attack.compareTo(a.stats.attack),
      'Defense' => b.stats.defense.compareTo(a.stats.defense),
      'Stamina' => b.stats.stamina.compareTo(a.stats.stamina),
      _ => 0,
    };
    if (byStat != 0) return byStat;
    return a.name.compareTo(b.name);
  }

  List<String> _options(Iterable<String> raw) {
    final values = raw
        .where((value) => value.trim().isNotEmpty)
        .map((value) => value.trim())
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }
}

class _PartList extends StatelessWidget {
  final List<BeyPart> parts;
  final _PartLibrary widget;

  const _PartList({required this.parts, required this.widget});

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) {
      return Center(
        child: Text('No matching parts.',
            style: HDTText.body(size: 12, color: HDTColors.text3)),
      );
    }
    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: parts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final part = parts[index];
        return _PartOption(
          part: part,
          slot: widget.activeSlot,
          selected: widget.selectedId == part.id,
          blocked: widget.blockedIds.contains(part.id),
          onPick: () => widget.onPick(part),
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : 'All',
        dropdownColor: const Color(0xFF151820),
        iconEnabledColor: HDTColors.text2,
        style: HDTText.body(size: 11),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: HDTText.overline(size: 8),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        ),
        items: [
          for (final item in values)
            DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: HDTText.body(size: 11),
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _PartOption extends StatelessWidget {
  final BeyPart part;
  final DeckSlot slot;
  final bool selected;
  final bool blocked;
  final VoidCallback onPick;

  const _PartOption({
    required this.part,
    required this.slot,
    required this.selected,
    required this.blocked,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: blocked ? .42 : 1,
      child: InkWell(
        borderRadius: HDTR.md,
        onTap: blocked ? null : onPick,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? HDTColors.accentDim : HDTColors.bg,
            borderRadius: HDTR.md,
            border: Border.all(
              color: selected ? HDTColors.accent : HDTColors.s2,
            ),
          ),
          child: Row(
            children: [
              _PartIcon(part: part, slot: slot, size: 38),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HDTText.body(size: 12, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${part.alias ?? part.line} . ${part.type}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HDTText.mono(size: 9, color: HDTColors.text3),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _MiniStat(
                            'A', part.stats.attack, HDTColors.accentHover),
                        _MiniStat('D', part.stats.defense, HDTColors.info),
                        _MiniStat('S', part.stats.stamina, HDTColors.success),
                      ],
                    ),
                  ],
                ),
              ),
              if (blocked)
                const Icon(Icons.block, size: 14, color: HDTColors.danger)
              else if (selected)
                const Icon(Icons.check_circle,
                    size: 15, color: HDTColors.accentHover),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartIcon extends StatelessWidget {
  final BeyPart? part;
  final DeckSlot slot;
  final double size;

  const _PartIcon({required this.part, required this.slot, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(part?.type ?? slot.name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Center(
        child: part?.assetPath == null
            ? _PartInitials(part: part, slot: slot, size: size, color: color)
            : Padding(
                padding: EdgeInsets.all(size * .08),
                child: Image.asset(
                  part!.assetPath!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => _PartInitials(
                    part: part,
                    slot: slot,
                    size: size,
                    color: color,
                  ),
                ),
              ),
      ),
    );
  }
}

class _PartInitials extends StatelessWidget {
  final BeyPart? part;
  final DeckSlot slot;
  final double size;
  final Color color;

  const _PartInitials({
    required this.part,
    required this.slot,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      part?.shortCode ?? slot.label.characters.first.toUpperCase(),
      style: HDTText.display(size: size * .28, color: color),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Text('$label$value', style: HDTText.mono(size: 9, color: color)),
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
      ('X-D', stats.xDash, HDTColors.warning),
      ('BST', stats.burstResistance, const Color(0xFFE67E22)),
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
                      value: (row.$2 / 180).clamp(0, 1),
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

class _SourceBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const BoxDecoration(
        color: HDTColors.s2,
        borderRadius: HDTR.sm,
      ),
      child: Text('BEYBREW', style: HDTText.overline(size: 8)),
    );
  }
}

class _DeckError extends StatelessWidget {
  const _DeckError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Part data could not be read. Try refreshing the page.',
          style: HDTText.body(color: HDTColors.danger),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
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
